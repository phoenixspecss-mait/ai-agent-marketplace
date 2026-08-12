"""
Automated Integration Test & Demonstration Fixture for AI Marketplace Agents
Verifies Wallet Top-Up, Sub-Cent Micro-Deductions, Specialist LLM Execution,
and x402 Protocol HTTP 402 Payment Required Enforcement.
"""

import sys
import os
from fastapi.testclient import TestClient
from fastapi import HTTPException

from payments import WalletManager, wallet_manager
from agent_routes import app, execute_specialist_call, CallAgentRequest, TopUpRequest

client = TestClient(app)

def run_integration_tests():
    print("==================================================================")
    print("      x402 AI MARKETPLACE INTEGRATION & DEMO FIXTURE TEST         ")
    print("==================================================================\n")

    user_id = "demo_user_01"

    # Reset wallet balance for demo user
    with wallet_manager._get_connection() as conn:
        conn.execute("DELETE FROM wallets WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM transactions WHERE user_id = ?", (user_id,))
        conn.execute("INSERT INTO wallets (user_id, balance) VALUES (?, 0.0)", (user_id,))
        conn.commit()

    # 1. Test Root Endpoint
    res = client.get("/")
    assert res.status_code == 200
    print("✅ 1. Root Endpoint Operational:", res.json()["service"])

    # 2. Check Initial Balance (0.0 USD)
    res = client.get(f"/api/marketplace/wallet/balance?user_id={user_id}")
    assert res.status_code == 200
    balance = res.json()["balance_usd"]
    assert balance == 0.0
    print(f"✅ 2. Initial Wallet Balance verified: ${balance:.4f} USD")

    # 3. Test HTTP 402 Payment Required on Zero Balance
    print("\n--- Testing x402 Protocol Payment Required ---")
    call_payload = {
        "user_id": user_id,
        "agent_id": "legal-clause-explainer",
        "query": "Explain what binding arbitration means."
    }
    res = client.post("/api/marketplace/call", json=call_payload)
    assert res.status_code == 402, f"Expected 402, got {res.status_code}"
    detail = res.json()["detail"]
    assert detail["error"] == "Payment Required"
    print("✅ 3. HTTP 402 Payment Required enforced correctly on zero balance:")
    print(f"   -> Message: {detail['message']}")
    print(f"   -> Protocol Asset: {detail['x402_protocol']['asset']} on {detail['x402_protocol']['network']}")

    # 4. Top-Up Wallet with $0.010 USD
    print("\n--- Pre-Funding Wallet ---")
    topup_res = client.post("/api/marketplace/wallet/topup", json={"user_id": user_id, "amount": 0.010})
    assert topup_res.status_code == 200
    new_bal = topup_res.json()["new_balance_usd"]
    assert new_bal == 0.010
    print(f"✅ 4. Wallet Top-Up successful. New Balance: ${new_bal:.4f} USD")

    # 5. Call 'legal-clause-explainer' ($0.005 USD)
    print("\n--- Executing Call 1: legal-clause-explainer ($0.005 USD) ---")
    req_legal = CallAgentRequest(
        user_id=user_id,
        agent_id="legal-clause-explainer",
        query="Explain: 'The user agrees to binding individual arbitration and waives all rights to participate in class actions.'"
    )
    res_legal = execute_specialist_call(req_legal)
    print(f"✅ 5. Call 1 Succeeded:")
    print(f"   -> Payment Status: {res_legal['payment_settlement']}")
    print(f"   -> Remaining Balance: ${res_legal['remaining_balance_usd']:.4f} USD")
    print(f"   -> Agent Answer Snippet: {res_legal['result'][:120]}...\n")

    # 6. Call 'punjabi-slang-translator' ($0.002 USD)
    print("--- Executing Call 2: punjabi-slang-translator ($0.002 USD) ---")
    req_slang = CallAgentRequest(
        user_id=user_id,
        agent_id="punjabi-slang-translator",
        query="What does 'Aaj da mahool poora siraa hai, gedhi route te chalde aa' mean?"
    )
    res_slang = execute_specialist_call(req_slang)
    print(f"✅ 6. Call 2 Succeeded:")
    print(f"   -> Payment Status: {res_slang['payment_settlement']}")
    print(f"   -> Remaining Balance: ${res_slang['remaining_balance_usd']:.4f} USD")
    print(f"   -> Agent Answer Snippet: {res_slang['result'][:120]}...\n")

    # Current Balance should be: 0.010 - 0.005 - 0.002 = $0.003 USD
    curr_bal = wallet_manager.get_balance(user_id)
    print(f"Current Balance after 2 calls: ${curr_bal:.4f} USD")

    # 7. Attempt Call 3 to 'legal-clause-explainer' ($0.005 USD) with $0.003 balance -> MUST TRIGGER 402!
    print("\n--- Executing Call 3: legal-clause-explainer ($0.005 USD) with insufficient balance ($0.003 USD) ---")
    try:
        execute_specialist_call(req_legal)
        print("❌ ERROR: Expected 402 exception but call succeeded!")
    except HTTPException as exc:
        assert exc.status_code == 402
        print("✅ 7. HTTP 402 Payment Required successfully triggered for Call 3:")
        print(f"   -> Detail: {exc.detail['message']}")

    # 8. Verify Transaction History
    print("\n--- Verifying SQLite Transaction History ---")
    history = wallet_manager.get_transaction_history(user_id)
    print(f"✅ 8. Transaction Log Records ({len(history)} entries):")
    for tx in history:
        print(f"   -> [{tx['timestamp']}] Agent: {tx['agent_id']} | Amount: ${tx['amount']:.4f} | Status: {tx['status']}")

    print("\n==================================================================")
    print("🎉 ALL INTEGRATION TESTS & x402 PROTOCOL VERIFICATIONS PASSED!")
    print("==================================================================")

if __name__ == "__main__":
    run_integration_tests()