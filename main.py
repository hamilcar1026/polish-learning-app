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

# --- Ordinal Numerals Set ---
ORDINAL_NUMERALS_SET = {
    "pierwszy", "drugi", "trzeci", "czwarty", "piąty", "szósty", "siódmy", "ósmy", "dziewiąty", "dziesiąty",
    "jedenasty", "dwunasty", "trzynasty", "czternasty", "piętnasty", "szesnasty", "siedemnasty", "osiemnasty", "dziewiętnasty",
    "dwudziesty", "trzydziesty", "czterdziesty", "pięćdziesiąty", "sześćdziesiąty", "siedemdziesiąty", "osiemdziesiąty", "dziewięćdziesiąty",
    "setny"
}
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
    },
    # --- Numerals --- 
    "zero": {
        "lemma": "zero",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                # Often treated as indeclinable or neuter noun
                {"form": "zero", "tag": "num:sg:nom:n:card"}, 
                {"form": "zera", "tag": "num:sg:gen:n:card"},
                {"form": "zeru", "tag": "num:sg:dat:n:card"},
                {"form": "zero", "tag": "num:sg:acc:n:card"},
                {"form": "zerem", "tag": "num:sg:inst:n:card"},
                {"form": "zerze", "tag": "num:sg:loc:n:card"},
                # Plural forms might exist in specific contexts but are less common for '0'
            ]
        },
        "translation_en": "zero"
    },
    "jeden": { # Also covers jedna, jedno - lemma is masculine form
        "lemma": "jeden",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                # Masculine (m1, m2, m3 often same for cardinal 1)
                {"form": "jeden", "tag": "num:sg:nom:m1:card"},
                {"form": "jednego", "tag": "num:sg:gen:m1:card"},
                {"form": "jednemu", "tag": "num:sg:dat:m1:card"},
                {"form": "jeden", "tag": "num:sg:acc:m1:card"},    # Acc m1 (animate)
                {"form": "jednego", "tag": "num:sg:acc:m2:card"},  # Acc m2 (animate)
                {"form": "jeden", "tag": "num:sg:acc:m3:card"},    # Acc m3 (inanimate)
                {"form": "jednym", "tag": "num:sg:inst:m1:card"},
                {"form": "jednym", "tag": "num:sg:loc:m1:card"},
                # Feminine
                {"form": "jedna", "tag": "num:sg:nom:f:card"},
                {"form": "jednej", "tag": "num:sg:gen:f:card"},
                {"form": "jednej", "tag": "num:sg:dat:f:card"},
                {"form": "jedną", "tag": "num:sg:acc:f:card"},
                {"form": "jedną", "tag": "num:sg:inst:f:card"},
                {"form": "jednej", "tag": "num:sg:loc:f:card"},
                # Neuter
                {"form": "jedno", "tag": "num:sg:nom:n:card"},
                {"form": "jednego", "tag": "num:sg:gen:n:card"},
                {"form": "jednemu", "tag": "num:sg:dat:n:card"},
                {"form": "jedno", "tag": "num:sg:acc:n:card"},
                {"form": "jednym", "tag": "num:sg:inst:n:card"},
                {"form": "jednym", "tag": "num:sg:loc:n:card"},
            ]
        },
        "translation_en": "one"
    },
    # --- Numerals 2-19 --- 
    "dwa": { # Also covers dwie
        "lemma": "dwa",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                # Masculine Personal (special case)
                {"form": "dwaj", "tag": "num:pl:nom:m1:card"},
                {"form": "dwóch", "tag": "num:pl:acc:m1:card"},
                # Other genders Nom/Acc
                {"form": "dwa", "tag": "num:pl:nom.acc:m2.m3:card"}, # m2/m3 non-personal
                {"form": "dwie", "tag": "num:pl:nom.acc:f:card"},
                {"form": "dwa", "tag": "num:pl:nom.acc:n:card"},
                # Common forms for other cases
                {"form": "dwóch", "tag": "num:pl:gen:m1.m2.m3.f.n:card"},
                {"form": "dwom", "tag": "num:pl:dat:m1.m2.m3.f.n:card"},
                {"form": "dwoma", "tag": "num:pl:inst:m1.m2.m3.f.n:card"},
                {"form": "dwóch", "tag": "num:pl:loc:m1.m2.m3.f.n:card"},
            ]
        },
        "translation_en": "two"
    },
    "trzy": {
        "lemma": "trzy",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                # Masculine Personal (special case)
                {"form": "trzej", "tag": "num:pl:nom:m1:card"},
                {"form": "trzech", "tag": "num:pl:acc:m1:card"},
                # Other genders Nom/Acc
                {"form": "trzy", "tag": "num:pl:nom.acc:m2.m3.f.n:card"},
                # Common forms for other cases
                {"form": "trzech", "tag": "num:pl:gen:m1.m2.m3.f.n:card"},
                {"form": "trzem", "tag": "num:pl:dat:m1.m2.m3.f.n:card"},
                {"form": "trzema", "tag": "num:pl:inst:m1.m2.m3.f.n:card"},
                {"form": "trzech", "tag": "num:pl:loc:m1.m2.m3.f.n:card"},
            ]
        },
        "translation_en": "three"
    },
    "cztery": {
        "lemma": "cztery",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                # Masculine Personal (special case)
                {"form": "czterej", "tag": "num:pl:nom:m1:card"},
                {"form": "czterech", "tag": "num:pl:acc:m1:card"},
                # Other genders Nom/Acc
                {"form": "cztery", "tag": "num:pl:nom.acc:m2.m3.f.n:card"},
                # Common forms for other cases
                {"form": "czterech", "tag": "num:pl:gen:m1.m2.m3.f.n:card"},
                {"form": "czterem", "tag": "num:pl:dat:m1.m2.m3.f.n:card"},
                {"form": "czterema", "tag": "num:pl:inst:m1.m2.m3.f.n:card"},
                {"form": "czterech", "tag": "num:pl:loc:m1.m2.m3.f.n:card"},
            ]
        },
        "translation_en": "four"
    },
    "pięć": {
        "lemma": "pięć",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "pięć", "tag": "num:pl:nom.acc:card"}, # Gender distinction usually lost for 5+
                {"form": "pięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "pięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "five"
    },
    "sześć": {
        "lemma": "sześć",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "sześć", "tag": "num:pl:nom.acc:card"},
                {"form": "sześciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "sześcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "six"
    },
     "siedem": {
        "lemma": "siedem",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "siedem", "tag": "num:pl:nom.acc:card"},
                {"form": "siedmiu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "siedmioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "seven"
    },
    "osiem": {
        "lemma": "osiem",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "osiem", "tag": "num:pl:nom.acc:card"},
                {"form": "ośmiu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "ośmioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "eight"
    },
    "dziewięć": {
        "lemma": "dziewięć",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "dziewięć", "tag": "num:pl:nom.acc:card"},
                {"form": "dziewięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "dziewięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "nine"
    },
    "dziesięć": {
        "lemma": "dziesięć",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "dziesięć", "tag": "num:pl:nom.acc:card"},
                {"form": "dziesięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "dziesięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "ten"
    },
    "jedenaście": {
        "lemma": "jedenaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "jedenaście", "tag": "num:pl:nom.acc:card"},
                {"form": "jedenastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "jedenastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "eleven"
    },
    "dwanaście": {
        "lemma": "dwanaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "dwanaście", "tag": "num:pl:nom.acc:card"},
                {"form": "dwunastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "dwunastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "twelve"
    },
    "trzynaście": {
        "lemma": "trzynaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "trzynaście", "tag": "num:pl:nom.acc:card"},
                {"form": "trzynastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "trzynastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "thirteen"
    },
    "czternaście": {
        "lemma": "czternaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "czternaście", "tag": "num:pl:nom.acc:card"},
                {"form": "czternastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "czternastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "fourteen"
    },
    "piętnaście": {
        "lemma": "piętnaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "piętnaście", "tag": "num:pl:nom.acc:card"},
                {"form": "piętnastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "piętnastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "fifteen"
    },
    "szesnaście": {
        "lemma": "szesnaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "szesnaście", "tag": "num:pl:nom.acc:card"},
                {"form": "szesnastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "szesnastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "sixteen"
    },
    "siedemnaście": {
        "lemma": "siedemnaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "siedemnaście", "tag": "num:pl:nom.acc:card"},
                {"form": "siedemnastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "siedemnastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "seventeen"
    },
    "osiemnaście": {
        "lemma": "osiemnaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "osiemnaście", "tag": "num:pl:nom.acc:card"},
                {"form": "osiemnastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "osiemnastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "eighteen"
    },
    "dziewiętnaście": {
        "lemma": "dziewiętnaście",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "dziewiętnaście", "tag": "num:pl:nom.acc:card"},
                {"form": "dziewiętnastu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "dziewiętnastoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "nineteen"
    },
    # --- Tens and Hundred ---
    "dwadzieścia": {
        "lemma": "dwadzieścia",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "dwadzieścia", "tag": "num:pl:nom.acc:card"},
                {"form": "dwudziestu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "dwudziestoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "twenty"
    },
    "trzydzieści": {
        "lemma": "trzydzieści",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "trzydzieści", "tag": "num:pl:nom.acc:card"},
                {"form": "trzydziestu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "trzydziestoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "thirty"
    },
    "czterdzieści": {
        "lemma": "czterdzieści",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "czterdzieści", "tag": "num:pl:nom.acc:card"},
                {"form": "czterdziestu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "czterdziestoma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "forty"
    },
    "pięćdziesiąt": {
        "lemma": "pięćdziesiąt",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "pięćdziesiąt", "tag": "num:pl:nom.acc:card"},
                {"form": "pięćdziesięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "pięćdziesięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "fifty"
    },
    "sześćdziesiąt": {
        "lemma": "sześćdziesiąt",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "sześćdziesiąt", "tag": "num:pl:nom.acc:card"},
                {"form": "sześćdziesięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "sześćdziesięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "sixty"
    },
    "siedemdziesiąt": {
        "lemma": "siedemdziesiąt",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "siedemdziesiąt", "tag": "num:pl:nom.acc:card"},
                {"form": "siedemdziesięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "siedemdziesięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "seventy"
    },
    "osiemdziesiąt": {
        "lemma": "osiemdziesiąt",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "osiemdziesiąt", "tag": "num:pl:nom.acc:card"},
                {"form": "osiemdziesięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "osiemdziesięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "eighty"
    },
    "dziewięćdziesiąt": {
        "lemma": "dziewięćdziesiąt",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "dziewięćdziesiąt", "tag": "num:pl:nom.acc:card"},
                {"form": "dziewięćdziesięciu", "tag": "num:pl:gen.dat.loc:card"},
                {"form": "dziewięćdziesięcioma", "tag": "num:pl:inst:card"},
            ]
        },
        "translation_en": "ninety"
    },
    "sto": {
        "lemma": "sto",
        "grouped_forms": {
            "declensionCategoryNumeral": [
                {"form": "sto", "tag": "num:sg:nom.acc:n:card"}, # Typically neuter sg
                {"form": "stu", "tag": "num:sg:gen.dat.loc:n:card"},
                {"form": "stu", "tag": "num:sg:inst:n:card"},
                # Plural forms like 'sta' exist but are complex, omitted for simplicity
            ]
        },
        "translation_en": "one hundred"
    }
}
# ----------------------------

# --- Numeral to Word Mapping (1-100) ---
# Base words needed for construction
_NUM_WORDS_BASE = {
    1: "jeden", 2: "dwa", 3: "trzy", 4: "cztery", 5: "pięć", 6: "sześć", 7: "siedem", 8: "osiem", 9: "dziewięć",
    10: "dziesięć", 11: "jedenaście", 12: "dwanaście", 13: "trzynaście", 14: "czternaście", 15: "piętnaście",
    16: "szesnaście", 17: "siedemnaście", 18: "osiemnaście", 19: "dziewiętnaście",
    20: "dwadzieścia", 30: "trzydzieści", 40: "czterdzieści", 50: "pięćdziesiąt", 60: "sześćdziesiąt",
    70: "siedemdziesiąt", 80: "osiemdziesiąt", 90: "dziewięćdziesiąt", 100: "sto"
}

NUMERAL_WORD_MAP = {}
# Populate 1-19
for i in range(1, 20):
    NUMERAL_WORD_MAP[str(i)] = _NUM_WORDS_BASE[i]
# Populate tens and 100
for i in range(20, 101, 10):
    NUMERAL_WORD_MAP[str(i)] = _NUM_WORDS_BASE[i]
# Populate composites (21-99)
for i in range(21, 100):
    if i % 10 == 0: continue # Skip tens
    tens_part = i // 10 * 10
    ones_part = i % 10
    NUMERAL_WORD_MAP[str(i)] = f"{_NUM_WORDS_BASE[tens_part]} {_NUM_WORDS_BASE[ones_part]}"

print(f"Numeral map created with {len(NUMERAL_WORD_MAP)} entries.")
# --------------------------------------

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
    
    # --- 입력값 숫자 -> 단어 매핑 --- 
    original_input = word # Store original input for potential messages
    if word in NUMERAL_WORD_MAP:
        mapped_word = NUMERAL_WORD_MAP[word]
        print(f"[analyze_word] Input '{word}' detected, mapping to '{mapped_word}'.")
        word = mapped_word
    # ------------------------------

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
            
            # Use the original results for further processing
            primary_lemma = formatted_results[0].get("lemma") if formatted_results else None # Use original formatted_results
            cleaned_lemma = _clean_lemma(primary_lemma)
            translation_result = None
            print(f"[analyze_word] DEBUG: Calling translate_text_lingvanex with target_lang = {target_lang}")
            translation_result = translate_text_lingvanex(cleaned_lemma, target_lang)

            # <<< DEFINE is_numeral HERE >>>
            is_numeral = any(result.get('tag', '').startswith('num') for result in formatted_results) if formatted_results else False

            response_data = {
                "status": "success",
                "word": original_word_lower,
                "data": formatted_results, # Return the original formatted_results
                "translation_en": translation_result,
                "is_numeral_input": is_numeral # <<< USE FLAG HERE >>>
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
             # suggestion_message = f"Did you mean '{suggested_word}'?" # REMOVE THIS LINE
             response_data = {
                 "status": "suggestion",
                 # "message": suggestion_message, # REMOVE or comment out this line
                 "suggested_word": suggested_word,
                 "original_word": original_word,
                 "is_numeral_input": False 
             }
             print(f"[analyze_word] Returning suggestion JSON (no hardcoded message): {response_data}")
             return jsonify(response_data)
        else:
             print(f"[analyze_word] Attempt 2 FAILED: No valid diacritic suggestion found for '{original_word}'")

        # --- All attempts failed --- 
        print(f"[analyze_word] All attempts failed for '{original_word}'")
        failed_translation_result = None
        print(f"[analyze_word] Trying to translate original word '{original_word}' as fallback.")
        if original_word:
            failed_translation_result = translate_text_lingvanex(original_word, target_lang)

        # <<< DEFINE is_numeral HERE for fallback case >>>
        # Check if the *original input* was a numeral, even if analysis failed
        is_numeral = original_input.isdigit() or (original_input in NUMERAL_WORD_MAP) # Check original input here

        final_response = {
             "status": "success", # Keep status success even if analysis failed, just return empty data
             "word": original_word, 
             "data": [], # Keep data empty on overall failure
             "message": f"No analysis found for '{original_word}'.",
             "is_numeral_input": is_numeral # <<< USE FLAG HERE >>>
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
    return tag in ['fin', 'impt', 'imps', 'inf', 'pact', 'pant', 'pcon', 'ppas', 'praet', 'bedzie', 'ger', 'cond', 'impt_periph', 'fut_imps', 'cond_imps', 'impt_imps']

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
    - Tries the next best lemma interpretation if the first one yields empty/invalid results.
    - Returns a dictionary containing the lemma and grouped forms, or None if no valid forms found.
    """
    print(f"[generate_and_format_forms] Starting for word: '{word}'")

    # --- Hardcoded Check --- 
    if word in hardcoded_declensions:
        print(f"[generate_and_format_forms] Found hardcoded entry for '{word}'. Returning pre-defined data.")
        return hardcoded_declensions[word]

    if morf is None:
        print("Error: Morfeusz2 is not initialized.")
        return None

    try:
        word = word.lower()
        print(f"[디버그] 분석 시작 - 단어: '{word}', 함수: {check_func.__name__}")
        analysis_result = morf.analyse(word)
        if not analysis_result:
            print(f"[generate_and_format_forms] Word '{word}' not found or cannot be analyzed.")
            return None

        # --- Lemma Selection Logic (Get potential candidates) ---
        possible_lemmas_data = []
        for r in analysis_result:
            if len(r) >= 3 and isinstance(r[2], tuple) and len(r[2]) >= 3:
                analysis_tuple = r[2]
                current_lemma = analysis_tuple[1]
                current_tag_full = analysis_tuple[2]
                current_base_tag = current_tag_full.split(':', 1)[0]
                cleaned_lemma = _clean_lemma(current_lemma)
                if check_func(current_base_tag): # Only consider lemmas matching the function type
                    possible_lemmas_data.append({
                        "lemma": current_lemma,
                        "cleaned_lemma": cleaned_lemma or word, # Fallback
                        "tag": current_tag_full,
                        "base_tag": current_base_tag,
                    })
        
        if not possible_lemmas_data:
            print(f"[generate_and_format_forms] No primary lemma matching check_func ({check_func.__name__}) found for '{word}'.")
            return None

        # --- Prioritization Logic (Select the single best candidate for the first attempt) ---
        # (This part remains the same as the Karolina fix version) 
        primary_lemma_info = None
        cleaned_lemmas_found = {p['cleaned_lemma'] for p in possible_lemmas_data}
        exact_match_candidates = [p for p in possible_lemmas_data if p["cleaned_lemma"].lower() == word.lower()]
        target_lemma_list = exact_match_candidates if exact_match_candidates else possible_lemmas_data
        print(f"[generate_and_format_forms] Prioritizing within {'exact matches' if exact_match_candidates else 'all lemmas'} ({len(target_lemma_list)} candidates).")

        # Apply rules within the target_lemma_list
        word_is_ordinal = any(cl in ORDINAL_NUMERALS_SET for cl in cleaned_lemmas_found)
        if word_is_ordinal and check_func == is_declinable:
            # ... (Ordinal adjective priority logic - find adj_interpretation) ...
            adj_interpretation = None
            subst_interpretation = None
            target_cleaned_ordinal_lemma = next((cl for cl in cleaned_lemmas_found if cl in ORDINAL_NUMERALS_SET), None)
            if target_cleaned_ordinal_lemma:
                 for p_info in target_lemma_list:
                     if p_info["cleaned_lemma"] == target_cleaned_ordinal_lemma:
                         if p_info["base_tag"] == 'adj': adj_interpretation = p_info
                         elif p_info["base_tag"] == 'subst': subst_interpretation = p_info
            if adj_interpretation and subst_interpretation:
                 primary_lemma_info = adj_interpretation
                 print(f"[generate_and_format_forms] Prioritizing ADJECTIVE for ordinal: {primary_lemma_info['lemma']}")

        if primary_lemma_info is None: # If ordinal rule didn't apply or didn't find both
            if check_func == is_declinable and len(target_lemma_list) > 1:
                 # ... (m2 priority logic - find m2_lemma_info) ...
                 m2_lemma_info = None; m1_lemma_info = None
                 for p in target_lemma_list:
                    if ':m2:' in p["tag"] or p["tag"].endswith(':m2'): m2_lemma_info = p
                    if ':m1:' in p["tag"] or p["tag"].endswith(':m1'): m1_lemma_info = p
                 if m2_lemma_info and m1_lemma_info:
                     primary_lemma_info = m2_lemma_info
                     print(f"[generate_and_format_forms] Prioritizing m2: {primary_lemma_info['lemma']}")
                 elif target_lemma_list: # Fallback to first in target list
                     primary_lemma_info = target_lemma_list[0]
                     print(f"[generate_and_format_forms] Using first from target list (no m2/ordinal prio): {primary_lemma_info['lemma']}")
            elif target_lemma_list: # Verb or single declinable result
                 primary_lemma_info = target_lemma_list[0]
                 print(f"[generate_and_format_forms] Using first from target list (verb/single): {primary_lemma_info['lemma']}")

        if primary_lemma_info is None: # Final check if no lemma could be selected
            print(f"Error: Could not determine primary lemma for '{word}' after prioritization.")
            return None
        # --- End of Prioritization Logic ---

        # Extract info for the first attempt
        current_lemma = primary_lemma_info["lemma"]
        current_tag_full = primary_lemma_info["tag"]
        current_base_tag = primary_lemma_info["base_tag"]
        current_is_imperfective = 'imperf' in current_tag_full.split(':')
        current_has_reflexive_sie = ' się' in current_lemma or current_lemma.endswith('się')
        print(f"[generate_and_format_forms] Attempt 1: Using lemma='{current_lemma}', tag='{current_tag_full}'")

        # --- First attempt at generating forms using helper --- 
        grouped_forms = _generate_grouped_forms(current_lemma, check_func, category_func, current_is_imperfective, current_has_reflexive_sie)
        
        # --- Check Validity and Potentially Retry --- 
        if not _is_form_result_valid(grouped_forms, check_func, current_base_tag, current_tag_full):
            print(f"  -> Attempt 1 result for '{current_lemma}' is empty or invalid. Looking for alternative lemma...")
            
            # Find the index of the failed lemma info in the original *filtered* list
            failed_lemma_index = -1
            for i, p_info in enumerate(possible_lemmas_data):
                 if p_info["lemma"] == current_lemma and p_info["tag"] == current_tag_full:
                     failed_lemma_index = i
                     break
            
            next_candidate_info = None
            if failed_lemma_index != -1:
                 # Iterate through the rest of the *original filtered* list 
                 for i in range(failed_lemma_index + 1, len(possible_lemmas_data)):
                     # No need to check check_func again, as possible_lemmas_data was already filtered
                     next_candidate_info = possible_lemmas_data[i]
                     print(f"  -> Found next candidate: '{next_candidate_info['lemma']}' ({next_candidate_info['tag']})")
                     break # Take the first valid alternative
            
            if next_candidate_info:
                # Retry with the next candidate
                print(f"--- Attempt 2: Retrying with {next_candidate_info['lemma']} ---")
                retry_lemma = next_candidate_info["lemma"]
                retry_tag_full = next_candidate_info["tag"]
                retry_base_tag = next_candidate_info["base_tag"]
                retry_is_imperfective = 'imperf' in retry_tag_full.split(':')
                retry_has_reflexive_sie = ' się' in retry_lemma or retry_lemma.endswith('się')

                # Call the helper function again for the retry
                retry_grouped_forms = _generate_grouped_forms(retry_lemma, check_func, category_func, retry_is_imperfective, retry_has_reflexive_sie)
                
                # Check if the retry was successful
                if _is_form_result_valid(retry_grouped_forms, check_func, retry_base_tag, retry_tag_full):
                    print(f"  -> SUCCESS: Attempt 2 with '{retry_lemma}' yielded valid results.")
                    # Update the main variables to reflect the successful retry
                    current_lemma = retry_lemma
                    grouped_forms = retry_grouped_forms
                    # Update current_tag_full, current_base_tag etc. if needed elsewhere, maybe not necessary if only lemma/forms are returned
                else:
                    print(f"  -> INFO: Attempt 2 with '{retry_lemma}' also failed or yielded invalid results.")
                    # Keep the original (invalid) grouped_forms from Attempt 1
            else:
                print(f"  -> No suitable alternative lemma found to retry.")
        else:
             print(f"  -> SUCCESS: Attempt 1 with '{current_lemma}' yielded valid results.")

        # --- Final Check and Return --- 
        # Check the *final* state of grouped_forms (could be from attempt 1 or 2)
        # Need the *final* base_tag and full_tag used for the result we are checking
        final_base_tag = current_base_tag # This assumes current_base_tag was updated if retry succeeded - let's ensure that
        final_tag_full = current_tag_full
        if 'retry_base_tag' in locals() and _is_form_result_valid(grouped_forms, check_func, retry_base_tag, retry_tag_full): # Check if retry succeeded using retry tags
            final_base_tag = retry_base_tag
            final_tag_full = retry_tag_full
            
        if not _is_form_result_valid(grouped_forms, check_func, final_base_tag, final_tag_full):
             print(f"[generate_and_format_forms] Final check: No valid forms found for '{word}' after all attempts.")
             return None

        print(f"  -> Final grouped forms categories being returned for lemma '{current_lemma}': {list(grouped_forms.keys())}")
        return {"lemma": current_lemma, "grouped_forms": grouped_forms}

    except Exception as e:
        print(f"Error during main part of generate_and_format_forms for '{word}': {e}")
        import traceback
        traceback.print_exc()
        return None

# --- NEW Internal Helper Function: Generate Grouped Forms --- 
def _generate_grouped_forms(lemma_to_generate, check_func, category_func, is_imperfective, has_reflexive_sie):
    """Internal helper to generate and group forms for a given lemma."""
    grouped_forms = {}
    infinitive_form = None
    past_forms = {} 
    past_impersonal_form = None
    present_impersonal_forms = []
    
    try:
        generated_forms_raw = morf.generate(lemma_to_generate)
        print(f"    [_generate_grouped_forms] Raw generated forms for '{lemma_to_generate}': count={len(generated_forms_raw)}")

        # --- Form Processing Loop --- 
        for form_tuple in generated_forms_raw:
            try:
                # ... (Logic for parsing form_tuple) ...
                if len(form_tuple) < 3: continue
                form = form_tuple[0]
                form_lemma_full = form_tuple[1]
                form_tag_full = form_tuple[2]
                qualifiers = list(form_tuple[3:]) if len(form_tuple) > 3 else []
                base_tag = form_tag_full.split(':', 1)[0]
                
                # ... (should_process check using check_func) ...
                should_process = False
                if check_func == is_verb: should_process = base_tag in ALLOWED_TAGS
                elif check_func == is_declinable: should_process = base_tag in DECLINABLE_TAGS
                if not should_process: continue
                
                # ... (Filtering, e.g., negative gerunds) ...
                if base_tag == 'ger' and ':neg' in form_tag_full: continue 

                # ... (Store key forms like infinitive, past_forms, impersonals) ...
                if base_tag == 'inf': infinitive_form = form
                if base_tag == 'imps' and (form.endswith('no') or form.endswith('to')): past_impersonal_form = form
                if check_func == is_verb and is_impersonal_form(form, form_tag_full) and base_tag == 'imps' and not (form.endswith('no') or form.endswith('to')):
                    if form not in present_impersonal_forms: present_impersonal_forms.append(form)
                if base_tag == 'praet':
                    parts = form_tag_full.split(':')
                    num = next((p for p in parts if p in ['sg', 'pl']), None)
                    person = next((p for p in parts if p in ['pri', 'sec', 'ter']), None) # Explicitly get person

                    if num and person: # Ensure number and person are found
                        genders_in_tag = [p for p in parts if p in ['m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2', 'non-m1'] or '.' in p]
                        
                        # Store in past_forms for each specific gender component
                        for gen_part_full in genders_in_tag:
                            for sub_gen in gen_part_full.split('.'):
                                if sub_gen in ['m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2', 'non-m1']:
                                    k = f"{person}:{num}:{sub_gen}" # Key: person:number:gender
                                    if k not in past_forms: # Store first encountered form for this specific key
                                        past_forms[k] = form
                                    # Store a general key as well if it's a non-m1 form for pl non-m1 fallback
                                    if num == 'pl' and sub_gen in ['f','n','m2','m3'] and f"{person}:pl:non-m1" not in past_forms:
                                        past_forms[f"{person}:pl:non-m1"] = form


                    # The form is already a past tense form from Morfeusz, directly add it to the category
                    category_key_for_past = get_conjugation_category_key(base_tag, form_tag_full)
                    if category_key_for_past == 'conjugationCategoryPastTense':
                        # Correction for specific past tense plural non-virile errors
                        # These errors might stem from Morfeusz with aggl="permissive"
                        corrected_form = form
                        
                        praet_parts_for_correction = form_tag_full.split(':')
                        praet_num_for_correction = next((p for p in praet_parts_for_correction if p in ['sg', 'pl']), None)
                        praet_person_for_correction = next((p for p in praet_parts_for_correction if p in ['pri', 'sec', 'ter']), None)

                        if praet_num_for_correction == 'pl':
                            if praet_person_for_correction == 'pri' and form.endswith('śmyśmy'):
                                # Correct "Xłyśmyśmy" to "Xłyśmy" or "Xśmyśmy" to "Xśmy"
                                corrected_form = form[:-3]
                                print(f"    [PastTenseCorrection] Corrected 1pl non-virile: {form} -> {corrected_form} (Tag: {form_tag_full})")
                            elif praet_person_for_correction == 'sec' and form.endswith('śmyście'):
                                # Correct "Xłyśmyście" to "Xłyście" (e.g., robiłyśmyście -> robiłyście)
                                # This means the original stem was form[:-7] (e.g., "robiły"), and correct ending is "ście"
                                corrected_form = form[:-7] + "ście"
                                print(f"    [PastTenseCorrection] Corrected 2pl non-virile: {form} -> {corrected_form} (Tag: {form_tag_full})")
                        
                        form_data_for_past = {"form": corrected_form, "tag": form_tag_full, "qualifiers": qualifiers}
                        
                        # --- BEGIN DEBUG LOGGING for Past Tense Plural Forms ---
                        if praet_num_for_correction == 'pl' and praet_person_for_correction in ['pri', 'sec']:
                            print(f"    [BackendCheck-PastTense] For {praet_person_for_correction}:{praet_num_for_correction} (Tag: {form_tag_full}), attempting to add: {form_data_for_past}")
                        # --- END DEBUG LOGGING ---
                        
                        if category_key_for_past not in grouped_forms: grouped_forms[category_key_for_past] = []
                        if form_data_for_past not in grouped_forms[category_key_for_past]:
                             grouped_forms[category_key_for_past].append(form_data_for_past)
                             print(f"    [_generate_grouped_forms] Directly added to PastTense: {form_data_for_past}")


                # ... (Get category_key using category_func, refine for impersonals) ...
                category_key = None
                if check_func == is_verb: category_key = get_conjugation_category_key(base_tag, form_tag_full)
                elif check_func == is_declinable: category_key = get_declension_category_key(base_tag, form_tag_full)
                if check_func == is_verb and is_impersonal_form(form, form_tag_full):
                   if form.endswith(('no', 'to')): category_key = 'conjugationCategoryPastImpersonal'
                   elif base_tag == 'imps': category_key = 'conjugationCategoryPresentImpersonal'
                   elif base_tag in ['impt', 'impt_imps'] or 'impt' in form_tag_full : category_key = 'conjugationCategoryImperativeImpersonal'
                   elif base_tag == 'fut_imps': category_key = 'conjugationCategoryFutureImpersonal'
                   elif base_tag == 'cond_imps': category_key = 'conjugationCategoryConditionalImpersonal'

                # ... (Append form_data to grouped_forms[category_key], avoid duplicates) ...
                if category_key:
                    form_data = {"form": form, "tag": form_tag_full, "qualifiers": qualifiers}
                    if category_key not in grouped_forms: grouped_forms[category_key] = []
                    if form_data not in grouped_forms[category_key]: grouped_forms[category_key].append(form_data)

            except Exception as form_proc_error:
                print(f"      [_generate_grouped_forms] ERROR processing form tuple: {form_tuple} - {form_proc_error}")
                continue
        # --- End Form Processing Loop ---

        # --- Post-processing (Impersonal, Future, Conditional - Copied from previous version) ---
        # (This extensive block should be copied here without changes from the previous working version)
        
        # Retrieve the neutral singular 3rd person past form, e.g., "robiło"
        # CORRECTED KEY to "ter:sg:n" to fetch the 3rd person neuter singular past form
        neutral_past_sg_3rd_form = past_forms.get("ter:sg:n")

        if past_impersonal_form:
            future_imps_key = 'conjugationCategoryFutureImpersonal'
            if future_imps_key not in grouped_forms: grouped_forms[future_imps_key] = []
            
            # Use the neutral past singular 3rd person form for future impersonal
            if neutral_past_sg_3rd_form:
                f1 = f"będzie {neutral_past_sg_3rd_form}"
                f2 = f"będzie się {neutral_past_sg_3rd_form}"
                if not any(d['form'] == f1 for d in grouped_forms[future_imps_key]): grouped_forms[future_imps_key].append({"form": f1, "tag": "fut_imps:imperf", "qualifiers": []})
                if not any(d['form'] == f2 for d in grouped_forms[future_imps_key]): grouped_forms[future_imps_key].append({"form": f2, "tag": "fut_imps:imperf:refl", "qualifiers": []})
            else:
                # Fallback to original behavior if neutral_past_sg_3rd_form is not found, though ideally it should exist.
                # This part might indicate an issue with past_forms population for some verbs if it's reached.
                print(f"    [_generate_grouped_forms] WARNING: neutral_past_sg_3rd_form not found for {lemma_to_generate} when forming future impersonal. Using past_impersonal_form: {past_impersonal_form}")
                f1_fallback = f"będzie {past_impersonal_form}"
                f2_fallback = f"będzie się {past_impersonal_form}"
                if not any(d['form'] == f1_fallback for d in grouped_forms[future_imps_key]): grouped_forms[future_imps_key].append({"form": f1_fallback, "tag": "fut_imps:imperf:fallback", "qualifiers": []})
                if not any(d['form'] == f2_fallback for d in grouped_forms[future_imps_key]): grouped_forms[future_imps_key].append({"form": f2_fallback, "tag": "fut_imps:imperf:refl:fallback", "qualifiers": []})

            cond_imps_key = 'conjugationCategoryConditionalImpersonal'
            if cond_imps_key not in grouped_forms: grouped_forms[cond_imps_key] = []
            c1 = f"{past_impersonal_form} by"
            c2 = f"by {past_impersonal_form}"
            c3 = f"{past_impersonal_form} by się"
            if not any(d['form'] == c1 for d in grouped_forms[cond_imps_key]): grouped_forms[cond_imps_key].append({"form": c1, "tag": "cond_imps", "qualifiers": []})
            if not any(d['form'] == c2 for d in grouped_forms[cond_imps_key]): grouped_forms[cond_imps_key].append({"form": c2, "tag": "cond_imps:alt", "qualifiers": []})
            if not has_reflexive_sie and not any(d['form'] == c3 for d in grouped_forms[cond_imps_key]): grouped_forms[cond_imps_key].append({"form": c3, "tag": "cond_imps:refl", "qualifiers": []})
        
        # --- DEBUG LOGGING for Populating Present Impersonal Category ---
        print(f"    [BackendDebug-PresImpsPopulate] Before populating 'conjugationCategoryPresentImpersonal', present_impersonal_forms list: {present_impersonal_forms}")
        # --- END DEBUG LOGGING ---
        
        # --- BEGIN: Construct Present Impersonal if not directly provided by Morfeusz ---
        if not present_impersonal_forms: 
            print(f"    [PresImpsConstruct-Info] 'present_impersonal_forms' is empty. Attempting to construct from 3rd person singular present.")
            fin_sg_ter_forms = []
            if "conjugationCategoryPresentIndicative" in grouped_forms:
                for f_data in grouped_forms["conjugationCategoryPresentIndicative"]:
                    if isinstance(f_data, dict) and "tag" in f_data and "form" in f_data: # Basic check for valid structure
                        if "sg" in f_data["tag"] and "ter" in f_data["tag"] and "fin" in f_data["tag"] and not f_data["form"].startswith("nie "):
                            fin_sg_ter_forms.append(f_data["form"])
            
            print(f"    [PresImpsConstruct-Debug] Found affirmative fin_sg_ter_forms for construction: {fin_sg_ter_forms}")

            temp_constructed_list = []
            for fin_form in fin_sg_ter_forms:
                # Affirmative: "robi się"
                form_aff = f"{fin_form} się"
                if form_aff not in temp_constructed_list:
                    temp_constructed_list.append(form_aff)
                    print(f"    [PresImpsConstruct-Confirm] Constructed and added to temp list (AFF): '{form_aff}'")
                
                # Negative: "nie robi się"
                form_neg = f"nie {fin_form} się"
                if form_neg not in temp_constructed_list:
                    temp_constructed_list.append(form_neg)
                    print(f"    [PresImpsConstruct-Confirm] Constructed and added to temp list (NEG): '{form_neg}'")
            
            # If successfully constructed, assign to present_impersonal_forms
            if temp_constructed_list:
                present_impersonal_forms = temp_constructed_list
                print(f"    [PresImpsConstruct-Success] 'present_impersonal_forms' updated to: {present_impersonal_forms}")
            else:
                print(f"    [PresImpsConstruct-Fail] Could not construct any present impersonal forms.")
        # --- END: Construct Present Impersonal --- 
       
        if present_impersonal_forms:
            impt_imps_key = 'conjugationCategoryImperativeImpersonal'
            if impt_imps_key not in grouped_forms: grouped_forms[impt_imps_key] = []
            for pf_candidate_for_impt in present_impersonal_forms:
                # Only create imperative for affirmative base forms
                if not pf_candidate_for_impt.startswith("nie "):
                    iif = f"{IMPERSONAL_IMPERATIVE_PREFIX} {pf_candidate_for_impt}"
                    if not any(d['form'] == iif for d in grouped_forms[impt_imps_key]): 
                        grouped_forms[impt_imps_key].append({"form": iif, "tag": "impt_imps", "qualifiers": []})
            
            present_imps_key = 'conjugationCategoryPresentImpersonal'
            if present_imps_key not in grouped_forms: grouped_forms[present_imps_key] = []

            # Use a set to track form strings already added to this specific category to prevent duplicates
            processed_forms_in_category = set()

            for pf_candidate in present_impersonal_forms:
                if pf_candidate.startswith("nie "):
                    # This is an already-negated form from the list
                    form_to_add = pf_candidate
                    tag_to_add = "imps:pres:neg" # Correct tag for negated form
                    form_data = {"form": form_to_add, "tag": tag_to_add, "qualifiers": []}
                    
                    # Check if this exact form string is already added
                    if form_to_add not in processed_forms_in_category:
                        grouped_forms[present_imps_key].append(form_data)
                        processed_forms_in_category.add(form_to_add)
                        print(f"    [BackendDebug-PresImpsPopulate] Added (pre-negated) form: {form_data} to {present_imps_key}")
                else:
                    # This is an affirmative form from the list
                    affirmative_form_to_add = pf_candidate
                    affirmative_tag = "imps:pres"
                    affirmative_form_data = {"form": affirmative_form_to_add, "tag": affirmative_tag, "qualifiers": []}
                    if affirmative_form_to_add not in processed_forms_in_category:
                        grouped_forms[present_imps_key].append(affirmative_form_data)
                        processed_forms_in_category.add(affirmative_form_to_add)
                        print(f"    [BackendDebug-PresImpsPopulate] Added AFFIRMATIVE form: {affirmative_form_data} to {present_imps_key}")

                    # Construct and add the corresponding negative form
                    negative_counterpart_form = f"nie {pf_candidate}"
                    negative_counterpart_tag = "imps:pres:neg"
                    negative_counterpart_data = {"form": negative_counterpart_form, "tag": negative_counterpart_tag, "qualifiers": []}
                    if negative_counterpart_form not in processed_forms_in_category:
                        grouped_forms[present_imps_key].append(negative_counterpart_data)
                        processed_forms_in_category.add(negative_counterpart_form)
                        print(f"    [BackendDebug-PresImpsPopulate] Added corresponding NEGATIVE form: {negative_counterpart_data} to {present_imps_key}")
                        
            print(f"    [BackendDebug-PresImpsPopulate] Populated 'conjugationCategoryPresentImpersonal': {grouped_forms.get(present_imps_key)}")

        if is_imperfective:
            if infinitive_form:
                future_key = 'conjugationCategoryFutureImperfectiveIndicative'
                if future_key not in grouped_forms: grouped_forms[future_key] = []
                for np, aux in BYC_FUTURE_FORMS.items():
                    num, pers = np.split(':')
                    gf = f"{aux} {infinitive_form}"
                    gt = f"fut:{num}:{pers}:imperf"
                    if not any(d['form'] == gf for d in grouped_forms[future_key]):
                        grouped_forms[future_key].append({"form": gf, "tag": gt, "qualifiers": []})
            conditional_key = 'conjugationCategoryConditional'
            if conditional_key not in grouped_forms: grouped_forms[conditional_key] = []
            if len(grouped_forms.get(conditional_key, [])) < 6 and past_forms:
                print(f"      [_generate_grouped_forms] Attempting conditional generation based on past forms for {lemma_to_generate}")
                for np, particle in BY_CONDITIONAL_PARTICLES.items():
                    num, pers = np.split(':')
                    genders_to_try = sorted(list(set(k.split(':')[1] for k in past_forms.keys() if k.startswith(f'{num}:'))))
                    if not genders_to_try and num == 'pl': genders_to_try = ['m1', 'non-m1'] 
                    if not genders_to_try and num == 'sg': genders_to_try = ['m1', 'f', 'n'] 
                    for gender in genders_to_try:
                        past_key_specific = f"{num}:{gender}"
                        past_key_composite = None # Logic to find composite tag if specific is missing
                        if num == 'sg' and gender in ['m1','m2','m3'] and 'sg:m1.m2.m3' in past_forms: past_key_composite = 'sg:m1.m2.m3'
                        elif num == 'pl' and gender in ['m2','m3','f','n','non-m1'] and 'pl:m2.m3.f.n' in past_forms: past_key_composite = 'pl:m2.m3.f.n'
                        elif num == 'pl' and gender == 'non-m1' and 'pl:m2.m3.f.n' in past_forms: past_key_composite = 'pl:m2.m3.f.n'
                        base_past = past_forms.get(past_key_specific) or past_forms.get(past_key_composite)
                        if base_past:
                            gf = f"{base_past}{particle}"
                            gt = f"cond:{num}:{gender}:{pers}:imperf"
                            is_already_present = any(f['form'] == gf and f['tag'] == gt for f in grouped_forms.get(conditional_key, []))
                            if not is_already_present:
                                grouped_forms[conditional_key].append({"form": gf, "tag": gt, "qualifiers": []})
        # --- End Post-processing ---
        
        return grouped_forms

    except Exception as e:
        print(f"    [_generate_grouped_forms] Error generating forms for '{lemma_to_generate}': {e}")
        import traceback
        traceback.print_exc() 
        return {} # Return empty dict on error within helper

# --- NEW Helper Function: Check if grouped_forms result is valid --- 
def _is_form_result_valid(grouped_forms, check_func, base_tag, full_tag):
    """Checks if the grouped_forms dictionary contains meaningful data."""
    print(f"[_is_form_result_valid] Checking validity for {'verb' if check_func == is_verb else 'declinable'}. Grouped forms: {grouped_forms}") # Add more logging
    if not grouped_forms:
        print("[_is_form_result_valid] Invalid: grouped_forms is empty.")
        return False
    
    if check_func == is_verb:
        # Check if any core verb category has actual forms
        verb_keys_to_check = [
            'conjugationCategoryPresentIndicative', 
            'conjugationCategoryPastTense', 
            'conjugationCategoryInfinitive',
            'conjugationCategoryFuturePerfectiveIndicative',
            'conjugationCategoryFutureImperfectiveIndicative',
            'conjugationCategoryPresentActiveParticiple', 
            'conjugationCategoryPastPassiveParticiple'
        ]
        is_valid = any(key in grouped_forms and grouped_forms[key] for key in verb_keys_to_check)
        print(f"[_is_form_result_valid] Verb validity check: {is_valid}")
        return is_valid
    
    elif check_func == is_declinable:
        # Check the specific category expected for this declinable word
        expected_category_key = get_declension_category_key(base_tag, full_tag)
        print(f"[_is_form_result_valid] Expected key for declinable: {expected_category_key}")
        if expected_category_key in grouped_forms and grouped_forms[expected_category_key]:
            # --- MODIFIED VALIDITY CHECK --- 
            # Check if there are MORE THAN ONE distinct forms in the main category.
            # This prevents accepting results where only the base form itself was generated.
            num_forms = len(grouped_forms[expected_category_key])
            is_valid = num_forms > 1 
            print(f"[_is_form_result_valid] Declinable validity check: Key '{expected_category_key}' found with {num_forms} forms. Valid: {is_valid}")
            return is_valid
        else:
            print(f"[_is_form_result_valid] Declinable validity check: Expected key '{expected_category_key}' not found or empty.")
            return False # Category not found or empty
        
    print("[_is_form_result_valid] Unknown check_func, defaulting to valid.")
    return True # Default to valid if check_func is unknown

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
    # --- Add Numeral Category --- 
    elif base_tag == 'num': return 'declensionCategoryNumeral'
    else: return 'declensionCategoryOtherForms'
# --------------------------------------------------

# --- NEW: Composite Numeral Declension Generation (Pilot 21-25) ---
def _generate_composite_numeral_declensions(num_str):
    """
    Generates detailed declension forms for composite numerals (21-99).
    Returns a structured dictionary: {'case': {'gender': 'form', ...}}
    Handles genitive construction rules based on the ones digit.
    """
    try:
        num = int(num_str)
        # --- REMOVE Pilot Range Check --- 
        # if not (21 <= num <= 25):
        #     print(f"[_generate_composite] Num {num} is outside pilot range (21-25).")
        #     return None
        # --- Ensure it's a two-digit composite number (excluding tens) ---
        if not (21 <= num <= 99 and num % 10 != 0):
            print(f"[_generate_composite] Num {num} is not a composite numeral in the 21-99 range (excluding tens).")
            return None

        tens_digit_val = num // 10 * 10
        ones_digit_val = num % 10

        # Get component words
        tens_word = _NUM_WORDS_BASE.get(tens_digit_val)
        ones_word_lemma = _NUM_WORDS_BASE.get(ones_digit_val) # Lemma form of the ones digit

        if not tens_word or not ones_word_lemma:
            print(f"[_generate_composite] Error: Base words not found for {num}")
            return None

        # Get declension data for components from hardcoded data
        tens_decl_raw = hardcoded_declensions.get(tens_word)
        ones_decl_raw = hardcoded_declensions.get(ones_word_lemma)

        if not tens_decl_raw or not ones_decl_raw:
             print(f"[_generate_composite] Error: Raw declension data missing for components of {num} ('{tens_word}', '{ones_word_lemma}')")
             return None

        tens_decl = tens_decl_raw.get("grouped_forms", {}).get("declensionCategoryNumeral", [])
        ones_decl = ones_decl_raw.get("grouped_forms", {}).get("declensionCategoryNumeral", [])

        if not tens_decl or not ones_decl:
            print(f"[_generate_composite] Error: Declension list data not found for components of {num}")
            return None

        # Helper to find specific form based on tag components (Keep the existing helper)
        def find_form(decl_list, case, gender=None, number='pl', exact_case_match=False):
            # ... (Keep the existing find_form implementation) ...
            target_parts = {number, case}
            gender_map = {
                'm1': {'m1'},
                'm_other': {'m2', 'm3'},
                'f': {'f'},
                'n': {'n', 'n1', 'n2'}
            }
            target_gender_tags = gender_map.get(gender, set()) if gender else set()

            best_match_form = None
            best_match_specificity = -1 # 0: case/num, 1: case/num/gender_in_tag, 2: exact_case/num/gender

            for item in decl_list:
                form = item['form']
                tag_parts = set(item['tag'].split(':'))
                item_genders = {'m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2'} & tag_parts
                item_cases_raw = ""
                for part in item['tag'].split(':'):
                     if any(c in part for c in ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']):
                         item_cases_raw = part
                         break
                item_cases = set(item_cases_raw.split('.'))

                # Check 1: Basic number and case match
                if number not in tag_parts or not (case in item_cases or (exact_case_match and case == item_cases_raw)):
                     continue # Skip if number or case doesn't match at all

                current_specificity = 0
                gender_match = False
                if gender:
                    if target_gender_tags & item_genders: # Direct gender match
                        gender_match = True
                        current_specificity = 1
                    elif not item_genders and not target_gender_tags: # No gender specified on either side
                        gender_match = True
                    elif not item_genders and target_gender_tags: # Item has no gender, applies generally
                         gender_match = True
                    elif item_genders and not target_gender_tags: # Item has gender, target doesn't, applies generally
                         gender_match = True
                else: # No specific gender required
                    gender_match = True

                if not gender_match:
                     continue # Skip if gender is required and doesn't match

                # Check 2: Prioritize exact case match if required
                if exact_case_match and case != item_cases_raw:
                     continue

                # Check 3: Prioritize specific gender matches
                if gender and (target_gender_tags & item_genders):
                     current_specificity = 2 # Higher specificity for direct gender match

                # Update best match if current is better or equally specific but preferred (e.g., m3 over m2 for acc)
                if current_specificity > best_match_specificity:
                    best_match_specificity = current_specificity
                    best_match_form = form
                elif current_specificity == best_match_specificity:
                     # Preference rules for ties (e.g., prefer m3 inanimate acc over m2 animate acc)
                     if case == 'acc' and gender == 'm_other':
                         if 'm3' in item_genders: # Prefer m3 if available
                             best_match_form = form
                     # Could add more tie-breaking if needed, otherwise first found wins
                     if best_match_form is None: best_match_form = form # Take first match in case of equal specificity

            # Fallback for combined cases like gen.dat.loc if no specific match found
            if best_match_form is None and not exact_case_match:
                 for item in decl_list:
                     form = item['form']
                     tag_parts = set(item['tag'].split(':'))
                     item_genders = {'m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2'} & tag_parts
                     item_cases_raw = ""
                     for part in item['tag'].split(':'):
                         if any(c in part for c in ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']):
                             item_cases_raw = part
                             break
                     item_cases = set(item_cases_raw.split('.'))

                     if number in tag_parts and case in item_cases:
                         # Check gender compatibility loosely
                         compatible = True
                         if gender and item_genders and not (target_gender_tags & item_genders): # If gender required and item has different gender
                             compatible = False

                         if compatible:
                             return form # Return first compatible form found in combined tag

            return best_match_form

        # --- Define Structure and Genders --- 
        cases = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc']
        genders_map = {'m1': 'm1', 'm_other': 'm2/m3', 'f': 'f', 'n': 'n'} # For display/grouping keys
        composite_declensions = {case: {g_key: "-" for g_key in genders_map.values()} for case in cases}
        composite_declensions['voc'] = {g_key: "-" for g_key in genders_map.values()} # Add vocative row

        # --- Combination Rules --- 
        for case in cases:
            # Find tens form - handle variations like gen/dat/loc and inst
            tens_form = find_form(tens_decl, case, exact_case_match=True) # Try exact case first
            if not tens_form:
                 # Common fallbacks for tens (50, 60, etc.)
                 if case in ['gen', 'dat', 'loc']:
                     tens_form = find_form(tens_decl, 'gen') # Try genitive form
                 elif case == 'inst':
                     tens_form = find_form(tens_decl, 'inst') # Try instrumental
                 # Fallback to nominative/accusative form if still not found
                 if not tens_form:
                      tens_form = find_form(tens_decl, 'nom')
                      
            tens_form = tens_form or _NUM_WORDS_BASE.get(tens_digit_val, '?') # Ultimate fallback

            # Iterate through display genders
            for gender_key, display_key in genders_map.items():
                ones_form = None
                # Determine number for 'ones' part (1 is sg, 2+ are pl)
                ones_number = 'sg' if ones_digit_val == 1 else 'pl'

                # --- Special Rule: Genitive construction --- 
                # Generalized: Use genitive construction for...
                # - m1 nom/acc when ones digit is 2, 3, 4 
                # - m1 acc when ones digit is 1
                # - gen/dat/loc for ALL genders when ones digit is 5, 6, 7, 8, 9
                use_genitive_construction = False
                if ones_digit_val in [2, 3, 4]:
                    if gender_key == 'm1' and case in ['nom', 'acc']:
                         use_genitive_construction = True
                elif ones_digit_val == 1:
                     if gender_key == 'm1' and case == 'acc':
                          use_genitive_construction = True
                elif ones_digit_val in [5, 6, 7, 8, 9]:
                     if case in ['gen', 'dat', 'loc']:
                         use_genitive_construction = True

                if use_genitive_construction:
                    # Use genitive form of the tens part
                    tens_form_gen = find_form(tens_decl, 'gen') or tens_form # Fallback to base if genitive missing
                    # Determine the case needed for the 'ones' part in genitive constructions
                    # For m1 nom/acc (with 2,3,4), use nom/acc of the ones part
                    # For m1 acc (with 1), use acc of the ones part (which is genitive)
                    # For gen/dat/loc (with 5-9), use genitive of the ones part
                    ones_case_for_gen_constr = 'gen' # Default for 5-9
                    if ones_digit_val in [2, 3, 4] and gender_key == 'm1' and case in ['nom', 'acc']:
                        ones_case_for_gen_constr = case # Use nom or acc
                    elif ones_digit_val == 1 and gender_key == 'm1' and case == 'acc':
                        ones_case_for_gen_constr = 'gen' # Accusative of m1 'jeden' is genitive 'jednego'
                    
                    ones_form = find_form(ones_decl, ones_case_for_gen_constr, gender_key, number=ones_number)
                    ones_form = ones_form or find_form(ones_decl, 'gen', gender_key, number=ones_number) # Fallback to genitive
                    if ones_form:
                         composite_declensions[case][display_key] = f"{tens_form_gen} {ones_form}"
                    else:
                         composite_declensions[case][display_key] = f"{tens_form_gen} ?"
                else:
                     # --- Standard construction --- 
                     # Find ones form for the current case and gender
                     ones_form = find_form(ones_decl, case, gender_key, number=ones_number)
                     # Fallback logic for missing forms (e.g., acc might use nom for non-m1)
                     if not ones_form and case == 'acc' and gender_key != 'm1':
                         ones_form = find_form(ones_decl, 'nom', gender_key, number=ones_number)
                     # Further fallback if still missing
                     ones_form = ones_form or find_form(ones_decl, 'nom', gender='f', number=ones_number) # Try common fem form
                     ones_form = ones_form or _NUM_WORDS_BASE.get(ones_digit_val, '?') # Ultimate fallback

                     if tens_form and ones_form:
                         composite_declensions[case][display_key] = f"{tens_form} {ones_form}"
                     else:
                         composite_declensions[case][display_key] = f"{tens_form or '?'} {ones_form or '?'}"

        # Set Vocative same as Nominative
        composite_declensions['voc'] = composite_declensions['nom'].copy()

        print(f"[_generate_composite] Generated composite declensions for {num_str}: {composite_declensions}")
        return composite_declensions

    except Exception as e:
        print(f"[_generate_composite] Error generating composite declensions for '{num_str}': {e}")
        import traceback
        traceback.print_exc()
        return None
# ------------------------------------------------------------------

# --- NEW Helper: Convert hardcoded simple numeral data to detailed format --- 
def _convert_simple_numeral_to_detailed(numeral_word, hardcoded_forms_list):
    """
    Converts the list-based hardcoded declension data for simple numerals 
    (like 'dwadzieścia', 'sto') into the detailed Case x Gender map format.
    Returns a structured dictionary: {'case': {'gender_key': 'form', ...}} or None.
    """
    if not hardcoded_forms_list or not isinstance(hardcoded_forms_list, list):
        print(f"[_convert_simple] Invalid input: hardcoded_forms_list is not a list for {numeral_word}.")
        return None

    cases = ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']
    # Use the same gender keys as the composite generator for consistency
    genders_map = {'m1': 'm1', 'm_other': 'm2/m3', 'f': 'f', 'n': 'n'}
    detailed_declensions = {case: {g_key: "-" for g_key in genders_map.values()} for case in cases}

    # Process the list of forms
    for item in hardcoded_forms_list:
        form = item.get('form')
        tag = item.get('tag')
        if not form or not tag:
            continue

        tag_parts = tag.split(':')
        item_number = None
        item_cases_raw = ""
        item_genders_raw = ""

        # Extract case, number, gender from the tag parts
        for part in tag_parts:
            if part in ['sg', 'pl']: item_number = part
            if any(c in part for c in ['nom', 'gen', 'dat', 'acc', 'inst', 'loc', 'voc']):
                item_cases_raw = part
            if any(g in part for g in ['m1', 'm2', 'm3', 'f', 'n', 'n1', 'n2']):
                 item_genders_raw = part # Potentially includes dots like m2.m3.f.n
        
        item_cases = set(item_cases_raw.split('.'))
        item_genders = set(item_genders_raw.split('.'))

        # Determine target display gender keys based on parsed tag genders
        target_display_keys = set()
        if 'm1' in item_genders:
            target_display_keys.add('m1')
        if 'm2' in item_genders or 'm3' in item_genders:
            target_display_keys.add('m2/m3')
        if 'f' in item_genders:
            target_display_keys.add('f')
        if 'n' in item_genders or 'n1' in item_genders or 'n2' in item_genders:
            target_display_keys.add('n')
            
        # If no specific gender tag found, assume it applies to all relevant genders (common for 5+)
        if not target_display_keys and tag.startswith('num:') and len(tag_parts) >= 3: 
             # For numerals 5+ (pięć, sześć...), forms often apply to all non-m1 plurals, or all genders in gen/dat/loc/inst
             if item_number == 'pl':
                  target_display_keys.update(['m1', 'm2/m3', 'f', 'n']) # Assume applies to all genders for simplicity if tag doesn't specify
             elif item_number == 'sg': # Like 'sto'
                  target_display_keys.add('n') # Default 'sto' to neuter if no other info

        # Populate the detailed map
        for case_code in item_cases:
            if case_code in detailed_declensions:
                for display_key in target_display_keys:
                    # Only fill if currently empty or default '-', avoid overwriting specific forms
                    if detailed_declensions[case_code][display_key] == "-":
                        detailed_declensions[case_code][display_key] = form
                    else:
                        # Handle potential conflicts/overwrites if needed, e.g., prefer more specific tag?
                        # For now, simple overwrite or keep first wins.
                        pass 
                        
    # Fill remaining '-' with likely forms (e.g., vocative = nominative)
    if 'nom' in detailed_declensions:
         detailed_declensions['voc'] = detailed_declensions['nom'].copy()
         for g_key in genders_map.values():
             if detailed_declensions['voc'][g_key] == "-":
                 detailed_declensions['voc'][g_key] = detailed_declensions['nom'][g_key]

    # Special handling for numbers 5+ (pięć, sześć...) where most forms are the same across genders
    # Ensure consistency for gen, dat, loc, inst if specific gender forms are missing
    numeral_val_approx = 0 # Need a way to roughly know the number value if possible, maybe from numeral_word?
    if numeral_word in ["pięć", "sześć", "siedem", "osiem", "dziewięć", "dziesięć", "jedenaście", "dwanaście", "trzynaście", "czternaście", "piętnaście", "szesnaście", "siedemnaście", "osiemnaście", "dziewiętnaście", "dwadzieścia", "trzydzieści", "czterdzieści", "pięćdziesiąt", "sześćdziesiąt", "siedemdziesiąt", "osiemdziesiąt", "dziewięćdziesiąt"]:
         numeral_val_approx = 5 # Mark as 5+ for rule application
         
    if numeral_val_approx >= 5:
         common_gen_form = None
         common_dat_form = None
         common_loc_form = None
         common_inst_form = None
         
         # Find the most common form for these cases
         for g_key in genders_map.values():
             if detailed_declensions['gen'][g_key] != '-': common_gen_form = detailed_declensions['gen'][g_key]
             if detailed_declensions['dat'][g_key] != '-': common_dat_form = detailed_declensions['dat'][g_key]
             if detailed_declensions['loc'][g_key] != '-': common_loc_form = detailed_declensions['loc'][g_key]
             if detailed_declensions['inst'][g_key] != '-': common_inst_form = detailed_declensions['inst'][g_key]
             
         # Apply the common form if found
         for case_code in ['gen', 'dat', 'loc', 'inst']:
             common_form = None
             if case_code == 'gen': common_form = common_gen_form
             elif case_code == 'dat': common_form = common_dat_form
             elif case_code == 'loc': common_form = common_loc_form
             elif case_code == 'inst': common_form = common_inst_form
             
             if common_form:
                 for g_key in genders_map.values():
                     detailed_declensions[case_code][g_key] = common_form
                     
    # Special handling for 'sto' (typically neuter)
    if numeral_word == 'sto':
        for case_code in cases:
             neuter_form = detailed_declensions[case_code]['n']
             if neuter_form != '-':
                 for g_key in genders_map.values():
                     detailed_declensions[case_code][g_key] = neuter_form

    print(f"[_convert_simple] Converted data for {numeral_word}: {detailed_declensions}")
    return detailed_declensions
# --- END NEW Helper --- 

@app.route('/conjugate/<word>', methods=['GET'])
def conjugate_word(word):
    # --- 입력값 숫자 -> 단어 매핑 --- 
    original_input = word
    if word in NUMERAL_WORD_MAP:
        mapped_word = NUMERAL_WORD_MAP[word]
        print(f"[/conjugate] Input '{word}' detected, mapping to '{mapped_word}'.")
        word = mapped_word
    # ------------------------------

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
    original_input = word
    # --- Flags to indicate response format ---
    is_detailed_numeral_table = False # Flag for detailed Case x Gender table
    # -----------------------------------------

    # --- Numeral Identification --- 
    is_numeral = False
    numeral_value = None
    mapped_word = word # Default to original input
    if word.isdigit():
        try:
            num_val = int(word)
            if 1 <= num_val <= 100:
                 is_numeral = True
                 numeral_value = num_val
                 # Get the base Polish word if available (for simple numerals)
                 mapped_word = NUMERAL_WORD_MAP.get(word, word) 
                 print(f"[/decline] Input '{word}' detected as numeral {numeral_value}, mapping to '{mapped_word}'.")
            else:
                 print(f"[/decline] Input '{word}' is a numeral but outside 1-100 range.")
        except ValueError:
             print(f"[/decline] Input '{word}' looks like a numeral but failed to parse.")
             is_numeral = False # Treat as non-numeral if parsing fails
    # ---------------------------

    result_data = None
    error_message = None

    # --- Consolidated Numeral Declension Generation (1-100) --- 
    if is_numeral and numeral_value is not None:
        structured_declensions = None
        lemma_for_result = mapped_word # Use mapped word as lemma for simple, composite generates own

        # 1. Composite Numerals (21-99 excluding tens)
        if 21 <= numeral_value <= 99 and numeral_value % 10 != 0:
            print(f"[/decline] Processing composite numeral '{original_input}' for detailed table.")
            structured_declensions = _generate_composite_numeral_declensions(original_input) 
            if structured_declensions:
                 # Composite generator constructs the full word, use original input as lemma key maybe?
                 lemma_for_result = original_input 
                 is_detailed_numeral_table = True
            else:
                 error_message = f"Failed to generate composite declensions for '{original_input}'."
                 print(f"[/decline] {error_message}")
        
        # 2. Simple Numerals (1-100 handled by NUMERAL_WORD_MAP)
        elif word in NUMERAL_WORD_MAP:
             print(f"[/decline] Processing simple numeral '{original_input}' ({mapped_word}) for detailed table.")
             hardcoded_data = hardcoded_declensions.get(mapped_word)
             if hardcoded_data and "grouped_forms" in hardcoded_data and "declensionCategoryNumeral" in hardcoded_data["grouped_forms"]:
                 hardcoded_forms_list = hardcoded_data["grouped_forms"]["declensionCategoryNumeral"]
                 # --- ALWAYS Convert to detailed format --- 
                 structured_declensions = _convert_simple_numeral_to_detailed(mapped_word, hardcoded_forms_list)
                 if structured_declensions:
                      is_detailed_numeral_table = True
                 else:
                      error_message = f"Failed to convert simple numeral data for '{mapped_word}'."
                      print(f"[/decline] {error_message}")
             else:
                  error_message = f"Hardcoded data not found or invalid for simple numeral '{mapped_word}'."
                  print(f"[/decline] {error_message}")
        
        else: # Should not happen if is_numeral is true and 1<=val<=100, but as a fallback
            error_message = f"Numeral '{original_input}' is within 1-100 but not handled by specific logic."
            print(f"[/decline] {error_message}")

        # --- Construct result_data if successful --- 
        if structured_declensions and is_detailed_numeral_table:
            result_data = {
                "lemma": lemma_for_result, 
                "grouped_forms": structured_declensions,
                "is_detailed_numeral_table": True 
            }
            print(f"[/decline] Successfully generated detailed table data for '{original_input}'. Flag set to True.")
        elif error_message:
             # If detailed generation failed, we might still want to return basic info
             # For now, let it fall through to standard path OR return error?
             # Let's try falling through to standard path if detailed fails.
             print(f"[/decline] Detailed generation failed for numeral '{original_input}', will attempt standard path.")
             result_data = None # Ensure it falls through
             is_detailed_numeral_table = False # Reset flag
        else: # No structured data generated, wasn't composite or known simple
            print(f"[/decline] No specific detailed numeral logic applied or succeeded for '{original_input}', attempting standard path.")
            result_data = None # Ensure it falls through

    # --- Standard Declension (Non-numerals OR Numerals where detailed generation failed) --- 
    if result_data is None:
        target_word = mapped_word if is_numeral else word # Use mapped word if it was a numeral initially
        print(f"[/decline] Processing standard declension for: '{target_word}' (Original: '{original_input}')")
        # generate_and_format_forms returns a dict (if successful) or None
        generated_data = generate_and_format_forms(target_word, is_declinable, get_declension_category_key)

        if generated_data and isinstance(generated_data, dict):
            result_data = generated_data
            # --- Ensure the flag is FALSE for standard path results --- 
            result_data["is_detailed_numeral_table"] = False 
            print(f"[/decline] Standard path successful for '{target_word}'. Detailed flag set to False.")
            # --- REMOVED redundant conversion attempt here --- 
        else:
             print(f"[/decline] Standard declension path (generate_and_format_forms) failed for '{target_word}'.")
             # If detailed num failed AND standard failed, set error message
             if is_numeral and not error_message: 
                  error_message = f"Could not generate declension data for numeral '{original_input}' via any method."

    # --- Final Response Construction --- 
    if result_data:
         # Add translation (if available, from hardcoded) and other info
         final_lemma = result_data.get('lemma', original_input if is_numeral else word)
         translation_en = hardcoded_declensions.get(final_lemma, {}).get('translation_en')
         result_data['translation_en'] = translation_en # Add translation if found
         # Ensure the detailed flag is correctly set based on earlier logic
         result_data['is_detailed_numeral_table'] = is_detailed_numeral_table 

         print(f"[/decline] Returning successful data structure for '{original_input}'. Detailed table: {is_detailed_numeral_table}")
         return jsonify({
             "status": "success",
             "word": original_input, 
             "data": [result_data] # Wrap in a list to match expected API structure
         })
    else:
         print(f"[/decline] Failed to get any declension data for '{original_input}'. Error: {error_message}")
         return jsonify({
             "status": "error",
             "word": original_input,
             "message": error_message or f"No declension data found for '{original_input}'."
         }), 404

# --- NEW Placeholder Function for Proper Noun Declension ---
def generate_proper_noun_declensions(word, analysis_result):
    """
    Generates declensions specifically for proper nouns identified by Morfeusz.
    Uses morf.generate() based on the lemma from the analysis result.
    """
    print(f"[generate_proper_noun_declensions] Processing: {word}")
    if not analysis_result:
        print(f"[generate_proper_noun_declensions] No analysis result provided for {word}, cannot generate.")
        return None

    # Extract the lemma from the first (most likely) analysis
    # Morfeusz interpretation tuple: (start_node, end_node, (form, lemma, tag, qual1, qual2))
    try:
        lemma = analysis_result[0][2][1] # Get the lemma
        base_tag = analysis_result[0][2][2] # Get the full tag
        print(f"[generate_proper_noun_declensions] Using lemma '{lemma}' and base tag '{base_tag}' for generation.")
    except IndexError:
        print(f"[generate_proper_noun_declensions] Could not extract lemma/tag from analysis result for {word}.")
        return None

    generated_forms = []
    try:
        # Use expand_tags=True to get individual forms directly
        # Use the identified lemma for generation
        generated = morf.generate(lemma, expand_tags=True)
        print(f"[generate_proper_noun_declensions] Morf.generate returned {len(generated)} forms for lemma '{lemma}'.")

        # Filter and format the results
        for item in generated:
            # item format: (start_node, end_node, (form, lemma, tag, qual1, qual2))
            # We only need the inner tuple's components
            form_data = item[2]
            form_text = form_data[0]
            form_lemma = form_data[1]
            form_tag = form_data[2]

            # Optional: Add more filtering if needed (e.g., only subst tags if the original was subst)
            # We keep the lemma from generation to handle potential homonyms resolved during generation
            # if form_lemma == lemma: # Optional: only keep forms for the exact input lemma if needed
            generated_forms.append({"form": form_text, "tag": form_tag})

    except Exception as e:
        print(f"[generate_proper_noun_declensions] Error during morf.generate or processing for lemma '{lemma}': {e}")
        return None # Indicate failure

    if not generated_forms:
        print(f"[generate_proper_noun_declensions] No forms generated or filtered for lemma '{lemma}'.")
        return None

    # Group the forms by category key (similar to generate_and_format_forms)
    grouped = {}
    # Use the base tag from the initial analysis to determine the category
    category_key = get_declension_category_key('subst', base_tag) # Assuming proper nouns are subst

    if category_key:
        grouped[category_key] = generated_forms
        print(f"[generate_proper_noun_declensions] Grouped {len(generated_forms)} forms under key '{category_key}'.")
        return grouped
    else:
        print(f"[generate_proper_noun_declensions] Could not determine category key for base tag '{base_tag}'.")
        return None # Indicate failure if no category key found

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