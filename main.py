import os
import requests # 추가
from flask import Flask, jsonify, request
import morfeusz2
from flask_cors import CORS
import logging # 상단에 추가

app = Flask(__name__)
CORS(app)

# --- 로거 설정 (선택 사항이지만 추가하면 좋음) ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
# ---------------------------------------------

# --- Lingvanex API Key ---
LINGVANEX_API_KEY = os.environ.get("LINGVANEX_API_KEY")
if not LINGVANEX_API_KEY:
    print("WARNING: LINGVANEX_API_KEY environment variable not set. Translation feature will be disabled.")
# --------------------------

# Initialize Morfeusz2
try:
    morf = morfeusz2.Morfeusz()
except Exception as e:
    print(f"Error initializing Morfeusz2: {e}")
    morf = None # Handle initialization failure gracefully

# --- Lingvanex Translation Function ---
def translate_text_lingvanex(text, target_language):
    if not LINGVANEX_API_KEY:
        return None # API 키 없으면 번역 안 함

    api_url = "https://api-b2b.backenster.com/b1/api/v3/translate"
    # API 키 형식 확인 필요 (Bearer 토큰인지, 다른 형식인지)
    # Lingvanex 문서에 따라 Authorization 헤더 형식을 맞춰야 함
    # 예시에서는 Bearer 토큰으로 가정
    headers = {
        "Authorization": f"Bearer {LINGVANEX_API_KEY}",
        "Content-Type": "application/json",
        "accept": "application/json"
    }
    payload = {
        "platform": "api",
        "from": "pl_PL", # 항상 폴란드어에서 출발
        # Lingvanex 언어 코드 형식 확인 필요 (e.g., 'en' or 'en_US')
        # 문서에는 en_GB, de_DE 등이 예시로 나와있으므로 xx_XX 형식을 따름
        "to": f"{target_language.lower()}_{target_language.upper()}",
        "data": text,
        "translateMode": "text" # 일반 텍스트 번역
    }

    try:
        logging.warning(f"[Lingvanex] Requesting translation for '{text}' to {target_language}") # Debug print
        response = requests.post(api_url, headers=headers, json=payload, timeout=10) # 10초 타임아웃 추가
        response.raise_for_status() # 오류 발생 시 예외 발생
        result = response.json()
        logging.warning(f"[Lingvanex] Response: {result}") # Debug print
        # 응답 형식 확인 필요 (실제 API 응답 구조에 맞춰야 함)
        # 예시에서는 'result' 키에 번역 결과가 있다고 가정
        if result and "result" in result:
            return result["result"] # 번역된 텍스트 반환
        else:
            logging.warning(f"[Lingvanex] Unexpected response format: {result}")
            return None
    except requests.exceptions.RequestException as e:
        logging.error(f"[Lingvanex] API call failed: {e}")
        # 오류 세부 정보 출력 (옵션)
        # print(f"Response status: {e.response.status_code if e.response else 'N/A'}")
        # print(f"Response text: {e.response.text if e.response else 'N/A'}")
        return None
    except Exception as e:
        logging.error(f"[Lingvanex] Error processing translation: {e}")
        return None
# -------------------------------------

