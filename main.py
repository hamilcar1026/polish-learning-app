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

# Helper function to generate forms and format them
def generate_and_format_forms(word, check_func):
    if morf is None:
        return jsonify({"status": "error", "message": "Morfeusz2 analyzer not available."}), 500

    try:
        # Convert word to lowercase before analysis
        word = word.lower()
        analysis_result = morf.analyse(word)
        if not analysis_result:
            return jsonify({"status": "success", "word": word, "data": [], "message": "Word not found or cannot be analyzed."}), 200

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
                 # Split tag from the string
                tag = tag_with_qualifiers.split(':', 1)[0]
            else:
                 print(f"[generate_and_format_forms] Skipping unexpected analysis tuple format: {r}")
                 continue # Skip to next analysis result

            # Now use the correctly parsed tag for the check_func condition
            if tag and check_func(tag) and lemma not in processed_lemmas:
                processed_lemmas.add(lemma)
                # print(f"[generate_and_format_forms] Generating forms for lemma='{lemma}', tag='{tag}' (check_func passed)") # DEBUG REMOVED
                # Generate all forms for the lemma
                # generate result: list of tuples (form, lemma, tag, qualifiers...)
                generated_forms_raw = morf.generate(lemma)
                # --- ADD DEBUG PRINT BACK --- 
                print(f"  -> Raw generated forms for lemma '{lemma}': {generated_forms_raw}")
                # --- END DEBUG PRINT BACK ---

                formatted_forms = []
                for form_tuple in generated_forms_raw:
                    # --- ADD DEBUG PRINT BACK --- 
                    print(f"    >> Processing generated tuple: {form_tuple}")
                    # --- END DEBUG PRINT BACK ---
                    if len(form_tuple) >= 3:
                        form_lemma_full = form_tuple[1] # e.g., 'nowy:S' or 'nowy:A'
                        form_tag_full = form_tuple[2] 
                        
                        # Extract base lemma and base tag for filtering
                        base_form_lemma = form_lemma_full.split(':', 1)[0]
                        base_tag = form_tag_full.split(':', 1)[0] 

                        # --- ADD MORE DEBUG BACK --- 
                        print(f"      Extracted: form='{form_tuple[0]}', base_lemma='{base_form_lemma}', base_tag='{base_tag}', full_tag='{form_tag_full}'")
                        # --- END DEBUG BACK ---

                        # Compare BASE lemmas - REMOVE filter1
                        # filter1 = base_form_lemma == lemma 
                        filter2 = check_func(base_tag)
                        # --- ADD DEBUG PRINT BACK --- 
                        print(f"      Filters: check_func('{base_tag}') -> {filter2} (using base tag)") 
                        # --- END DEBUG PRINT BACK ---

                        # Only check filter2 now
                        if filter2:
                            print(f"      >>>>> Filter PASSED for form '{form_tuple[0]}' <<<<<") # ADD DEBUG BACK
                            formatted_forms.append({
                                "form": form_tuple[0],
                                "tag": form_tag_full, # Keep the full tag for the response
                                "qualifiers": list(form_tuple[3:]) 
                            })
                        else:
                            print(f"      >>>>> Filter FAILED for form '{form_tuple[0]}' <<<<<") # ADD DEBUG BACK
                    else:
                        print(f"    >> Skipping unexpected generated tuple format: {form_tuple}") # Keep this potentially useful one?
                # --- ADD DEBUG PRINT BACK --- 
                print(f"  -> Filtered forms count for lemma '{lemma}': {len(formatted_forms)}")
                # --- END DEBUG PRINT BACK --- 
                if formatted_forms:
                     generated_data.append({
                        "lemma": lemma,
                        "forms": formatted_forms
                    })
            # Add an else case for debugging why the block might be skipped
            elif lemma is not None: # Only print if lemma was parsed
                 print(f"[generate_and_format_forms] Skipping generation for lemma '{lemma}': tag='{tag}', check_func result={check_func(tag)}, already processed={lemma in processed_lemmas}")

        if not generated_data:
            return jsonify({"status": "success", "word": word, "data": [], "message": f"No relevant forms found for '{word}'. It might not be the expected part of speech."}), 200

        return jsonify({"status": "success", "word": word, "data": generated_data})

    except Exception as e:
        print(f"Error during generation for '{word}': {e}")
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