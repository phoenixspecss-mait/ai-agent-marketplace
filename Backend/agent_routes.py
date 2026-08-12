import os
import sys
from typing import Optional, Dict, Any

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Ensure Backend directory is in sys.path for local module resolution
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

try:
    from agents import run_specialist, AGENT_PRICING, SYSTEM_PROMPTS
    from payments import wallet_manager, WalletManager
except ModuleNotFoundError:
    from Backend.agents import run_specialist, AGENT_PRICING, SYSTEM_PROMPTS
    from Backend.payments import wallet_manager, WalletManager

app = FastAPI(
    title="x402 AI Marketplace Backend",
    description="Specialist AI Agents Engine & Micro-Payment Settlement Broker",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request / Response Schemas
class TopUpRequest(BaseModel):
    user_id: str = Field(..., examples=["demo_user_01"])
    amount: float = Field(..., gt=0.0, examples=[1.00])

class AgentCallRequest(BaseModel):
    user_id: str = Field(..., examples=["demo_user_01"])
    agent_id: str = Field(..., examples=["legal-clause-explainer"])
    query: str = Field(..., examples=["Explain what a class action waiver means."])

# Alias for backward compatibility
CallAgentRequest = AgentCallRequest

# Core Execution Function
def execute_specialist_call(req: AgentCallRequest) -> Dict[str, Any]:
    """
    Core handler executing a Specialist AI Agent call with x402 micro-payment settlement.
    Returns dictionary on success or raises HTTPException on error / 402 Payment Required.
    """
    # 1. Validate Agent ID
    if req.agent_id not in SYSTEM_PROMPTS:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Agent '{req.agent_id}' not found. Available agents: {list(SYSTEM_PROMPTS.keys())}"
        )

    agent_cost = AGENT_PRICING.get(req.agent_id, 0.005)
    current_balance = wallet_manager.get_balance(req.user_id)

    # 2. Evaluate Wallet Balance (x402 Protocol Check)
    if current_balance < agent_cost:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail={
                "status": "error",
                "error": "Payment Required",
                "message": f"Insufficient wallet balance (${current_balance:.4f} USD). Call cost is ${agent_cost:.4f} USD.",
                "user_id": req.user_id,
                "agent_id": req.agent_id,
                "cost_usd": agent_cost,
                "current_balance_usd": current_balance,
                "x402_protocol": {
                    "status": 402,
                    "network": "Base testnet",
                    "asset": "USDC",
                    "topup_endpoint": "/api/marketplace/wallet/topup"
                }
            }
        )

    # 3. Deduct Payment (Sub-Cent Micro-Payment Settlement)
    success, settlement_msg, remaining_balance = wallet_manager.deduct_payment(
        req.user_id, req.agent_id, agent_cost
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=settlement_msg
        )

    # 4. Invoke Specialist Agent
    try:
        agent_result = run_specialist(req.agent_id, req.query)
    except Exception as err:
        # Refund on failure if execution errors out
        wallet_manager.top_up(req.user_id, agent_cost)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Agent execution failed: {str(err)}. Cost refunded."
        )

    # 5. Return Success Response
    return {
        "status": "success",
        "agent_id": req.agent_id,
        "cost_usd": agent_cost,
        "payment_settlement": settlement_msg,
        "remaining_balance_usd": remaining_balance,
        "result": agent_result
    }

# Routes

@app.get("/")
def read_root():
    return {
        "service": "x402 AI Marketplace Broker",
        "available_agents": list(AGENT_PRICING.keys()),
        "status": "operational"
    }

@app.get("/api/marketplace/wallet/balance")
def get_wallet_balance(user_id: str):
    """Retrieves current USD wallet balance for a user."""
    balance = wallet_manager.get_balance(user_id)
    return {
        "user_id": user_id,
        "balance_usd": balance
    }

@app.post("/api/marketplace/wallet/topup")
def topup_wallet(req: TopUpRequest):
    """Pre-funds user wallet with USD balance."""
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
def call_agent(req: AgentCallRequest):
    """API endpoint for calling specialist agents."""
    return execute_specialist_call(req)
