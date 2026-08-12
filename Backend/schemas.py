"""
Pydantic schemas - define what JSON goes in and out of each endpoint.
Share this shape with Role 2 (payments) and Role 3 (orchestrator) early.
"""
from pydantic import BaseModel, Field
from typing import Optional
import datetime


class AgentRegister(BaseModel):
    name: str
    description: str
    category: Optional[str] = None
    price_per_call: float = Field(gt=0, description="Price in USD, must be positive")
    endpoint_or_identifier: Optional[str] = None


class AgentOut(BaseModel):
    id: int
    name: str
    description: str
    category: Optional[str]
    price_per_call: float
    endpoint_or_identifier: Optional[str]
    rating_avg: Optional[float] = None
    rating_count: int

    class Config:
        from_attributes = True  # lets us build this directly from the SQLAlchemy model


class RatingSubmit(BaseModel):
    stars: int = Field(ge=1, le=5, description="Rating from 1 to 5")


class SearchQuery(BaseModel):
    query: str
    top_k: int = 3  # how many matching agents to return


class SearchResult(BaseModel):
    agent: AgentOut
    match_score: float


class TransactionLog(BaseModel):
    agent_id: int
    amount: float
    query_text: Optional[str] = None
