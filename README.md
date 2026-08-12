# Specialist AI Agent Marketplace & Micro-Payments Broker

[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688.svg?style=flat&logo=FastAPI&logoColor=white)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB.svg?style=flat&logo=Python&logoColor=white)](https://www.python.org/)
[![Google Gemini API](https://img.shields.io/badge/Google%20Gemini-v1.0+-4285F4.svg?style=flat&logo=Google&logoColor=white)](https://ai.google.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A unified platform combining a **Specialist AI Agent Directory**, **Semantic Search & Discovery**, **x402 Protocol Sub-Cent Micro-Payment Settlement**, and an **Autonomous Agent Execution Engine** backed by Google Gemini and a cross-platform **Flutter** frontend.

---

## 🌟 Architecture Overview

The system consists of two primary modules:

```
AI Agent Marketplace/
├── Backend/                # Python FastAPI Micro-Payments & Agent Execution Engine
│   ├── main.py             # Main FastAPI Server & Marketplace Lifecycle
│   ├── agents.py           # Gemini AI Specialist Agents & Prompt Scoping
│   ├── payments.py         # Wallet Settlement Manager & x402 Protocol Broker
│   ├── database.py         # SQLAlchemy ORM Models & SQLite DB Setup
│   ├── schemas.py          # Pydantic Schemas & Data Contracts
│   ├── agent_routes.py     # Endpoint Handlers & Micro-Payment Enforcers
│   └── test_demo.py        # End-to-End Automated Verification Test Suite
└── frontend/               # Cross-Platform Flutter Application
    ├── lib/                # Flutter UI Views, Services, and State Providers
    ├── assets/             # Images, Icons, and Fonts
    └── README.md           # Mobile/Web Client Specific Documentation
```

---

## 🚀 Key Features

### 🤖 1. Specialist AI Agents Engine
Powered by **Google Gemini API** (`google-genai`), providing specialized domain-scoped AI agents with sub-cent pricing per call:

| Agent ID | Display Name | Sub-Cent Price | Scoped Capabilities |
|---|---|---|---|
| `legal-clause-explainer` | Rental & Legal Clause Explainer | `$0.005` USD | Explains complex legal terms in plain English with mandatory liability disclaimers. |
| `punjabi-slang-translator` | Punjabi & Regional Slang Translator | `$0.002` USD | Translates regional idioms, slang, and cultural context. |
| `symptom-triage-explainer` | Medical Symptom Triage Explainer | `$0.003` USD | Provides educational triage guidance and emergency warning indicators. |
| `career-agent` | Tech Career Resume Agent | `$0.004` USD | Evaluates tech resumes, bullet points, and role optimization. |

### 💳 2. x402 Micro-Payment Settlement Broker
- **Pre-funded Simulated Wallets**: Tracks user balances with 4-decimal-place precision (sub-cent micro-transactions).
- **x402 Protocol Standard Compliance**: Automatically returns `HTTP 402 Payment Required` when user balance is lower than the agent cost, including settlement protocol details in response headers/body.
- **Instant Settlement**: Deducts exact call fee and issues unique cryptographic transaction settlement hashes.
- **Auto-Seeding**: Automatically seeds new demo users with a `$5.00` USD starter balance.

### 🔍 3. Semantic Search & Agent Discovery
- Query agent capabilities using keywords and categories.
- Real-time user rating and feedback collection system.

### 📱 4. Flutter Cross-Platform Frontend
- Responsive mobile & web UI built with Flutter 3.x.
- Firebase integration for authentication, realtime database, and storage.
- Agent browsing catalog, wallet balance manager, and agent interactive view.

---

## 🛠️ Getting Started

### Prerequisites

- **Python**: 3.10 or higher
- **Flutter SDK**: 3.x or higher (for frontend development)
- **Google Gemini API Key**: Obtainable from [Google AI Studio](https://aistudio.google.com/)

---

### Backend Setup & Execution

1. **Navigate to the Backend Directory**:
   ```bash
   cd Backend
   ```

2. **Create and Activate Virtual Environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables**:
   Create a `.env` file in the `Backend` directory:
   ```env
   GEMINI_API_KEY=your_google_gemini_api_key_here
   PORT=8000
   ```

5. **Start the FastAPI Server**:
   ```bash
   python main.py
   ```
   *Alternatively, run with Uvicorn:*
   ```bash
   uvicorn main:app --reload --port 8000
   ```

6. **Access Interactive API Docs**:
   - Swagger UI: `http://localhost:8000/docs`
   - Redoc: `http://localhost:8000/redoc`

---

### Frontend Setup & Execution

1. **Navigate to Frontend Directory**:
   ```bash
   cd frontend
   ```

2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Application**:
   ```bash
   flutter run
   ```
   *(Add `-d chrome` for web, or specify connected mobile device ID)*

---

## 📡 API Reference

### Core Endpoints

#### `GET /api/marketplace/agents`
Returns a list of all registered specialist agents in the directory.

#### `POST /api/marketplace/search`
Search agents by text query or category.
```json
{
  "query": "explain legal lease clause",
  "category": "legal-clause-explainer"
}
```

#### `POST /api/marketplace/agents/{agent_id}/call`
Executes an AI agent call with x402 payment settlement.
- **Request Body**:
  ```json
  {
    "user_id": "demo_user_01",
    "query": "What does a binding arbitration clause mean?"
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "status": "success",
    "agent_id": "legal-clause-explainer",
    "cost_usd": 0.005,
    "remaining_balance_usd": 4.995,
    "response": "Core terms explained...",
    "settlement_hash": "tx_a1b2c3d4..."
  }
  ```
- **Insufficient Funds Response (`402 Payment Required`)**:
  ```json
  {
    "status": "error",
    "error": "Payment Required",
    "message": "Insufficient wallet balance ($0.0010 USD). Call cost is $0.0050 USD.",
    "x402_protocol": {
      "status": 402,
      "topup_endpoint": "/api/marketplace/wallet/topup"
    }
  }
  ```

#### `POST /api/marketplace/wallet/topup`
Fund user wallet balance.
```json
{
  "user_id": "demo_user_01",
  "amount": 5.00
}
```

#### `GET /api/marketplace/wallet/{user_id}/balance`
Retrieve current USD wallet balance for specified user.

---

## 🧪 Testing & Automated Demonstration

Run the automated test suite to verify wallet settlement, agent calls, x402 protocol enforcement, and top-up flows:

```bash
cd Backend
python test_demo.py
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
