import os
from flask import Flask, jsonify
import morfeusz2
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Initialize Morfeusz2
try:
    morf = morfeusz2.Morfeusz()
except Exception as e:
    print(f"Error initializing Morfeusz2: {e}")
    morf = None # Handle initialization failure gracefully

@app.route('/analyze/<word>', methods=['GET'])
def analyze_word(word):
    if morf is None:
        return jsonify({"status": "error", "message": "Morfeusz2 analyzer not available."}), 500

    try:
        # Convert word to lowercase
        word = word.lower()
        # Perform analysis
        # result is a list of tuples: (start_pos, end_pos, (lemma, tag, qualifiers...))
        # Example from Morfeusz docs: (0, 3, ('dom', 'subst:sg:nom:m3', ['nazwa_pospolita']))
        analysis_result = morf.analyse(word)

        formatted_results = []
        print(f"Raw analysis result for '{word}': {analysis_result}") # Keep this debug print

        for r in analysis_result:
            print(f"Processing analysis tuple: {r}") # Keep this debug print
            # Based on debug logs, the structure seems to be:
            # analysis_tuple = (lemma, surface_form, tag_and_qualifiers_str, extra_qualifiers_list, ...)
            if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 4:
                analysis_tuple = r[2]
                lemma = analysis_tuple[1]
                # analysis_tuple[1] seems to be the surface form, skipping for now
                tag_with_qualifiers = analysis_tuple[2] # e.g., 'subst:sg:nom:m3'
                extra_qualifiers_list = analysis_tuple[3] if isinstance(analysis_tuple[3], list) else []
                
                # Split tag and main qualifiers from the string
                parts = tag_with_qualifiers.split(':', 1)
                tag = parts[0] # e.g., "subst"
                main_qualifiers_str = parts[1] if len(parts) > 1 else ""
                
                # Combine qualifiers
                main_qualifiers = [q for q in main_qualifiers_str.split(':') if q]
                extra_qualifiers = [str(q) for q in extra_qualifiers_list]
                
                qualifiers = main_qualifiers + extra_qualifiers

                # Ensure we are using the extracted lemma from Morfeusz
                # The lemma is the SECOND element in the Morfeusz tuple
                actual_lemma = analysis_tuple[1] 
                print(f"  -> Parsed: lemma='{actual_lemma}', tag='{tag}', qualifiers={qualifiers}") # Keep debug

                formatted_results.append({
                    "lemma": actual_lemma, # Use the correctly extracted lemma
                    "tag": tag,
                    "qualifiers": qualifiers
                })
            else:
                print(f"  -> Skipping unexpected analysis tuple format: {r}")


        if not formatted_results:
             return jsonify({"status": "success", "word": word, "data": [], "message": "Word not found or no analysis available."}), 200

        # Print the final results being sent as JSON
        print(f"[analyze_word] Returning JSON: {formatted_results}") 
        return jsonify({"status": "success", "word": word, "data": formatted_results})

    except Exception as e:
        print(f"Error during analysis for '{word}': {e}")
        return jsonify({"status": "error", "message": f"An error occurred during analysis: {e}"}), 500

# Helper function to check if a tag represents a verb
def is_verb(tag):
    # Add more verb tags if needed based on Morfeusz tagset
    return tag in ['fin', 'bedzie', 'impt', 'imps', 'inf', 'pact', 'pant', 'pcon', 'ppas']

# Helper function to check if a tag represents a declinable word (noun, adjective, etc.)
def is_declinable(tag):
    # Add more declinable tags if needed
    return tag in ['subst', 'depr', 'adj', 'adja', 'adjp']

# Helper function to extract the primary gender/animacy tag (m1, m2, m3, f, n1, n2)
def get_primary_analysis_tag(analysis_result):
    if not analysis_result:
        return None
    # Assume the first analysis result is the most likely one
    first_result = analysis_result[0]
    if len(first_result) >= 3 and isinstance(first_result[2], tuple) and len(first_result[2]) >= 3:
        tag_with_qualifiers = first_result[2][2] # e.g., 'subst:sg:nom:m2'
        parts = tag_with_qualifiers.split(':')
        # Find the gender/animacy tag (usually the 4th part for subst)
        for part in parts:
            if part in ['m1', 'm2', 'm3', 'f', 'n1', 'n2']:
                print(f"[Debug] Primary tag identified: {part}")
                return part
    print("[Debug] Could not identify primary tag from first analysis.")
    return None

# Helper function to extract the gender/animacy tag from a generated form's tag
def get_form_tag_gender_animacy(form_tag_full):
     parts = form_tag_full.split(':')
     for part in parts:
         if part in ['m1', 'm2', 'm3', 'f', 'n1', 'n2']:
             return part
     return None