# --- Lingvanex Dictionary Function ---
def get_dictionary_info_lingvanex(text, target_language):
    """Fetches dictionary information (especially examples) from Lingvanex Dictionary API.
    Uses the structure: POST https://api-b2b.backenster.com/b1/api/v3/lookupDictionary with Bearer token and JSON payload.
    """
    if not LINGVANEX_API_KEY:
        print("[Lingvanex Dict] API key not set, skipping dictionary lookup.")
        return None

    # Corrected endpoint and parameters based on user image (POST to /lookupDictionary)
    api_url = "https://api-b2b.backenster.com/b1/api/v3/lookupDictionary"
    headers = {
        "Authorization": f"Bearer {LINGVANEX_API_KEY}", # Use Bearer token auth
        "Content-Type": "application/json", # Need Content-Type for POST JSON
        "accept": "application/json"
    }
    # Parameters go in the JSON payload for POST
    payload = {
        "platform": "api",
        "text": text,
        "src_lang": "pl", # Source language code (Polish)
        "dst_lang": target_language.lower() # Target language code (e.g., 'en')
    }

    try:
        logging.warning(f"[Lingvanex Dict] Requesting dictionary info for '{text}' in {target_language} using POST to /lookupDictionary")
        # Use POST request with json payload and headers
        response = requests.post(api_url, headers=headers, json=payload, timeout=15)
        response.raise_for_status() # Raise exception for bad status codes (4xx or 5xx)
        result = response.json()
        logging.warning(f"[Lingvanex Dict] Raw Response: {result}") # Print raw response for debugging

        # --- Extract Examples (Keeping previous guesses, might need adjustment) ---
        extracted_examples = []

        # Guess 1: Direct list in 'examples'
        if "examples" in result and isinstance(result["examples"], list):
            for ex_item in result["examples"]:
                 if isinstance(ex_item, str):
                     extracted_examples.append(ex_item)
                 elif isinstance(ex_item, dict) and "text" in ex_item:
                     extracted_examples.append(str(ex_item["text"]))

        # Guess 2: Nested under a 'result' list, inside 'definitions' or similar
        elif "result" in result and isinstance(result["result"], list):
             for entry in result["result"]:
                 if isinstance(entry, dict):
                     # Check within definitions
                     if "definitions" in entry and isinstance(entry["definitions"], list):
                         for definition in entry["definitions"]:
                             if isinstance(definition, dict) and "examples" in definition and isinstance(definition["examples"], list):
                                 for ex_item in definition["examples"]:
                                     if isinstance(ex_item, str):
                                         extracted_examples.append(ex_item)
                                     elif isinstance(ex_item, dict) and "text" in ex_item:
                                         extracted_examples.append(str(ex_item["text"]))
                     # Check directly in entry
                     elif "examples" in entry and isinstance(entry["examples"], list):
                          for ex_item in entry["examples"]:
                             if isinstance(ex_item, str):
                                 extracted_examples.append(ex_item)
                             elif isinstance(ex_item, dict) and "text" in ex_item:
                                 extracted_examples.append(str(ex_item["text"]))

        # Guess 3: Examples might be associated with translations if provided in same call
        elif "translations" in result and isinstance(result["translations"], list):
             for trans_entry in result["translations"]:
                 if isinstance(trans_entry, dict) and "examples" in trans_entry and isinstance(trans_entry["examples"], list):
                     for ex_item in trans_entry["examples"]:
                         if isinstance(ex_item, str):
                            extracted_examples.append(ex_item)
                         elif isinstance(ex_item, dict) and "text" in ex_item:
                            extracted_examples.append(str(ex_item["text"]))

        if not extracted_examples:
             logging.warning(f"[Lingvanex Dict] No examples found or extracted for '{text}'. Response structure might differ from guesses.")
        else:
             logging.warning(f"[Lingvanex Dict] Extracted examples for '{text}': {extracted_examples}")

        return extracted_examples # Return list of example strings

    except requests.exceptions.Timeout:
        logging.warning(f"[Lingvanex Dict] API call timed out for '{text}'.")
        return None
    except requests.exceptions.HTTPError as e:
         logging.error(f"[Lingvanex Dict] HTTP Error fetching dictionary info for '{text}': {e.response.status_code} {e.response.reason}")
         # Optionally log response body for more details on error
         logging.error(f"[Lingvanex Dict] Error Response Body: {e.response.text}") # Log error body for inspection
         return None # Indicate failure clearly
    except requests.exceptions.RequestException as e:
        logging.error(f"[Lingvanex Dict] API call failed for '{text}': {e}")
        return None
    except Exception as e:
        logging.error(f"[Lingvanex Dict] Error processing dictionary info for '{text}': {e}")
        return None
# --------------------------------------

