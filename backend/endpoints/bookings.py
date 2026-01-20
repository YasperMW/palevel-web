from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import text, exists
from database import get_db, db_session
from models import Booking as BookingModel, Payment, Room, Hostel, User, Configuration
from endpoints.users import get_current_user, require_landlord
from endpoints.config import get_platform_fee
from endpoints.notifications import send_notification_to_users
from datetime import datetime, date
from decimal import Decimal
from dateutil.relativedelta import relativedelta
import uuid
import os
import logging
import json
from email_service import email_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/bookings", tags=["bookings"])




# Background task function for sending booking notifications
async def _send_booking_notifications(
    booking_id: str,
    room_id: str,
    hostel_id: str,
    student_id: str,
    landlord_id: uuid.UUID | None,
    room_number: str,
    hostel_name: str,
    student_name: str
):
    """Background task to send booking notifications"""
    with db_session() as db:
        try:
            import uuid as uuid_module
            student_uuid = uuid_module.UUID(student_id)
            
            # Notify student about booking submission
            await send_notification_to_users(
                db=db,
                user_ids=[student_uuid],
                title="Booking Submitted",
                body=f"Your booking request for Room {room_number} at {hostel_name} has been submitted and is pending approval.",
                notification_type="booking",
                data={
                    "booking_id": booking_id,
                    "room_id": room_id,
                    "hostel_id": hostel_id,
                    "status": "pending"
                }
            )
            
            # Notify landlord about new booking request
            if landlord_id:
                await send_notification_to_users(
                    db=db,
                    user_ids=[landlord_id],
                    title="New Booking Request",
                    body=f"New booking request from {student_name} for Room {room_number} at {hostel_name}.",
                    notification_type="booking",
                    data={
                        "booking_id": booking_id,
                        "room_id": room_id,
                        "hostel_id": hostel_id,
                        "student_id": student_id,
                        "status": "pending"
                    }
                )
        except Exception as e:
            print(f"Error sending booking notifications: {e}")


# Background task function for sending approval notification
async def _send_approval_notification(
    booking_id: str,
    room_id: str,
    student_id: uuid.UUID,
    room_number: str,
    hostel_name: str
):
    """Background task to send booking approval notification"""
    try:
        with db_session() as db:
            # Get full booking details for email
            booking = (
                db.query(BookingModel)
                .options(
                    joinedload(BookingModel.student),
                    joinedload(BookingModel.room)
                    .joinedload(Room.hostel)
                    .joinedload(Hostel.landlord),
                    joinedload(BookingModel.payments)
                )
                .filter(BookingModel.booking_id == uuid.UUID(booking_id))
                .first()
            )
            
            if booking:
                # Use stored booking duration for email receipt
                duration_months = booking.duration_months
                
                platform_fee = get_platform_fee(db)
                
                booking_data = {
                    'booking_id': str(booking.booking_id),
                    'student_name': f"{booking.student.first_name} {booking.student.last_name}",
                    'student_email': booking.student.email,
                    'student_phone': booking.student.phone_number or 'N/A',
                    'student_university': booking.student.university or 'N/A',
                    'hostel_name': booking.room.hostel.name,
                    'room_number': booking.room.room_number,
                    'room_type': booking.room.type or 'Standard',
                    'hostel_address': booking.room.hostel.address or 'N/A',
                    'landlord_name': f"{booking.room.hostel.landlord.first_name} {booking.room.hostel.landlord.last_name}",
                    'check_in': booking.start_date.strftime("%B %d, %Y"),
                    'check_out': booking.end_date.strftime("%B %d, %Y"),
                    'payment_type': booking.payment_type,
                    'payment_type_display': 'Full Payment' if booking.payment_type == 'full' else 'Booking Fee',
                    'monthly_rent': float(booking.room.price_per_month),
                    'duration_months': duration_months,
                    'platform_fee': float(platform_fee),
                    'total_amount': float(booking.total_amount),
                }
                
                # Add payment details if available
                if booking.payments:
                    latest_payment = sorted(booking.payments, key=lambda p: p.paid_at or datetime.min, reverse=True)[0]
                    booking_data.update({
                        'payment_method': latest_payment.payment_method,
                        'transaction_id': latest_payment.transaction_id,
                        'payment_date': latest_payment.paid_at.strftime("%B %d, %Y") if latest_payment.paid_at else 'N/A',
                    })
                
                # Send booking confirmation email with PDF
                from email_service import email_service
                await email_service.send_booking_confirmation_email(
                    email=booking.student.email,
                    first_name=booking.student.first_name,
                    booking_data=booking_data
                )
            
            # Send in-app notification
            await send_notification_to_users(
                db=db,
                user_ids=[student_id],
                title="Booking Approved",
                body=f"Your booking for Room {room_number} at {hostel_name} has been approved! Check your email for receipt.",
                notification_type="booking",
                data={
                    "booking_id": booking_id,
                    "room_id": room_id,
                    "status": "confirmed"
                }
            )
    except Exception as e:
        print(f"Error sending approval notification: {e}")


