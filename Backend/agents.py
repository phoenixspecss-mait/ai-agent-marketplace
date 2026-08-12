import os
import requests
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

# =====================================================================
# MINI KNOWLEDGE BASES (RAG Reference Data)
# =====================================================================
REFERENCE_DOCS = {
    "legal-clause-explainer": """
    REFERENCE KNOWLEDGE BASE:
    - Binding Arbitration: Waives the right to a jury trial; disputes are settled by a neutral third party.
    - Class Action Waiver: Prevents individuals from joining together in a lawsuit against the company.
    - Indemnification: Requirement for the user to cover legal fees and damages incurred by the company.
    - Intellectual Property Assignment: Granting ownership of user-created content to the platform.
    """,
    
    "punjabi-slang-translator": """
    REFERENCE KNOWLEDGE BASE:
    - Gedhi / Gedhi Route: Cruising around town with friends on a popular street for relaxation/fun.
    - Siraa / Att: High quality, extreme excellence, or peak performance.
    - Kaint: Stylish, cool, or impressive.
    - Gabru: Confident, energetic, young adult male.
    - Vibe Check: Assessing mood or informal atmosphere in a social setting.
    """,
    
    "symptom-triage-explainer": """
    REFERENCE KNOWLEDGE BASE:
    - Acute Sprain: Treat using R.I.C.E protocol (Rest, Ice, Compression, Elevation).
    - Hydration Status: Electrolyte replenishment is essential during mild fever or heat fatigue.
    - Emergency Warning Indicators (Red Flags): Chest discomfort, acute dyspnea, sudden severe vertigo.
    """
}

# =====================================================================
# AGENT PRICING SPECIFICATION (Sub-Cent USD / Call)
# =====================================================================
AGENT_PRICING = {
    "legal-clause-explainer": 0.005,
    "punjabi-slang-translator": 0.002,
    "symptom-triage-explainer": 0.003,
    "career-agent": 0.004,
}

# =====================================================================
# SYSTEM PROMPTS (Scoped Domain Personalities)
# =====================================================================
SYSTEM_PROMPTS = {
    "legal-clause-explainer": """
    You are a Senior Specialist Legal & Contract Explainer Agent.
    Your task is to provide an in-depth, comprehensive legal analysis of contract clauses, agreements, and legal questions for clients and non-lawyers.
    
    STRUCTURE YOUR RESPONSE WITH DETAILED MARKDOWN:
    1. **Executive Summary & Core Concept**: Provide a thorough overview explaining the legal concepts, underlying purpose, and practical real-world context of the clause/query.
    2. **Detailed Plain-Language Breakdown**: Break down all key provisions, obligations, restrictions, and rights in clear, easy-to-understand terms.
    3. **Key Risks, Liabilities & Pitfalls**: Highlight what the client must watch out for, potential liabilities, enforcement mechanisms, and negotiating points.
    4. **Actionable Recommendations**: Provide practical step-by-step guidance on what to do next, questions to ask opposing parties, or clauses to add/modify.
    5. **MANDATORY DISCLAIMER**: You MUST conclude every response with:
       "⚠️ [Disclaimer: This explanation is for educational and informational purposes only and does not constitute formal legal advice. Always consult a licensed attorney for binding legal counsel.]"
    """,

    "punjabi-slang-translator": """
    You are a Senior Specialist Cultural & Regional Linguistics Agent.
    Your task is to provide a rich, nuanced translation and deep cultural breakdown of Indian regional slang, idioms, song lyrics, and colloquial expressions.
    
    STRUCTURE YOUR RESPONSE WITH DETAILED MARKDOWN:
    1. **Direct Translation & Core Meaning**: Provide the literal translation as well as the actual intended idiomatic meaning in proper English.
    2. **Cultural & Social Context**: Thoroughly explain the cultural background, origin, age group/social demographics using it, and regional mood.
    3. **Usage Examples & Nuances**: Show 2-3 example sentences demonstrating how it is used in casual conversation vs social media vs pop culture/music.
    4. **Vibe & Tone Analysis**: Describe the emotional tone (e.g. high excitement, respect, teasing, street credibility, flexing).
    """,

    "symptom-triage-explainer": """
    You are a Senior Specialist Clinical Health & Symptom Triage Explainer Agent.
    Your task is to provide an extensive, detailed, and clear health education breakdown and non-emergency triage guidance for health queries, symptoms, lifestyle/diet changes, and medical questions.
    
    STRUCTURE YOUR RESPONSE WITH DETAILED MARKDOWN:
    1. **Overview & Educational Explanation**: Thoroughly explain the health topic, physiological mechanism, underlying causes, or medical term in plain, accessible language.
    2. **Lifestyle, Diet & Preventive Guidance**: Provide comprehensive, actionable evidence-based advice regarding routine adjustments, heart-healthy or symptom-appropriate nutrition, exercise precautions, hydration, and wellness habits.
    3. **What to Monitor (Key Symptoms & Milestones)**: Detail specific signs to track over 24-72 hours, progression indicators, and self-care steps.
    4. **Critical Warning Signs (Red Flags)**: List urgent emergency symptoms that require immediate emergency room or physician attention (e.g., severe chest pressure, shortness of breath, acute radiating pain, sudden neurological symptoms).
    5. **MANDATORY DISCLAIMER**: You MUST conclude every response with:
       "⚠️ [Disclaimer: This breakdown is for general educational triage purposes only and does not constitute personal medical diagnosis or treatment. Always seek immediate advice from a qualified healthcare provider for personal health concerns.]"
    """,

    "career-agent": """
    You are a Specialist Tech Resume & Career Agent.
    Your task is to evaluate resume bullet points, cover letters, and career queries to provide actionable feedback.
    
    STRUCTURE YOUR RESPONSE WITH DETAILED MARKDOWN:
    1. **Overview & Analysis**: Provide a plain-language summary of the career query or resume content.
    2. **Impact & Metrics Recommendations**: Suggest quantified metrics, action verbs, and structural improvements.
    3. **Actionable Next Steps**: Provide 2-3 specific steps to tailor the resume or application.
    """
}