@app.route('/analyze/<word>', methods=['GET'])
def analyze_word(word):
    # --- 로깅 모듈 사용으로 변경 ---
    logging.warning(f"[analyze_word] SIMPLIFIED Function called! Received word: {word}") # 수정된 로그 메시지
    # -----------------------------

    # --- 임시로 함수 로직 대부분 주석 처리 ---
    # if morf is None:
    #     logging.error("Morfeusz2 analyzer not available.") # 오류도 logging 사용 권장
    #     return jsonify({"status": "error", "message": "Morfeusz2 analyzer not available."}), 500
    # 
    # target_lang = request.args.get('target_lang', default='en', type=str)
    # # logging.info(f"[analyze_word] Target language requested: {target_lang} for word: {word}") # 필요시 INFO 레벨 사용
    # 
    # try:
    #     original_word_lower = word.lower()
    # 
    #     # --- Attempt 1: Analyze the original word --- 
    #     # logging.info(f"[analyze_word] Attempt 1: Analyzing original word '{original_word_lower}'")
    #     analysis_result = morf.analyse(original_word_lower)
    # 
    #     # --- Improved Check: Ensure analysis has valid (non-'ign') results --- 
    #     # Check if analysis_result is not empty AND if any tuple's tag is NOT 'ign'
    #     is_analysis_valid = analysis_result and any(
    #         len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3 and r[2][2].split(':', 1)[0] != 'ign'
    #         for r in analysis_result
    #     )
    # 
    #     if is_analysis_valid:
    #         logging.warning(f"[analyze_word] Attempt 1 SUCCESS: Found valid analysis for '{original_word_lower}'")
    #         # --- Format results and get translation --- 
    #         formatted_results = _format_analysis_results(analysis_result)
    #         if not formatted_results: # Should not happen if analysis_result was non-empty, but check anyway
    #              # Should ideally log an error here
    #              return jsonify({"status": "success", "word": original_word_lower, "data": [], "message": f"Analysis found but formatting failed for '{original_word_lower}'."}), 200
    #         
    #         primary_lemma = formatted_results[0].get("lemma")
    #         cleaned_lemma = _clean_lemma(primary_lemma)
    #         translation_result = None
    #         if cleaned_lemma:
    #             # --- 임시 디버깅 코드 (logging 사용) ---
    #             temp_api_key = os.environ.get("LINGVANEX_API_KEY")
    #             logging.warning(f"[analyze_word] DEBUG: LINGVANEX_API_KEY value before calling translate: {'SET' if temp_api_key else 'NOT SET'}")
    #             # -----------------------------------
    # 
    #             # --- Use Lingvanex for Translation --- 
    #             # logging.info(f"[analyze_word] DEBUG: Calling translate_text_lingvanex with target_lang = {target_lang}")
    #             translation_result = translate_text_lingvanex(cleaned_lemma, target_lang)
    #             # -------------------------------------
    #         
    #         response_data = {
    #             "status": "success",
    #             "word": original_word_lower,
    #             "data": formatted_results,
    #             "translation_en": translation_result # Renamed for clarity
    #         }
    #         # logging.info(f"[analyze_word] Returning JSON (translation is for {target_lang}): {response_data}")
    #         return jsonify(response_data)
    #     else:
    #         # --- Handle cases where original analysis failed or only returned 'ign' --- 
    #         if analysis_result: # If analysis_result exists but only contains 'ign'
    #              logging.warning(f"[analyze_word] Attempt 1 FAILED: Only 'ign' analysis found for '{original_word_lower}'")
    #         else: # If analysis_result is completely empty
    #              logging.warning(f"[analyze_word] Attempt 1 FAILED: No analysis found for '{original_word_lower}'")
    # 
    #     # --- Attempt 2: Try finding suggestions by correcting potential diacritic errors --- 
    #     # ... (Attempt 2 logic commented out) ...
    # 
    #     # --- All attempts failed --- 
    #     logging.warning(f"[analyze_word] All attempts failed for '{original_word}'")
    #     
    #     # --- Attempt to translate the original word even if analysis failed --- 
    #     # ... (Fallback translation logic commented out) ...
    #
    # except Exception as e:
    #     logging.error(f"Error during analysis for '{word}': {e}")
    #     # TODO: Localize message
    #     return jsonify({"status": "error", "message": f"An error occurred during analysis: {e}"}), 500
    # ---------------------------------------

    # --- 즉시 간단한 응답 반환 ---
    return jsonify({"status": "simplified_test", "message": f"analyze_word called for {word}"})
    # -----------------------------

