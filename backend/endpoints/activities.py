from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlalchemy.orm import Session, joinedload
from datetime import datetime, timedelta
import uuid

from database import get_db
from models import User, Notification, Booking, Payment, Message, Hostel, Room
from endpoints.users import get_current_user

router = APIRouter(prefix="/api/activities", tags=["activities"])

@router.get("", response_model=List[dict])
async def get_recent_activities(
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get recent activities for the current user by aggregating data from multiple tables.
    """
    try:
        activities = []
        
        # 1. Get hostels owned by the landlord with a separate query
        hostels = db.query(Hostel).filter(
            Hostel.landlord_id == current_user.user_id
        ).all()
        
        hostel_ids = [h.hostel_id for h in hostels]
        
        if not hostel_ids:
            return []
            
        # 2. Get recent bookings for these hostels with proper eager loading
        bookings = (
            db.query(Booking)
            .join(Room)
            .options(
                joinedload(Booking.student).load_only(User.first_name, User.last_name),
                joinedload(Booking.room).load_only(Room.room_number, Room.hostel_id)
            )
            .filter(Room.hostel_id.in_(hostel_ids))
            .order_by(Booking.created_at.desc())
            .limit(limit)
            .all()
        )
        
        # Process bookings
        for booking in bookings:
            student_name = f"{booking.student.first_name} {booking.student.last_name}" if booking.student else "A student"
            activities.append({
                "id": str(booking.booking_id),
                "type": "booking",
                "title": f"New Booking for Room {booking.room.room_number if booking.room else 'Unknown'}",
                "description": f"{student_name} booked room {booking.room.room_number if booking.room else 'Unknown'}",
                "timestamp": booking.created_at,
                "is_read": False,
                "metadata": {
                    "status": booking.status,
                    "room_id": str(booking.room.room_id) if booking.room else None,
                    "hostel_id": str(booking.room.hostel_id) if booking.room and hasattr(booking.room, 'hostel_id') else None,
                    "start_date": booking.start_date.isoformat() if booking.start_date else None,
                    "end_date": booking.end_date.isoformat() if booking.end_date else None
                }
            })
        
        # 3. Get recent payments for these bookings with proper eager loading
        payments = (
            db.query(Payment)
            .join(Booking)
            .join(Room)
            .options(
                joinedload(Payment.booking).joinedload(Booking.room)
            )
            .filter(Room.hostel_id.in_(hostel_ids))
            .order_by(Payment.paid_at.desc().nulls_last())  # Use paid_at with nulls last
            .limit(limit)
            .all()
        )
        
        for payment in payments:
            activities.append({
                "id": f"payment_{payment.payment_id}",
                "type": "payment",
                "title": f"Payment Received - MWK {payment.amount:.2f}",
                "description": f"Payment for Room {payment.booking.room.room_number if payment.booking.room else 'Unknown'} at {payment.booking.room.hostel.name if payment.booking.room and payment.booking.room.hostel else 'Unknown Hostel'}",
                "timestamp": payment.paid_at or payment.booking.created_at,  # Fallback to booking created_at
                "is_read": False,
                "metadata": {
                    "status": payment.status,
                    "amount": float(payment.amount),
                    "booking_id": str(payment.booking_id),
                    "payment_method": payment.payment_method
                }
            })
        
        # 4. Get messages with proper eager loading
        messages = (
            db.query(Message)
            .options(
                joinedload(Message.sender).load_only(User.first_name)
            )
            .filter(Message.receiver_id == current_user.user_id)
            .order_by(Message.created_at.desc())
            .limit(limit)
            .all()
        )
        
        for msg in messages:
            activities.append({
                "id": f"message_{msg.message_id}",
                "type": "message",
                "title": f"New message from {msg.sender.first_name if msg.sender else 'User'}",
                "description": msg.content[:100] + ('...' if len(msg.content) > 100 else ''),
                "timestamp": msg.created_at,
                "is_read": msg.is_read,
                "metadata": {
                    "sender_id": str(msg.sender_id),
                    "receiver_id": str(msg.receiver_id),
                    "conversation_id": str(msg.conversation_id)
                }
            })
        
        # 5. Get notifications
        notifications = (
            db.query(Notification)
            .filter(Notification.user_id == current_user.user_id)
            .order_by(Notification.created_at.desc())
            .limit(limit)
            .all()
        )
        
        for notif in notifications:
            activities.append({
                "id": f"notif_{notif.notification_id}",
                "type": notif.type or "notification",
                "title": notif.title or "Notification",
                "description": notif.body or "",
                "timestamp": notif.created_at,
                "is_read": notif.is_read,
                "metadata": notif.data or {}
            })
        
        # Sort all activities by timestamp (newest first) and limit
        activities.sort(key=lambda x: x["timestamp"], reverse=True)
        return activities[:limit]
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching activities: {str(e)}"
        )

@router.post("/{activity_id}/mark-read", status_code=status.HTTP_200_OK)
async def mark_activity_as_read(
    activity_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark a specific activity as read.
    Handles different activity types (notification, message, etc.)
    """
    try:
        # Handle notification activities
        if activity_id.startswith("notif_"):
            notif_id = activity_id.replace("notif_", "")
            notification = db.query(Notification).filter(
                (Notification.notification_id == notif_id) &
                (Notification.user_id == current_user.user_id)
            ).first()
            
            if notification and not notification.is_read:
                notification.is_read = True
                db.commit()
                return {"message": "Notification marked as read"}
        
        # Handle message activities
        elif activity_id.startswith("message_"):
            message_id = activity_id.replace("message_", "")
            message = db.query(Message).filter(
                (Message.message_id == message_id) &
                (Message.receiver_id == current_user.user_id)
            ).first()
            
            if message and not message.is_read:
                message.is_read = True
                db.commit()
                return {"message": "Message marked as read"}
        
        return {"message": "Activity not found or already marked as read"}
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error marking activity as read: {str(e)}"
        )