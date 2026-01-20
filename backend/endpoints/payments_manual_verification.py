from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from fastapi.responses import JSONResponse
from datetime import datetime, date
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from database import get_db
from models import Payment as PaymentModel, Booking as BookingModel, Room, Hostel, User
from endpoints.config import get_platform_fee
from email_service import email_service
from dateutil.relativedelta import relativedelta
import asyncio

# Pydantic models for request validation
class ManualVerifyExtensionRequest(BaseModel):
    payment_id: str = Field(..., description="Payment ID to verify")
    new_end_date: date = Field(..., description="New checkout date for the booking")

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/manual-verify-extension/")
async def manual_verify_extension(
    request: ManualVerifyExtensionRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Manually verify extension payment when automatic verification fails.
    
    This endpoint allows admins to verify extension payments that failed
    automatic verification due to server downtime or connectivity issues.
    """
    try:
        # Get payment record
        payment = db.query(PaymentModel).filter(
            PaymentModel.payment_id == request.payment_id
        ).first()
        
        if not payment:
            raise HTTPException(
                status_code=404, 
                detail="Payment not found"
            )
        
        # Verify this is an extension payment
        if payment.payment_type != "extension":
            raise HTTPException(
                status_code=400,
                detail="This endpoint only handles extension payments"
            )
        
        # Check if payment is already completed
        if payment.status == 'completed':
            return {
                "status": "already_completed",
                "message": "Payment has already been verified",
                "payment_id": str(payment.payment_id)
            }
        
        # Get associated booking
        booking = db.query(BookingModel).filter(
            BookingModel.booking_id == payment.booking_id
        ).first()
        
        if not booking:
            raise HTTPException(
                status_code=404,
                detail="Associated booking not found"
            )
        
        # Get room and student info for email
        room = db.query(Room).filter(Room.room_id == booking.room_id).first()
        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
        student = db.query(User).filter(User.user_id == booking.student_id).first()
        
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        
        # Update booking
        booking.status = 'confirmed'
        booking.end_date = request.new_end_date
        
        # Update total amount to include extension payment
        previous_payments = db.query(PaymentModel).filter(
            PaymentModel.booking_id == booking.booking_id,
            PaymentModel.status == 'completed'
        ).all()
        
        previous_total = sum(p.amount for p in previous_payments)
        new_total_amount = previous_total + payment.amount
        booking.total_amount = float(new_total_amount)
        
        # Note: Extension payments do NOT update room occupancy
        # since student is already occupying the room
        # Only extending their stay duration
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
            print(f"Manual verification successful: Payment {payment.payment_id}, New total: {new_total_amount}")
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail=f"Database update failed: {e}"
            )
        
        # Prepare extension data for email
        extension_data = {
            'booking_id': str(booking.booking_id),
            'student_first_name': student.first_name if student else 'N/A',
            'student_last_name': student.last_name if student else 'N/A',
            'student_email': student.email if student else 'N/A',
            'hostel_name': hostel.name if hostel else 'N/A',
            'room_number': room.room_number if room else 'N/A',
            'room_type': room.type if room else 'N/A',
            'extension_payment_id': str(payment.payment_id),
            'payment_date': payment.paid_at.strftime("%B %d, %Y") if payment.paid_at else "Payment Processing",
            'previous_checkout_date': payment.meta.get("original_end_date", "N/A") if payment.meta else 'N/A',
            'new_checkout_date': request.new_end_date.strftime("%B %d, %Y"),
            'monthly_rent': str(room.price_per_month) if room else 'N/A',
            'platform_fee': str(get_platform_fee(db)),
            'extension_amount': str(payment.amount),
            'new_total_amount': str(new_total_amount),
            'payment_method': payment.payment_method,
            'transaction_id': payment.transaction_id or 'N/A',
        }
        
        # Send extension confirmation email in background
        if student and student.email:
            background_tasks.add_task(
                email_service.send_booking_extension_email,
                email=student.email,
                first_name=student.first_name,
                booking_data=extension_data
            )
        
        return {
            "status": "success",
            "message": "Extension manually verified successfully",
            "payment_id": str(payment.payment_id),
            "booking_id": str(booking.booking_id),
            "new_end_date": request.new_end_date.isoformat(),
            "new_total_amount": float(new_total_amount),
            "previous_total": float(previous_total),
            "extension_amount": float(payment.amount)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Manual verification failed: {e}"
        )


@router.get("/pending-extensions/")
async def get_pending_extensions(db: Session = Depends(get_db)):
    """
    Get all pending extension payments for admin review.
    
    This helps admins identify payments that failed automatic verification
    and need manual intervention.
    """
    try:
        # Get all pending extension payments older than 1 hour
        from datetime import timedelta
        one_hour_ago = datetime.utcnow() - timedelta(hours=1)
        
        pending_payments = db.query(PaymentModel).filter(
            PaymentModel.payment_type == "extension",
            PaymentModel.status == "pending",
            PaymentModel.created_at >= one_hour_ago  # Note: You may need to add created_at field
        ).all()
        
        # If created_at doesn't exist, use paid_at filter
        if not pending_payments:
            pending_payments = db.query(PaymentModel).filter(
                PaymentModel.payment_type == "extension",
                PaymentModel.status == "pending"
            ).all()
        
        result = []
        for payment in pending_payments:
            booking = db.query(BookingModel).filter(
                BookingModel.booking_id == payment.booking_id
            ).first()
            
            result.append({
                "payment_id": str(payment.payment_id),
                "booking_id": str(payment.booking_id),
                "amount": float(payment.amount),
                "payment_method": payment.payment_method,
                "transaction_id": payment.transaction_id,
                "booking_status": booking.status if booking else "Not found",
                "student_email": booking.student.email if booking else "N/A",
                "room_number": booking.room.room_number if booking and booking.room else "N/A",
                "hostel_name": booking.room.hostel.name if booking and booking.room and booking.room.hostel else "N/A",
                "created_at": payment.created_at.isoformat() if hasattr(payment, 'created_at') else "Unknown",
            })
        
        return {
            "status": "success",
            "pending_extensions": result,
            "count": len(result)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch pending extensions: {e}"
        )
