import os
from fastapi import APIRouter, Depends, HTTPException, status, Query, Form, Body
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import text, func, desc
from database import get_db, db_session
from models import User, Hostel, Room, Booking, Payment, Configuration, Notification, Verification, PaymentPreference, Disbursement, DisbursementCreate, BatchDisbursementCreate
from endpoints.users import get_current_user
from datetime import datetime, timedelta
from typing import Optional
import uuid
import logging

# Logging for admin endpoints
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(tags=["admin"])

def require_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """Require admin user role"""
    if current_user.user_type != 'admin':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

@router.get("/stats")
async def get_admin_stats(
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get comprehensive platform statistics for admin dashboard"""
    
    # Total users by type
    total_users = db.query(User).count()
    total_students = db.query(User).filter(User.user_type == 'tenant').count()
    total_landlords = db.query(User).filter(User.user_type == 'landlord').count()
    total_admins = db.query(User).filter(User.user_type == 'admin').count()
    
    # Total hostels and rooms
    total_hostels = db.query(Hostel).count()
    total_rooms = db.query(Room).count()
    active_hostels = db.query(Hostel).filter(Hostel.is_active == True).count()
    
    # Bookings statistics
    total_bookings = db.query(Booking).count()
    pending_bookings = db.query(Booking).filter(Booking.status == 'pending').count()
    confirmed_bookings = db.query(Booking).filter(Booking.status == 'confirmed').count()
    cancelled_bookings = db.query(Booking).filter(Booking.status == 'cancelled').count()
    
    # Revenue statistics
    platform_fee = db.query(Configuration.config_value).filter(
        Configuration.config_key == "platform_fee"
    ).scalar() or 0
    
    total_payments = db.query(Payment).filter(Payment.status == 'completed').count()
    total_revenue = db.query(Payment).filter(Payment.status == 'completed').with_entities(
        func.sum(Payment.amount)
    ).scalar() or 0
    
    # Recent activity (last 7 days)
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    recent_bookings = db.query(Booking).filter(Booking.created_at >= seven_days_ago).count()
    recent_users = db.query(User).filter(User.created_at >= seven_days_ago).count()
    
    return {
        "users": {
            "total": total_users,
            "students": total_students,
            "landlords": total_landlords,
            "admins": total_admins
        },
        "properties": {
            "total_hostels": total_hostels,
            "active_hostels": active_hostels,
            "total_rooms": total_rooms
        },
        "bookings": {
            "total": total_bookings,
            "pending": pending_bookings,
            "confirmed": confirmed_bookings,
            "cancelled": cancelled_bookings,
            "recent": recent_bookings
        },
        "payments": {
            "total_payments": total_payments,
            "total_revenue": float(total_revenue),
            "platform_fee": float(platform_fee)
        },
        "activity": {
            "recent_users": recent_users
        }
    }

@router.get("/students")
async def get_all_students(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get all students with pagination and filtering"""
    
    query = db.query(User).filter(User.user_type == 'tenant')
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (User.first_name.ilike(search_term)) |
            (User.last_name.ilike(search_term)) |
            (User.email.ilike(search_term)) |
            (User.phone_number.ilike(search_term))
        )
    
    # Note: User model doesn't have status field, so we'll skip status filtering for now
    # if status:
    #     query = query.filter(User.status == status)
    
    total = query.count()
    students = query.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "total": total,
        "students": [
            {
                "user_id": str(student.user_id),
                "first_name": student.first_name,
                "last_name": student.last_name,
                "email": student.email,
                "phone": student.phone_number,
                "university": student.university,
                "status": "active" if not student.is_blacklisted else "suspended",
                "created_at": student.created_at.isoformat() if student.created_at else None,
                "last_login": None,  # User model doesn't have last_login field
                "booking_count": db.query(Booking).filter(Booking.student_id == student.user_id).count()
            }
            for student in students
        ]
    }

