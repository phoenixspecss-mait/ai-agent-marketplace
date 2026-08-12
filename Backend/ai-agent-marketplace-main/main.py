"""
Specialist AI Agent Marketplace - Backend (Role 1)

Run with:
    uvicorn main:app --reload

Then open http://127.0.0.1:8000/docs for the interactive Swagger UI -
use that to test every endpoint without needing a frontend yet.
"""
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import re

from database import init_db, get_db, Agent, Transaction
from schemas import (
    AgentRegister, AgentOut, RatingSubmit,
    SearchQuery, SearchResult, TransactionLog
)

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(title="Specialist AI Agent Marketplace - Directory Service", lifespan=lifespan)


@app.get("/health")
def health():
    return {"status": "ok"}


# ---------------------------------------------------------------------------
# Step 3: Agent registration + CRUD
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
    """Submit a 1-5 star rating, updates the running average."""
    agent = db.query(Agent).filter(Agent.id == agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    agent.rating_sum += rating.stars
    agent.rating_count += 1
    db.commit()
    db.refresh(agent)
    return agent


# ---------------------------------------------------------------------------
# Step 4: Search / matching
#
# Starts as the dumbest possible version - keyword overlap between the
# query and each agent's name/description/category. Get this working
# end-to-end first. Only upgrade to sentence-transformers embeddings
# (see the commented block below) if there's time left.
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
    """
    Find the best-matching specialist agent(s) for a natural-language query.
    Returns top_k agents ranked by match score (embedding similarity, 0-1).
    """
    agents = db.query(Agent).all()
    if not agents:
        return []

    scored = [
        SearchResult(agent=AgentOut.model_validate(a), match_score=round(_embedding_score(search.query, a), 3))
        for a in agents
    ]
    scored = [s for s in scored if s.match_score > 0]
    scored.sort(key=lambda s: (s.match_score, s.agent.rating_avg or 0), reverse=True)
    return scored[: search.top_k]


try:
    from sentence_transformers import SentenceTransformer, util
    model = SentenceTransformer("all-MiniLM-L6-v2")
    def _embedding_score(query: str, agent: Agent) -> float:
        agent_text = f"{agent.name}. {agent.description}"
        emb1 = model.encode(query, convert_to_tensor=True)
        emb2 = model.encode(agent_text, convert_to_tensor=True)
        return float(util.cos_sim(emb1, emb2)[0][0])
except ImportError:
    def _embedding_score(query: str, agent: Agent) -> float:
        return _keyword_score(query, agent)

# Swap `_keyword_score` for `_embedding_score` in `search_agents` once this
# is wired in - the endpoint's request/response shape stays identical, so
# Role 2 and Role 3 don't need to change anything on their end.
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Transaction logging - Role 2 calls this after a payment settles via x402,
# so the directory has a record of what was actually paid and to whom.
# ---------------------------------------------------------------------------

@app.post("/transactions/log")
def log_transaction(txn: TransactionLog, db: Session = Depends(get_db)):
    agent = db.query(Agent).filter(Agent.id == txn.agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent not found")
    db_txn = Transaction(agent_id=txn.agent_id, amount=txn.amount, query_text=txn.query_text)
    db.add(db_txn)
    db.commit()
    return {"status": "logged", "agent_id": txn.agent_id, "amount": txn.amount}


@app.get("/transactions")
def list_transactions(db: Session = Depends(get_db)):
    return db.query(Transaction).all()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)