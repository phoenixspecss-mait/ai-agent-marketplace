import sqlite3
import uuid
import time
from datetime import datetime
from typing import Tuple, Dict, Any, List, Optional

DB_FILE = "wallet_sim.db"

class WalletManager:
    """
    Wallet & Payment Settlement Handler for the x402 marketplace architecture.
    Manages pre-funded balances and records sub-cent micro-payment deductions in SQLite.
    """
    def __init__(self, db_path: str = DB_FILE):
        self.db_path = db_path
        self._init_db()

    def _get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        """Initializes wallets and transactions tables in SQLite with column migration."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS wallets (
                    user_id TEXT PRIMARY KEY,
                    balance REAL NOT NULL DEFAULT 0.0,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            
            # Check for legacy balance_usd column and migrate if needed
            cursor.execute("PRAGMA table_info(wallets)")
            columns = [col["name"] for col in cursor.fetchall()]
            if "balance_usd" in columns and "balance" not in columns:
                cursor.execute("ALTER TABLE wallets RENAME COLUMN balance_usd TO balance")

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS transactions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id TEXT NOT NULL,
                    agent_id TEXT,
                    amount REAL NOT NULL,
                    status TEXT NOT NULL,
                    settlement_hash TEXT NOT NULL,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            conn.commit()

    def get_balance(self, user_id: str) -> float:
        """Returns the current USD wallet balance for a given user. Auto-seeds new users with $5.00 starting balance."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT balance FROM wallets WHERE user_id = ?", (user_id,))
            row = cursor.fetchone()
            if row:
                return round(float(row["balance"]), 4)
        # Auto-fund new demo users with $5.00 initial balance
        self.top_up(user_id, 5.00)
        return 5.00

    def top_up(self, user_id: str, amount: float) -> float:
        """
        Top up a user's wallet with specified USD amount.
        Returns the updated total balance.
        """
        if amount <= 0:
            raise ValueError("Top-up amount must be greater than zero.")

        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO wallets (user_id, balance, updated_at)
                VALUES (?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(user_id) DO UPDATE SET
                    balance = balance + excluded.balance,
                    updated_at = CURRENT_TIMESTAMP;
            """, (user_id, amount))
            
            settlement_hash = f"topup_{uuid.uuid4().hex[:12]}"
            cursor.execute("""
                INSERT INTO transactions (user_id, agent_id, amount, status, settlement_hash)
                VALUES (?, 'TOPUP', ?, 'SETTLED', ?);
            """, (user_id, amount, settlement_hash))
            
            conn.commit()
            
        return self.get_balance(user_id)

    def deduct_payment(self, user_id: str, agent_id: str, cost: float) -> Tuple[bool, str, float]:
        """
        Attempts to deduct sub-cent cost from user wallet.
        Returns: (success: bool, settlement_msg: str, remaining_balance: float)
        """
        current_balance = self.get_balance(user_id)
        if current_balance < cost:
            return False, f"Insufficient balance. Available: ${current_balance:.4f}, Required: ${cost:.4f}", current_balance

        new_balance = round(current_balance - cost, 4)
        settlement_hash = f"0x{uuid.uuid4().hex}"

        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE wallets
                SET balance = ?, updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ?;
            """, (new_balance, user_id))

            cursor.execute("""
                INSERT INTO transactions (user_id, agent_id, amount, status, settlement_hash)
                VALUES (?, ?, ?, 'SETTLED', ?);
            """, (user_id, agent_id, cost, settlement_hash))

            conn.commit()

        settlement_msg = f"Settled ${cost:.4f} USDC on Base testnet (Tx: {settlement_hash[:18]}...)"
        return True, settlement_msg, new_balance

    def process_agent_payment(self, user_id: str, agent_id: str, price_usd: float) -> Tuple[bool, str]:
        success, msg, _ = self.deduct_payment(user_id, agent_id, price_usd)
        return success, msg

    def get_transaction_history(self, user_id: str) -> List[Dict[str, Any]]:
        """Retrieves user transaction execution history."""
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT user_id, agent_id, amount, status, settlement_hash, timestamp
                FROM transactions
                WHERE user_id = ?
                ORDER BY id DESC;
            """, (user_id,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

# Global singleton instance for application routes
wallet_manager = WalletManager()