"""
Database setup for the Specialist AI Agent Marketplace.
Uses SQLite for hackathon simplicity - zero setup, one file (marketplace.db).
"""
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import datetime

DATABASE_URL = "sqlite:///./marketplace.db"

# check_same_thread=False is needed because FastAPI can use SQLite across threads
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class Agent(Base):
    """A registered specialist AI agent listed on the marketplace."""
    __tablename__ = "agents"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)  # used for keyword/semantic search matching
    category = Column(String, nullable=True)  # e.g. "legal", "translation", "health-info"
    price_per_call = Column(Float, nullable=False)  # in USD, e.g. 0.02
    endpoint_or_identifier = Column(String, nullable=True)  # how Role 2's agent is reached
    rating_sum = Column(Float, default=0.0)
    rating_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    @property
    def rating_avg(self):
        if self.rating_count == 0:
            return None
        return round(self.rating_sum / self.rating_count, 2)


class Transaction(Base):
    """A log of a completed (or simulated) payment to an agent."""
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    agent_id = Column(Integer, nullable=False)
    amount = Column(Float, nullable=False)
    query_text = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)


def init_db():
    Base.metadata.create_all(bind=engine)


def get_db():
    """FastAPI dependency - gives each request its own DB session, closes it after."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()