@router.get("/landlords")
async def get_all_landlords(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get all landlords with pagination and search"""
    
    query = db.query(User).filter(User.user_type == 'landlord')
    
    # Left join with verifications to get verification status
    query = query.outerjoin(Verification, User.user_id == Verification.landlord_id)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (User.first_name.ilike(search_term)) |
            (User.last_name.ilike(search_term)) |
            (User.email.ilike(search_term)) |
            (User.phone_number.ilike(search_term))
        )
    
    if status:
        query = query.filter(User.is_blacklisted == (status == 'suspended'))
        if status != 'suspended':
            query = query.filter(User.is_blacklisted == False)
    
    total = query.count()
    landlords = query.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for landlord in landlords:
        # Get verification status
        verification = db.query(Verification).filter(
            Verification.landlord_id == landlord.user_id
        ).order_by(Verification.updated_at.desc()).first()
        
        # Get property count
        property_count = db.query(Hostel).filter(Hostel.landlord_id == landlord.user_id).count()
        
        result.append({
            "user_id": str(landlord.user_id),
            "first_name": landlord.first_name,
            "last_name": landlord.last_name,
            "email": landlord.email,
            "phone": landlord.phone_number,
            "university": landlord.university,
            "status": "suspended" if landlord.is_blacklisted else "active",
            "verification_status": verification.status if verification else None,
            "property_count": property_count,
            "created_at": landlord.created_at.isoformat() if landlord.created_at else None,
            "last_login": None
        })
    
    return {
        "total": total,
        "landlords": result
    }

@router.put("/users/{user_id}/status")
async def update_user_status(
    user_id: uuid.UUID,
    new_status: str,
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Update user status (active/inactive/suspended)"""
    
    if new_status not in ['active', 'inactive', 'suspended']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid status. Must be 'active', 'inactive', or 'suspended'"
        )
    
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.status = new_status
    db.commit()
    
    return {"message": f"User status updated to {new_status}"}