# Background task function for sending rejection notification
async def _send_rejection_notification(
    booking_id: str,
    room_id: str,
    student_id: uuid.UUID,
    room_number: str,
    hostel_name: str
):
    """Background task to send booking rejection notification"""
    try:
        with db_session() as db:
            await send_notification_to_users(
                db=db,
                user_ids=[student_id],
                title="Booking Rejected",
                body=f"Your booking request for Room {room_number} at {hostel_name} has been rejected.",
                notification_type="booking",
                data={
                    "booking_id": booking_id,
                    "room_id": room_id,
                    "status": "rejected"
                }
            )
    except Exception as e:
        print(f"Error sending rejection notification: {e}")


# Background task function for sending extension notification
async def _send_extension_notification(
    booking_id: str,
    extension_payment_id: str,
    additional_months: int,
    student_id: uuid.UUID,
    landlord_id: uuid.UUID | None,
    room_number: str,
    hostel_name: str,
    student_name: str,
    new_end_date: str
):
    """Background task to send booking extension notification"""
    try:
        with db_session() as db:
            # Notify student about extension initiation
            await send_notification_to_users(
                db=db,
                user_ids=[student_id],
                title="Booking Extension Initiated",
                body=f"Your booking for Room {room_number} at {hostel_name} has been extended by {additional_months} month(s). Please complete the payment to confirm.",
                notification_type="booking",
                data={
                    "booking_id": booking_id,
                    "extension_payment_id": extension_payment_id,
                    "additional_months": additional_months,
                    "new_end_date": new_end_date,
                    "status": "extension_pending"
                }
            )
            
            # Notify landlord about extension request
            if landlord_id:
                await send_notification_to_users(
                    db=db,
                    user_ids=[landlord_id],
                    title="Booking Extension Request",
                    body=f"{student_name} has requested to extend their booking for Room {room_number} at {hostel_name} by {additional_months} month(s).",
                    notification_type="booking",
                    data={
                        "booking_id": booking_id,
                        "student_id": str(student_id),
                        "additional_months": additional_months,
                        "new_end_date": new_end_date,
                        "status": "extension_pending"
                    }
                )
    except Exception as e:
        print(f"Error sending extension notification: {e}")


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_booking(
    payload: dict, 
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    print("\n=== New Booking Request ===")
    print(f"Request from user: {current_user.email} (ID: {current_user.user_id})")
    print(f"Request payload: {json.dumps(payload, indent=2, default=str)}")
    
    room_id = payload.get("room_id")
    check_in = payload.get("check_in_date")
    duration_months = payload.get("duration_months")  # Accept duration from frontend
    payment_type = payload.get("payment_type", "full")  # 'full' or 'booking_fee'
    payment_method = payload.get("payment_method")
    amount = payload.get("amount")


    print(f"\nProcessing booking with:")
    print(f"- Room ID: {room_id}")
    print(f"- Check-in: {check_in}")
    print(f"- Duration (months): {duration_months}")
    print(f"- Payment Type: {payment_type}")
    print(f"- Payment Method: {payment_method}")
    print(f"- Amount from client: {amount}")

    if not all([room_id, check_in, payment_method, duration_months]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incomplete booking information. duration_months is required.")
    
    # Validate and convert duration_months
    try:
        duration_months = int(duration_months)
        if duration_months <= 0:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="duration_months must be a positive integer")
    except (ValueError, TypeError):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid duration_months format")

    # Calculate end_date based on provided duration
    start_date = datetime.fromisoformat(check_in).date()
    delta = relativedelta(months=duration_months)
    end_date = start_date + delta
    
    print(f"\nUsing duration: {duration_months} months")
    print(f"\nPayment type: {payment_type}")
    if payment_type not in ["full", "booking_fee"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment_type. Must be 'full' or 'booking_fee'"
        )
    # Get room details
    room = db.query(Room).filter(Room.room_id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # Get platform fee from configuration
    platform_fee = get_platform_fee(db)
    
    # Calculate amount based on payment type
    if payment_type == "booking_fee":
        # Get the hostel to access its booking fee
        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
        if not hostel:
            raise HTTPException(status_code=404, detail="Hostel not found")
        
        # Use booking fee from hostel (should always be set in database)
        if hostel.booking_fee is not None:
            booking_fee = hostel.booking_fee
            print(f"Booking Creation: Using hostel booking fee from database: {booking_fee}")
        else:
            raise HTTPException(
                status_code=400, 
                detail="Hostel booking fee not configured. Please contact the landlord to set the booking fee."
            )
        # Convert platform_fee to Decimal for consistent arithmetic

        
        platform_fee_decimal = Decimal(str(platform_fee))
        total_amount = float(booking_fee + platform_fee_decimal)
        payment_description = f"Booking fee for Room {room.room_number} at {hostel.name}"
    else:  # full payment
        # Convert platform_fee to Decimal and calculate total
        platform_fee_decimal = Decimal(str(platform_fee))
        total_amount = float((room.price_per_month * Decimal(duration_months)) + platform_fee_decimal)
        payment_description = f"Full payment for {duration_months} months at Room {room.room_number}, {room.hostel.name}"
    
   
    
    try:
        # Create booking
        booking = BookingModel(
            student_id=current_user.user_id,
            room_id=room_id,
            start_date=start_date,
            end_date=end_date,
            duration_months=duration_months,  # Store calculated duration
            status="pending",
            total_amount=total_amount,
            payment_type=payment_type  # Store the payment type
        )
        db.add(booking)
        db.flush()
        
        # Create payment record
        payment = Payment(
            booking_id=booking.booking_id,
            amount=total_amount,
            payment_method=payment_method,
            status="pending",
            payment_type=payment_type
        )
        db.add(payment)

        db.commit()
        db.refresh(booking)
        
        # Get hostel and landlord information for notifications
        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
        landlord_id = hostel.landlord_id if hostel else None
        
        # Prepare notification data for background task
        booking_id_str = str(booking.booking_id)
        room_id_str = str(room.room_id)
        hostel_id_str = str(room.hostel_id) if room.hostel_id else None
        student_id_str = str(current_user.user_id)
        room_number = room.room_number
        hostel_name = hostel.name if hostel else 'the property'
        student_name = f"{current_user.first_name} {current_user.last_name}"
        
        # Send notifications in background (don't block the response)
        background_tasks.add_task(
            _send_booking_notifications,
            booking_id_str,
            room_id_str,
            hostel_id_str,
            student_id_str,
            landlord_id,
            room_number,
            hostel_name,
            student_name
        )
        
        response_content = {
    "booking_id": str(booking.booking_id),
    "student_id": str(booking.student_id),
    "room_id": str(booking.room_id),
    "start_date": booking.start_date.isoformat(),
    "end_date": booking.end_date.isoformat(),
    "status": booking.status,
    "payment_type": booking.payment_type,
    "amount_breakdown": {
        "room_fee": float(total_amount - platform_fee) if payment_type == "booking_fee" else float(room.price_per_month * Decimal(duration_months)),
        "platform_fee": float(platform_fee),
        "total_amount": float(total_amount)
    },
    "currency": "MWK",
    "created_at": booking.created_at.isoformat() if booking.created_at else None,
    }
        return JSONResponse(status_code=status.HTTP_201_CREATED, content=response_content)

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to create booking: {e}")

@router.get("/my-bookings/", response_model=list[dict])
def get_user_bookings(
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db),
    include_payment_details: bool = Query(False)
):
    """Retrieve all bookings for the currently authenticated user."""
    
    query = (
        db.query(BookingModel)
        .options(
            joinedload(BookingModel.room)
            .joinedload(Room.hostel)
            .options(
                joinedload(Hostel.landlord),
                joinedload(Hostel.media)
            ),
            joinedload(BookingModel.room)
            .joinedload(Room.media)
        )
    )

    if include_payment_details:
        query = query.options(joinedload(BookingModel.payments))

    bookings = (
        query
        .filter(BookingModel.student_id == current_user.user_id)
        .filter(BookingModel.status != 'payment_failed')
        .order_by(BookingModel.created_at.desc())
        .all()
    )

    if not bookings:
        return []
  
    result = []
    for b in bookings: 
        # Use stored duration_months from database instead of calculating
        duration_months = b.duration_months if b.duration_months else 0
        
        booking_dict = {
            "booking_id": str(b.booking_id),
            "status": b.status,
            "payment_type": b.payment_type,
            "total_amount": float(b.total_amount),
            "base_room_price": float(b.room.price_per_month) if b.room else None,
            "check_in_date": b.start_date.isoformat(),
            "check_out_date": b.end_date.isoformat(),
            "created_at": b.created_at.isoformat(),
            "platform_fee": float(db.query(Configuration.config_value)
                     .filter(Configuration.config_key == "platform_fee")
                     .scalar() or 0),
            "duration_months": duration_months,
            "room": {
                "room_id": str(b.room.room_id),
                "room_number": b.room.room_number,
                "room_type": b.room.type,
                "media": [{"url": m.url} for m in b.room.media],
                "hostel": {
                    "name": b.room.hostel.name,
                    "landlord": {
                        "first_name": b.room.hostel.landlord.first_name,
                        "last_name": b.room.hostel.landlord.last_name,
                    },
                    "media": [{"url": m.url} for m in b.room.hostel.media]
                },
            },
        }

        if include_payment_details and b.payments:
            # Filter out payments with null paid_at and sort by paid_at
            payments_with_paid_at = [p for p in b.payments if p.paid_at is not None]
            if payments_with_paid_at:
                latest_payment = sorted(payments_with_paid_at, key=lambda p: p.paid_at, reverse=True)[0]
                booking_dict["payment_method"] = latest_payment.payment_method
                booking_dict["transaction_id"] = latest_payment.transaction_id

        result.append(booking_dict)
        
    return JSONResponse(content=result)


@router.get("/landlord/", response_model=list[dict])
def get_landlord_bookings(current_user: User = Depends(require_landlord), db: Session = Depends(get_db)):
    """Retrieve all bookings for the hostels managed by the currently authenticated landlord."""

    bookings = (
        db.query(BookingModel)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .join(User, BookingModel.student_id == User.user_id)
        .filter(Hostel.landlord_id == current_user.user_id)
        .options(
            joinedload(BookingModel.student),
            joinedload(BookingModel.room).joinedload(Room.hostel),
        )
        .order_by(BookingModel.created_at.desc())
        .all()
    )

    if not bookings:
        return []

    result = [
        {
            "id": str(b.booking_id),
            "propertyName": b.room.hostel.name,
            "roomNumber": b.room.room_number,
            "studentName": f"{b.student.first_name} {b.student.last_name}",
            "studentEmail": b.student.email,
            "checkInDate": b.start_date.isoformat(),
            "checkOutDate": b.end_date.isoformat(),
            "monthlyRent": float(b.total_amount), 
            "status": b.status,
        }
        for b in bookings
    ]

    return JSONResponse(content=result)


@router.get("/landlord/reports/", response_model=dict)
def get_landlord_reports(
    current_user: User = Depends(require_landlord), 
    db: Session = Depends(get_db)
):
    """
    Get comprehensive reports for landlord including all bookings and payments
    with payment due dates for all hostels managed by the landlord.
    """
    from sqlalchemy import func, case
    
    # Get all bookings for landlord's hostels with payment details
    bookings = (
        db.query(BookingModel)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .join(User, BookingModel.student_id == User.user_id)
        .filter(Hostel.landlord_id == current_user.user_id)
        .options(
            joinedload(BookingModel.student),
            joinedload(BookingModel.room).joinedload(Room.hostel),
            joinedload(BookingModel.payments),
        )
        .order_by(BookingModel.created_at.desc())
        .all()
    )
    
    # Get all payments for landlord's hostels
    payments = (
        db.query(Payment)
        .join(BookingModel, Payment.booking_id == BookingModel.booking_id)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .filter(Hostel.landlord_id == current_user.user_id)
        .options(
            joinedload(Payment.booking).joinedload(BookingModel.student),
            joinedload(Payment.booking).joinedload(BookingModel.room).joinedload(Room.hostel),
        )
        .order_by(Payment.paid_at.desc().nulls_last(), Payment.payment_id.desc())
        .all()
    )
    
    # Get all disbursements for landlord
    from models import Disbursement
    disbursements = (
        db.query(Disbursement)
        .filter(Disbursement.landlord_id == current_user.user_id)
        .filter(Disbursement.status == 'completed')
        .all()
    )
    
    # Process bookings with payment due dates
    bookings_data = []
    total_revenue = Decimal('0.0')
    total_pending = Decimal('0.0')
    total_paid = Decimal('0.0')
    total_disbursed = Decimal('0.0')
    
    for booking in bookings:
        # Use room's price_per_month as monthly rent
        monthly_rent = booking.room.price_per_month
        
        # Get all payments for this booking
        booking_payments = [p for p in payments if p.booking_id == booking.booking_id]
        paid_amount = sum(p.amount for p in booking_payments if p.status == 'completed')
        
        # Calculate next payment due date
        next_payment_due = None
        next_payment_amount = None
        payment_due_explanation = None
        
        if booking.status in ['confirmed', 'active']:
            # Calculate next payment due date within booking period
            today = date.today()
            
            # Debug logging
            logger.info(f"Booking {booking.booking_id}: start_date={booking.start_date}, end_date={booking.end_date}, today={today}")
            
            # If booking hasn't started yet, first payment is due on start_date
            if today < booking.start_date:
                next_payment_due = booking.start_date
                payment_due_explanation = f"Due in {(booking.start_date - today).days} day(s)"
            else:
                # Calculate how many full payments have been made
                months_paid = len([p for p in booking_payments if p.status == 'completed' and p.payment_type == 'full'])
                logger.info(f"Booking {booking.booking_id}: months_paid={months_paid}")
                
                # Use stored booking duration instead of calculating
                total_months = booking.duration_months
                logger.info(f"Booking {booking.booking_id}: total_months={total_months}")
                
                # Next payment is for the next month after the last paid month
                # If no payments made, first payment is due on start_date
                if months_paid == 0:
                    potential_due = booking.start_date
                else:
                    potential_due = booking.start_date + relativedelta(months=months_paid)
                
                logger.info(f"Booking {booking.booking_id}: potential_due={potential_due}")
                
                # Check if this payment is still within the booking period
                if potential_due <= booking.end_date and months_paid < total_months:
                    next_payment_due = potential_due
                    next_payment_amount = float(monthly_rent)
                    
                    # Calculate days until due relative to end_date
                    days_until_due = (booking.end_date - today).days
                    logger.info(f"Booking {booking.booking_id}: days_until_end={days_until_due}")
                    
                    # Show time remaining until booking ends
                    if days_until_due < 0:
                        payment_due_explanation = f"Booking ended {abs(days_until_due)} day(s) ago"
                    elif days_until_due == 0:
                        payment_due_explanation = "Booking ends today"
                    elif days_until_due <= 7:
                        payment_due_explanation = f"Booking ends in {days_until_due} day(s)"
                    else:
                        payment_due_explanation = f"Booking ends in {days_until_due} day(s)"
                else:
                    # All payments within booking period are completed
                    next_payment_due = None
                    logger.info(f"Booking {booking.booking_id}: All payments completed within booking period")
        
        # Calculate remaining amount
        remaining_amount = float(booking.total_amount) - float(paid_amount)
        
        # Update totals
        total_paid += Decimal(str(paid_amount))
        if remaining_amount > 0:
            total_pending += Decimal(str(remaining_amount))
        total_revenue += Decimal(str(booking.total_amount))
        
        bookings_data.append({
            "booking_id": str(booking.booking_id),
            "hostel_name": booking.room.hostel.name,
            "room_number": booking.room.room_number,
            "student_name": f"{booking.student.first_name} {booking.student.last_name}",
            "student_email": booking.student.email,
            "check_in_date": booking.start_date.isoformat(),
            "check_out_date": booking.end_date.isoformat(),
            "duration_months": booking.duration_months,
            "monthly_rent": float(monthly_rent),
            "total_amount": float(booking.total_amount),
            "paid_amount": float(paid_amount),
            "remaining_amount": remaining_amount,
            "status": booking.status,
            "next_payment_due_date": next_payment_due.isoformat() if next_payment_due else None,
            "next_payment_amount": next_payment_amount,
            "payment_due_explanation": payment_due_explanation,
            "created_at": booking.created_at.isoformat() if booking.created_at else None,
        })
    
    # Process payments data
    payments_data = []
    for payment in payments:
        payments_data.append({
            "payment_id": str(payment.payment_id),
            "booking_id": str(payment.booking_id),
            "hostel_name": payment.booking.room.hostel.name if payment.booking and payment.booking.room else None,
            "room_number": payment.booking.room.room_number if payment.booking and payment.booking.room else None,
            "student_name": f"{payment.booking.student.first_name} {payment.booking.student.last_name}" if payment.booking and payment.booking.student else None,
            "amount": float(payment.amount),
            "payment_type": payment.payment_type,
            "payment_method": payment.payment_method,
            "status": payment.status,
            "transaction_id": payment.transaction_id,
            "paid_at": payment.paid_at.isoformat() if payment.paid_at else None,
        })
    
    # Calculate summary statistics
    active_bookings = len([b for b in bookings_data if b['status'] in ['confirmed', 'active']])
    pending_bookings = len([b for b in bookings_data if b['status'] == 'pending'])
    completed_bookings = len([b for b in bookings_data if b['status'] == 'completed'])
    
    completed_payments = [p for p in payments_data if p['status'] == 'completed']
    pending_payments = [p for p in payments_data if p['status'] == 'pending']
    
    # Calculate total disbursed amount
    total_disbursed = sum(d.disbursement_amount for d in disbursements)
    
    return {
        "summary": {
            "total_revenue": float(total_revenue),
            "total_paid": float(total_paid),
            "total_disbursed": float(total_disbursed),
            "total_pending": float(total_pending),
            "active_bookings": active_bookings,
            "pending_bookings": pending_bookings,
            "completed_bookings": completed_bookings,
            "total_payments": len(payments_data),
            "completed_payments": len(completed_payments),
            "pending_payments": len(pending_payments),
        },
        "bookings": bookings_data,
        "payments": payments_data,
    }


@router.post("/{booking_id}/approve/", status_code=status.HTTP_200_OK)
async def approve_booking(
    booking_id: uuid.UUID, 
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_landlord), 
    db: Session = Depends(get_db)
):
    """Approve a booking."""

    booking = (
        db.query(BookingModel)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .filter(
            BookingModel.booking_id == booking_id,
            Hostel.landlord_id == current_user.user_id
        )
        .first()
    )

    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found or you don't have permission to modify it")

    if booking.status.lower() != 'pending':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Booking is already in '{booking.status}' status")

    booking.status = 'confirmed'
    db.commit()
    
    # Get room and hostel info for background notification
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
    
    # Send notification in background
    if room and hostel:
        background_tasks.add_task(
            _send_approval_notification,
            str(booking.booking_id),
            str(booking.room_id),
            booking.student_id,
            room.room_number,
            hostel.name
        )

    return {"message": "Booking approved successfully"}




