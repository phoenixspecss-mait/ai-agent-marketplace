# Specialist AI Agent Marketplace Backend

FastAPI micro-services backend powering the **Specialist AI Agent Marketplace**, featuring **x402 Micro-Payment Protocol settlement**, pre-funded simulated wallets, semantic directory search, ratings, topic auto-routing, and **Google Gemini API** execution engine.

---

## 🌐 Live Render Cloud Deployment

- **Production API URL**: [`https://ai-agent-marketplace-sa1v.onrender.com`](https://ai-agent-marketplace-sa1v.onrender.com)
- **Interactive Swagger Docs**: [`https://ai-agent-marketplace-sa1v.onrender.com/docs`](https://ai-agent-marketplace-sa1v.onrender.com/docs)
- **ReDoc Schema**: [`https://ai-agent-marketplace-sa1v.onrender.com/redoc`](https://ai-agent-marketplace-sa1v.onrender.com/redoc)

---

## ⚡ Quick Start (Local Setup)

### 1. Requirements
- Python 3.10+
- Virtual Environment tool (`venv`)
- Google Gemini API Key

### 2. Environment Setup
Create a `.env` file in this directory (`Backend/.env`):
```env
GEMINI_API_KEY=your_actual_google_gemini_api_key
PORT=8000
```

### 3. Install Dependencies
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Run Local Server
```bash
uvicorn main:app --reload --port 8000
```

---

## 📁 Backend File Architecture

- `main.py` - Primary FastAPI application entry point, CORS middleware, seed data generator.
- `agents.py` - Core Google Gemini & OpenRouter AI execution engine (`google-genai`), system prompts, sub-cent pricing dictionary, RAG reference docs.
- `payments.py` - `WalletManager` SQLite class supporting sub-cent balances, top-ups, x402 settlement ledger.
- `database.py` - SQLAlchemy models (`Agent`, `Transaction`), SQLite engine (`marketplace.db`).
- `schemas.py` - Pydantic models for API request/response validation.
- `render.yaml` - 1-Click Render Cloud deployment blueprint.
- `test_demo.py` - End-to-end integration test runner validating end-to-end payment & agent execution workflows.

---

## 🛠️ Automated Testing

To execute the test script and observe x402 micro-payment settlement:

```bash
python test_demo.py
```