# Helper function to generate forms and format them (MODIFIED)
def generate_and_format_forms(word, check_func):
    if morf is None:
        return jsonify({"status": "error", "message": "Morfeusz2 analyzer not available."}), 500

    try:
        # Convert word to lowercase before analysis
        word = word.lower()
        analysis_result = morf.analyse(word)
        if not analysis_result:
            return jsonify({"status": "success", "word": word, "data": [], "message": "Word not found or cannot be analyzed."}), 200

        # --- Get the primary tag of the input word ---
        primary_tag_gender = get_primary_analysis_tag(analysis_result)
        # --------------------------------------------

        generated_data = []
        processed_lemmas = set()

        for r in analysis_result:
            lemma = None
            tag = None
            # Based on debug logs, the structure seems to be:
            # analysis_tuple = (lemma, surface_form, tag_and_qualifiers_str, extra_qualifiers_list, ...)
            if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3: # Need at least 3 elements in inner tuple
                analysis_tuple = r[2]
                lemma = analysis_tuple[1]
                tag_with_qualifiers = analysis_tuple[2] # e.g., 'subst:sg:nom:m3'
                tag = tag_with_qualifiers.split(':', 1)[0] # Get base tag like 'subst'
            else:
                 print(f"[generate_and_format_forms] Skipping unexpected analysis tuple format: {r}")
                 continue # Skip to next analysis result

            if tag and check_func(tag) and lemma not in processed_lemmas:
                processed_lemmas.add(lemma)
                generated_forms_raw = morf.generate(lemma)
                print(f"  -> Raw generated forms for lemma '{lemma}': {generated_forms_raw}") # DEBUG

                formatted_forms = []
                for form_tuple in generated_forms_raw:
                    print(f"    >> Processing generated tuple: {form_tuple}") # DEBUG
                    if len(form_tuple) >= 3:
                        form = form_tuple[0]
                        form_lemma_full = form_tuple[1]
                        form_tag_full = form_tuple[2]

                        base_form_lemma = form_lemma_full.split(':', 1)[0]
                        base_tag = form_tag_full.split(':', 1)[0]
                        form_gender_animacy = get_form_tag_gender_animacy(form_tag_full)
                        is_plural = ':pl:' in form_tag_full # Check if it's a plural form

                        print(f"      Extracted: form='{form}', base_lemma='{base_form_lemma}', base_tag='{base_tag}', form_gender='{form_gender_animacy}', is_plural={is_plural}, full_tag='{form_tag_full}'") # DEBUG

                        # --- Filtering Logic ---
                        passes_check_func = check_func(base_tag)
                        passes_gender_filter = True # Assume passes by default

                        if primary_tag_gender and form_gender_animacy:
                            # Rule 1: If primary is m1, only accept m1 forms (for plurals mostly)
                            if primary_tag_gender == 'm1' and form_gender_animacy != 'm1' and is_plural:
                                passes_gender_filter = False
                            # Rule 2: If primary is m2/m3, EXCLUDE m1 forms (for plurals)
                            elif primary_tag_gender in ['m2', 'm3'] and form_gender_animacy == 'm1' and is_plural:
                                passes_gender_filter = False
                            # Rule 3: If primary is f/n1/n2, ensure form matches (less critical for m1 exclusion)
                            elif primary_tag_gender in ['f', 'n1', 'n2'] and form_gender_animacy != primary_tag_gender:
                                # This might be too strict, could allow some cross-gender forms? Revisit if needed.
                                # For now, let's keep it simpler and focus on m1/m2/m3 issue.
                                # We could relax this later if needed.
                                pass # Let's not filter based on f/n for now, focus on m1/m2/m3

                        print(f"      Filters: check_func({base_tag}) -> {passes_check_func}, gender_filter -> {passes_gender_filter} (primary: {primary_tag_gender}, form: {form_gender_animacy}, plural: {is_plural})") # DEBUG

                        if passes_check_func and passes_gender_filter:
                            print(f"      >>>>> Filter PASSED for form '{form}' <<<<<" ) # DEBUG
                            formatted_forms.append({
                                "form": form,
                                "tag": form_tag_full,
                                "qualifiers": list(form_tuple[3:])
                            })
                        else:
                            print(f"      >>>>> Filter FAILED for form '{form}' <<<<<" ) # DEBUG
                    else:
                         print(f"    >> Skipping unexpected generated tuple format: {form_tuple}")

                print(f"  -> Filtered forms count for lemma '{lemma}': {len(formatted_forms)}") # DEBUG
                if formatted_forms:
                     generated_data.append({
                        "lemma": lemma,
                        "forms": formatted_forms
                    })
            elif lemma is not None: # Only print if lemma was parsed
                 print(f"[generate_and_format_forms] Skipping generation for lemma '{lemma}': tag='{tag}', check_func result={check_func(tag)}, already processed={lemma in processed_lemmas}")

        if not generated_data:
             # Return success but indicate no forms match the criteria
             return jsonify({"status": "success", "word": word, "data": [], "message": f"No relevant forms found matching the primary analysis for '{word}'. Check the word or its category."}), 200

        return jsonify({"status": "success", "word": word, "data": generated_data})

    except Exception as e:
        print(f"Error during generation for '{word}': {e}")
        # Consider logging the traceback for better debugging
        import traceback
        traceback.print_exc()
        return jsonify({"status": "error", "message": f"An error occurred during form generation: {e}"}), 500


@app.route('/conjugate/<word>', methods=['GET'])
def conjugate_word(word):
    """Generates verb conjugations for the given word."""
    return generate_and_format_forms(word, is_verb)

@app.route('/decline/<word>', methods=['GET'])
def decline_word(word):
    """Generates declensions for nouns/adjectives related to the given word."""
    return generate_and_format_forms(word, is_declinable)


if __name__ == '__main__':
    # Use Gunicorn's suggested way to run for development if needed,
    # but 'flask run' is generally preferred for development.
    # The Dockerfile uses gunicorn for production.
    app.run(host='0.0.0.0', port=int(os.environ.get("PORT", 8080)), debug=True) 