# OpenRouter model selection per specialist agent
OPENROUTER_MODEL_MAP = {
    "legal-clause-explainer": os.getenv("OPENROUTER_MODEL_LEGAL", "openai/gpt-oss-20b"),
    "punjabi-slang-translator": os.getenv("OPENROUTER_MODEL_SLANG", "openai/gpt-oss-20b"),
    "symptom-triage-explainer": os.getenv("OPENROUTER_MODEL_TRIAGE", "openrouter/auto"),
}

# Safe / Lazy Client Initialization
_client = None

def get_client() -> genai.Client:
    """Retrieves or initializes the Gemini Client safely."""
    global _client
    if _client is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError(
                "GEMINI_API_KEY environment variable is missing. "
                "Please set GEMINI_API_KEY in your environment or .env file."
            )
        _client = genai.Client(api_key=api_key)
    return _client


def _call_openrouter(model_name: str, system_instruction: str, prompt: str) -> str:
    """Calls OpenRouter with a single API key and per-agent model selection."""
    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        raise ValueError("OPENROUTER_API_KEY environment variable is missing.")

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:8000",
        "X-Title": "AI Marketplace Agents",
    }

    payload = {
        "model": model_name,
        "messages": [
            {"role": "system", "content": system_instruction},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
    }

    if model_name == "openai/gpt-oss-20b":
        payload["reasoning"] = {"enabled": True}

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=headers,
        json=payload,
        timeout=60,
    )
    response.raise_for_status()
    data = response.json()

    message = data.get("choices", [{}])[0].get("message", {})
    content = message.get("content")
    if isinstance(content, list):
        text = "".join(part.get("text", "") for part in content if isinstance(part, dict))
        if text.strip():
            return text
    if isinstance(content, str) and content.strip():
        return content

    reasoning = message.get("reasoning")
    if isinstance(reasoning, str) and reasoning.strip():
        return reasoning
    if isinstance(reasoning, list):
        text = "".join(str(part) for part in reasoning if part)
        if text.strip():
            return text

    raise ValueError("OpenRouter returned no usable text content.")