@router.get("/payments")
async def get_all_payments(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = Query(None),
    payment_type: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get all payments with filtering"""
    
    query = (
        db.query(Payment)
        .options(
            joinedload(Payment.booking)
            .joinedload(Booking.student),
            joinedload(Payment.booking)
            .joinedload(Booking.room)
            .joinedload(Room.hostel)
        )
    )
    
    if status:
        query = query.filter(Payment.status == status)
    
    if payment_type:
        query = query.filter(Payment.payment_type == payment_type)
    
    if start_date:
        try:
            start_dt = datetime.fromisoformat(start_date)
            query = query.filter(Payment.paid_at >= start_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid start_date format")
    
    if end_date:
        try:
            end_dt = datetime.fromisoformat(end_date)
            query = query.filter(Payment.paid_at <= end_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid end_date format")
    
    total = query.count()
    payments = query.order_by(Payment.paid_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for payment in payments:
        result.append({
            "payment_id": str(payment.payment_id),
            "booking_id": str(payment.booking_id),
            "amount": float(payment.amount),
            "payment_method": payment.payment_method,
            "status": payment.status,
            "payment_type": payment.payment_type,
            "transaction_id": payment.transaction_id,
            "created_at": payment.paid_at.isoformat() if payment.paid_at else None,
            "paid_at": payment.paid_at.isoformat() if payment.paid_at else None,
            "student": {
                "name": f"{payment.booking.student.first_name} {payment.booking.student.last_name}",
                "email": payment.booking.student.email
            } if payment.booking and payment.booking.student else None,
            "hostel": payment.booking.room.hostel.name if payment.booking and payment.booking.room and payment.booking.room.hostel else None,
            "room": payment.booking.room.room_number if payment.booking and payment.booking.room else None
        })
    
    return {
        "total": total,
        "payments": result
    }

@router.get("/bookings")
async def get_all_bookings(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get all bookings with filtering"""
    
    query = (
        db.query(Booking)
        .options(
            joinedload(Booking.student),
            joinedload(Booking.room).joinedload(Room.hostel)
        )
    )
    
    if status:
        query = query.filter(Booking.status == status)
    
    if start_date:
        try:
            start_dt = datetime.fromisoformat(start_date)
            query = query.filter(Booking.created_at >= start_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid start_date format")
    
    if end_date:
        try:
            end_dt = datetime.fromisoformat(end_date)
            query = query.filter(Booking.created_at <= end_dt)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid end_date format")
    
    total = query.count()
    bookings = query.order_by(Booking.created_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for booking in bookings:
        result.append({
            "booking_id": str(booking.booking_id),
            "student": {
                "name": f"{booking.student.first_name} {booking.student.last_name}",
                "email": booking.student.email
            } if booking.student else None,
            "hostel": booking.room.hostel.name if booking.room and booking.room.hostel else None,
            "room": booking.room.room_number if booking.room else None,
            "status": booking.status,
            "total_amount": float(booking.total_amount),
            "payment_type": booking.payment_type,
            "start_date": booking.start_date.isoformat() if booking.start_date else None,
            "end_date": booking.end_date.isoformat() if booking.end_date else None,
            "created_at": booking.created_at.isoformat() if booking.created_at else None
        })
    
    return {
        "total": total,
        "bookings": result
    }

@router.get("/logs")
async def get_system_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    level: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get system activity logs"""
    
    query = db.query(Notification)
    
    if level:
        query = query.filter(Notification.type == level)
    
    if start_date:
        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        query = query.filter(Notification.created_at >= start_dt)
    
    if end_date:
        end_dt = datetime.strptime(end_date, "%Y-%m-%d")
        query = query.filter(Notification.created_at <= end_dt)
    
    logs = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "logs": [
            {
                "activity_id": str(log.notification_id),
                "user_id": str(log.user_id) if log.user_id else None,
                "description": log.title or log.body or "No description",
                "activity_type": log.type,
                "created_at": log.created_at.isoformat(),
                "ip_address": None,  # Not available in Notification model
                "user_agent": None   # Not available in Notification model
            }
            for log in logs
        ],
        "total": query.count(),
        "skip": skip,
        "limit": limit
    }

@router.get("/hostels")
async def get_all_hostels(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get all hostels with filtering"""
    
    query = (
        db.query(Hostel)
        .options(
            joinedload(Hostel.landlord),
            joinedload(Hostel.media)
        )
    )
    
    if status:
        if status == 'active':
            query = query.filter(Hostel.is_active == True)
        elif status == 'inactive':
            query = query.filter(Hostel.is_active == False)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(Hostel.name.ilike(search_term))
    
    total = query.count()
    hostels = query.order_by(Hostel.created_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for hostel in hostels:
        room_count = db.query(Room).filter(Room.hostel_id == hostel.hostel_id).count()
        booking_count = db.query(Booking).join(Room).filter(Room.hostel_id == hostel.hostel_id).count()
        
        result.append({
            "hostel_id": str(hostel.hostel_id),
            "name": hostel.name,
            "description": hostel.description,
            "address": hostel.address,
            "status": 'active' if hostel.is_active else 'inactive',
            "created_at": hostel.created_at.isoformat() if hostel.created_at else None,
            "landlord": {
                "name": f"{hostel.landlord.first_name} {hostel.landlord.last_name}",
                "email": hostel.landlord.email
            } if hostel.landlord else None,
            "room_count": room_count,
            "booking_count": booking_count,
            "media_count": len(hostel.media)
        })
    
    return {
        "total": total,
        "hostels": result
    }

@router.put("/hostels/{hostel_id}/status")
async def update_hostel_status(
    hostel_id: uuid.UUID,
    new_status: str,
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Update hostel status"""
    
    if new_status not in ['active', 'inactive', 'suspended']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid status. Must be 'active', 'inactive', or 'suspended'"
        )
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_id).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    hostel.is_active = (new_status == 'active')
    db.commit()
    
    return {"message": f"Hostel status updated to {new_status}"}

@router.get("/config")
async def get_system_config(
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get system configuration"""
    
    configs = db.query(Configuration).all()
    
    return {
        "configs": [
            {
                "config_key": config.config_key,
                "config_value": config.config_value,
                "description": config.description
            }
            for config in configs
        ]
    }

@router.put("/config/{config_key}")
async def update_system_config(
    config_key: str,
    value: float = Form(...),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Update system configuration"""
    
    config = db.query(Configuration).filter(Configuration.config_key == config_key).first()
    if not config:
        raise HTTPException(status_code=404, detail="Configuration not found")
    
    config.config_value = value
    db.commit()
    
    return {"message": f"Configuration {config_key} updated to {value}"}

@router.get("/user-details")
async def get_user_details(
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get current user details"""
    
    return {
        "user_id": str(current_user.user_id),
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "email": current_user.email,
        "phone_number": current_user.phone_number,
        "user_type": current_user.user_type,
        "is_verified": current_user.is_verified,
        "is_blacklisted": current_user.is_blacklisted,
        "university": current_user.university,
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        "updated_at": current_user.updated_at.isoformat() if current_user.updated_at else None
    }

# Verification endpoints
@router.get("/verifications")
async def get_all_verifications(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get all verifications with pagination and filtering"""
    
    query = (
        db.query(Verification)
        .options(joinedload(Verification.landlord))
    )
    
    if status:
        query = query.filter(Verification.status == status)
    
    total = query.count()
    verifications = query.order_by(Verification.updated_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for verification in verifications:
        result.append({
            "verification_id": str(verification.verification_id),
            "landlord_id": str(verification.landlord_id),
            "landlord_name": f"{verification.landlord.first_name} {verification.landlord.last_name}" if verification.landlord else None,
            "landlord_email": verification.landlord.email if verification.landlord else None,
            "landlord_phone": verification.landlord.phone_number if verification.landlord else None,
            "id_type": verification.id_type,
            "id_document_url": verification.id_document_url,
            "status": verification.status,
            "verified_at": verification.verified_at.isoformat() if verification.verified_at else None,
            "updated_at": verification.updated_at.isoformat() if verification.updated_at else None
        })
    
    return {
        "total": total,
        "verifications": result
    }

@router.put("/verifications/{verification_id}")
async def update_verification_status(
    verification_id: uuid.UUID,
    status: str = Form(...),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Update verification status (approve/reject)"""
    
    if status not in ['approved', 'rejected']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid status. Must be 'approved' or 'rejected'"
        )
    
    verification = db.query(Verification).filter(Verification.verification_id == verification_id).first()
    if not verification:
        raise HTTPException(status_code=404, detail="Verification not found")
    
    verification.status = status
    verification.verified_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Verification status updated successfully"}

@router.get("/disbursements")
async def get_disbursements(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get disbursement data for landlords with booking details and payment preferences"""
    
    # Get platform fee from configuration
    platform_fee_config = db.query(Configuration).filter(Configuration.config_key == 'platform_fee').first()
    platform_fee_amount = float(platform_fee_config.config_value) if platform_fee_config else 10.0
    
    # Query confirmed bookings that haven't been disbursed
    query = db.query(Booking).options(
        joinedload(Booking.student),
        joinedload(Booking.room).joinedload(Room.hostel).joinedload(Hostel.landlord),
        joinedload(Booking.disbursements)
    ).filter(Booking.status == 'confirmed')
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (Booking.room.has(Hostel.landlord.has(User.first_name.ilike(search_term)))) |
            (Booking.room.has(Hostel.landlord.has(User.last_name.ilike(search_term)))) |
            (Booking.room.has(Hostel.landlord.has(User.email.ilike(search_term))))
        )
    
    total = query.count()
    bookings = query.order_by(Booking.created_at.desc()).offset(skip).limit(limit).all()
    
    # Group bookings by landlord
    landlord_disbursements = {}
    for booking in bookings:
        landlord = booking.room.hostel.landlord
        landlord_id = str(landlord.user_id)
        
        # Calculate amounts
        booking_amount = float(booking.total_amount) if booking.total_amount else 0.0
        platform_fee = platform_fee_amount
        disbursement_amount = booking_amount - platform_fee
        
        if landlord_id not in landlord_disbursements:
            # Get landlord's payment preferences
            payment_preference = db.query(PaymentPreference).filter(
                PaymentPreference.user_id == landlord.user_id,
                PaymentPreference.is_preferred == True
            ).first()
            
            landlord_disbursements[landlord_id] = {
                "landlord_id": landlord_id,
                "landlord_name": f"{landlord.first_name} {landlord.last_name}",
                "landlord_email": landlord.email,
                "landlord_phone": landlord.phone_number,
                "total_bookings": 0,
                "total_amount": 0.0,
                "total_platform_fee": 0.0,
                "total_disbursement": 0.0,
                "payment_preference": {
                    "mobile_number": payment_preference.mobile_number if payment_preference else None,
                    "account_number": payment_preference.account_number if payment_preference else None,
                    "account_name": payment_preference.account_name if payment_preference else None,
                    "bank_name": payment_preference.bank_name if payment_preference else None
                },
                "bookings": []
            }
        
        landlord_disbursements[landlord_id]["total_bookings"] += 1
        landlord_disbursements[landlord_id]["total_amount"] += booking_amount
        landlord_disbursements[landlord_id]["total_platform_fee"] += platform_fee
        landlord_disbursements[landlord_id]["total_disbursement"] += disbursement_amount
        
        landlord_disbursements[landlord_id]["bookings"].append({
            "booking_id": str(booking.booking_id),
            "student_name": f"{booking.student.first_name} {booking.student.last_name}" if booking.student else "Unknown",
            "hostel_name": booking.room.hostel.name,
            "room_number": booking.room.room_number,
            "booking_amount": booking_amount,
            "platform_fee": platform_fee,
            "disbursement_amount": disbursement_amount,
            "booking_date": booking.created_at.isoformat() if booking.created_at else None,
            "disbursement_status": booking.disbursements[0].status if booking.disbursements and len(booking.disbursements) > 0 else "pending"
        })
    
    return {
        "total": total,
        "disbursements": list(landlord_disbursements.values()),
        "summary": {
            "total_landlords": len(landlord_disbursements),
            "total_bookings": len(bookings),
            "total_amount": sum(d["total_amount"] for d in landlord_disbursements.values()),
            "total_platform_fee": sum(d["total_platform_fee"] for d in landlord_disbursements.values()),
            "total_disbursement": sum(d["total_disbursement"] for d in landlord_disbursements.values())
        }
    }

@router.post("/disbursements/process")
async def process_disbursement(
    payload: DisbursementCreate = Body(...),
    is_batch: bool = False,
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Process an individual disbursement to a landlord using JSON payload."""

    booking_id = payload.booking_id
    landlord_id = payload.landlord_id
    amount = payload.disbursement_amount if hasattr(payload, 'disbursement_amount') and payload.disbursement_amount is not None else payload.amount

    # Get the booking
    booking = db.query(Booking).filter(Booking.booking_id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Get landlord
    landlord = db.query(User).filter(User.user_id == landlord_id, User.user_type == 'landlord').first()
    if not landlord:
        raise HTTPException(status_code=404, detail="Landlord not found")

    # Get payment preferences
    payment_preference = db.query(PaymentPreference).filter(
        PaymentPreference.user_id == landlord_id,
        PaymentPreference.is_preferred == True
    ).first()

    if not payment_preference:
        raise HTTPException(status_code=400, detail="Landlord has no payment preferences set")

    # Check if disbursement is already processed
    if booking.disbursements and len(booking.disbursements) > 0:
        existing_disbursement = booking.disbursements[0]
        if existing_disbursement.status == 'completed':
            raise HTTPException(status_code=400, detail="Disbursement already processed")

    try:
        # Get platform fee from configuration
        platform_fee_config = db.query(Configuration).filter(Configuration.config_key == 'platform_fee').first()
        platform_fee_amount = float(platform_fee_config.config_value) if platform_fee_config else 10.0
        print("Creating disbursement")
        # Create disbursement record in processing state
        disbursement = Disbursement(
            booking_id=booking_id,
            landlord_id=landlord_id,
            amount=float(booking.total_amount) if booking.total_amount else 0.0,
            platform_fee=platform_fee_amount,
            disbursement_amount=float(amount),
            status='processing',
            payment_reference=None,
            payment_method=payload.payment_method or ('mobile_money' if payment_preference.mobile_number else 'bank_transfer'),
            processed_at=None
        )
        db.add(disbursement)
        
        # Update booking status if needed
        if booking.status != 'confirmed':
            booking.status = 'confirmed'
        
        db.commit()
        db.refresh(disbursement)
        print("Disbursement created with ID:", disbursement.disbursement_id)
        # Determine transfer params (allow overrides from payload)
        bank_uuid = payload.bank_uuid or getattr(payment_preference, 'bank_uuid', None) or os.getenv('PAYCHANGU_DEFAULT_BANK_UUID')
        bank_account_number = payload.bank_account_number or payment_preference.account_number or payment_preference.mobile_number
        bank_account_name = payload.bank_account_name or payment_preference.account_name
        # Use account_name as the default mobile account name when mobile-specific name is not provided
        mobile_account_name = payload.mobile_account_name or payment_preference.account_name
        # Use account_name as the default mobile account name when mobile-specific name is not provided
        mobile_account_name = payload.mobile_account_name or payment_preference.account_name
        # Optional mobile operator reference id (fallback to env if not provided)
        mobile_money_operator_ref_id = payload.mobile_money_operator_ref_id or os.getenv('PAYCHANGU_MOBILE_OPERATOR_REF_ID')
        payment_method = payload.payment_method or disbursement.payment_method

        print("Executing disbursement via PayChangu")
        if not bank_uuid:
            db.rollback()
            raise HTTPException(status_code=400, detail="Missing bank_uuid for PayChangu transfer. Set PAYCHANGU_DEFAULT_BANK_UUID or provide bank_uuid in request.")

        try:
            print("Calling process_disbursement for disbursement ID:", disbursement.disbursement_id)
            # Execute live transfer (this will poll PayChangu and update the DB record)
            from paychangu_service import process_disbursement as execute_disbursement
            processed_disb = execute_disbursement(
                str(disbursement.disbursement_id),
                bank_uuid=bank_uuid,
                bank_account_number=str(bank_account_number) if bank_account_number is not None else None,
                bank_account_name=bank_account_name,
                mobile_number=payload.mobile_number or payment_preference.mobile_number,
                mobile_account_name=mobile_account_name,
                mobile_money_operator_ref_id=bank_uuid,
                payment_method=payment_method
            )

            payment_result = {
                "success": processed_disb.status == 'completed',
                "transaction_id": processed_disb.payment_reference,
                "amount": float(processed_disb.disbursement_amount),
                "status": processed_disb.status,
                "failure_reason": processed_disb.failure_reason,
                "landlord_name": f"{landlord.first_name} {landlord.last_name}",
                "payment_method": {
                    "mobile_number": payment_preference.mobile_number,
                    "bank_name": payment_preference.bank_name,
                    "account_name": payment_preference.account_name,
                },
                "processed_at": processed_disb.processed_at.isoformat() if processed_disb.processed_at else None,
                "message": "Disbursement completed" if processed_disb.status == 'completed' else "Transfer initiated; pending settlement"
            }

            return payment_result

        except Exception as e:
            print("Disbursement processing failed:", str(e))
            logger.exception("PayChangu transfer failed for disbursement=%s: %s", disbursement.disbursement_id, str(e))
            # process_disbursement already updated the DB to failed; refresh to return failure_reason
            db.refresh(disbursement)
            raise HTTPException(status_code=500, detail=f"Failed to process disbursement: {str(e)}")
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to process disbursement: {str(e)}")

@router.post("/disbursements/batch")
async def process_batch_disbursement(
    payload: BatchDisbursementCreate = Body(...),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Process batch disbursement for a landlord. Accepts JSON payload; if totals are omitted they will be computed."""

    landlord_id = payload.landlord_id
    total_amount = payload.total_amount
    total_bookings = payload.total_bookings

    # Get landlord
    landlord = db.query(User).filter(User.user_id == landlord_id, User.user_type == 'landlord').first()
    if not landlord:
        raise HTTPException(status_code=404, detail="Landlord not found")

    # Get payment preferences
    payment_preference = db.query(PaymentPreference).filter(
        PaymentPreference.user_id == landlord_id,
        PaymentPreference.is_preferred == True
    ).first()

    if not payment_preference:
        raise HTTPException(status_code=400, detail="Landlord has no payment preferences set")

    # Get all confirmed bookings for landlord
    bookings = db.query(Booking).options(
        joinedload(Booking.disbursements)
    ).join(Room).join(Hostel).filter(
        Hostel.landlord_id == landlord_id,
        Booking.status == 'confirmed'
    ).all()

    # Filter bookings that haven't been processed
    unprocessed_bookings = []
    for booking in bookings:
        if not booking.disbursements or len(booking.disbursements) == 0 or booking.disbursements[0].status != 'completed':
            unprocessed_bookings.append(booking)

    if len(unprocessed_bookings) == 0:
        raise HTTPException(status_code=400, detail="No pending disbursements found for this landlord")

    try:
        # If totals are not provided, compute them
        if total_amount is None:
            total_amount = sum(float(b.total_amount or 0.0) for b in unprocessed_bookings)
        if total_bookings is None:
            total_bookings = len(unprocessed_bookings)

        # Create disbursement records for all unprocessed bookings (initially processing)
        processed_disbursements = []
        for booking in unprocessed_bookings:
            # Calculate platform fee and disbursement amount
            platform_fee_config = db.query(Configuration).filter(Configuration.config_key == 'platform_fee').first()
            platform_fee_amount = float(platform_fee_config.config_value) if platform_fee_config else 10.0

            booking_amount = float(booking.total_amount) if booking.total_amount else 0.0
            platform_fee = platform_fee_amount
            disbursement_amount = booking_amount - platform_fee

            # Determine payment method based on payment preference
            if payment_preference.mobile_number:
                payment_method = 'mobile_money'
            elif payment_preference.account_number:
                payment_method = 'bank_transfer'
            else:
                payment_method = 'bank_transfer'  # fallback

            disbursement = Disbursement(
                booking_id=booking.booking_id,
                landlord_id=landlord_id,
                amount=booking_amount,
                platform_fee=platform_fee,
                disbursement_amount=disbursement_amount,
                status='processing',
                payment_reference=None,
                payment_method=payment_method,
                processed_at=None
            )
            db.add(disbursement)
            processed_disbursements.append(disbursement)

        db.commit()

        # Execute transfers sequentially (will poll each until settled or failed)
        results = []        # Prefer any stored bank_uuid on the landlord's payment preference, fall back to env default
        bank_uuid = payload.bank_uuid or getattr(payment_preference, 'bank_uuid', None) or os.getenv('PAYCHANGU_DEFAULT_BANK_UUID')
        if not bank_uuid:
            logger.error("Missing bank_uuid for batch disbursement: neither payment preference nor PAYCHANGU_DEFAULT_BANK_UUID is set for landlord=%s", landlord_id)
            raise HTTPException(status_code=400, detail="Missing bank UUID for batch disbursements. Set PAYCHANGU_DEFAULT_BANK_UUID or save a bank_uuid in the landlord's payment preferences.")

        for disbursement in processed_disbursements:
            try:
                from paychangu_service import process_disbursement as execute_disbursement
                processed = execute_disbursement(
                    str(disbursement.disbursement_id),
                    bank_uuid=bank_uuid,
                    bank_account_number=payment_preference.account_number or payment_preference.mobile_number,
                    bank_account_name=payment_preference.account_name,
                    mobile_account_name=payment_preference.account_name,
                    mobile_money_operator_ref_id=os.getenv('PAYCHANGU_MOBILE_OPERATOR_REF_ID'),
                    payment_method=disbursement.payment_method
                )
                db.refresh(processed)
                results.append({
                    "booking_id": str(processed.booking_id),
                    "amount": float(processed.disbursement_amount),
                    "transaction_id": processed.payment_reference,
                    "status": processed.status,
                    "failure_reason": processed.failure_reason
                })
            except Exception as e:
                db.refresh(disbursement)
                results.append({
                    "booking_id": str(disbursement.booking_id),
                    "amount": float(disbursement.disbursement_amount),
                    "transaction_id": disbursement.payment_reference,
                    "status": disbursement.status,
                    "failure_reason": disbursement.failure_reason or str(e)
                })

        # Build batch result summary
        all_completed = all(r["status"] == 'completed' for r in results)
        batch_result = {
            "success": all_completed,
            "batch_reference": f"BATCH_DISB_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}",
            "total_amount": float(total_amount),
            "total_bookings": int(total_bookings),
            "landlord_name": f"{landlord.first_name} {landlord.last_name}",
            "payment_method": {
                "mobile_number": payment_preference.mobile_number,
                "bank_name": payment_preference.bank_name,
                "account_name": payment_preference.account_name
            },
            "processed_bookings": results,
            "processed_at": datetime.utcnow().isoformat(),
            "message": f"Batch disbursement processed: {len(results)} transactions. " + ("All completed" if all_completed else "Some pending/failed")
        }

        return batch_result

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to process batch disbursement: {str(e)}")

@router.get("/recent-activity")
async def get_recent_activity(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get recent platform activity for admin dashboard"""
    
    activities = []
    
    # Get recent user registrations
    recent_users = db.query(User).order_by(User.created_at.desc()).limit(5).all()
    for user in recent_users:
        activities.append({
            "id": str(user.user_id),
            "type": "user_registration",
            "title": f"New {user.user_type} registration",
            "description": f"{user.first_name} {user.last_name} - {user.user_type.title()}",
            "timestamp": user.created_at.isoformat(),
            "icon": "user-plus",
            "color": "green"
        })
    
    # Get recent bookings
    recent_bookings = db.query(Booking).order_by(Booking.created_at.desc()).limit(5).all()
    for booking in recent_bookings:
        activities.append({
            "id": str(booking.booking_id),
            "type": "booking",
            "title": f"Booking {booking.status}",
            "description": f"Room {booking.room.room_number} - {booking.room.hostel.name}",
            "timestamp": booking.created_at.isoformat(),
            "icon": "calendar-check",
            "color": "blue"
        })
    
    # Get recent payments
    recent_payments = db.query(Payment).order_by(Payment.created_at.desc()).limit(5).all()
    for payment in recent_payments:
        activities.append({
            "id": str(payment.payment_id),
            "type": "payment",
            "title": f"Payment {payment.status}",
            "description": f"MWK {payment.amount} - {payment.payment_type}",
            "timestamp": payment.created_at.isoformat(),
            "icon": "money-bill-wave",
            "color": "purple"
        })
    
    # Get recent hostels
    recent_hostels = db.query(Hostel).order_by(Hostel.created_at.desc()).limit(3).all()
    for hostel in recent_hostels:
        activities.append({
            "id": str(hostel.hostel_id),
            "type": "hostel",
            "title": "New hostel added",
            "description": f"{hostel.name} - {hostel.location}",
            "timestamp": hostel.created_at.isoformat(),
            "icon": "building",
            "color": "yellow"
        })
    
    # Sort all activities by timestamp
    activities.sort(key=lambda x: x["timestamp"], reverse=True)
    
    return {
        "activities": activities[:limit],
        "total": len(activities)
    }

@router.get("/recent-signups")
async def get_recent_signups(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(require_admin_user),
    db: Session = Depends(get_db)
):
    """Get recent user signups for admin dashboard"""
    
    recent_signups = db.query(User).order_by(User.created_at.desc()).limit(limit).all()
    
    signups_data = []
    for user in recent_signups:
        signups_data.append({
            "user_id": str(user.user_id),
            "first_name": user.first_name,
            "last_name": user.last_name,
            "email": user.email,
            "phone": user.phone_number,
            "user_type": user.user_type,
            "status": user.status,
            "created_at": user.created_at.isoformat(),
            "is_verified": user.is_verified,
            "is_blacklisted": user.is_blacklisted
        })
    
    return {
        "signups": signups_data,
        "total": len(signups_data)
    }
