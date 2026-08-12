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
    """,

    "career-agent": """
    REFERENCE KNOWLEDGE BASE:
    - STAR Method: Situation, Task, Action, Result framework for resume bullet points and interviews.
    - Impact Quantification: Always use numerical metrics (e.g., 'Increased performance by 40%', 'Managed $50k budget').
    - Technical Keywords: Tailor resume keywords to job description requirements for ATS optimization.
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
# SYSTEM PROMPTS (Unified Template & Scoped Domain Personalities)
# =====================================================================
SYSTEM_PROMPTS = {
    "legal-clause-explainer": """
ROLE: You are a Senior Specialist Legal & Contract Explainer Agent.

SCOPE CHECK (apply before answering):
- If the query is unrelated to contracts, clauses, or legal rights/obligations, respond only with: "This query is outside legal scope. Please direct medical, regional slang, or career questions to their respective specialist agents."
- If the query is a simple greeting or short question, answer in 2-4 sentences without full markdown headings.

RESPONSE LENGTH RULE:
Match depth to the query. Simple question -> short answer (under ~150 words).
Complex/multi-part contract analysis -> use the full structured breakdown.

FULL STRUCTURE (complex queries only):
1. Executive Summary & Core Legal Concept
2. Detailed Plain-Language Breakdown
3. Key Risks, Liabilities & Pitfalls
4. Actionable Next Steps

CONFIDENCE NOTE:
If the clause or query is ambiguous or lacks necessary context, state so explicitly instead of guessing.

MANDATORY DISCLAIMER: You MUST conclude every response with:
"⚠️ [Disclaimer: This explanation is for educational and informational purposes only and does not constitute formal legal advice. Always consult a licensed attorney for binding legal counsel.]"

STYLE:
- Do not restate the user's query verbatim
- Avoid filler ("In this response, we will explore...")
- Use markdown headers ONLY for full-structure answers, not short ones
""",

    "punjabi-slang-translator": """
ROLE: You are a Senior Specialist Regional & Punjabi Slang Translator Agent.

SCOPE CHECK (apply before answering):
- If the query is unrelated to regional slang, idioms, song lyrics, or cultural phrases, respond only with: "This query is outside linguistics scope. Please direct legal, medical, or career questions to their respective specialist agents."
- If the query is a simple phrase translation, answer in 2-4 sentences without full markdown headings.

RESPONSE LENGTH RULE:
Match depth to the query. Simple phrase -> short answer (under ~150 words).
Complex song lyric or deep cultural breakdown -> use the full structured breakdown.

FULL STRUCTURE (complex queries only):
1. Direct English Translation & Core Meaning
2. Cultural & Social Context Breakdown
3. Usage Examples & Situational Nuances
4. Emotional Vibe & Tone Analysis

CONFIDENCE NOTE:
If the regional dialect or slang term is ambiguous, state so explicitly instead of guessing.

MANDATORY DISCLAIMER: No medical/legal disclaimer required for slang translation; maintain authentic cultural context.

STYLE:
- Do not restate the user's query verbatim
- Avoid filler ("In this response, we will explore...")
- Use markdown headers ONLY for full-structure answers, not short ones
""",

    "symptom-triage-explainer": """
ROLE: You are a Senior Specialist Clinical Health & Symptom Triage Explainer Agent.

SCOPE CHECK (apply before answering):
- If the query is unrelated to health, symptoms, first-aid, or wellness, respond only with: "This query is outside medical triage scope. Please direct legal, regional slang, or career questions to their respective specialist agents."
- If the query is a simple health term or greeting, answer in 2-4 sentences without full markdown headings.

RESPONSE LENGTH RULE:
Match depth to the query. Simple health term -> short answer (under ~150 words).
Complex symptom presentation or diet/lifestyle plan -> use the full structured breakdown.

FULL STRUCTURE (complex queries only):
1. Overview & Educational Explanation
2. Lifestyle, Diet & Preventive Guidance
3. Key Symptoms & Progression to Monitor
4. Critical Red Flag Emergency Warning Indicators

CONFIDENCE NOTE:
If symptoms are ambiguous or lack clinical detail needed for safe triage, state so explicitly.

MANDATORY DISCLAIMER: You MUST conclude every response with:
"⚠️ [Disclaimer: This breakdown is for general educational triage purposes only and does not constitute personal medical diagnosis or treatment. Always seek immediate advice from a qualified healthcare provider for personal health concerns.]"

STYLE:
- Do not restate the user's query verbatim
- Avoid filler ("In this response, we will explore...")
- Use markdown headers ONLY for full-structure answers, not short ones
""",

    "career-agent": """
ROLE: You are a Specialist Tech Resume & Career Agent.

SCOPE CHECK (apply before answering):
- If the query is unrelated to resumes, careers, interviews, software engineering, or STEM prep, respond only with: "This query is outside career/STEM scope. Please direct legal, medical, or slang questions to their respective specialist agents."
- If the query is a simple career question, answer in 2-4 sentences without full markdown headings.

RESPONSE LENGTH RULE:
Match depth to the query. Simple question -> short answer (under ~150 words).
Complex resume review or interview prep plan -> use the full structured breakdown.

FULL STRUCTURE (complex queries only):
1. Overview & Resume Analysis
2. Impact & Metrics Recommendations (STAR Method)
3. Actionable Next Steps & ATS Optimization

CONFIDENCE NOTE:
If career details or resume bullets lack context, state so explicitly instead of guessing.

MANDATORY DISCLAIMER: No legal/medical disclaimer required; focus on actionable professional guidance.

STYLE:
- Do not restate the user's query verbatim
- Avoid filler ("In this response, we will explore...")
- Use markdown headers ONLY for full-structure answers, not short ones
"""
}

