from sqlalchemy import create_engine, text, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
import os
import logging
from contextlib import contextmanager
from typing import Generator, Optional, Union
import time
from datetime import datetime

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('database.log')
    ]
)
logger = logging.getLogger('database')
logging.getLogger('sqlalchemy.engine').setLevel(logging.WARNING)

# Environment Configuration
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')
IS_PRODUCTION = ENVIRONMENT == 'production'
DB_URL = os.getenv("DATABASE_URL", "postgresql://postgres:Yasperchisale343.@localhost/palevel")
ASYNC_DB_URL = DB_URL.replace('postgresql://', 'postgresql+asyncpg://')

# Connection Pool Configuration
POOL_CONFIG = {
    'pool_size': 20 if IS_PRODUCTION else 5,
    'max_overflow': 30 if IS_PRODUCTION else 10,
    'pool_timeout': 10,  # seconds
    'pool_recycle': 3600,  # 1 hour
    'pool_pre_ping': True,
    'connect_args': {
        'connect_timeout': 5,  # seconds
        'keepalives': 1,
        'keepalives_idle': 30,  # seconds
        'keepalives_interval': 10,  # seconds
        'keepalives_count': 5,
        'application_name': f"palevel_{ENVIRONMENT}",
    }
}

# Create database engines
engine = create_engine(DB_URL, **POOL_CONFIG)
async_engine = create_async_engine(ASYNC_DB_URL, **POOL_CONFIG)

# Session Factories
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    expire_on_commit=False
)

AsyncSessionLocal = sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Scoped session for thread safety
ScopedSession = scoped_session(SessionLocal)
Base = declarative_base()

# Connection monitoring
connection_stats = {
    'total_checkouts': 0,
    'active_connections': 0,
    'peak_connections': 0,
    'last_checkout': None,
    'errors': []
}

@event.listens_for(engine, 'checkout')
def on_checkout(dbapi_connection, connection_record, connection_proxy):
    """Track connection checkouts and monitor pool usage."""
    connection_stats['total_checkouts'] += 1
    connection_stats['active_connections'] += 1
    connection_stats['peak_connections'] = max(
        connection_stats['peak_connections'],
        connection_stats['active_connections']
    )
    connection_stats['last_checkout'] = datetime.utcnow().isoformat()
    
    if connection_stats['active_connections'] > POOL_CONFIG['pool_size'] * 0.8:
        logger.warning(
            "High connection pool usage: %d/%d connections in use",
            connection_stats['active_connections'],
            POOL_CONFIG['pool_size'] + POOL_CONFIG['max_overflow']
        )

@event.listens_for(engine, 'checkin')
def on_checkin(dbapi_connection, connection_record):
    """Track connection checkins."""
    if connection_stats['active_connections'] > 0:
        connection_stats['active_connections'] -= 1

@event.listens_for(engine, 'handle_error')
def handle_error(exception_context):
    """Log database errors with context."""
    error = str(exception_context.original_exception)
    connection_stats['errors'].append({
        'time': datetime.utcnow().isoformat(),
        'error': error
    })
    logger.error("Database error: %s", error)

@contextmanager
def db_session() -> Generator[SessionLocal, None, None]:
    """Context manager for manual session management in non-request code."""
    session = ScopedSession()
    try:
        yield session
    except Exception as e:
        session.rollback()
        logger.error("Database session error: %s", str(e))
        raise
    finally:
        session.close()

def get_db() -> Generator[SessionLocal, None, None]:
    """FastAPI dependency that yields a database session per request."""
    session = SessionLocal()
    try:
        yield session
    except Exception as e:
        session.rollback()
        logger.error("Database session error: %s", str(e))
        raise
    finally:
        session.close()

async def get_async_db() -> Generator[AsyncSession, None, None]:
    """Async FastAPI dependency that yields an async session per request."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error("Async database session error: %s", str(e))
            raise

def check_db_connection() -> bool:
    """
    Verify database connectivity and return status.
    """
    try:
        start_time = time.monotonic()
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        latency = (time.monotonic() - start_time) * 1000  # ms
        logger.debug("Database connection check successful (%.2fms)", latency)
        return True
    except Exception as e:
        logger.error("Database connection check failed: %s", str(e))
        return False

def get_connection_stats() -> dict:
    """
    Return current connection pool statistics.
    """
    return {
        **connection_stats,
        'pool_size': POOL_CONFIG['pool_size'],
        'max_overflow': POOL_CONFIG['max_overflow'],
        'current_time': datetime.utcnow().isoformat()
    }

# Health check endpoint
def health_check() -> dict:
    """
    Comprehensive health check of the database connection.
    """
    is_healthy = check_db_connection()
    stats = get_connection_stats()
    
    return {
        'status': 'healthy' if is_healthy else 'unhealthy',
        'database': {
            'status': 'connected' if is_healthy else 'disconnected',
            'connection_pool': {
                'size': f"{stats['active_connections']}/{stats['pool_size'] + stats['max_overflow']}",
                'peak_connections': stats['peak_connections'],
                'total_checkouts': stats['total_checkouts']
            }
        },
        'timestamp': datetime.utcnow().isoformat()
    }