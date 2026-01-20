from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Configuration, ConfigCreate, ConfigUpdate, ConfigRead
from typing import List
from .users import get_current_user, require_landlord as require_admin

router = APIRouter(prefix="/config", tags=["config"])

def get_config_value(db: Session, key: str, default: float = 0.0) -> float:
    """Helper function to get a configuration value by key."""
    config = db.query(Configuration).filter(Configuration.config_key == key).first()
    if not config:
        return default
    return float(config.config_value)

@router.get("/{config_key}", response_model=ConfigRead)
def get_config(config_key: str, db: Session = Depends(get_db)):
    """Get a specific configuration by key."""
    config = db.query(Configuration).filter(Configuration.config_key == config_key).first()
    if not config:
        raise HTTPException(status_code=404, detail="Configuration not found")
    return config

@router.get("/", response_model=List[ConfigRead])
def list_configs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List all configurations."""
    return db.query(Configuration).offset(skip).limit(limit).all()

@router.post("/", status_code=status.HTTP_201_CREATED, response_model=ConfigRead)
def create_config(config: ConfigCreate, db: Session = Depends(get_db), current_user=Depends(require_admin)):
    """Create a new configuration."""
    db_config = Configuration(**config.dict())
    db.add(db_config)
    db.commit()
    db.refresh(db_config)
    return db_config

@router.put("/{config_key}", response_model=ConfigRead)
def update_config(config_key: str, config_update: ConfigUpdate, db: Session = Depends(get_db), current_user=Depends(require_admin)):
    """Update an existing configuration."""
    db_config = db.query(Configuration).filter(Configuration.config_key == config_key).first()
    if not db_config:
        raise HTTPException(status_code=404, detail="Configuration not found")
    
    update_data = config_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_config, field, value)
    
    db.commit()
    db.refresh(db_config)
    return db_config

def get_platform_fee(db: Session) -> float:
    """Get the platform fee from the database."""
    return get_config_value(db, "platform_fee", 2500.0)  # Default to 2500 MWK if not set