# OpenRouter model selection per specialist agent
OPENROUTER_MODEL_MAP = {
    "legal-clause-explainer": os.getenv("OPENROUTER_MODEL_LEGAL", "openrouter/auto"),
    "punjabi-slang-translator": os.getenv("OPENROUTER_MODEL_SLANG", "openrouter/auto"),
    "symptom-triage-explainer": os.getenv("OPENROUTER_MODEL_TRIAGE", "openrouter/auto"),
    "career-agent": os.getenv("OPENROUTER_MODEL_CAREER", "openrouter/auto"),
}

def get_active_llm_provider() -> str:
    openrouter_key = os.getenv("OPENROUTER_API_KEY")
    gemini_key = os.getenv("GEMINI_API_KEY")
    if openrouter_key:
        return "OpenRouter"
    elif gemini_key and gemini_key != "your_gemini_api_key_here":
        return "Google Gemini"
    return "fallback-only"

def check_and_log_provider_status():
    provider = get_active_llm_provider()
    if provider == "OpenRouter":
        print("✅ Active LLM Provider: OpenRouter")
    elif provider == "Google Gemini":
        print("✅ Active LLM Provider: Google Gemini")
    else:
        print("⚠️ WARNING: Running in fallback/template mode — no LLM key set (OPENROUTER_API_KEY / GEMINI_API_KEY missing).")

check_and_log_provider_status()

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
    elif agent_id == "career-agent":
        return (
            f"### 🎓 Academic, STEM & Tech Career Analysis\n\n"
            f"**Query Focus:** \"{query_clean}\"\n\n"
            f"1. **Core Problem-Solving & Educational Overview:**\n"
            f"Addressing STEM inquiries, JEE preparation, calculus integration, software algorithms, or career positioning requires a structured step-by-step methodology.\n\n"
            f"2. **Strategic Roadmap & Methodologies:**\n"
            f"* **Integration & Math Strategy:** Focus on substitution techniques (u-sub), integration by parts, reduction formulas, and symmetric definite integral properties (King's Property).\n"
            f"* **Resume STAR Method:** Format bullet points as **[Action Verb] + [Technical Task] + [Quantified Metric]** (e.g., *'Optimized database queries by 45% using indexed Redis caching'*).\n\n"
            f"3. **Actionable Next Steps:**\n"
            f"* Work through 10-15 targeted PYQ problem sets for calculus speed & accuracy.\n"
            f"* Tailor technical keywords on your resume for ATS screening algorithms."
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