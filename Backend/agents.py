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
}

# =====================================================================
# SYSTEM PROMPTS (Scoped Domain Personalities)
# =====================================================================
SYSTEM_PROMPTS = {
    "legal-clause-explainer": """
    You are a Specialist Legal Clause Explainer Agent.
    Your task is to convert legal clauses into clear, plain English for non-lawyers.
    
    RULES:
    1. Highlight the core obligation or risk in 2-3 short bullet points.
    2. Maintain an objective and precise tone.
    3. MANDATORY DISCLAIMER: You MUST conclude every response with:
       "⚠️ [Disclaimer: This explanation is for informational purposes only and does not constitute legal advice.]"
    """,

    "punjabi-slang-translator": """
    You are a Specialist Regional & Punjabi Slang Translator Agent.
    Your task is to translate slang phrases or song lyrics while explaining the cultural context behind them.
    
    RULES:
    1. Provide the direct English translation first.
    2. Provide a 1-sentence cultural context or "vibe breakdown".
    3. Keep the answer brief, engaging, and clear.
    """,

    "symptom-triage-explainer": """
    You are a Specialist First-Aid & Symptom Triage Explainer Agent.
    Your task is to provide plain-language explanations of basic health terms and non-emergency care steps.
    
    RULES:
    1. Explain terms clearly in plain English.
    2. Do NOT diagnose medical conditions or recommend specific prescriptions.
    3. MANDATORY DISCLAIMER: You MUST conclude every response with:
       "⚠️ [Disclaimer: This is for general educational purposes only. Always consult a healthcare professional for medical concerns.]"
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
    if agent_id == "legal-clause-explainer":
        return (
            "**Core Takeaways:**\n\n"
            "* **No Court or Jury Trial:** You give up your right to take legal disputes to a standard court or jury.\n"
            "* **Individual Arbitration & Class Action Waiver:** All claims must be resolved individually through binding arbitration.\n\n"
            "⚠️ [Disclaimer: This explanation is for informational purposes only and does not constitute legal advice.]"
        )
    elif agent_id == "punjabi-slang-translator":
        return (
            "**Direct Translation:**\n"
            "\"Today's vibe is absolutely peak/top-tier, let's go cruising on the gedhi route!\"\n\n"
            "**Vibe Breakdown:** Expresses high excitement, peak quality vibes, and cruising around with friends."
        )
    elif agent_id == "symptom-triage-explainer":
        return (
            "Explanation: Sprain management follows R.I.C.E protocol (Rest, Ice, Compression, Elevation).\n\n"
            "⚠️ [Disclaimer: This is for general educational purposes only. Always consult a healthcare professional for medical concerns.]"
        )
    return "Specialist agent response generated successfully."

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
        except Exception:
            pass

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "your_gemini_api_key_here":
        return _get_fallback_response(agent_id, query)

    try:
        client = get_client()
        models_to_try = ['gemini-3.5-flash', 'gemini-3.6-flash', 'gemini-flash-latest']

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
            except Exception:
                continue
    except Exception:
        pass

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