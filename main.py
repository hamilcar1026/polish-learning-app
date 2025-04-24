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

# Helper function to extract the primary gender/animacy tag (MODIFIED)
def get_primary_analysis_tag(analysis_result):
    if not analysis_result:
        return None

    primary_tag = None
    # Look through the first few analysis results
    for result_tuple in analysis_result[:3]: # Check top 3 results
        if len(result_tuple) >= 3 and isinstance(result_tuple[2], tuple) and len(result_tuple[2]) >= 3:
            tag_with_qualifiers = result_tuple[2][2]
            parts = tag_with_qualifiers.split(':')
            current_tag = None
            for part in parts:
                if part in ['m1', 'm2', 'm3', 'f', 'n1', 'n2']:
                    current_tag = part
                    break # Found the gender tag for this analysis

            if current_tag:
                # Prioritize non-m1 tags (m2/m3) if found first for common nouns/animals potentially
                # If the absolute first result is m1, keep it for now,
                # but if we find m2/m3 later among top results, prefer that.
                # This heuristic might need refinement based on Morfeusz behavior.
                if primary_tag is None: # First valid tag found
                     primary_tag = current_tag
                elif primary_tag == 'm1' and current_tag in ['m2', 'm3']: # Prefer m2/m3 over m1 if found later
                     primary_tag = current_tag
                     break # Found a likely better tag, stop searching
                elif current_tag != 'm1' and primary_tag == 'm1': # Current is non-m1, prev was m1, prefer current
                     primary_tag = current_tag
                     break
                # If primary is already m2/m3/f/n, don't switch back to m1 unless it's the only option.
                # Let's stick with the first reasonable tag found or prefer m2/m3.

    print(f"[Debug] Final primary tag identified: {primary_tag}")
    return primary_tag

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

        # --- Determine the primary lemma and its tag ---
        primary_lemma = None
        primary_tag_full = None # Will store the full tag like 'subst:sg:nom:m2'
        primary_base_tag = None # Will store the base tag like 'subst'
        primary_tag_gender = None # Will store gender tag like 'm2'

        # Find the first analysis result that matches the check_func (is_verb or is_declinable)
        # and determine its primary gender tag using the existing helper.
        # This selects the most likely relevant analysis to generate forms for.
        temp_primary_gender = get_primary_analysis_tag(analysis_result) # Get preferred gender first

        for r in analysis_result:
            if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3:
                analysis_tuple = r[2]
                current_lemma = analysis_tuple[1]
                current_tag_full = analysis_tuple[2]
                current_base_tag = current_tag_full.split(':', 1)[0]
                current_gender = get_form_tag_gender_animacy(current_tag_full)

                # Check if this analysis is of the correct type (verb/declinable)
                # AND if its gender matches the preferred gender (or if preferred gender couldn't be determined)
                if check_func(current_base_tag):
                    if temp_primary_gender is None or current_gender == temp_primary_gender:
                         primary_lemma = current_lemma
                         primary_tag_full = current_tag_full
                         primary_base_tag = current_base_tag
                         primary_tag_gender = current_gender # Use the gender from this chosen tag
                         print(f"[generate_and_format_forms] Selected primary analysis: lemma='{primary_lemma}', tag='{primary_tag_full}'")
                         break # Found the primary analysis, stop searching
                    # If no exact gender match, keep searching but store the first valid type as fallback
                    elif primary_lemma is None:
                         primary_lemma = current_lemma
                         primary_tag_full = current_tag_full
                         primary_base_tag = current_base_tag
                         primary_tag_gender = current_gender
                         print(f"[generate_and_format_forms] Selected fallback primary analysis (gender mismatch): lemma='{primary_lemma}', tag='{primary_tag_full}'")
                         # Continue searching for a gender match

            else:
                 print(f"[generate_and_format_forms] Skipping unexpected analysis tuple format in primary search: {r}")

        # If no suitable primary lemma found after checking all analyses
        if primary_lemma is None:
             print(f"[generate_and_format_forms] No primary lemma matching check_func found for '{word}'.")
             return jsonify({"status": "success", "word": word, "data": [], "message": f"No analysis matching the required type (verb/declinable) found for '{word}'."}), 200


        # --- Generate forms ONLY for the primary lemma ---
        generated_forms_raw = morf.generate(primary_lemma)
        print(f"  -> Raw generated forms for primary lemma '{primary_lemma}': {generated_forms_raw}") # DEBUG

        formatted_forms = []
        for form_tuple in generated_forms_raw:
            print(f"    >> Processing generated tuple: {form_tuple}") # DEBUG
            if len(form_tuple) >= 3:
                form = form_tuple[0]
                form_lemma_full = form_tuple[1] # e.g., kot:Sm2
                form_tag_full = form_tuple[2]   # e.g., subst:pl:nom:m2

                # We primarily filter based on the characteristics of the GENERATED form's tag,
                # compared against the PRIMARY analysis gender tag determined earlier.
                base_tag = form_tag_full.split(':', 1)[0]
                form_gender_animacy = get_form_tag_gender_animacy(form_tag_full)
                is_plural = ':pl:' in form_tag_full # Check if it's a plural form

                print(f"      Extracted: form='{form}', base_tag='{base_tag}', form_gender='{form_gender_animacy}', is_plural={is_plural}, full_tag='{form_tag_full}'") # DEBUG

                # --- Filtering Logic (Applied to generated forms) ---
                passes_check_func = check_func(base_tag) # Check if the generated form tag type is correct
                passes_gender_filter = True # Assume passes by default

                # Use the primary_tag_gender determined from the initial analysis for filtering
                if primary_tag_gender and form_gender_animacy:
                    # Rule 1: If primary word tag is m1, only accept m1 forms (for plurals mostly)
                    if primary_tag_gender == 'm1' and form_gender_animacy != 'm1' and is_plural:
                        passes_gender_filter = False
                    # Rule 2: If primary word tag is m2/m3, EXCLUDE m1 forms (for plurals)
                    elif primary_tag_gender in ['m2', 'm3'] and form_gender_animacy == 'm1' and is_plural:
                        passes_gender_filter = False
                    # Rule 3: Relaxed f/n check

                print(f"      Filters: check_func({base_tag}) -> {passes_check_func}, gender_filter -> {passes_gender_filter} (primary_word_gender: {primary_tag_gender}, form_gender: {form_gender_animacy}, plural: {is_plural})") # DEBUG

                if passes_check_func and passes_gender_filter:
                    print(f"      >>>>> Filter PASSED for form '{form}' <<<<<" ) # DEBUG
                    formatted_forms.append({
                        "form": form,
                        "tag": form_tag_full,
                        "qualifiers": list(form_tuple[3:]) # Qualifiers might still be useful
                    })
                else:
                    print(f"      >>>>> Filter FAILED for form '{form}' <<<<<" ) # DEBUG
            else:
                 print(f"    >> Skipping unexpected generated tuple format: {form_tuple}")


        # --- Structure the final output ---
        # Return a list containing zero or one result dictionary
        final_data = []
        if formatted_forms:
             print(f"  -> Final filtered forms count for primary lemma '{primary_lemma}': {len(formatted_forms)}") # DEBUG
             final_data.append({
                "lemma": primary_lemma, # Return the primary lemma
                "forms": formatted_forms
            })
        else:
             print(f"  -> No forms passed filters for primary lemma '{primary_lemma}'.")
             # Return success status but empty data list
             return jsonify({"status": "success", "word": word, "data": [], "message": f"No relevant forms found matching the primary analysis for '{word}'. Check the word or its category."}), 200

        # Always return status: success if processing completed without internal errors
        return jsonify({"status": "success", "word": word, "data": final_data})

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