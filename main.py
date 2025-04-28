import os
import requests # 추가
from flask import Flask, jsonify, request
import morfeusz2
from flask_cors import CORS
import logging

app = Flask(__name__)
# --- CORS 설정 (모든 출처 허용 - 개발용) ---
# origins = [
#     "http://localhost:8000", # 로컬 개발 환경 (필요하다면)
#     "http://localhost:3000", # 또 다른 로컬 개발 환경 포트 (필요하다면)
#     "https://polish-learning-app.web.app", # 배포된 프론트엔드 주소
#     # 필요한 다른 프론트엔드 주소 추가 가능
# ]
CORS(app, supports_credentials=True, methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"]) # origins 파라미터 제거
# ------------------------------------

# --- Lingvanex API Key ---
LINGVANEX_API_KEY = os.environ.get("LINGVANEX_API_KEY")
if not LINGVANEX_API_KEY:
    print("WARNING: LINGVANEX_API_KEY environment variable not set. Translation feature will be disabled.")
# --------------------------

# Initialize Morfeusz2
try:
    # 향상된 옵션으로 Morfeusz2 초기화
    morf = morfeusz2.Morfeusz(praet="composite", aggl="permissive")
    print(f"Morfeusz2 initialized with enhanced options: praet=composite, aggl=permissive")
except Exception as e:
    print(f"Error initializing Morfeusz2: {e}")
    morf = None # Handle initialization failure gracefully

# Add these constants near the top of the file, perhaps after imports
# Auxiliary forms for future imperfective (być)
BYC_FUTURE_FORMS = {
    "sg:pri": "będę",
    "sg:sec": "będziesz",
    "sg:ter": "będzie",
    "pl:pri": "będziemy",
    "pl:sec": "będziecie",
    "pl:ter": "będą",
}

# Conditional particles/endings 'by'
BY_CONDITIONAL_PARTICLES = {
    "sg:pri": "bym",
    "sg:sec": "byś",
    "sg:ter": "by",
    "pl:pri": "byśmy",
    "pl:sec": "byście",
    "pl:ter": "by", # 3rd pl uses the same base particle
}

# Allowed tags (Ensure all needed tags are included)
ALLOWED_TAGS = {'fin', 'impt', 'imps', 'inf', 'pact', 'pant', 'pcon', 'ppas', 'praet', 'bedzie', 'ger', 'cond', 'impt_periph', 'fut_imps', 'cond_imps', 'impt_imps'} # Add all needed impersonal tags

# --- 추가: 곡용 가능한 품사 태그 목록 ---
DECLINABLE_TAGS = {'subst', 'depr', 'adj', 'adja', 'adjp'}
# -------------------------------------

# --- 향상된 비인칭 처리를 위한 새로운 상수 추가 ---
# 비인칭 동사의 się 위치 패턴 (동사에 따라 다를 수 있음)
IMPERSONAL_SIE_PATTERNS = {
    'before': True,  # się가 동사 앞에 오는 경우 (się + 동사)
    'after': False,  # się가 동사 뒤에 오는 경우 (동사 + się)
}

# 명령형 비인칭 접두사
IMPERSONAL_IMPERATIVE_PREFIX = "niech"
# ---------------------------

# --- 하드코딩된 곡용 데이터 --- 
hardcoded_declensions = {
    "ja": {
        "lemma": "ja",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "ja", "tag": "ppron12:sg:nom:m1"},
                {"form": "mnie", "tag": "ppron12:sg:gen:m1"},
                {"form": "mi", "tag": "ppron12:sg:dat:m1"},
                {"form": "mnie", "tag": "ppron12:sg:acc:m1"},
                {"form": "mną", "tag": "ppron12:sg:inst:m1"},
                {"form": "mnie", "tag": "ppron12:sg:loc:m1"},
            ]
        },
        "translation_en": "I" # 번역 정보도 추가
    },
    "ty": {
        "lemma": "ty",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "ty", "tag": "ppron12:sg:nom:m1"},
                {"form": "ciebie", "tag": "ppron12:sg:gen:m1"},
                {"form": "ci", "tag": "ppron12:sg:dat:m1"}, # Short form
                {"form": "tobie", "tag": "ppron12:sg:dat:m1"}, # Long form
                {"form": "ciebie", "tag": "ppron12:sg:acc:m1"},
                {"form": "tobą", "tag": "ppron12:sg:inst:m1"},
                {"form": "tobie", "tag": "ppron12:sg:loc:m1"},
                {"form": "ty", "tag": "ppron12:sg:voc:m1"},
            ]
        },
        "translation_en": "you (sg.)"
    },
    "on": {
        "lemma": "on",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "on", "tag": "ppron3:sg:nom:m1"},
                {"form": "niego", "tag": "ppron3:sg:gen:m1"},
                {"form": "jemu", "tag": "ppron3:sg:dat:m1"}, # or mu
                {"form": "mu", "tag": "ppron3:sg:dat:m1"}, 
                {"form": "go", "tag": "ppron3:sg:acc:m1"},   # or niego
                {"form": "niego", "tag": "ppron3:sg:acc:m1"},
                {"form": "nim", "tag": "ppron3:sg:inst:m1"},
                {"form": "nim", "tag": "ppron3:sg:loc:m1"},
                # --- Add m2/m3 specific forms if different (often overlap) ---
                {"form": "on", "tag": "ppron3:sg:nom:m2"}, # Same nom
                {"form": "niego", "tag": "ppron3:sg:gen:m2"}, # Same gen
                {"form": "jemu", "tag": "ppron3:sg:dat:m2"}, # Same dat
                {"form": "mu", "tag": "ppron3:sg:dat:m2"}, 
                {"form": "go", "tag": "ppron3:sg:acc:m2"},   # Same acc
                {"form": "niego", "tag": "ppron3:sg:acc:m2"}, 
                {"form": "nim", "tag": "ppron3:sg:inst:m2"}, # Same inst
                {"form": "nim", "tag": "ppron3:sg:loc:m2"}, # Same loc
                {"form": "on", "tag": "ppron3:sg:nom:m3"}, # Same nom
                {"form": "niego", "tag": "ppron3:sg:gen:m3"}, # Same gen
                {"form": "jemu", "tag": "ppron3:sg:dat:m3"}, # Same dat
                {"form": "mu", "tag": "ppron3:sg:dat:m3"}, 
                {"form": "go", "tag": "ppron3:sg:acc:m3"},   # Same acc
                {"form": "niego", "tag": "ppron3:sg:acc:m3"},
                {"form": "nim", "tag": "ppron3:sg:inst:m3"}, # Same inst
                {"form": "nim", "tag": "ppron3:sg:loc:m3"}, # Same loc
            ]
        },
        "translation_en": "he/it (masc.)"
    },
    "ona": {
        "lemma": "ona",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "ona", "tag": "ppron3:sg:nom:f"},
                {"form": "niej", "tag": "ppron3:sg:gen:f"},
                {"form": "jej", "tag": "ppron3:sg:dat:f"}, # or niej
                {"form": "niej", "tag": "ppron3:sg:dat:f"},
                {"form": "ją", "tag": "ppron3:sg:acc:f"},  # or nią
                {"form": "nią", "tag": "ppron3:sg:acc:f"},
                {"form": "nią", "tag": "ppron3:sg:inst:f"},
                {"form": "niej", "tag": "ppron3:sg:loc:f"},
            ]
        },
        "translation_en": "she/it (fem.)"
    },
    "ono": {
        "lemma": "ono",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "ono", "tag": "ppron3:sg:nom:n"},
                {"form": "niego", "tag": "ppron3:sg:gen:n"}, # or go
                {"form": "go", "tag": "ppron3:sg:gen:n"}, 
                {"form": "jemu", "tag": "ppron3:sg:dat:n"}, # or mu
                {"form": "mu", "tag": "ppron3:sg:dat:n"}, 
                {"form": "je", "tag": "ppron3:sg:acc:n"},  # or nie
                {"form": "nie", "tag": "ppron3:sg:acc:n"},
                {"form": "nim", "tag": "ppron3:sg:inst:n"},
                {"form": "nim", "tag": "ppron3:sg:loc:n"},
            ]
        },
        "translation_en": "it (neuter)"
    },
    "siebie": {
        "lemma": "siebie",
        "grouped_forms": {
             # Note: Need a specific category or use Pronoun? Pronoun is fine.
             # Tags need careful consideration for parsing on frontend
            "declensionCategoryPronoun": [
                # No nominative/vocative
                {"form": "siebie", "tag": "siebie:gen:nodist"}, # Add :nodist or similar if gender/number don't apply
                {"form": "sobie", "tag": "siebie:dat:nodist"},
                {"form": "siebie", "tag": "siebie:acc:nodist"},
                {"form": "sobą", "tag": "siebie:inst:nodist"},
                {"form": "sobie", "tag": "siebie:loc:nodist"},
            ]
        },
        "translation_en": "oneself"
    },
    # --- Plural pronouns --- 
    "my": {
        "lemma": "my",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "my", "tag": "ppron12:pl:nom:m1"}, # Gender usually doesn't matter for 1st/2nd pl nom
                {"form": "nas", "tag": "ppron12:pl:gen:m1"},
                {"form": "nam", "tag": "ppron12:pl:dat:m1"},
                {"form": "nas", "tag": "ppron12:pl:acc:m1"},
                {"form": "nami", "tag": "ppron12:pl:inst:m1"},
                {"form": "nas", "tag": "ppron12:pl:loc:m1"},
            ]
        },
        "translation_en": "we"
    },
    "wy": {
        "lemma": "wy",
        "grouped_forms": {
            "declensionCategoryPronoun": [
                {"form": "wy", "tag": "ppron12:pl:nom:m1"},
                {"form": "was", "tag": "ppron12:pl:gen:m1"},
                {"form": "wam", "tag": "ppron12:pl:dat:m1"},
                {"form": "was", "tag": "ppron12:pl:acc:m1"},
                {"form": "wami", "tag": "ppron12:pl:inst:m1"},
                {"form": "was", "tag": "ppron12:pl:loc:m1"},
                {"form": "wy", "tag": "ppron12:pl:voc:m1"},
            ]
        },
        "translation_en": "you (pl.)"
    },
    "oni": {
        "lemma": "oni",
        "grouped_forms": {
            # Masculine personal plural
            "declensionCategoryPronoun": [
                {"form": "oni", "tag": "ppron3:pl:nom:m1"},
                {"form": "ich", "tag": "ppron3:pl:gen:m1"},
                {"form": "im", "tag": "ppron3:pl:dat:m1"},
                {"form": "ich", "tag": "ppron3:pl:acc:m1"}, # or nich
                {"form": "nich", "tag": "ppron3:pl:acc:m1"},
                {"form": "nimi", "tag": "ppron3:pl:inst:m1"},
                {"form": "nich", "tag": "ppron3:pl:loc:m1"},
            ]
        },
        "translation_en": "they (masc. pers.)"
    },
    "one": {
        "lemma": "one",
        "grouped_forms": {
             # Non-masculine personal plural (feminine, neuter, non-pers masc.)
            "declensionCategoryPronoun": [
                {"form": "one", "tag": "ppron3:pl:nom:f"}, # Use 'f' as representative non-m1
                {"form": "ich", "tag": "ppron3:pl:gen:f"}, # or nich
                {"form": "nich", "tag": "ppron3:pl:gen:f"},
                {"form": "im", "tag": "ppron3:pl:dat:f"},  # or nim
                {"form": "nim", "tag": "ppron3:pl:dat:f"},
                {"form": "je", "tag": "ppron3:pl:acc:f"},  # or nie
                {"form": "nie", "tag": "ppron3:pl:acc:f"},
                {"form": "nimi", "tag": "ppron3:pl:inst:f"},
                {"form": "nich", "tag": "ppron3:pl:loc:f"},
            ]
        },
        "translation_en": "they (non-masc. pers.)"
    }
}
# ----------------------------