@router.post("/{booking_id}/reject/", status_code=status.HTTP_200_OK)
async def reject_booking(
    booking_id: uuid.UUID, 
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_landlord), 
    db: Session = Depends(get_db)
):
    """Reject a booking."""

    booking = (
        db.query(BookingModel)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .filter(
            BookingModel.booking_id == booking_id,
            Hostel.landlord_id == current_user.user_id
        )
        .first()
    )

    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found or you don't have permission to modify it")

    if booking.status.lower() != 'pending':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Booking is already in '{booking.status}' status")

    booking.status = 'rejected'
    db.commit()
    
    # Get room and hostel info for background notification
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
    
    # Send notification in background
    if room and hostel:
        background_tasks.add_task(
            _send_rejection_notification,
            str(booking.booking_id),
            str(booking.room_id),
            booking.student_id,
            room.room_number,
            hostel.name
        )

    return {"message": "Booking rejected successfully"}




@router.post("/{booking_id}/cancel/", status_code=status.HTTP_200_OK)
def cancel_booking(booking_id: uuid.UUID, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Cancel a booking."""
    booking = db.query(BookingModel).filter(BookingModel.booking_id == booking_id, BookingModel.student_id == current_user.user_id).first()

    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")

    if booking.status.lower() != 'pending':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only pending bookings can be cancelled")

    booking.status = 'cancelled'
    db.commit()

    return {"message": "Booking cancelled successfully"}


@router.post("/{booking_id}/extension-status-update")
async def update_extension_status(
    booking_id: str,
    payload: dict,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update booking status when user proceeds to extension payment."""
    try:
        booking_uuid = uuid.UUID(booking_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid booking ID format")
    
    # Get booking and verify ownership
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_uuid,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission")
    
    # Check if booking can be extended
    if booking.status.lower() != 'confirmed':
        # Allow extension if stuck in extension_in_progress status
        if booking.status.lower() == 'extension_in_progress':
            # Check if there's an existing extension payment
            existing_extension_payment = db.query(Payment).filter(
                Payment.booking_id == booking_uuid,
                Payment.payment_type == "extension"
            ).first()
            
            if existing_extension_payment:
                # If payment exists but is still pending, allow retry
                if existing_extension_payment.status == 'pending':
                    # Allow proceeding with existing payment
                    return {
                        "message": "Extension payment already initiated. Please complete the payment.",
                        "extension_payment_id": str(existing_extension_payment.payment_id),
                        "booking_status": booking.status,
                        "action_required": "complete_payment"
                    }
                else:
                    # Payment completed but status not updated - reset to confirmed
                    booking.status = 'confirmed'
                    db.commit()
                    return {
                        "message": "Extension payment was already completed. Status reset to confirmed.",
                        "booking_status": booking.status,
                        "action_required": "none"
                    }
            else:
                # No payment record found - reset to confirmed
                booking.status = 'confirmed'
                db.commit()
                return {
                    "message": "Extension status reset. You can now extend the booking.",
                    "booking_status": booking.status,
                    "action_required": "retry_extension"
                }
        
        raise HTTPException(status_code=400, detail=f"Booking is in '{booking.status}' status and cannot be extended")
    
    if booking.end_date < datetime.now().date():
        raise HTTPException(status_code=400, detail="Cannot extend a booking that has already ended")
    
    # Get additional months from payload
    additional_months = payload.get("additional_months")
    if not additional_months or not isinstance(additional_months, int) or additional_months < 1 or additional_months > 2:
        raise HTTPException(status_code=400, detail="additional_months must be 1 or 2")
    
    # Update booking status to extension_in_progress
    booking.status = 'extension_in_progress'
    
    # Store extension details in booking meta for tracking
    if not booking.meta:
        booking.meta = {}
    booking.meta.update({
        "extension_requested": True,
        "additional_months": additional_months,
        "extension_request_date": datetime.utcnow().isoformat(),
        "original_end_date": booking.end_date.isoformat()
    })
    
    db.commit()
    
    return {
        "message": "Extension status updated successfully",
        "booking_status": booking.status,
        "additional_months": additional_months,
        "original_end_date": booking.end_date.isoformat()
    }


@router.post("/{booking_id}/complete-payment-status-update")
async def update_complete_payment_status(
    booking_id: str,
    payload: dict,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update booking status when user proceeds to complete payment."""
    try:
        booking_uuid = uuid.UUID(booking_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid booking ID format")
    
    # Get booking and verify ownership
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_uuid,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission")
    
    # Check if booking can be completed
    if booking.status.lower() != 'confirmed':
        # Allow completion if stuck in completing_payment status
        if booking.status.lower() == 'completing_payment':
            # Check if there's an existing complete payment
            existing_complete_payment = db.query(Payment).filter(
                Payment.booking_id == booking_uuid,
                Payment.payment_type == "complete"
            ).first()
            
            if existing_complete_payment:
                # If payment exists but is still pending, allow retry
                if existing_complete_payment.status == 'pending':
                    # Allow proceeding with existing payment
                    return {
                        "message": "Complete payment already initiated. Please complete the payment.",
                        "complete_payment_id": str(existing_complete_payment.payment_id),
                        "booking_status": booking.status,
                        "action_required": "complete_payment"
                    }
                else:
                    # Payment completed but status not updated - reset to confirmed
                    booking.status = 'confirmed'
                    db.commit()
                    return {
                        "message": "Complete payment was already completed. Status reset to confirmed.",
                        "booking_status": booking.status,
                        "action_required": "none"
                    }
            else:
                # No payment record found - reset to confirmed
                booking.status = 'confirmed'
                db.commit()
                return {
                    "message": "Complete payment status reset. You can now complete the payment.",
                    "booking_status": booking.status,
                    "action_required": "retry_complete_payment"
                }
        
        raise HTTPException(status_code=400, detail=f"Booking is in '{booking.status}' status and cannot be completed")
    
    # Verify booking is in booking fee status
    if booking.payment_type.lower() != "booking_fee":
        raise HTTPException(status_code=400, detail="Only booking fee payments can be completed to full payment")
    
    # Update booking status to completing_payment
    booking.status = 'completing_payment'
    
    # Store completion details in booking meta for tracking
    if not booking.meta:
        booking.meta = {}
    booking.meta.update({
        "completion_initiated_at": datetime.utcnow().isoformat(),
        "completion_initiated_by": str(current_user.email)
    })
    
    db.add(booking)
    db.commit()
    
    return {
        "message": "Complete payment status updated successfully",
        "booking_status": booking.status,
        "action_required": "initiate_payment"
    }


@router.post("/{booking_id}/reset-complete-payment-status")
async def reset_complete_payment_status(
    booking_id: str,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reset complete payment status when payment gets stuck."""
    try:
        booking_uuid = uuid.UUID(booking_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid booking ID format")
    
    # Get booking and verify ownership
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_uuid,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission")
    
    # Check if booking is stuck in completing_payment
    if booking.status.lower() != 'completing_payment':
        raise HTTPException(status_code=400, detail="Booking is not in completing_payment status")
    
    # Reset status to confirmed
    booking.status = 'confirmed'
    
    # Clear completion metadata
    if booking.meta:
        booking.meta.pop('completion_initiated_at', None)
        booking.meta.pop('completion_initiated_by', None)
    
    db.add(booking)
    db.commit()
    
    return {
        "message": "Complete payment status reset successfully",
        "booking_status": booking.status,
        "action_required": "retry_complete_payment"
    }


@router.post("/{booking_id}/reset-extension-status")
async def reset_extension_status(
    booking_id: str,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reset stuck extension status back to confirmed."""
    try:
        booking_uuid = uuid.UUID(booking_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid booking ID format")
    
    # Get booking and verify ownership
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_uuid,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission")
    
    # Only allow reset if stuck in extension_in_progress
    if booking.status.lower() != 'extension_in_progress':
        raise HTTPException(status_code=400, detail="Only bookings stuck in extension_in_progress status can be reset")
    
    # Check if there are any pending extension payments
    pending_payments = db.query(Payment).filter(
        Payment.booking_id == booking_uuid,
        Payment.payment_type == "extension",
        Payment.status == "pending"
    ).count()
    
    if pending_payments > 0:
        raise HTTPException(
            status_code=400, 
            detail="Cannot reset status while there are pending extension payments. Please complete payment or contact support."
        )
    
    # Reset status to confirmed
    booking.status = 'confirmed'
    
    # Clear extension metadata
    if booking.meta:
        booking.meta.pop('extension_requested', None)
        booking.meta.pop('additional_months', None)
        booking.meta.pop('extension_request_date', None)
        booking.meta.pop('original_end_date', None)
    
    db.commit()
    
    return {
        "message": "Extension status reset successfully. You can now extend the booking again.",
        "booking_status": booking.status
    }


@router.post("/{booking_id}/extend/", status_code=status.HTTP_200_OK)
async def extend_booking(
    booking_id: uuid.UUID,
    payload: dict,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Extend a confirmed booking by additional months."""
    
    # Get booking and verify it belongs to the current user
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found or you don't have permission to access it")
    
    # Check if booking is confirmed
    if booking.status.lower() != 'confirmed':
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only confirmed bookings can be extended")
    
    # Check if booking has not ended
    if booking.end_date < datetime.now().date():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot extend a booking that has already ended")
    
    # Get additional months from payload
    additional_months = payload.get("additional_months")
    if not additional_months or not isinstance(additional_months, int) or additional_months < 1:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="additional_months must be a positive integer")
    
    # Get room and hostel information
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    if not hostel:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hostel not found")
    
    # Calculate extension amount
    platform_fee = get_platform_fee(db)
    monthly_rent = room.price_per_month
    extension_amount = (monthly_rent * Decimal(additional_months)) + Decimal(platform_fee)
    
    # Create extension payment record
    extension_payment = Payment(
        booking_id=booking.booking_id,
        amount=float(extension_amount),
        payment_method=payload.get("payment_method", "paychangu"),
        status="pending",
        payment_type="extension"
    )
    db.add(extension_payment)
    db.flush()
    
    # Update booking status to pending_extension
    booking.status = 'pending_extension'
    
    # Store additional months in payment meta for later use
    extension_payment.meta = {
        "additional_months": additional_months,
        "original_end_date": booking.end_date.isoformat()
    }
    
    db.commit()
    
    # Get landlord info for notification
    landlord_id = hostel.landlord_id
    
    # Send notifications in background
    background_tasks.add_task(
        _send_extension_notification,
        str(booking.booking_id),
        str(extension_payment.payment_id),
        additional_months,
        booking.student_id,
        landlord_id,
        room.room_number,
        hostel.name,
        f"{current_user.first_name} {current_user.last_name}",
        booking.end_date.isoformat()
    )
    
    return {
        "message": "Booking extension initiated successfully",
        "extension_payment_id": str(extension_payment.payment_id),
        "current_end_date": booking.end_date.isoformat(),
        "extension_amount": float(extension_amount),
        "additional_months": additional_months,
        "booking_status": booking.status
    }


@router.get("/{booking_id}/extension-pricing")
async def get_extension_pricing(
    booking_id: str,
    additional_months: int = Query(..., ge=1, le=2, description="Number of additional months (1-2)"),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get pricing information for extending a booking.
    
    This endpoint returns the current room pricing from the database,
    including the platform fee stored in the configuration.
    Only allows 1-2 months extension as per business requirements.
    """
    # Get booking and verify ownership
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == uuid.UUID(booking_id),
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Booking not found or you don't have permission to access it"
        )
    
    # Verify booking is in a state that can be extended
    if booking.status.lower() != "confirmed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only confirmed bookings can be extended"
        )
    
    # Get room information
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
    
    # Get platform fee from database configuration
    platform_fee = get_platform_fee(db)
    
    # Get current monthly rent from database
    monthly_rent = room.price_per_month
    
    # Calculate total extension amount
    total_amount = (monthly_rent * Decimal(additional_months)) + Decimal(platform_fee)
    
    # Calculate new checkout date
    new_checkout_date = booking.end_date + relativedelta(months=additional_months)
    
    return {
        "monthly_price": float(monthly_rent),
        "platform_fee": float(platform_fee),
        "total_amount": float(total_amount),
        "additional_months": additional_months,
        "current_checkout_date": booking.end_date.isoformat(),
        "new_checkout_date": new_checkout_date.isoformat(),
        "room_number": room.room_number,
        "hostel_name": room.hostel.name if room.hostel else "Unknown Hostel"
    }


@router.get("/{booking_id}/complete-payment-pricing")
async def get_complete_payment_pricing(
    booking_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get pricing information for completing booking fee to full payment.
    
    This endpoint returns the pricing breakdown for converting a booking fee
    payment to full payment for the remaining months.
    """
    # Get booking and verify ownership
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == uuid.UUID(booking_id),
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Booking not found or you don't have permission to access it"
        )
    
    # Verify booking is in booking fee status
    if booking.payment_type.lower() != "booking_fee":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only booking fee payments can be completed to full payment"
        )
    
    # Get room information
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    if not room:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
    
    # Get platform fee from database configuration
    platform_fee = get_platform_fee(db)
    
    # Get current monthly rent from database
    monthly_rent = room.price_per_month
    
    # Use stored booking duration for consistent pricing
    remaining_months = booking.duration_months
    
    if remaining_months <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid booking duration"
        )
    
    # Calculate total price for remaining months
    total_price = monthly_rent * Decimal(remaining_months)
    
    # Get booking fee already paid from payment records
    booking_fee_payment = db.query(Payment).filter(
        Payment.booking_id == booking.booking_id,
        Payment.payment_type == 'booking_fee',
        Payment.status == 'completed'
    ).first()
    
    booking_fee = booking_fee_payment.amount if booking_fee_payment else Decimal('0')
    
    # Calculate remaining amount (total price + platform fee - booking fee already paid)
    remaining_amount = (total_price + Decimal(platform_fee)) - booking_fee
    
    return {
        "total_price": float(total_price),
        "platform_fee": float(platform_fee),
        "booking_fee": float(booking_fee),
        "remaining_amount": float(remaining_amount),
        "remaining_months": remaining_months,
        "monthly_rent": float(monthly_rent),
        "current_checkout_date": booking.end_date.isoformat(),
        "room_number": room.room_number,
        "hostel_name": room.hostel.name if room.hostel else "Unknown Hostel"
    }