# --- Helper function to format analysis results (extracted logic) --- 
def _format_analysis_results(analysis_result):
    formatted_results = []
    logging.warning(f"Raw analysis result for formatting: {analysis_result}") 
    for r in analysis_result:
        logging.warning(f"Processing analysis tuple: {r}") 
        if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 4:
            analysis_tuple = r[2]
            lemma = analysis_tuple[1]
            tag_with_qualifiers = analysis_tuple[2]
            extra_qualifiers_list = analysis_tuple[3] if isinstance(analysis_tuple[3], list) else []
            
            parts = tag_with_qualifiers.split(':', 1)
            tag = parts[0]
            main_qualifiers_str = parts[1] if len(parts) > 1 else ""
            
            main_qualifiers = [q for q in main_qualifiers_str.split(':') if q]
            extra_qualifiers = [str(q) for q in extra_qualifiers_list]
            qualifiers = main_qualifiers + extra_qualifiers

            actual_lemma = analysis_tuple[1] 
            logging.warning(f"  -> Parsed: lemma='{actual_lemma}', tag='{tag}', qualifiers={qualifiers}")
            formatted_results.append({
                "lemma": actual_lemma,
                "tag": tag,
                "qualifiers": qualifiers
            })
        else:
            logging.warning(f"  -> Skipping unexpected analysis tuple format: {r}")
    return formatted_results

# --- Helper function to clean lemma (extracted logic) ---
def _clean_lemma(lemma):
    if lemma and ':' in lemma:
        cleaned = lemma.split(':', 1)[0]
        logging.warning(f"[lemma cleaning] Cleaned '{lemma}' to '{cleaned}'")
        return cleaned
    return lemma

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

    logging.warning(f"[Debug] Final primary tag identified: {primary_tag}")
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
        # 오류 처리 수정: 함수는 직접 jsonify를 반환하는 대신 처리 결과를 반환해야 함
        return None, "Morfeusz2 analyzer not available."

    try:
        word = word.lower()
        analysis_result = morf.analyse(word)
        if not analysis_result:
             return [], "Word not found or cannot be analyzed." # 데이터는 빈 리스트, 메시지 반환

        primary_lemma = None
        primary_tag_full = None
        primary_base_tag = None
        primary_tag_gender = None
        temp_primary_gender = get_primary_analysis_tag(analysis_result)

        for r in analysis_result:
            if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3:
                analysis_tuple = r[2]
                current_lemma = analysis_tuple[1]
                current_tag_full = analysis_tuple[2]
                current_base_tag = current_tag_full.split(':', 1)[0]
                current_gender = get_form_tag_gender_animacy(current_tag_full)
                if check_func(current_base_tag):
                    if temp_primary_gender is None or current_gender == temp_primary_gender:
                         primary_lemma = current_lemma
                         primary_tag_full = current_tag_full
                         primary_base_tag = current_base_tag
                         primary_tag_gender = current_gender
                         logging.warning(f"[generate_and_format_forms] Selected primary analysis: lemma='{primary_lemma}', tag='{primary_tag_full}'")
                         break
                    elif primary_lemma is None:
                         primary_lemma = current_lemma
                         primary_tag_full = current_tag_full
                         primary_base_tag = current_base_tag
                         primary_tag_gender = current_gender
                         logging.warning(f"[generate_and_format_forms] Selected fallback primary analysis (gender mismatch): lemma='{primary_lemma}', tag='{primary_tag_full}'")
            else:
                 logging.warning(f"[generate_and_format_forms] Skipping unexpected analysis tuple format in primary search: {r}")

        if primary_lemma is None:
             logging.warning(f"[generate_and_format_forms] No primary lemma matching check_func found for '{word}'.")
             # 오류 처리 수정: 빈 리스트와 메시지 반환
             return [], f"No analysis matching the required type (verb/declinable) found for '{word}'."

        generated_forms_raw = morf.generate(primary_lemma)
        logging.warning(f"  -> Raw generated forms for primary lemma '{primary_lemma}': {generated_forms_raw}") # DEBUG

        formatted_forms = []
        present_3sg = None
        present_3pl = None

        for form_tuple in generated_forms_raw:
            logging.warning(f"    >> Processing generated tuple: {form_tuple}") # DEBUG
            if len(form_tuple) >= 3:
                form = form_tuple[0]
                form_lemma_full = form_tuple[1]
                form_tag_full = form_tuple[2]
                base_tag = form_tag_full.split(':', 1)[0]
                form_gender_animacy = get_form_tag_gender_animacy(form_tag_full)
                is_plural = ':pl:' in form_tag_full
                is_singular = ':sg:' in form_tag_full
                is_3rd_person = ':ter:' in form_tag_full
                logging.warning(f"      Extracted: form='{form}', base_tag='{base_tag}', form_gender='{form_gender_animacy}', is_plural={is_plural}, full_tag='{form_tag_full}'") # DEBUG

                if base_tag == 'fin' and is_3rd_person:
                    if is_singular:
                        present_3sg = {"form": form, "tag": form_tag_full, "qualifiers": list(form_tuple[3:])}
                        logging.warning(f"      >> Stored present_3sg: {present_3sg}")
                    elif is_plural:
                        present_3pl = {"form": form, "tag": form_tag_full, "qualifiers": list(form_tuple[3:])}
                        logging.warning(f"      >> Stored present_3pl: {present_3pl}")

                passes_check_func = check_func(base_tag)
                passes_gender_filter = True
                if primary_tag_gender and form_gender_animacy:
                    if primary_tag_gender == 'm1' and form_gender_animacy != 'm1' and is_plural:
                        passes_gender_filter = False
                    elif primary_tag_gender in ['m2', 'm3'] and form_gender_animacy == 'm1' and is_plural:
                        passes_gender_filter = False
                logging.warning(f"      Filters: check_func({base_tag}) -> {passes_check_func}, gender_filter -> {passes_gender_filter} (primary_word_gender: {primary_tag_gender}, form_gender: {form_gender_animacy}, plural: {is_plural})") # DEBUG

                if passes_check_func and passes_gender_filter:
                    logging.warning(f"      >>>>> Filter PASSED for form '{form}' <<<<<" ) # DEBUG
                    formatted_forms.append({
                        "form": form,
                        "tag": form_tag_full,
                        "qualifiers": list(form_tuple[3:])
                    })
                else:
                     logging.warning(f"      >>>>> Filter FAILED for form '{form}' <<<<<") # DEBUG

        # --- Add 'niech' forms for Imperative ---
        if check_func == is_verb and present_3sg and present_3pl:
            # Create 3rd person singular imperative with 'niech'
            niech_3sg = f"niech {present_3sg['form']}"
            # Tag needs adjustment - maybe 'impt_periph:sg:ter' or similar?
            # For now, just use original tag with a note or custom tag
            impt_tag_sg = 'impt_periph:sg:ter'
            logging.warning(f"      >> Generating 'niech' form (sg): {niech_3sg} with tag {impt_tag_sg}")
            formatted_forms.append({"form": niech_3sg, "tag": impt_tag_sg, "qualifiers": present_3sg['qualifiers']})

            # Create 3rd person plural imperative with 'niech'
            niech_3pl = f"niech {present_3pl['form']}"
            impt_tag_pl = 'impt_periph:pl:ter'
            logging.warning(f"      >> Generating 'niech' form (pl): {niech_3pl} with tag {impt_tag_pl}")
            formatted_forms.append({"form": niech_3pl, "tag": impt_tag_pl, "qualifiers": present_3pl['qualifiers']})
        # ---------------------------------------

        logging.warning(f"  -> Final formatted forms count for lemma '{primary_lemma}': {len(formatted_forms)}") # DEBUG
        # Return lemma and forms separately
        return [{"lemma": primary_lemma, "forms": formatted_forms}], None # Return data and no error message

    except Exception as e:
        logging.error(f"Error during form generation for '{word}': {e}")
        # Return None and error message
        return None, f"An error occurred during form generation: {e}"

