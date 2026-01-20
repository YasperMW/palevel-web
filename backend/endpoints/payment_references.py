from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone
from pydantic import BaseModel, UUID4, Field, validator
from database import get_db
from sqlalchemy.orm import Session
from sqlalchemy import text, exc
from endpoints.users import get_current_user
import logging
import uuid

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

class PaymentPreferencesBase(BaseModel):
    preferred_method: str = Field(..., description="Preferred payment method (e.g., 'mobile_money', 'bank_transfer')")
    mobile_number: Optional[str] = Field(None, max_length=20, description="Mobile number for mobile money payments")
    account_number: Optional[str] = Field(None, max_length=50, description="Bank account number")
    account_name: Optional[str] = Field(None, max_length=255, description="Name on the bank account")
    bank_name: Optional[str] = Field(None, max_length=100, description="Name of the bank")
    bank_uuid: Optional[str] = Field(None, description="UUID of the bank or mobile money provider")

    @validator('mobile_number')
    def validate_mobile_number(cls, v, values):
        if v is not None and not v.isdigit():
            raise ValueError('Mobile number must contain only digits')
        return v

class PaymentPreferencesCreate(PaymentPreferencesBase):
    pass

class PaymentPreferences(PaymentPreferencesBase):
    payment_reference_id: UUID4
    user_id: UUID4
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
        json_encoders = {
            uuid.UUID: str
        }

