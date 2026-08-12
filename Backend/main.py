"""
Specialist AI Agent Marketplace - Complete Unified Server
Combines Agent Directory, Semantic Search, Ratings, Wallet Micro-Payments (x402 protocol), and Specialist AI Agent Execution Engine.

Run with:
    cd Backend
    python main.py
OR:
    uvicorn main:app --reload --port 8000
"""
import sys
import os
import re
from typing import List, Dict, Any, Optional

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

# Add subdirectory to sys.path to easily load database & schemas
MARKETPLACE_DIR = os.path.join(os.path.dirname(__file__), "ai-agent-marketplace-main")
if MARKETPLACE_DIR not in sys.path:
    sys.path.append(MARKETPLACE_DIR)

from database import init_db, get_db, Agent, Transaction
from schemas import (
    AgentRegister, AgentOut, RatingSubmit,
    SearchQuery, SearchResult, TransactionLog
)

from agents import run_specialist, AGENT_PRICING, SYSTEM_PROMPTS
from payments import wallet_manager

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    seed_demo_data()
    yield

app = FastAPI(
    title="Specialist AI Agent Marketplace & Micro-Payments Broker",
    description="Unified Directory, Semantic Matching, x402 Micro-Payment Settlement, and AI Execution Engine",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS Configuration for Flutter Frontend & Web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def seed_demo_data():
    db = next(get_db())
    try:
        if db.query(Agent).count() == 0:
            demo_agents = [
                Agent(
                    name="Rental Clause Explainer",
                    description="Explains legal lease agreement clauses in plain language with fair wear & tear advice.",
                    category="legal-clause-explainer",
                    price_per_call=0.005,
                    endpoint_or_identifier="legal-clause-explainer",
                ),
                Agent(
                    name="Punjabi & Regional Slang Translator",
                    description="Translates Indian regional slang, idioms, and colloquial expressions with cultural mood context.",
                    category="punjabi-slang-translator",
                    price_per_call=0.002,
                    endpoint_or_identifier="punjabi-slang-translator",
                ),
                Agent(
                    name="Symptom Triage Explainer",
                    description="Provides general educational triage explanation for medical symptoms.",
                    category="symptom-triage-explainer",
                    price_per_call=0.003,
                    endpoint_or_identifier="symptom-triage-explainer",
                ),
                Agent(
                    name="Tech Career Resume Agent",
                    description="Evaluates resume bullet points and formatting for tech role applications.",
                    category="career-agent",
                    price_per_call=0.004,
                    endpoint_or_identifier="career-agent",
                ),
            ]
            db.add_all(demo_agents)
            db.commit()
            print("Successfully seeded demo agents into database.")
    except Exception as e:
        print(f"Seed error: {e}")

# ---------------------------------------------------------------------------
# Health & Status Endpoints
# ---------------------------------------------------------------------------
@app.get("/")
def read_root():
    return {
        "service": "Specialist AI Agent Marketplace & Micro-Payments Broker",
        "status": "operational",
        "available_agents": list(SYSTEM_PROMPTS.keys()),
        "endpoints": [
            "/agents", "/search", "/api/marketplace/call",
            "/api/marketplace/wallet/balance", "/api/marketplace/wallet/topup"
        ]
    }

@app.get("/health")
def health():
    return {"status": "ok"}

# ---------------------------------------------------------------------------
# Step 3: Agent Directory & CRUD (from ai-agent-marketplace-main)
# ---------------------------------------------------------------------------
@app.post("/agents/register", response_model=AgentOut)
def register_agent(agent: AgentRegister, db: Session = Depends(get_db)):
    """Add a new specialist agent to the directory."""
    db_agent = Agent(
        name=agent.name,
        description=agent.description,
        category=agent.category,
        price_per_call=agent.price_per_call,
        endpoint_or_identifier=agent.endpoint_or_identifier,
    )
    db.add(db_agent)
    db.commit()
    db.refresh(db_agent)
    return db_agent

@app.get("/agents", response_model=List[AgentOut])
def list_agents(category: Optional[str] = None, db: Session = Depends(get_db)):
    """List all registered agents, optionally filtered by category."""
    query = db.query(Agent)
    if category:
        query = query.filter(Agent.category == category)
    return query.all()

@app.get("/agents/{agent_id}", response_model=AgentOut)
def get_agent(agent_id: int, db: Session = Depends(get_db)):
    agent = db.query(Agent).filter(Agent.id == agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    return agent

@app.post("/agents/{agent_id}/rate", response_model=AgentOut)
def rate_agent(agent_id: int, rating: RatingSubmit, db: Session = Depends(get_db)):
    """Submit a 1-5 star rating for an agent."""
    agent = db.query(Agent).filter(Agent.id == agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")

    # SQLAlchemy instrumented attributes trigger static type-checker complaints
    # when using augmented assignment on mapped columns, so update via setattr.
    setattr(agent, "rating_sum", getattr(agent, "rating_sum") + rating.stars)
    setattr(agent, "rating_count", getattr(agent, "rating_count") + 1)

    db.commit()
    db.refresh(agent)
    return agent

# ---------------------------------------------------------------------------
# Step 4: Semantic Keyword / Matching Search
# ---------------------------------------------------------------------------
def _tokenize(text: str) -> set:
    return set(re.findall(r"[a-z0-9]+", text.lower()))

def _keyword_score(query: str, agent: Agent) -> float:
    query_tokens = _tokenize(query)
    if not query_tokens:
        return 0.0
    agent_text = f"{agent.name} {agent.description} {agent.category or ''}"
    agent_tokens = _tokenize(agent_text)
    overlap = query_tokens & agent_tokens
    return len(overlap) / len(query_tokens)

@app.post("/search", response_model=List[SearchResult])
def search_agents(search: SearchQuery, db: Session = Depends(get_db)):
    """Match natural language queries to top matching specialist agents."""
    agents = db.query(Agent).all()
    if not agents:
        return []

    scored = [
        SearchResult(agent=AgentOut.model_validate(a), match_score=round(_keyword_score(search.query, a), 3))
        for a in agents
    ]
    scored = [s for s in scored if s.match_score > 0]
    scored.sort(key=lambda s: (s.match_score, s.agent.rating_avg or 0), reverse=True)
    if not scored:
        # Fallback to returning all agents ranked by rating if no direct keyword match
        scored = [
            SearchResult(agent=AgentOut.model_validate(a), match_score=0.5)
            for a in agents
        ]
    return scored[: search.top_k]

# ---------------------------------------------------------------------------
# Transaction Logging
# ---------------------------------------------------------------------------
@app.post("/transactions/log")
def log_transaction(txn: TransactionLog, db: Session = Depends(get_db)):
    db_txn = Transaction(agent_id=txn.agent_id, amount=txn.amount, query_text=txn.query_text)
    db.add(db_txn)
    db.commit()
    return {"status": "logged", "agent_id": txn.agent_id, "amount": txn.amount}

@app.get("/transactions")
def list_transactions(db: Session = Depends(get_db)):
    return db.query(Transaction).all()

# ---------------------------------------------------------------------------
# x402 Payment & Specialist Execution Broker
# ---------------------------------------------------------------------------
class TopUpRequest(BaseModel):
    user_id: str = Field(..., json_schema_extra={"example": "demo_user_01"})
    amount: float = Field(..., gt=0.0, json_schema_extra={"example": 1.00})

class AgentCallRequest(BaseModel):
    user_id: str = Field(..., json_schema_extra={"example": "demo_user_01"})
    agent_id: str = Field(..., json_schema_extra={"example": "legal-clause-explainer"})
    query: str = Field(..., json_schema_extra={"example": "Explain what a class action waiver means."})

@app.get("/api/marketplace/wallet/balance")
def get_wallet_balance(user_id: str):
    """Retrieves current wallet balance in USD."""
    balance = wallet_manager.get_balance(user_id)
    return {"user_id": user_id, "balance_usd": balance}

@app.post("/api/marketplace/wallet/topup")
def topup_wallet(req: TopUpRequest):
    """Adds USD funds to user wallet."""
    try:
        new_balance = wallet_manager.top_up(req.user_id, req.amount)
        return {
            "status": "success",
            "user_id": req.user_id,
            "amount_added_usd": req.amount,
            "new_balance_usd": new_balance
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@app.post("/api/marketplace/call")
def call_agent(req: AgentCallRequest, db: Session = Depends(get_db)):
    """
    Executes a Specialist AI Agent query with sub-cent micro-payment settlement (x402 protocol).
    """
    # Normalize agent_id
    agent_key = req.agent_id
    if agent_key not in SYSTEM_PROMPTS:
        # Fallback mapping
        if "slang" in agent_key:
            agent_key = "punjabi-slang-translator"
        elif "symptom" in agent_key or "health" in agent_key:
            agent_key = "symptom-triage-explainer"
        else:
            agent_key = "legal-clause-explainer"

    agent_cost = AGENT_PRICING.get(agent_key, 0.005)
    current_balance = wallet_manager.get_balance(req.user_id)

    # Balance check (x402 402 Payment Required)
    if current_balance < agent_cost:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail={
                "status": "error",
                "error": "Payment Required",
                "message": f"Insufficient balance (${current_balance:.4f} USD). Cost is ${agent_cost:.4f} USD.",
                "user_id": req.user_id,
                "agent_id": req.agent_id,
                "cost_usd": agent_cost,
                "current_balance_usd": current_balance,
            }
        )

    # Deduct Micro-Payment
    success, settlement_msg, remaining_balance = wallet_manager.deduct_payment(
        req.user_id, req.agent_id, agent_cost
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=settlement_msg
        )

    # Invoke Agent LLM execution engine
    try:
        result = run_specialist(agent_key, req.query)
        # Log transaction in database
        try:
            db_txn = Transaction(agent_id=1, amount=agent_cost, query_text=req.query)
            db.add(db_txn)
            db.commit()
        except Exception:
            pass

        return {
            "status": "success",
            "agent_id": req.agent_id,
            "cost_usd": agent_cost,
            "payment_settlement": settlement_msg,
            "remaining_balance_usd": remaining_balance,
            "result": result
        }
    except Exception as err:
        # Refund payment on failure
        wallet_manager.top_up(req.user_id, agent_cost)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Agent execution error: {str(err)}. Cost refunded."
        )

if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "8000"))
    reload_enabled = os.getenv("UVICORN_RELOAD", "0").lower() in {"1", "true", "yes", "on"}
    print(f"Starting server on http://127.0.0.1:{port} (reload={reload_enabled})")
    uvicorn.run("main:app", host="127.0.0.1", port=port, reload=reload_enabled)
