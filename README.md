# Specialist AI Agent Marketplace & Micro-Payments Broker

[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688.svg?style=flat&logo=FastAPI&logoColor=white)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Render](https://img.shields.io/badge/Render-Deployed-46E3B7.svg?style=flat&logo=Render&logoColor=white)](https://ai-agent-marketplace-sa1v.onrender.com)
[![Google Gemini API](https://img.shields.io/badge/Google%20Gemini-v1.0+-4285F4.svg?style=flat&logo=Google&logoColor=white)](https://ai.google.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A unified platform combining a **Specialist AI Agent Directory**, **Semantic Topic Auto-Routing & Search**, **x402 Protocol Sub-Cent Micro-Payment Settlement**, and an **Autonomous Agent Execution Engine** backed by Google Gemini & OpenRouter with a cross-platform **Flutter** frontend.

---

## 🌐 Live Cloud Deployment

The backend server is live on Render:
- **Production API Endpoint**: [`https://ai-agent-marketplace-sa1v.onrender.com`](https://ai-agent-marketplace-sa1v.onrender.com)
- **Interactive Swagger Documentation**: [`https://ai-agent-marketplace-sa1v.onrender.com/docs`](https://ai-agent-marketplace-sa1v.onrender.com/docs)
- **ReDoc API Reference**: [`https://ai-agent-marketplace-sa1v.onrender.com/redoc`](https://ai-agent-marketplace-sa1v.onrender.com/redoc)

---

## 🌟 Architecture Overview

The system consists of two primary modules:

```
AI Agent Marketplace/
├── Backend/                # Python FastAPI Micro-Payments & Agent Execution Engine
│   ├── main.py             # Main FastAPI Server & Marketplace Lifecycle
│   ├── agents.py           # Gemini & OpenRouter AI Specialist Execution Engine
│   ├── payments.py         # Wallet Settlement Manager & x402 Protocol Broker
│   ├── database.py         # SQLAlchemy ORM Models & SQLite DB Setup
│   ├── schemas.py          # Pydantic Schemas & Data Contracts
│   ├── render.yaml         # Render Cloud Deployment Blueprint
│   └── test_demo.py        # End-to-End Automated Verification Test Suite
└── frontend/               # Cross-Platform Flutter Application
    ├── lib/                # Flutter UI Views, Services, and State Providers
    │   └── services/       # ApiService connected to live Render cloud backend
    ├── assets/             # Images, Icons, and Fonts
    └── README.md           # Mobile/Web Client Specific Documentation
```

---

## 🚀 Key Features

### 🤖 1. Specialist AI Agents & Topic Auto-Routing
Powered by **Google Gemini API** (`google-genai`) and **OpenRouter**, providing specialized domain-scoped AI agents with sub-cent pricing per call:

| Agent ID | Display Name | Sub-Cent Price | Scoped Capabilities |
|---|---|---|---|
| `legal-clause-explainer` | Rental & Legal Clause Explainer | `$0.005` USD | Explains legal agreement clauses in plain language with mandatory liability disclaimers. |
| `punjabi-slang-translator` | Punjabi & Regional Slang Translator | `$0.002` USD | Translates regional idioms, slang, and cultural context. |
| `symptom-triage-explainer` | Medical Symptom Triage Explainer | `$0.003` USD | Provides educational triage guidance and emergency warning indicators. |
| `career-agent` | Tech Career Resume Agent | `$0.004` USD | Evaluates tech resumes, bullet points, and role optimization. |

- **Dynamic Topic Auto-Routing**: User input queries are automatically classified via `/search` (semantic transformer/keyword match) to automatically select and invoke the most relevant specialist AI agent for that topic.

### 💳 2. x402 Micro-Payment Settlement Broker
- **Pre-funded Simulated Wallets**: Tracks user balances with 4-decimal-place precision (sub-cent micro-transactions).
- **x402 Protocol Standard Compliance**: Automatically returns `HTTP 402 Payment Required` when user balance is lower than the agent cost, including settlement protocol details.
- **Instant Settlement**: Deducts exact call fee and issues transaction logs.

### 🔍 3. Semantic Search & Agent Discovery
- Query agent capabilities using natural language keywords and categories.
- Real-time user rating and feedback collection system.

### 📱 4. Flutter Cross-Platform Frontend
- Responsive mobile & web UI built with Flutter 3.x.
- Connected directly to the live Render cloud backend (`api_service.dart`).
- Dynamic verified domain badges (`VERIFIED LEGAL`, `VERIFIED LINGUISTICS`, `VERIFIED MEDICAL`).

---

## 🛠️ Getting Started

### Prerequisites

- **Python**: 3.10 or higher
- **Flutter SDK**: 3.x or higher
- **Google Gemini API Key**: Obtainable from [Google AI Studio](https://aistudio.google.com/)

---

### Cloud Backend Deployment (Render)

The backend is configured for 1-click deployment on Render via [`render.yaml`](Backend/render.yaml):
- **Root Directory**: `Backend`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

---

### Local Backend Execution

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
   uvicorn main:app --reload --port 8000
   ```

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

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