# --- Lingvanex Translation Function ---
def translate_text_lingvanex(text, target_language):
    if not LINGVANEX_API_KEY:
        return None # API 키 없으면 번역 안 함

    api_url = "https://api-b2b.backenster.com/b1/api/v3/translate"
    headers = {
        "Authorization": f"Bearer {LINGVANEX_API_KEY}",
        "Content-Type": "application/json",
        "accept": "application/json"
    }
    payload = {
        "platform": "api",
        "from": "pl_PL",
        "to": f"{target_language.lower()}_{target_language.upper()}",
        "data": text,
        "translateMode": "text"
    }

    try:
        print(f"[Lingvanex] Requesting translation for '{text}' to {target_language}")
        response = requests.post(api_url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        result = response.json()
        print(f"[Lingvanex] Response: {result}")
        if result and "result" in result:
            return result["result"]
        else:
            print(f"[Lingvanex] Unexpected response format: {result}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"[Lingvanex] API call failed: {e}")
        return None
    except Exception as e:
        print(f"[Lingvanex] Error processing translation: {e}")
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
        print(f"[Lingvanex Dict] Requesting dictionary info for '{text}' in {target_language} using POST to /lookupDictionary")
        # Use POST request with json payload and headers
        response = requests.post(api_url, headers=headers, json=payload, timeout=15)
        response.raise_for_status() # Raise exception for bad status codes (4xx or 5xx)
        result = response.json()
        print(f"[Lingvanex Dict] Raw Response: {result}") # Print raw response for debugging

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
             print(f"[Lingvanex Dict] No examples found or extracted for '{text}'. Response structure might differ from guesses.")
        else:
             print(f"[Lingvanex Dict] Extracted examples for '{text}': {extracted_examples}")

        return extracted_examples # Return list of example strings

    except requests.exceptions.Timeout:
        print(f"[Lingvanex Dict] API call timed out for '{text}'.")
        return None
    except requests.exceptions.HTTPError as e:
         print(f"[Lingvanex Dict] HTTP Error fetching dictionary info for '{text}': {e.response.status_code} {e.response.reason}")
         # Optionally log response body for more details on error
         print(f"[Lingvanex Dict] Error Response Body: {e.response.text}") # Log error body for inspection
         return None # Indicate failure clearly
    except requests.exceptions.RequestException as e:
        print(f"[Lingvanex Dict] API call failed for '{text}': {e}")
        return None
    except Exception as e:
        print(f"[Lingvanex Dict] Error processing dictionary info for '{text}': {e}")
        return None
# --------------------------------------

@app.route('/analyze/<word>', methods=['GET'])
def analyze_word(word):
    if morf is None:
        return jsonify({"status": "error", "message": "Morfeusz2 analyzer not available."}), 500
    
    target_lang = request.args.get('target_lang', default='en', type=str)
    print(f"[analyze_word] Target language requested: {target_lang} for word: {word}")

    try:
        original_word_lower = word.lower()

        # --- Attempt 1: Analyze the original word --- 
        print(f"[analyze_word] Attempt 1: Analyzing original word '{original_word_lower}'")
        analysis_result = morf.analyse(original_word_lower)

        is_analysis_valid = analysis_result and any(
            len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3 and r[2][2].split(':', 1)[0] != 'ign'
            for r in analysis_result
        )

        if is_analysis_valid:
            print(f"[analyze_word] Attempt 1 SUCCESS: Found valid analysis for '{original_word_lower}'")
            formatted_results = _format_analysis_results(analysis_result)
            if not formatted_results:
                 return jsonify({"status": "success", "word": original_word_lower, "data": [], "message": f"Analysis found but formatting failed for '{original_word_lower}'."}), 200
            
            primary_lemma = formatted_results[0].get("lemma")
            cleaned_lemma = _clean_lemma(primary_lemma)
            translation_result = None
            if cleaned_lemma:
                print(f"[analyze_word] DEBUG: Calling translate_text_lingvanex with target_lang = {target_lang}")
                translation_result = translate_text_lingvanex(cleaned_lemma, target_lang)
            
            response_data = {
                "status": "success",
                "word": original_word_lower,
                "data": formatted_results,
                "translation_en": translation_result
            }
            print(f"[analyze_word] Returning JSON (translation is for {target_lang}): {response_data}")
            return jsonify(response_data)
        else:
            if analysis_result:
                 print(f"[analyze_word] Attempt 1 FAILED: Only 'ign' analysis found for '{original_word_lower}'")
            else:
                 print(f"[analyze_word] Attempt 1 FAILED: No analysis found for '{original_word_lower}'")

        # --- Attempt 2: Try finding suggestions by correcting potential diacritic errors --- 
        suggestion_found = False
        suggested_word = None
        original_word = original_word_lower
        diacritic_map = {
            'a': ['ą'], 'e': ['ę'], 'c': ['ć'], 'l': ['ł'],
            'n': ['ń'], 'o': ['ó'], 's': ['ś'], 'z': ['ź', 'ż']
        }
        print(f"[analyze_word] Attempt 2: Trying diacritic suggestions for '{original_word}'")
        for i, char in enumerate(original_word):
            if char in diacritic_map:
                for replacement in diacritic_map[char]:
                    potential_suggestion = list(original_word)
                    potential_suggestion[i] = replacement
                    potential_suggestion = "".join(potential_suggestion)
                    print(f"  -> Trying suggestion: '{potential_suggestion}'")
                    suggestion_analysis = morf.analyse(potential_suggestion)
                    print(f"  -> Raw analysis for '{potential_suggestion}': {suggestion_analysis}")
                    is_suggestion_valid = suggestion_analysis and any(
                        len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3 and r[2][2].split(':', 1)[0] != 'ign'
                        for r in suggestion_analysis
                    )
                    if is_suggestion_valid:
                        print(f"[analyze_word] Attempt 2 SUCCESS: Found valid analysis for suggested word '{potential_suggestion}'")
                        suggested_word = potential_suggestion
                        suggestion_found = True
                        break
                if suggestion_found:
                    break
        if suggestion_found and suggested_word:
             suggestion_message = f"Did you mean '{suggested_word}'?"
             response_data = {
                 "status": "suggestion",
                 "message": suggestion_message,
                 "suggested_word": suggested_word,
                 "original_word": original_word
             }
             print(f"[analyze_word] Returning suggestion JSON: {response_data}")
             return jsonify(response_data)
        else:
             print(f"[analyze_word] Attempt 2 FAILED: No valid diacritic suggestion found for '{original_word}'")

        # --- All attempts failed --- 
        print(f"[analyze_word] All attempts failed for '{original_word}'")
        failed_translation_result = None
        print(f"[analyze_word] Trying to translate original word '{original_word}' as fallback.")
        if original_word:
            failed_translation_result = translate_text_lingvanex(original_word, target_lang)
        final_response = {
             "status": "success", 
             "word": original_word, 
             "data": [], 
             "message": f"No analysis found for '{original_word}'."
        }
        if failed_translation_result:
             final_response["translation_en"] = failed_translation_result
             print(f"[analyze_word] Added fallback translation for '{original_word}': {failed_translation_result}")
        return jsonify(final_response), 200

    except Exception as e:
        print(f"Error during analysis for '{word}': {e}")
        return jsonify({"status": "error", "message": f"An error occurred during analysis: {e}"}), 500

# --- Helper function to format analysis results (extracted logic) --- 
def _format_analysis_results(analysis_result):
    formatted_results = []
    print(f"Raw analysis result for formatting: {analysis_result}") 
    for r in analysis_result:
        print(f"Processing analysis tuple: {r}") 
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
            print(f"  -> Parsed: lemma='{actual_lemma}', tag='{tag}', qualifiers={qualifiers}")
            formatted_results.append({
                "lemma": actual_lemma,
                "tag": tag,
                "qualifiers": qualifiers
            })
        else:
            print(f"  -> Skipping unexpected analysis tuple format: {r}")
    return formatted_results

# --- Helper function to clean lemma (extracted logic) ---
def _clean_lemma(lemma):
    if lemma and ':' in lemma:
        cleaned = lemma.split(':', 1)[0]
        print(f"[lemma cleaning] Cleaned '{lemma}' to '{cleaned}'")
        return cleaned
    return lemma

# Helper function to check if a tag represents a verb
def is_verb(tag):
    # Add more verb tags if needed based on Morfeusz tagset
    return tag in ['fin', 'impt', 'imps', 'inf', 'pact', 'pant', 'pcon', 'ppas', 'praet', 'bedzie', 'ger', 'imps', 'cond']

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

# --- 비인칭 형태 감지 함수 (새로 추가) ---
def is_impersonal_form(form, tag_full):
    """비인칭 형태인지 확인하는 함수"""
    # -no, -to로 끝나는 형태는 과거 비인칭
    if form.endswith(('no', 'to')) and 'imps' in tag_full:
        return True
    # 명시적으로 imps 태그가 있는 경우
    if tag_full.split(':', 1)[0] == 'imps':
        return True
    # się가 포함된 특정 패턴 (일부 reflexive 동사는 예외)
    if ' się ' in form or form.endswith(' się') or form.startswith('się '):
        return True
    return False
# ---------------------------

# --- Generic Form Generation and Formatting ---
def generate_and_format_forms(word, check_func, category_func):
    """Generates and formats forms (either conjugation or declension) for a given word.
    - Uses Morfeusz.generate().
    - Filters based on check_func (e.g., is_verb, is_declinable).
    - Groups forms using category_func (e.g., get_conjugation_category_key).
    - Handles potential errors gracefully.
    - Returns a dictionary containing the lemma and grouped forms, or None if no valid forms found.
    """
    print(f"[generate_and_format_forms] Starting for word: '{word}'")

    # --- 하드코딩된 대명사/단어 확인 --- 
    if word in hardcoded_declensions:
        print(f"[generate_and_format_forms] Found hardcoded entry for '{word}'. Returning pre-defined data.")
        # 프론트엔드가 기대하는 리스트 형태로 감싸서 반환 ([{lemma:..., grouped_forms:...}])
        # 또는 API 응답 구조에 맞게 수정 필요 (여기서는 /decline, /conjugate가 직접 반환하므로 그냥 dict 반환)
        return hardcoded_declensions[word]
    # -------------------------------------

    if morf is None:
        print("Error: Morfeusz2 is not initialized.")
        return None

    try:
        word = word.lower()
        print(f"[디버그] 분석 시작 - 단어: '{word}', 함수: {check_func.__name__}")
        analysis_result = morf.analyse(word)
        if not analysis_result:
            print(f"[generate_and_format_forms] Word '{word}' not found or cannot be analyzed.")
            return None # Return None on failure

        # --- 수정: 기본형 선택 로직 (m2 우선) ---
        possible_lemmas = []
        for r in analysis_result:
            if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3:
                analysis_tuple = r[2]
                current_lemma = analysis_tuple[1]
                current_tag_full = analysis_tuple[2]
                current_base_tag = current_tag_full.split(':', 1)[0]
                if check_func(current_base_tag): # Check if it's the desired type (verb/declinable)
                    possible_lemmas.append((current_lemma, current_tag_full))

        if not possible_lemmas:
            print(f"[generate_and_format_forms] No primary lemma matching check_func found for '{word}'.")
            return None # Return None if no suitable lemma found

        # m2 우선 선택 로직 (is_declinable 경우)
        if check_func == is_declinable and len(possible_lemmas) > 1:
            m2_lemma = None
            m1_lemma = None
            # Check if both m1 and m2 types exist
            for lem, tag in possible_lemmas:
                if ':m2' in tag: m2_lemma = (lem, tag)
                if ':m1' in tag: m1_lemma = (lem, tag)
            
            if m2_lemma and m1_lemma:
                # If both exist, prioritize m2
                primary_lemma, primary_tag_full = m2_lemma
                print(f"[generate_and_format_forms] Prioritizing m2 lemma: '{primary_lemma}' from {possible_lemmas}")
            else:
                # Otherwise, just take the first one found
                primary_lemma, primary_tag_full = possible_lemmas[0]
                print(f"[generate_and_format_forms] Using first found lemma: '{primary_lemma}' from {possible_lemmas}")
        else:
            # For verbs or single declinable result, take the first one
            primary_lemma, primary_tag_full = possible_lemmas[0]
            print(f"[generate_and_format_forms] Using first found lemma (verb or single): '{primary_lemma}'")

        # --- 수정: 선택된 기본형 정보 설정 (is_primary_imperfective, has_reflexive_sie 포함) ---
        primary_base_tag = primary_tag_full.split(':', 1)[0]
        is_primary_imperfective = False # 기본값 초기화
        if 'imperf' in primary_tag_full.split(':'):
            is_primary_imperfective = True
        has_reflexive_sie = False # 기본값 초기화
        if ' się' in primary_lemma or primary_lemma.endswith('się'):
            has_reflexive_sie = True
        print(f"[generate_and_format_forms] Selected primary analysis: lemma='{primary_lemma}', tag='{primary_tag_full}', is_imperfective={is_primary_imperfective}, has_reflexive_sie={has_reflexive_sie}")
        # -------------------------------------------------

        # Morfeusz2 generate 호출 시 expand_tags=True 옵션 사용 (복합 태그 자동 분리)
        generated_forms_raw = morf.generate(primary_lemma)
        print(f"  -> Raw generated forms for primary lemma '{primary_lemma}': {generated_forms_raw}")

        # --- Process generated forms and store needed ones ---
        grouped_forms = {}
        infinitive_form = None
        past_forms = {} # To store praet forms: {'sg:m1': 'robił', 'sg:f': 'robiła', ...}
        past_impersonal_form = None
        present_impersonal_forms = [] # 다양한 현재 비인칭 형태 저장
        
        # 디버깅: 동명사(Gerund) 추적
        print(f"[디버그-동명사] 형태 생성 시작 - 기본형: '{primary_lemma}'")
        gerund_forms_found = 0

        # 디버깅: 미래시제 추적
        future_forms_perf = 0
        future_forms_imperf = 0
        print(f"[디버그-미래시제] 미래시제 처리 - 미완료상: {is_primary_imperfective}")
        
        # 디버깅: 비인칭 추적
        impersonal_forms_found = 0
        print(f"[디버그-비인칭] 비인칭 처리 시작 - 동사: '{primary_lemma}', 본질적 재귀형: {has_reflexive_sie}")

        for form_tuple in generated_forms_raw:
            try:
                if len(form_tuple) < 3:
                    continue

                form = form_tuple[0]
                form_lemma_full = form_tuple[1]
                form_tag_full = form_tuple[2]
                qualifiers = list(form_tuple[3:]) if len(form_tuple) > 3 else []
                base_tag = form_tag_full.split(':', 1)[0]

                should_process = False
                if check_func == is_verb:
                    should_process = base_tag in ALLOWED_TAGS
                elif check_func == is_declinable:
                    should_process = base_tag in DECLINABLE_TAGS
                
                if not should_process:
                    continue
                
                # 디버깅: 동명사 형태 확인
                if base_tag == 'ger':
                    gerund_forms_found += 1
                    print(f"[디버그-동명사] 동명사 발견 #{gerund_forms_found}: '{form}', 태그: '{form_tag_full}'")
                    if ':neg' in form_tag_full:
                        print(f"[디버그-동명사] 부정 동명사 필터링됨: '{form}'")
                        continue  # 부정 동명사 필터링
                
                # 디버깅: 미래시제 형태 확인 (완료상)
                if base_tag == 'fin' and 'perf' in form_tag_full.split(':'):
                    future_forms_perf += 1
                    print(f"[디버그-미래시제] 미래 완료형 발견 #{future_forms_perf}: '{form}', 태그: '{form_tag_full}'")
                    
                    # 인칭/수 정보 추출 디버깅
                    parts = form_tag_full.split(':')
                    number = next((p for p in parts if p in ['sg', 'pl']), 'unknown')
                    person = next((p for p in parts if p in ['pri', 'sec', 'ter']), 'unknown')
                    print(f"[디버그-미래시제] 태그 파싱 결과 - 수: {number}, 인칭: {person}")
                
                # --- 비인칭 형태 감지 및 처리 (향상됨) ---
                is_impersonal = False
                if check_func == is_verb: # Only check for impersonals if processing a verb
                    is_impersonal = is_impersonal_form(form, form_tag_full)
                    if is_impersonal:
                        impersonal_forms_found += 1
                        print(f"[디버그-비인칭] 비인칭 형태 발견 #{impersonal_forms_found}: '{form}', 태그: '{form_tag_full}'")
                        
                        # 현재 비인칭 형태 저장
                        if base_tag == 'imps' and not (form.endswith('no') or form.endswith('to')):
                            if form not in present_impersonal_forms:
                                present_impersonal_forms.append(form)
                                print(f"[디버그-비인칭] 현재 비인칭 형태 저장: '{form}'")

                # --- Store infinitive ---
                if base_tag == 'inf':
                    infinitive_form = form
                    print(f"      >> Found infinitive: {infinitive_form}")
                # -----------------------

                # --- Store past tense forms needed for conditional ---
                if base_tag == 'praet':
                    parts = form_tag_full.split(':')
                    num_gen_key = None
                    # 과거시제 형태 저장 개선 - 보다 세부적인 성별 구분 지원
                    if 'sg' in parts:
                        num = 'sg'
                        # 단수형에서 더 세부적인 성별 처리 (m1, m2, m3, f, n1, n2, m1.m2.m3 등 모든 가능한 성별 포함)
                        for gen in parts:
                            # 복합 태그(m1.m2.m3 등) 분리해서 각각 past_forms에 넣기
                            if '.' in gen:
                                for subgen in gen.split('.'):
                                    if subgen in ['m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2']:
                                        num_gen_key = f"{num}:{subgen}"
                                        past_forms[num_gen_key] = form
                                        print(f"      >> Found past form for {num_gen_key} (from composite tag {gen}): {form}")
                            # 기존 단일 태그 처리
                            if gen in ['m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2']:
                                num_gen_key = f"{num}:{gen}"
                                past_forms[num_gen_key] = form
                                print(f"      >> Found past form for {num_gen_key}: {form}")
                    elif 'pl' in parts:
                        num = 'pl'
                        # 복수형에서 더 세부적인 처리 (m1, non-m1, m2.m3.f.n 등 가능한 모든 조합)
                        for gen in parts:
                            if gen in ['m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2', 'non-m1', 'm2.m3.f.n']:
                                num_gen_key = f"{num}:{gen}"
                                if num_gen_key:
                                    past_forms[num_gen_key] = form
                                    print(f"      >> Found past form for {num_gen_key}: {form}")
                    
                    # 추가: 인칭 정보 명시적으로 처리
                    person = None
                    # 태그에서 인칭 정보 직접 확인
                    for part in parts:
                        if part in ['pri', 'sec', 'ter']:
                            person = part
                            break
                    
                    # 태그에 인칭 정보가 없을 경우 형태에서 추론
                    if person is None:
                        if form.endswith(('łem', 'łam')): person = 'pri'
                        elif form.endswith(('łeś', 'łaś')): person = 'sec'
                        elif form.endswith(('ł', 'ła', 'ło')): person = 'ter'
                        elif form.endswith(('liśmy', 'łyśmy')): person = 'pri'
                        elif form.endswith(('liście', 'łyście')): person = 'sec'
                        elif form.endswith(('li', 'ły')): person = 'ter'
                    
                    if person:
                        form_tag_full += f':{person}' # Append inferred person
                # --------------------------------------------------

                # --- 과거 비인칭 형태 저장 (no/to 형태) ---
                if base_tag == 'imps' and (form.endswith('no') or form.endswith('to')):
                    past_impersonal_form = form
                    print(f"      >> Found past impersonal form: {past_impersonal_form}")
                # --------------------------------------------------

                # --- 수정: 품사 종류에 따라 적절한 카테고리 키 함수 사용 ---
                category_key = None
                if check_func == is_verb:
                    category_key = get_conjugation_category_key(base_tag, form_tag_full)
                elif check_func == is_declinable:
                    category_key = get_declension_category_key(base_tag, form_tag_full)
                # -----------------------------------------------------

                # --- 향상된 비인칭 카테고리 분류 (업데이트됨) ---
                if is_impersonal: # This check is now inside the is_verb specific logic above
                    if form.endswith(('no', 'to')):
                        category_key = 'conjugationCategoryPastImpersonal'
                    elif base_tag == 'imps':
                        category_key = 'conjugationCategoryPresentImpersonal'
                    elif base_tag == 'impt' or 'impt' in form_tag_full:
                        category_key = 'conjugationCategoryImperativeImpersonal'
                # -------------------------------------------------

                if category_key:
                    form_data = {"form": form, "tag": form_tag_full, "qualifiers": qualifiers}
                    if category_key not in grouped_forms:
                         grouped_forms[category_key] = []
                    grouped_forms[category_key].append(form_data)
                else:
                    pass # Explicitly pass if skipping

            except Exception as form_proc_error:
                print(f"!!!!! ERROR processing form tuple: {form_tuple} !!!!!")
                print(f"!!!!! Form Processing Error: {form_proc_error}")
                import traceback
                traceback.print_exc() # Keep traceback for unexpected errors
                continue 
        # --- End processing loop ---
        
        # 디버깅: 동명사 결과 요약
        print(f"[디버그-동명사] 동명사 처리 결과: 발견된 형태 {gerund_forms_found}개")
        if 'conjugationCategoryVerbalNoun' in grouped_forms:
            print(f"[디버그-동명사] 집계된 동명사 형태: {len(grouped_forms['conjugationCategoryVerbalNoun'])}개")
            for idx, form_data in enumerate(grouped_forms['conjugationCategoryVerbalNoun']):
                print(f"[디버그-동명사] #{idx+1}: 형태='{form_data['form']}', 태그='{form_data['tag']}'")
        else:
            print(f"[디버그-동명사] 최종 결과에 포함된 동명사 없음")
        
        # 디버깅: 비인칭 결과 요약
        print(f"[디버그-비인칭] 비인칭 처리 결과: 발견된 형태 {impersonal_forms_found}개")
        print(f"[디버그-비인칭] 현재 비인칭 형태: {present_impersonal_forms}")
        print(f"[디버그-비인칭] 과거 비인칭 형태: {past_impersonal_form}")

        # --- 향상된 비인칭 형태 생성 ---
        # 1. 과거 비인칭 형태가 있는 경우 미래/조건 비인칭 생성
        if past_impersonal_form:
            # 미래 비인칭 (다양한 변형)
            future_imps_key = 'conjugationCategoryFutureImpersonal'
            if future_imps_key not in grouped_forms: grouped_forms[future_imps_key] = []
            
            # 기본 미래 비인칭 (będzie + 과거 비인칭)
            future_imps_form1 = f"będzie {past_impersonal_form}"
            grouped_forms[future_imps_key].append({
                "form": future_imps_form1, 
                "tag": "fut_imps:imperf", 
                "qualifiers": []
            })
            print(f"[디버그-비인칭] 미래 비인칭 생성 (기본): {future_imps_form1}")
            
            # się가 있는 미래 비인칭 (będzie się + 과거 비인칭)
            future_imps_form2 = f"będzie się {past_impersonal_form}"
            grouped_forms[future_imps_key].append({
                "form": future_imps_form2, 
                "tag": "fut_imps:imperf:refl", 
                "qualifiers": []
            })
            print(f"[디버그-비인칭] 미래 비인칭 생성 (się): {future_imps_form2}")

            # 조건 비인칭 (다양한 변형)
            cond_imps_key = 'conjugationCategoryConditionalImpersonal'
            if cond_imps_key not in grouped_forms: grouped_forms[cond_imps_key] = []
            
            # 기본 조건 비인칭 (standard by + past impersonal)
            cond_imps_form1 = f"{past_impersonal_form} by"
            grouped_forms[cond_imps_key].append({
                "form": cond_imps_form1, 
                "tag": "cond_imps", 
                "qualifiers": []
            })
            print(f"[디버그-비인칭] 조건 비인칭 생성 (기본): {cond_imps_form1}")
            
            # 대체 조건 비인칭 (by + past impersonal)
            cond_imps_form2 = f"by {past_impersonal_form}"
            grouped_forms[cond_imps_key].append({
                "form": cond_imps_form2, 
                "tag": "cond_imps:alt", 
                "qualifiers": []
            })
            print(f"[디버그-비인칭] 조건 비인칭 생성 (대체): {cond_imps_form2}")
            
            # się가 있는 조건 비인칭
            if not has_reflexive_sie:  # 이미 reflexive 동사가 아닌 경우에만
                cond_imps_form3 = f"{past_impersonal_form} by się"
                grouped_forms[cond_imps_key].append({
                    "form": cond_imps_form3, 
                    "tag": "cond_imps:refl", 
                    "qualifiers": []
                })
                print(f"[디버그-비인칭] 조건 비인칭 생성 (się): {cond_imps_form3}")
        
        # 2. 현재 비인칭 형태가 있는 경우
        if present_impersonal_forms and len(present_impersonal_forms) > 0:
            # 명령형 비인칭 생성
            impt_imps_key = 'conjugationCategoryImperativeImpersonal'
            if impt_imps_key not in grouped_forms: grouped_forms[impt_imps_key] = []
            
            for present_form in present_impersonal_forms:
                impt_imps_form = f"{IMPERSONAL_IMPERATIVE_PREFIX} {present_form}"
                grouped_forms[impt_imps_key].append({
                    "form": impt_imps_form,
                    "tag": "impt_imps",
                    "qualifiers": []
                })
                print(f"[디버그-비인칭] 명령형 비인칭 생성: {impt_imps_form}")
        
        # 3. 부정형 비인칭 추가 (현재 비인칭 기준)
        if present_impersonal_forms and len(present_impersonal_forms) > 0:
            present_imps_key = 'conjugationCategoryPresentImpersonal'
            
            # 부정형 추가
            for present_form in present_impersonal_forms:
                if not present_form.startswith("nie "):  # 이미 부정형이 아닌 경우에만
                    neg_form = f"nie {present_form}"
                    grouped_forms[present_imps_key].append({
                        "form": neg_form,
                        "tag": "imps:neg",
                        "qualifiers": []
                    })
                    print(f"[디버그-비인칭] 부정 현재 비인칭 추가: {neg_form}")
        # ----------------------------------------------

        # --- Generate Future Imperfective / Conditional ---
        if is_primary_imperfective:
            # 1. Future Imperfective (using infinitive)
            if infinitive_form:
                future_key = 'conjugationCategoryFutureImperfectiveIndicative'
                print(f"[디버그-미래시제] 미래 미완료형 생성 시작: infinitive='{infinitive_form}'")
                if future_key not in grouped_forms: grouped_forms[future_key] = []
                for num_pers, aux_form in BYC_FUTURE_FORMS.items():
                    num, pers = num_pers.split(':')
                    generated_form = f"{aux_form} {infinitive_form}"
                    generated_tag = f"fut:{num}:{pers}:imperf" # Construct a tag
                    print(f"      >> Generating Future Imperfective: {generated_form} ({generated_tag})")
                    future_forms_imperf += 1
                    grouped_forms[future_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                
                print(f"[디버그-미래시제] 미래 미완료형 생성 완료: {future_forms_imperf}개 생성됨")
            else:
                print(f"      >> Cannot generate Future Imperfective: Infinitive form not found.")

            # 2. Conditional (using past forms)
            # 중요: 알고리즘 추측을 최소화하고 morf에서 직접 가져온 형태 우선 사용
            conditional_key = 'conjugationCategoryConditional'
            if conditional_key not in grouped_forms: grouped_forms[conditional_key] = []
            
            # 2-1. Morfeusz에서 직접 조건법 형태 찾기
            direct_conditional_forms = []
            for form_tuple in generated_forms_raw:
                if len(form_tuple) < 3:
                    continue
                form = form_tuple[0]
                form_tag_full = form_tuple[2]
                if form_tag_full.startswith('cond:'):
                    print(f"      >> Found direct conditional form: {form}, tag: {form_tag_full}")
                    direct_conditional_forms.append(form_tuple)
                    # 바로 그룹에 추가
                    base_tag = form_tag_full.split(':', 1)[0]
                    qualifiers = list(form_tuple[3:]) if len(form_tuple) > 3 else []
                    form_data = {"form": form, "tag": form_tag_full, "qualifiers": qualifiers}
                    grouped_forms[conditional_key].append(form_data)
            
            print(f"[디버그-조건법] Morfeusz에서 직접 찾은 조건법 형태 수: {len(direct_conditional_forms)}")
            
            # 2-2. 직접 찾은 형태가 충분하지 않은 경우에만 생성
            if len(direct_conditional_forms) < 6:  # 최소한 몇 개의 기본 형태가 있어야 함
                print(f"[디버그-조건법] 직접 찾은 조건법 형태가 부족하여 필요한 형태 생성 시도")
                if past_forms:
                    for num_pers, particle in BY_CONDITIONAL_PARTICLES.items():
                        num, pers = num_pers.split(':')
                        # 이미 해당 인칭/수에 대한 형태가 있는지 확인
                        has_existing_form = any(
                            form["tag"].startswith(f"cond:{num}:") and f":{pers}:" in form["tag"]
                            for form in grouped_forms[conditional_key]
                        )
                        
                        if has_existing_form:
                            print(f"      >> Skipping generation for {num}:{pers} - already exists in direct forms")
                            continue
                        
                        # Find corresponding past forms based on number and gender
                        if num == 'sg':
                            # 수정: 모든 필요한 단수 성별을 명시적으로 처리 (중성 포함)
                            genders_to_try = []
                            
                            # 남성 단수 형태들 - m1, m2, m3 중 있는 것 사용
                            if 'sg:m1' in past_forms: 
                                genders_to_try.append('m1')
                                past_key = 'sg:m1'
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    generated_form = f"{base_past}{particle}" # Attach particle
                                    generated_tag = f"cond:{num}:m1:{pers}:imperf"
                                    print(f"      >> Generating Conditional (남성 인격): {generated_form} ({generated_tag})")
                                    grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                            
                            if 'sg:m2' in past_forms:
                                genders_to_try.append('m2')
                                past_key = 'sg:m2'
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    generated_form = f"{base_past}{particle}" # Attach particle
                                    generated_tag = f"cond:{num}:m2:{pers}:imperf"
                                    print(f"      >> Generating Conditional (남성 동물): {generated_form} ({generated_tag})")
                                    grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                                    
                            if 'sg:m3' in past_forms:
                                genders_to_try.append('m3')
                                past_key = 'sg:m3'
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    generated_form = f"{base_past}{particle}" # Attach particle
                                    generated_tag = f"cond:{num}:m3:{pers}:imperf"
                                    print(f"      >> Generating Conditional (남성 사물): {generated_form} ({generated_tag})")
                                    grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                            
                            # 만약 sg:m, sg:m1, sg:m2, sg:m3 중 어느 것도 없다면 m1.m2.m3 키를 확인
                            if 'sg:m1.m2.m3' in past_forms and not (set(genders_to_try) & set(['m1', 'm2', 'm3'])):
                                past_key = 'sg:m1.m2.m3'
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    # 남성 전체 형태를 각각의 세부 성별로 복제 (m1, m2, m3)
                                    for m_gender in ['m1', 'm2', 'm3']:
                                        generated_form = f"{base_past}{particle}" # Attach particle
                                        generated_tag = f"cond:{num}:{m_gender}:{pers}:imperf"
                                        print(f"      >> Generating Conditional (남성 통합): {generated_form} ({generated_tag})")
                                        grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                            
                            # 여성 단수 형태
                            if 'sg:f' in past_forms:
                                past_key = 'sg:f'
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    generated_form = f"{base_past}{particle}" # Attach particle
                                    generated_tag = f"cond:{num}:f:{pers}:imperf"
                                    print(f"      >> Generating Conditional (여성): {generated_form} ({generated_tag})")
                                    grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                            
                            # 중성 단수 형태 - 이 부분을 누락하지 않도록 명시적으로 처리
                            if 'sg:n' in past_forms:
                                past_key = 'sg:n'
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    generated_form = f"{base_past}{particle}" # Attach particle
                                    generated_tag = f"cond:{num}:n:{pers}:imperf"
                                    print(f"      >> Generating Conditional (중성): {generated_form} ({generated_tag})")
                                    grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                            elif 'sg:n1' in past_forms or 'sg:n2' in past_forms:
                                # n1, n2 등의 세부 구분이 있는 경우
                                for n_type in ['n1', 'n2']:
                                    past_key = f'sg:{n_type}'
                                    if past_key in past_forms:
                                        base_past = past_forms[past_key]
                                        generated_form = f"{base_past}{particle}" # Attach particle
                                        generated_tag = f"cond:{num}:{n_type}:{pers}:imperf"
                                        print(f"      >> Generating Conditional (중성 세부): {generated_form} ({generated_tag})")
                                        grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})

                        elif num == 'pl':
                            # 복수 형태도 더 세부적으로 처리 - m1(남성 인격) 외에도 non-m1 형태도 포함
                            genders_to_try = ['m1', 'm2.m3.f.n', 'non-m1']
                            for gender in genders_to_try:
                                past_key = f"pl:{gender}"
                                if past_key in past_forms:
                                    base_past = past_forms[past_key]
                                    generated_form = f"{base_past}{particle}" # Attach particle
                                    generated_tag = f"cond:{num}:{gender}:{pers}:imperf" # Use simplified gender tag
                                    print(f"      >> Generating Conditional: {generated_form} ({generated_tag})")
                                    grouped_forms[conditional_key].append({"form": generated_form, "tag": generated_tag, "qualifiers": []})
                else:
                     print(f"      >> Cannot generate Conditional: Past tense forms not found.")
        # ---------------------------------------------------
        
        # 디버깅: 미래시제 결과 요약
        print(f"[디버그-미래시제] 미래시제 처리 결과: 완료형 {future_forms_perf}개, 미완료형 {future_forms_imperf}개")
        
        # 미래 완료형 결과
        if 'conjugationCategoryFuturePerfectiveIndicative' in grouped_forms:
            print(f"[디버그-미래시제] 집계된 미래 완료형: {len(grouped_forms['conjugationCategoryFuturePerfectiveIndicative'])}개")
            for idx, form_data in enumerate(grouped_forms['conjugationCategoryFuturePerfectiveIndicative']):
                print(f"[디버그-미래시제] 완료형 #{idx+1}: 형태='{form_data['form']}', 태그='{form_data['tag']}'")
        
        # 미래 미완료형 결과
        if 'conjugationCategoryFutureImperfectiveIndicative' in grouped_forms:
            print(f"[디버그-미래시제] 집계된 미래 미완료형: {len(grouped_forms['conjugationCategoryFutureImperfectiveIndicative'])}개")
            for idx, form_data in enumerate(grouped_forms['conjugationCategoryFutureImperfectiveIndicative']):
                print(f"[디버그-미래시제] 미완료형 #{idx+1}: 형태='{form_data['form']}', 태그='{form_data['tag']}'")

        final_grouped_forms = grouped_forms

        print(f"  -> Final grouped forms categories: {list(final_grouped_forms.keys())}")
        return {"lemma": primary_lemma, "grouped_forms": final_grouped_forms}

    except Exception as e:
        print(f"Error during form generation for '{word}': {e}")
        import traceback
        traceback.print_exc() # Print full traceback for debugging
        return None # Return None on exception

# --- NEW Helper function to get category key (similar to frontend) ---
# Maps Morfeusz base tags (and sometimes qualifiers) to frontend category keys
def get_conjugation_category_key(base_tag, full_tag):
    aspect = None
    tense_aspect = None
    mood = None # Not reliably extracted from standard tags

    parts = full_tag.split(':')
    # Basic positional guessing (can be refined)
    if len(parts) > 1: number = parts[1]
    if len(parts) > 2: case_person_gender = parts[2]
    if len(parts) > 3: gender_aspect_etc = parts[3]

    # Try to find aspect more reliably
    for part in parts:
        if part == 'perf': aspect = 'perf'; break
        if part == 'imperf': aspect = 'imperf'; break

    # Assign tense_aspect based on base tag and aspect
    if base_tag == 'fin' and aspect: tense_aspect = aspect
    if base_tag == 'praet' and aspect: tense_aspect = aspect # Past uses aspect
    # Add more specific tense_aspect logic if needed

    # Mimic frontend logic
    if base_tag == 'fin':
        if tense_aspect == 'imperf': return 'conjugationCategoryPresentIndicative'
        if tense_aspect == 'perf': return 'conjugationCategoryFuturePerfectiveIndicative'
        return 'conjugationCategoryFiniteVerb' # Fallback
    elif base_tag == 'bedzie': return 'conjugationCategoryFutureImperfectiveIndicative'
    elif base_tag == 'praet': return 'conjugationCategoryPastTense'
    elif base_tag == 'impt': return 'conjugationCategoryImperative'
    elif base_tag == 'impt_periph': return 'conjugationCategoryImperative' # Group with impt
    elif base_tag == 'inf': return 'conjugationCategoryInfinitive'
    elif base_tag == 'pcon': return 'conjugationCategoryPresentAdverbialParticiple'
    elif base_tag == 'pant': return 'conjugationCategoryAnteriorAdverbialParticiple'
    elif base_tag == 'pact': return 'conjugationCategoryPresentActiveParticiple'
    elif base_tag == 'ppas': return 'conjugationCategoryPastPassiveParticiple'
    elif base_tag == 'ger': return 'conjugationCategoryVerbalNoun'
    elif base_tag == 'imps':
        # 향상된 비인칭 구분 로직
        if full_tag.startswith('imps:pef') or any(part == 'perf' for part in parts):
            return 'conjugationCategoryPastImpersonal'
        else:
            return 'conjugationCategoryPresentImpersonal'
    elif base_tag == 'cond': return 'conjugationCategoryConditional'
    # 추가된 비인칭 태그 처리
    elif base_tag == 'fut_imps': return 'conjugationCategoryFutureImpersonal'
    elif base_tag == 'cond_imps': return 'conjugationCategoryConditionalImpersonal'
    elif base_tag == 'impt_imps': return 'conjugationCategoryImperativeImpersonal'
    else: return 'conjugationCategoryOtherForms' # Group others

# --- NEW Helper function for Declension Categories ---
def get_declension_category_key(base_tag, full_tag):
    # Simple mapping for now, can be expanded
    if base_tag == 'subst': return 'declensionCategoryNoun'
    elif base_tag in ['adj', 'adja', 'adjp']:
        # --- 수정: 형용사 등급 구분 ---
        parts = full_tag.split(':')
        degree = None
        for part in parts:
            if part in ['pos', 'com', 'sup']:
                degree = part
                break
        if degree == 'pos': return 'declensionCategoryAdjectivePositive'
        elif degree == 'com': return 'declensionCategoryAdjectiveComparative'
        elif degree == 'sup': return 'declensionCategoryAdjectiveSuperlative'
        else: return 'declensionCategoryAdjective' # Fallback if degree not found
        # ---------------------------
    elif base_tag == 'depr': return 'declensionCategoryPronoun' # Assuming depr is pronoun
    else: return 'declensionCategoryOtherForms'
# --------------------------------------------------

@app.route('/conjugate/<word>', methods=['GET'])
def conjugate_word(word):
    # generate_and_format_forms returns a dict (if successful) or None
    result_data = generate_and_format_forms(word, is_verb, get_conjugation_category_key)

    if result_data is None:
        # Handle case where generation failed or no matching forms found
        print(f"[/conjugate] No valid conjugation data found for '{word}'.")
        return jsonify({
            "status": "success", # Still return success, but with empty data
            "word": word,
            "data": [],
            "message": f"No conjugation data found for '{word}' or word type mismatch."
        }), 200
    elif isinstance(result_data, dict):
        # Success: Wrap the result dict in a list for the API response
        response_payload = {
            "status": "success",
            "word": word,
            "data": [result_data] # Wrap the dict in a list
        }
        print(f"[/conjugate] Returning successful data structure for '{word}'.")
        return jsonify(response_payload)
    else:
        # Should not happen normally
        print(f"[/conjugate] Unexpected result type from generate_and_format_forms for '{word}': {type(result_data)}")
        return jsonify({"status": "error", "message": "Internal server error processing conjugation."}), 500

@app.route('/decline/<word>', methods=['GET'])
def decline_word(word):
    # generate_and_format_forms returns a dict (if successful) or None
    result_data = generate_and_format_forms(word, is_declinable, get_declension_category_key)

    if result_data is None:
         # Handle case where generation failed or no matching forms found
        print(f"[/decline] No valid declension data found for '{word}'.")
        return jsonify({
            "status": "success", # Still return success, but with empty data
            "word": word,
            "data": [],
            "message": f"No declension data found for '{word}' or word type mismatch."
        }), 200
    elif isinstance(result_data, dict):
        # Success: Wrap the result dict in a list for the API response
        response_payload = {
            "status": "success",
            "word": word,
            "data": [result_data] # Wrap the dict in a list
        }
        print(f"[/decline] Returning successful data structure for '{word}'.")
        return jsonify(response_payload)
    else:
        # Should not happen normally
        print(f"[/decline] Unexpected result type from generate_and_format_forms for '{word}': {type(result_data)}")
        return jsonify({"status": "error", "message": "Internal server error processing declension."}), 500

# --- 간단한 테스트 경로 추가 ---
@app.route('/test_log/<item>', methods=['GET'])
def test_log_route(item):
    logging.warning(f"[test_log_route] Function called! Received item: {item}")
    return jsonify({"status": "success", "message": f"Test route received: {item}"}) 
# ---------------------------

if __name__ == '__main__':
    # Use PORT environment variable if available (for Cloud Run), otherwise default to 8080
    port = int(os.environ.get('PORT', 8080))
    # Set debug=False for production/Cloud Run
    # Set debug=True for local development
    is_local_dev = os.environ.get('DEV_ENVIRONMENT') == 'local'
    app.run(debug=is_local_dev, host='0.0.0.0', port=port) 