@app.route('/conjugate/<word>', methods=['GET'])
def conjugate_word(word):
    data, error_message = generate_and_format_forms(word, is_verb)
    if error_message:
        return jsonify({"status": "error", "message": error_message}), 500
    if data is None or not data: # Check if data is None or empty list
         return jsonify({"status": "success", "word": word, "data": [], "message": f"No conjugation data found for '{word}' or word type mismatch."}), 200
    return jsonify({"status": "success", "word": word, "data": data})

@app.route('/decline/<word>', methods=['GET'])
def decline_word(word):
    data, error_message = generate_and_format_forms(word, is_declinable)
    if error_message:
        return jsonify({"status": "error", "message": error_message}), 500
    if data is None or not data: # Check if data is None or empty list
        return jsonify({"status": "success", "word": word, "data": [], "message": f"No declension data found for '{word}' or word type mismatch."}), 200
    return jsonify({"status": "success", "word": word, "data": data})

if __name__ == '__main__':
    # Use PORT environment variable if available (for Cloud Run), otherwise default to 8080
    port = int(os.environ.get('PORT', 8080))
    # Set debug=False for production/Cloud Run
    # Set debug=True for local development
    is_local_dev = os.environ.get('DEV_ENVIRONMENT') == 'local'
    app.run(debug=is_local_dev, host='0.0.0.0', port=port) 