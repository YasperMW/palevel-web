from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db, engine
import time

router = APIRouter(tags=["health"])

@router.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint to verify database connectivity"""
    db_status = "connected"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"disconnected: {str(e)}"
    
    return {
        "status": "healthy" if db_status == "connected" else "unhealthy",
        "database": db_status,
        "timestamp": time.time()
    }

@router.get("/db-stats")
async def db_stats():
    """Get database connection pool statistics"""
    try:
        stats = {
            "pool_size": engine.pool.size(),
            "checked_in": engine.pool.checkedin(),
            "checked_out": engine.pool.checkedout(),
            "timeout": engine.pool.timeout(),
            "status": "healthy"
        }
        if hasattr(engine.pool, 'overflow'):
            stats["overflow"] = engine.pool.overflow()
        return stats
    except Exception as e:
        return {"status": "error", "message": str(e)}