@router.get("/user/payment-preferences/", status_code=status.HTTP_200_OK)
async def get_payment_preferences(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all payment methods for the current user
    """
    try:
        user_id = str(current_user.user_id)
        logger.info(f"Fetching payment preferences for user: {user_id}")
        
        # Get all payment methods for the user
        result = db.execute(
            text("""
                SELECT
                    payment_reference_id,
                    mobile_number,
                    account_number,
                    account_name,
                    bank_name,
                    bank_uuid,
                    is_preferred,
                    created_at,
                    updated_at
                FROM payment_preferences
                WHERE user_id = :user_id
                ORDER BY updated_at DESC
            """),
            {"user_id": user_id}
        ).fetchall()
        
        # Convert to list of dicts
        payment_methods = []
        for row in result:
            # Determine the type based on mobile_number and bank_uuid
            # Mobile money has mobile_number, bank transfers have account_number
            payment_type = "mobile_money" if row[1] else "bank_transfer"
            
            payment_methods.append({
                "id": str(row[0]),
                "type": payment_type,
                "details": {
                    "mobileNumber": row[1],
                    "accountNumber": row[2],
                    "accountName": row[3],
                    "bankName": row[4],
                    "bankUuid": str(row[5]) if row[5] else None
                },
                "isPreferred": row[6],
                "createdAt": row[7].isoformat() if row[7] else None,
                "updatedAt": row[8].isoformat() if row[8] else None
            })
        
        return {
            "paymentMethods": payment_methods
        }
    except Exception as e:
        logger.error(f"Error getting payment preferences: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not retrieve payment preferences"
        )


@router.post("/user/payment-methods/", status_code=status.HTTP_201_CREATED)
async def add_payment_method(
    payment_method: PaymentPreferencesCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Add a new payment method for the current user
    """
    try:
        user_id = str(current_user.user_id)
        logger.info(f"Adding payment method for user: {user_id}")
        
        # Generate a new payment reference ID
        payment_reference_id = str(uuid.uuid4())
        
        # Check if this is the first payment method for the user
        is_first_method = db.execute(
            text("SELECT COUNT(*) = 0 FROM payment_preferences WHERE user_id = :user_id"),
            {"user_id": user_id}
        ).scalar()
        
        # If this is the first method, it will be set as preferred by default
        is_preferred = is_first_method

        # Insert the new payment method
        result = db.execute(
            text("""
                INSERT INTO payment_preferences (
                    payment_reference_id,
                    user_id,
                    mobile_number,
                    account_number,
                    account_name,
                    bank_name,
                    bank_uuid,
                    is_preferred,
                    created_at,
                    updated_at
                ) VALUES (
                    :payment_reference_id, 
                    :user_id, 
                    :mobile_number, 
                    :account_number, 
                    :account_name, 
                    :bank_name,
                    :bank_uuid,
                    :is_preferred,
                    NOW(),
                    NOW()
                )
                RETURNING payment_reference_id
            """),
            {
                "payment_reference_id": payment_reference_id,
                "user_id": user_id,
                "mobile_number": payment_method.mobile_number or None,
                "account_number": payment_method.account_number or None,
                "account_name": payment_method.account_name or None,
                "bank_name": payment_method.bank_name or None,
                "bank_uuid": payment_method.bank_uuid or None,
                "is_preferred": is_preferred
            }
        )
        
        # If this is the preferred method, ensure no other methods are marked as preferred
        if is_preferred:
            db.execute(
                text("""
                    UPDATE payment_preferences
                    SET is_preferred = FALSE
                    WHERE user_id = :user_id
                    AND payment_reference_id != :payment_reference_id
                """),
                {
                    "user_id": user_id,
                    "payment_reference_id": payment_reference_id
                }
            )
        
        db.commit()
        
        # Get the newly created payment method with all fields
        new_method = db.execute(
            text("""
                SELECT 
                    payment_reference_id,
                    mobile_number,
                    account_number,
                    account_name,
                    bank_name,
                    bank_uuid,
                    is_preferred,
                    created_at,
                    updated_at
                FROM payment_preferences
                WHERE payment_reference_id = :payment_reference_id
            """),
            {"payment_reference_id": payment_reference_id}
        ).fetchone()
        
        # Determine the payment type based on mobile_number and account_number
        # Mobile money has mobile_number, bank transfers have account_number
        payment_type = "mobile_money" if new_method[1] else "bank_transfer" if new_method[2] else "unknown"
        
        # Convert to dict
        method_dict = {
            "id": str(new_method[0]),
            "type": payment_type,
            "details": {
                "mobileNumber": new_method[1],
                "accountNumber": new_method[2],
                "accountName": new_method[3],
                "bankName": new_method[4],
                "bankUuid": str(new_method[5]) if new_method[5] else None
            },
            "isPreferred": new_method[6],
            "createdAt": new_method[7].isoformat() if new_method[7] else None,
            "updatedAt": new_method[8].isoformat() if new_method[8] else None
        }
        
        return {
            "status": "success", 
            "message": "Payment method added successfully",
            "paymentMethod": method_dict
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error adding payment method: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not add payment method"
        )

@router.put("/user/payment-methods/{payment_method_id}/set-preferred", status_code=status.HTTP_200_OK)
async def set_preferred_payment_method(
    payment_method_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Set a payment method as the preferred one for the current user
    """
    try:
        user_id = str(current_user.user_id)
        
        # Verify the payment method exists and belongs to the user
        result = db.execute(
            text("""
                SELECT 1 FROM payment_preferences 
                WHERE payment_reference_id = :payment_method_id 
                AND user_id = :user_id
            """),
            {
                "payment_method_id": payment_method_id,
                "user_id": user_id
            }
        ).fetchone()
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment method not found"
            )
        
        # Update the preferred method
        db.execute(
            text("""
                UPDATE payment_preferences 
                SET updated_at = NOW()
                WHERE payment_reference_id = :payment_method_id
                AND user_id = :user_id
            """),
            {
                "payment_method_id": payment_method_id,
                "user_id": user_id
            }
        )
        
        db.commit()
        
        return {
            "status": "success", 
            "message": "Preferred payment method updated successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error setting preferred payment method: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not update preferred payment method"
        )

@router.delete("/user/payment-methods/{payment_method_id}", status_code=status.HTTP_200_OK)
async def delete_payment_method(
    payment_method_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a payment method for the current user
    """
    try:
        user_id = str(current_user.user_id)
        
        # Verify the payment method exists and belongs to the user
        result = db.execute(
            text("""
                DELETE FROM payment_preferences 
                WHERE payment_reference_id = :payment_method_id 
                AND user_id = :user_id
                RETURNING 1
            """),
            {
                "payment_method_id": payment_method_id,
                "user_id": user_id
            }
        ).fetchone()
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment method not found or you don't have permission to delete it"
            )
        
        db.commit()
        
        return {
            "status": "success", 
            "message": "Payment method deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting payment method: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not delete payment method"
        )

@router.put("/user/payment-methods/{payment_method_id}/set-preferred", status_code=status.HTTP_200_OK)
async def set_preferred_payment_method(
    payment_method_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Set a payment method as the preferred one for the current user
    """
    try:
        user_id = str(current_user.user_id)
        
        # Start a transaction
        db.begin()
        
        # 1. Verify the payment method exists and belongs to the user
        # 1. Verify the payment method exists and belongs to the user
        method = db.execute(
            text("""
                SELECT 1 FROM payment_preferences 
                WHERE payment_reference_id = :payment_method_id 
                AND user_id = :user_id
                FOR UPDATE
            """),
            {
                "payment_method_id": payment_method_id,
                "user_id": user_id
            }
        ).fetchone()
                
        if not method:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment method not found"
            )
        
        # 2. Set all payment methods for this user as not preferred
        db.execute(
            text("""
                UPDATE payment_preferences 
                SET is_preferred = FALSE, 
                    updated_at = NOW()
                WHERE user_id = :user_id
            """),
            {"user_id": user_id}
        )
        
        # 3. Set the specified payment method as preferred
        db.execute(
            text("""
                UPDATE payment_preferences 
                SET is_preferred = TRUE,
                    updated_at = NOW()
                WHERE payment_reference_id = :payment_method_id
                AND user_id = :user_id
            """),
            {
                "payment_method_id": payment_method_id,
                "user_id": user_id
            }
        )
        
        # Commit the transaction
        db.commit()
        
        # Get the updated payment method
        updated_method = db.execute(
            text("""
                SELECT 
                    payment_reference_id,
                    mobile_number,
                    account_number,
                    account_name,
                    bank_name,
                    is_preferred,
                    created_at,
                    updated_at
                FROM payment_preferences
                WHERE payment_reference_id = :payment_method_id
            """),
            {"payment_method_id": payment_method_id}
        ).fetchone()
        
        # Convert to response format
        payment_type = "bank_transfer" if updated_method[4] else "mobile_money"
        method_dict = {
            "id": str(updated_method[0]),
            "type": payment_type,
            "details": {
                "mobileNumber": updated_method[1],
                "accountNumber": updated_method[2],
                "accountName": updated_method[3],
                "bankName": updated_method[4]
            },
            "isPreferred": updated_method[5],
            "createdAt": updated_method[6].isoformat() if updated_method[6] else None,
            "updatedAt": updated_method[7].isoformat() if updated_method[7] else None
        }
        
        return {
            "status": "success",
            "message": "Payment method set as preferred",
            "paymentMethod": method_dict
        }
        
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error setting preferred payment method: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not set preferred payment method"
        )