"""
Seed script - registers 3-4 demo agents in one go, so you don't have to
manually re-type them into Swagger every time you restart with a fresh
database.

Run this ONCE, after the server is already running:
    python seed.py

Uses the /agents/register endpoint itself (not the database directly),
so it's testing the real API path, same as your teammates will.
"""
import requests

BASE_URL = "http://127.0.0.1:8000"  # change to your local IP if teammates need it too

demo_agents = [
    {
        "name": "Rental Clause Explainer",
        "description": "Explains Indian rental agreement clauses in plain language, cites the specific clause, not legal advice",
        "category": "housing and rentals",
        "price_per_call": 0.02,
        "endpoint_or_identifier": "PLACEHOLDER-role2-legal-agent",
    },
    {
        "name": "Regional Slang Translator",
        "description": "Translates Hindi and regional Indian slang and colloquial phrases into plain English",
        "category": "translation",
        "price_per_call": 0.01,
        "endpoint_or_identifier": "PLACEHOLDER-role2-translation-agent",
    },
    {
        "name": "Symptom Info Explainer",
        "description": "Explains common symptom information in plain language, informational only, not a diagnosis",
        "category": "health-info",
        "price_per_call": 0.03,
        "endpoint_or_identifier": "PLACEHOLDER-role2-health-agent",
    },
    {
        "name": "Resume Feedback Agent",
        "description": "Gives feedback on resume wording and formatting for tech internship applications",
        "category": "career",
        "price_per_call": 0.015,
        "endpoint_or_identifier": "PLACEHOLDER-role2-career-agent",
    },
]

if __name__ == "__main__":
    for agent in demo_agents:
        resp = requests.post(f"{BASE_URL}/agents/register", json=agent)
        if resp.status_code == 200:
            created = resp.json()
            print(f"Registered: {created['name']} (id={created['id']})")
        else:
            print(f"Failed to register {agent['name']}: {resp.status_code} - {resp.text}")

    print("\nDone. Run GET /agents in /docs to confirm they're all there.")