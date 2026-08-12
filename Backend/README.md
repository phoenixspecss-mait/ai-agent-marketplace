# Specialist AI Agent Marketplace Backend

FastAPI micro-services backend powering the **Specialist AI Agent Marketplace**, featuring **x402 Micro-Payment Protocol settlement**, pre-funded simulated wallets, semantic directory search, ratings, and **Google Gemini API** execution engine.

---

## ⚡ Quick Start

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

### 4. Run Server
```bash
python main.py
```
Or with auto-reload:
```bash
uvicorn main:app --reload --port 8000
```

---

## 📁 Backend File Architecture

- `main.py` - Primary FastAPI application entry point, CORS middleware, seed data generator.
- `agents.py` - Core Google Gemini AI execution engine (`google-genai`), system prompts, sub-cent pricing dictionary, RAG reference docs.
- `payments.py` - `WalletManager` SQLite class supporting sub-cent balances, top-ups, x402 settlement ledger.
- `database.py` - SQLAlchemy models (`Agent`, `Transaction`), SQLite engine (`marketplace.db`).
- `schemas.py` - Pydantic models for API request/response validation.
- `agent_routes.py` - Modular API handlers for agent calls & wallet actions.
- `test_demo.py` - End-to-end integration test runner validating end-to-end payment & agent execution workflows.

---

## 🛠️ Automated Testing

To execute the test script and observe x402 micro-payment settlement:

```bash
python test_demo.py
```

---

## 📖 API Documentation

Once the server is running, visit:
- **Swagger Interactive Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc Schema**: [http://localhost:8000/redoc](http://localhost:8000/redoc)