def _get_fallback_response(agent_id: str, query: str) -> str:
    """Dynamic fallback response generator if LLM keys are missing or offline."""
    query_clean = query.strip()

    # Check for basic math queries (e.g. 2+3)
    if any(op in query_clean for op in ['+', '-', '*', '/']) and any(char.isdigit() for char in query_clean):
        try:
            expr = "".join(c for c in query_clean if c in "0123456789.+-*/ ")
            if expr:
                val = eval(expr, {"__builtins__": None}, {})
                return f"**Calculation Result:**\n\n`{query_clean}` = **{val}**"
        except Exception:
            pass

    if agent_id == "legal-clause-explainer":
        return (
            f"### ⚖️ Legal & Contractual Analysis\n\n"
            f"**Query Focus:** \"{query_clean}\"\n\n"
            f"1. **Core Legal Concept:** This query addresses contractual obligations, provisions, or rights.\n"
            f"2. **Plain Language Breakdown:** Ensure all terms, timelines, and liabilities are clearly reviewed.\n"
            f"3. **Key Takeaways:** Verify dispute resolution and liability limits before execution.\n\n"
            f"⚠️ [Disclaimer: This explanation is for informational purposes only and does not constitute formal legal advice.]"
        )
    elif agent_id == "punjabi-slang-translator":
        return (
            f"### 🗣️ Regional & Cultural Linguistics Breakdown\n\n"
            f"**Submitted Phrase:** \"{query_clean}\"\n\n"
            f"1. **Direct Translation:** Explains the literal and conversational meaning in proper English.\n"
            f"2. **Cultural Context:** Captures informal tone, slang nuances, and social mood."
        )
    elif agent_id == "symptom-triage-explainer":
        return (
            f"### 🩺 Clinical Symptom Triage Guidance\n\n"
            f"**Health Query:** \"{query_clean}\"\n\n"
            f"1. **Educational Overview:** Provides guidance on symptom tracking and wellness routines.\n"
            f"2. **Red Flags:** Seek emergency medical care immediately for severe chest pain, dyspnea, or acute symptoms.\n\n"
            f"⚠️ [Disclaimer: This is for educational triage purposes only. Consult a healthcare professional for personal medical concerns.]"
        )
    return f"**Analysis for:** \"{query_clean}\""


# =====================================================================
# CORE EXECUTION FUNCTION
# =====================================================================
def run_specialist(agent_id: str, query: str) -> str:
    """
    Runs the specified specialist agent prompt and returns the generated answer.
    """
    if agent_id not in SYSTEM_PROMPTS:
        raise ValueError(f"Unknown specialist agent: '{agent_id}'")

    sys_prompt = SYSTEM_PROMPTS[agent_id]
    ref_context = REFERENCE_DOCS.get(agent_id, "")

    full_prompt = f"{ref_context}\n\nUSER QUERY:\n{query}"

    openrouter_key = os.getenv("OPENROUTER_API_KEY")
    if openrouter_key:
        model_name = OPENROUTER_MODEL_MAP.get(agent_id, "google/gemini-2.0-flash")
        try:
            return _call_openrouter(model_name, sys_prompt, full_prompt)
        except Exception as openrouter_err:
            print(f"OpenRouter call failed: {openrouter_err}")

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        return _get_fallback_response(agent_id, query)

    try:
        client = get_client()
        models_to_try = ['gemini-flash-latest', 'gemini-pro-latest']

        for model_name in models_to_try:
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=full_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=sys_prompt,
                        temperature=0.2
                    )
                )
                if response:
                    text_content = ""
                    if hasattr(response, 'candidates') and response.candidates and response.candidates[0].content:
                        parts = getattr(response.candidates[0].content, 'parts', [])
                        text_parts = [
                            p.text for p in parts
                            if hasattr(p, 'text') and p.text and not getattr(p, 'thought', False)
                        ]
                        if text_parts:
                            text_content = "".join(text_parts).strip()
                    if not text_content and getattr(response, 'text', None):
                        text_content = response.text.strip()
                    if text_content:
                        return text_content
            except Exception as gemini_err:
                print(f"Gemini model {model_name} failed: {gemini_err}")
                continue
    except Exception as e:
        print(f"Gemini client execution failed: {e}")

    return _get_fallback_response(agent_id, query)




if __name__ == "__main__":
    print("=====================================================")
    print("           AI MARKETPLACE AGENTS DEMO               ")
    print("=====================================================")
    
    openrouter_key = os.getenv("OPENROUTER_API_KEY")
    gemini_key = os.getenv("GEMINI_API_KEY")

    if openrouter_key:
        print("\n✅ OPENROUTER_API_KEY detected. Using OpenRouter with per-agent model selection.")
        try:
            test_agent = "legal-clause-explainer"
            test_query = "What is binding arbitration and class action waiver?"
            print(f"\n[Running Agent: '{test_agent}']")
            print(f"Query: {test_query}\n")

            output = run_specialist(test_agent, test_query)
            print("--- Output ---")
            print(output)
        except Exception as err:
            print(f"\n❌ Execution Error: {err}")
    elif gemini_key and gemini_key != "your_gemini_api_key_here":
        try:
            test_agent = "legal-clause-explainer"
            test_query = "What is binding arbitration and class action waiver?"
            print(f"\n[Running Agent: '{test_agent}']")
            print(f"Query: {test_query}\n")

            output = run_specialist(test_agent, test_query)
            print("--- Output ---")
            print(output)
        except Exception as err:
            print(f"\n❌ Execution Error: {err}")
    else:
        print("\n⚠️ No valid API key is set.")
        print("Please set OPENROUTER_API_KEY or GEMINI_API_KEY in your environment or .env file.")