from fastapi import APIRouter, Depends, HTTPException, Response, status, BackgroundTasks, Request
from fastapi.responses import JSONResponse
from datetime import datetime, date
from pydantic import BaseModel, Field
import os
import time
import uuid
import hmac
import hashlib
import json
import asyncio
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
from decimal import Decimal

from endpoints.users import get_current_user
from endpoints.notifications import send_notification_to_users
from database import get_db, db_session
from sqlalchemy.orm import Session, joinedload
from models import Booking as BookingModel, Payment as PaymentModel, Room, Hostel, User, Configuration
from datetime import datetime
from email_service import email_service
from endpoints.config import get_platform_fee
from dateutil.relativedelta import relativedelta

router = APIRouter()

# Thread pool for PayChangu blocking calls
_paychangu_executor = ThreadPoolExecutor(max_workers=5)


def _safe_format_datetime(dt, format_str="%B %d, %Y", default="N/A"):
    """Safely format datetime with timezone handling"""
    if not dt:
        return default
    try:
        # Handle both timezone-aware and timezone-naive datetimes
        if hasattr(dt, 'tzinfo') and dt.tzinfo is not None:
            # Convert timezone-aware datetime to timezone-naive for consistent formatting
            dt = dt.replace(tzinfo=None)
        return dt.strftime(format_str)
    except Exception as e:
        print(f"Error formatting datetime {dt}: {e}")
        return default


def _get_paychangu_client():
    """Try to construct a PayChangu client from the installed package."""
    try:
        from paychangu import PayChanguClient
        from paychangu.models.payment import Payment
    except Exception as e:
        raise RuntimeError(
            "PayChangu Python client is not installed. Install the package 'paychangu' in your backend environment."
        )

    secret = os.getenv("PAYCHANGU_SECRET_KEY")
    if not secret:
        raise RuntimeError("PAYCHANGU_SECRET_KEY is not set in environment variables")

    client = PayChanguClient(secret_key=secret)
    return client, Payment


@router.post("/paychangu/initiate/")
def initiate_paychangu_payment(payload: dict, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    """Initiate a PayChangu payment server-side and return a payment URL."""
    try:
        client, Payment = _get_paychangu_client()
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    booking_id = payload.get("booking_id")
    amount = payload.get("amount")
    email = payload.get("email")
    phone = payload.get("phone_number")
    first_name = payload.get("first_name") or ""
    last_name = payload.get("last_name") or ""
    currency = payload.get("currency") or "MWK"
    callback_url = payload.get("callback_url") or os.getenv("PAYMENT_CALLBACK_URL")
    return_url = payload.get("return_url") or os.getenv("PAYMENT_RETURN_URL")

    if not booking_id or amount is None or not email:
        raise HTTPException(status_code=400, detail="booking_id, amount and email are required")

    booking = db.query(BookingModel).filter(BookingModel.booking_id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail=f"Booking with ID {booking_id} not found")

    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room associated with booking not found")

    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel associated with room not found")

    tx_ref = f"bk_{booking_id}_{int(time.time())}_{uuid.uuid4().hex[:6]}"

    payment = Payment(
        amount=amount,
        currency=currency,
        email=email,
        first_name=first_name,
        last_name=last_name,
        callback_url=callback_url,
        return_url=return_url,
        tx_ref=tx_ref,
        customization={
            "title": f"Hostel Room Booking: {hostel.name}",
            "description": f"Payment for Room {room.room_number} from {booking.start_date.isoformat()} to {booking.end_date.isoformat()}",
        },
        meta={
            "booking_id": str(booking.booking_id),
            "room_id": str(room.room_id),
            "hostel_id": str(hostel.hostel_id),
            "student_email": email,
            "initiated_by": str(current_user.email),
            "phone_number": phone,
        },
    )

    try:
        # Run blocking initiate_transaction in a thread with a timeout
        future = _paychangu_executor.submit(client.initiate_transaction, payment)
        response = future.result(timeout=20)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to contact PayChangu: {e}")

    if isinstance(response, dict) and response.get("status") == "success":
        data = response.get("data") or {}
        payment_url = data.get("checkout_url")

        try:
            payment_record = db.query(PaymentModel).filter(PaymentModel.booking_id == booking_id).first()
            if payment_record:
                payment_record.transaction_id = tx_ref
                db.add(payment_record)
                db.commit()
            else:
                payment_record = PaymentModel(
                    booking_id=booking_id,
                    amount=amount,
                    payment_method="paychangu",
                    transaction_id=tx_ref,
                    status="pending",
                )
                db.add(payment_record)
                db.commit()
        except Exception as db_error:
            print(f"!!! WARNING: Failed to update payment record for tx_ref {tx_ref}: {db_error}")
            try:
                db.rollback()
            except Exception:
                pass

        return JSONResponse({
            "payment_url": payment_url,
            "tx_ref": tx_ref
        })
    else:
        error_detail = response.get("message", str(response))
        raise HTTPException(status_code=400, detail=f"PayChangu initiation failed: {error_detail}")

@router.get("/verify/")
async def verify_payment(
    reference: str, 
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Verify a PayChangu transaction and update booking and room status."""
    try:
        client, _ = _get_paychangu_client()
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    try:
        print(reference)
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, client.verify_transaction, reference)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

    payment = db.query(PaymentModel).filter(PaymentModel.transaction_id == reference).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment record not found.")

    # Idempotency check: If booking is already confirmed, do nothing further.
    booking = db.query(BookingModel).filter(BookingModel.booking_id == payment.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Associated booking not found.")

    if booking.status == 'confirmed':
        return {"status": "success", "message": "Booking already confirmed."}

    # Handle successful payment
    if response.get("status") == "success":
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        booking.status = 'confirmed'
        
        # Handle different payment types
        if payment.payment_type == "complete":
            # Update booking to full payment type and status
            booking.payment_type = 'full'
            booking.status = 'confirmed'
            
            # Update total_amount to reflect full payment
            # Use stored duration_months from booking instead of calculating
            try:
                platform_fee = get_platform_fee(db)
                # Use stored duration_months from booking creation
                original_months = booking.duration_months
                full_amount = float((booking.room.price_per_month * Decimal(original_months)) + Decimal(str(platform_fee)))
                booking.total_amount = full_amount
                print(f"Updated booking total_amount to {full_amount} for complete payment (stored duration_months: {original_months})")
            except Exception as e:
                print(f"Error calculating full amount for booking: {e}")

        # Update room occupancy
        room = db.query(Room).filter(Room.room_id == booking.room_id).with_for_update().first()
        if room:
            room.occupants = (room.occupants or 0) + 1
            db.add(room)

        db.add(payment)
        db.add(booking)

        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        # Get room, hostel, and student info for background notification
        room = db.query(Room).filter(Room.room_id == booking.room_id).first()
        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
        student = db.query(User).filter(User.user_id == booking.student_id).first()
        landlord_id = hostel.landlord_id if hostel else None
        
        # Send notifications in background
        if room and hostel and student:
            background_tasks.add_task(
                _send_payment_notifications,
                str(booking.booking_id),
                str(payment.payment_id),
                str(payment.amount),
                payment.transaction_id or "",
                booking.student_id,
                landlord_id,
                room.room_number,
                hostel.name,
                student.first_name,
                student.last_name
            )

        return response
    
    # Handle failed payment
    else:
        # Update payment and booking status for failed payment
        payment.status = 'failed'
        booking.status = 'payment_failed'
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        return {
            "status": "failed", 
            "message": "Payment verification failed. Booking status updated to payment_failed."
        }


# Background task function for sending payment notifications
async def _send_payment_notifications(
    booking_id: str,
    payment_id: str,
    amount: str,
    transaction_id: str,
    student_id: uuid.UUID,
    landlord_id: uuid.UUID | None,
    room_number: str,
    hostel_name: str,
    student_first_name: str,
    student_last_name: str
):
    """Background task to send payment notifications"""
    try:
        with db_session() as db:
            # Notify student about successful payment
            await send_notification_to_users(
                db=db,
                user_ids=[student_id],
                title="Payment Successful",
                body=f"Your payment of MWK {float(amount):,.0f} for Room {room_number} at {hostel_name} has been confirmed. Your booking is now active!",
                notification_type="payment",
                data={
                    "booking_id": booking_id,
                    "payment_id": payment_id,
                    "amount": amount,
                    "transaction_id": transaction_id,
                    "status": "completed"
                }
            )
            
            # Send email receipt to student after successful payment
            try:
                import uuid as uuid_module
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
                    .filter(BookingModel.booking_id == uuid_module.UUID(booking_id))
                    .first()
                )
                
                if booking:
                    # Prepare booking data for email
                    # Use stored duration_months from booking instead of calculating
                    original_months = booking.duration_months
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
                        'check_in': _safe_format_datetime(booking.start_date, "%B %d, %Y"),
                        'check_out': _safe_format_datetime(booking.end_date, "%B %d, %Y"),
                        'payment_type': booking.payment_type,
                        'payment_type_display': 'Full Payment' if booking.payment_type == 'full' else 'Booking Fee',
                        'monthly_rent': float(booking.room.price_per_month),
                        'duration_months': original_months,
                        'platform_fee': float(platform_fee),
                        'total_amount': float(booking.total_amount),
                        'status': 'confirmed',
                    }
                    
                    # Add payment details
                    if booking.payments:
                        latest_payment = sorted(booking.payments, key=lambda p: p.paid_at or datetime.min, reverse=True)[0]
                        booking_data.update({
                            'payment_method': latest_payment.payment_method,
                            'transaction_id': latest_payment.transaction_id,
                            'payment_date': _safe_format_datetime(latest_payment.paid_at, "%B %d, %Y", "N/A"),
                        })
                    
                    # Send booking confirmation email with PDF receipt
                    await email_service.send_booking_confirmation_email(
                        email=booking.student.email,
                        first_name=booking.student.first_name,
                        booking_data=booking_data
                    )
                    print(f"Payment receipt email sent to {booking.student.email}")
                    
            except Exception as email_error:
                print(f"Error sending payment receipt email: {email_error}")
            
            # Notify landlord about payment received
            if landlord_id:
                await send_notification_to_users(
                    db=db,
                    user_ids=[landlord_id],
                    title="Payment Processing",
                    body=f"Payment of MWK {float(amount):,.0f} received from {student_first_name} {student_last_name} for Room {room_number} at {hostel_name}. Payment being processed by Palevel will reflect within 24 hours.",
                    notification_type="payment",
                    data={
                        "booking_id": booking_id,
                        "payment_id": payment_id,
                        "amount": amount,
                        "student_id": str(student_id),
                        "transaction_id": transaction_id,
                        "status": "completed"
                    }
                )
    except Exception as e:
        print(f"Error sending payment notifications: {e}")


@router.post("/paychangu/webhook/")
async def paychangu_webhook(request: Request, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """Receive PayChangu webhook callbacks."""
    try:
        request_body = await request.body()
    except Exception:
        request_body = b""

    payload_bytes = request_body or b""

    def _get_header_value(name: str):
        try:
            if request is not None:
                hv = request.headers.get(name)
                if hv:
                    return hv
        except Exception:
            pass
        return None

    # Get the Signature header - try multiple possible names
    sig_header = (_get_header_value('Signature') or 
                   _get_header_value('signature') or 
                   _get_header_value('X-Signature') or
                   _get_header_value('x-signature') or
                   _get_header_value('Paychangu-Signature') or
                   _get_header_value('paychangu-signature'))
    
    webhook_secret = os.getenv("PAYCHANGU_WEBHOOK_SECRET")
    if not webhook_secret:
        raise HTTPException(status_code=500, detail="Webhook secret not configured")
        
    if not sig_header:
        raise HTTPException(status_code=400, detail="Missing Signature header")
    
    # Generate HMAC-SHA256 hash of the payload using the webhook secret
    computed_signature = hmac.new(
        webhook_secret.encode('utf-8'),
        payload_bytes,
        hashlib.sha256
    ).hexdigest()
    
    # Compare the computed signature with the received signature
    if not hmac.compare_digest(computed_signature, sig_header):
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

    try:
        data = json.loads(payload_bytes.decode('utf-8') or "{}")
    except Exception:
        data = {}

    tx_ref = None
    if isinstance(data, dict):
        tx_ref = data.get('tx_ref') or data.get('txRef')
        if not tx_ref:
            d = data.get('data')
            if isinstance(d, dict):
                tx_ref = d.get('tx_ref') or d.get('txRef') or d.get('txRef')

    if tx_ref:
        try:
            client, _ = _get_paychangu_client()
            loop = asyncio.get_running_loop()
            verify_resp = await loop.run_in_executor(None, client.verify_transaction, tx_ref)

            try:
                payment_query = db.query(PaymentModel).filter(PaymentModel.transaction_id == tx_ref)
                try:
                    payment_query = payment_query.with_for_update()
                except Exception:
                    pass

                payment = payment_query.first()
                if payment:
                    # Idempotency: webhook delivery is retried by payment providers.
                    # If we've already processed this payment, do not apply booking updates again.
                    if (payment.status or "").lower() == "completed":
                        return Response(status_code=204)

                    if verify_resp.get('status') == 'success':
                        payment.status = 'completed'
                        payment.paid_at = datetime.utcnow()
                        
                        booking = db.query(BookingModel).filter(BookingModel.booking_id == payment.booking_id).first()
                        if booking:
                            booking.status = 'confirmed'
                            
                            # Handle different payment types
                            if payment.payment_type == "complete":
                                # Update booking to full payment type and status
                                booking.payment_type = 'full'
                                booking.status = 'confirmed'
                                
                                # Update total_amount to reflect full payment
                                # Use stored duration_months from booking instead of calculating
                                try:
                                    platform_fee = get_platform_fee(db)
                                    # Use stored duration_months from booking creation
                                    original_months = booking.duration_months
                                    full_amount = float((booking.room.price_per_month * Decimal(original_months)) + Decimal(str(platform_fee)))
                                    booking.total_amount = full_amount
                                    print(f"Updated booking total_amount to {full_amount} for complete payment (stored duration_months: {original_months})")
                                except Exception as e:
                                    print(f"Error calculating full amount for booking: {e}")
                            elif payment.payment_type == "extension":
                                # Update booking end date and total_amount after successful payment
                                try:
                                    extension_months = None
                                    if payment.meta and isinstance(payment.meta, dict):
                                        extension_months = payment.meta.get('additional_months')
                                    
                                    if extension_months:
                                        booking.duration_months = (booking.duration_months or 0) + int(extension_months)
                                        new_end_date = booking.end_date + relativedelta(months=extension_months)
                                        booking.end_date = new_end_date
                                        booking.status = 'confirmed'
                                        
                                        # Update total_amount to include extension payment
                                        # Get sum of all previous completed payments
                                        previous_payments = db.query(PaymentModel).filter(
                                            PaymentModel.booking_id == booking.booking_id,
                                            PaymentModel.status == 'completed',
                                            PaymentModel.transaction_id != tx_ref
                                        ).all()
                                        
                                        previous_total = sum(
                                            (
                                                (p.amount if p.amount is not None else Decimal("0"))
                                                for p in previous_payments
                                            ),
                                            Decimal("0"),
                                        )
                                        payment_amount = payment.amount if payment.amount is not None else Decimal("0")
                                        new_total_amount = previous_total + payment_amount
                                        booking.total_amount = float(new_total_amount)
                                        print(f"Updated booking total_amount to {new_total_amount} for extension (previous: {previous_total}, extension: {payment.amount})")
                                except Exception as e:
                                    print(f"Error updating extension payment: {e}")
                            
                            db.add(booking)
                            
                            # Note: Extension payments do NOT update room occupancy
                            # since student is already occupying the room
                            # Only extending their stay duration
                    else:
                        # Handle failed payment in webhook
                        payment.status = 'failed'
                        
                        booking = db.query(BookingModel).filter(BookingModel.booking_id == payment.booking_id).first()
                        if booking:
                            booking.status = 'payment_failed'
                            db.add(booking)
                    
                    db.add(payment)

                    db.commit()
                    
                    # Send notifications after successful payment (webhook) - in background
                    if booking and verify_resp.get('status') == 'success' and payment.status == 'completed':
                        # Get room, hostel, and student info (refresh from DB after commit)
                        room = db.query(Room).filter(Room.room_id == booking.room_id).first()
                        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
                        student = db.query(User).filter(User.user_id == booking.student_id).first()
                        landlord_id = hostel.landlord_id if hostel else None
                        
                        # Schedule notification sending in background (don't await)
                        if room and hostel and student:
                            import asyncio
                            
                            # Check if this is an extension payment
                            if payment.payment_type == "extension":
                                print(f"Extension payment found: {payment.payment_id}, meta: {payment.meta}")
                                
                                # Booking updates were already applied above; do NOT update/commit again here.
                                additional_months = None
                                if payment.meta and isinstance(payment.meta, dict):
                                    additional_months = payment.meta.get("additional_months")
                                    print(f"Additional months from meta: {additional_months}")
                                else:
                                    print(f"Payment meta is None or not a dict: {payment.meta}")
                                
                                if not additional_months:
                                    print(f"Extension payment found but additional_months metadata missing for payment {payment.payment_id}")

                                # Prepare extension data for email
                                extension_data = {
                                    'booking_id': str(booking.booking_id),
                                    'student_first_name': student.first_name,
                                    'student_last_name': student.last_name,
                                    'student_email': student.email,
                                    'hostel_name': hostel.name,
                                    'room_number': room.room_number,
                                    'room_type': room.room_type,
                                    'extension_payment_id': str(payment.payment_id),
                                    'payment_date': _safe_format_datetime(payment.paid_at, "%B %d, %Y", "Payment Processing"),
                                    'previous_checkout_date': payment.meta.get("original_end_date", "N/A") if payment.meta else 'N/A',
                                    'new_checkout_date': _safe_format_datetime(booking.end_date, "%B %d, %Y", "N/A"),
                                    'monthly_rent': str(room.price_per_month),
                                    'platform_fee': str(get_platform_fee(db)),
                                    'extension_amount': str(payment.amount),
                                    'new_total_amount': str(booking.total_amount),
                                    'payment_method': payment.payment_method,
                                    'transaction_id': payment.transaction_id or 'N/A',
                                }
                                
                                # Send extension email with PDF (in background to avoid blocking)
                                try:
                                    background_tasks.add_task(
                                        email_service.send_booking_extension_email,
                                        email=student.email,
                                        first_name=student.first_name,
                                        booking_data=extension_data
                                    )
                                except Exception as email_error:
                                    # Log email error but don't fail the payment
                                    print(f"Failed to send extension email: {email_error}")
                            else:
                                # Regular booking confirmation email (in background to avoid blocking)
                                background_tasks.add_task(
                                    _send_payment_notifications,
                                    str(booking.booking_id),
                                    str(payment.payment_id),
                                    str(payment.amount),
                                    payment.transaction_id or "",
                                    booking.student_id,
                                    landlord_id,
                                    room.room_number,
                                    hostel.name,
                                    student.first_name,
                                    student.last_name
                                )
            except Exception:
                try:
                    db.rollback()
                except Exception:
                    pass

            return Response(status_code=204)
        except Exception as e:
            return Response(status_code=204)

    return Response(status_code=204)



@router.post("/verify-extension-payment/")
async def verify_extension_payment(
    request: Request,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Verify payment specifically for booking extensions."""
    # Get request body
    try:
        request_body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON in request body")
    
    # Get transaction_id from request body
    transaction_id = request_body.get("payment_id")  # This is actually the transaction_id from PayChangu
    if not transaction_id:
        raise HTTPException(status_code=422, detail="payment_id field is required")
    
    # Get extension payment record by transaction_id (lock row if supported)
    payment_query = db.query(PaymentModel).filter(
        PaymentModel.transaction_id == transaction_id,
        PaymentModel.payment_type == "extension"
    )
    try:
        payment_query = payment_query.with_for_update()
    except Exception:
        pass

    payment = payment_query.first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Extension payment not found")
    
    # Get associated booking
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == payment.booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Associated booking not found or you don't have permission")
    
    if not payment.transaction_id:
        raise HTTPException(
            status_code=400, 
            detail="Extension payment was not initiated properly. No transaction ID found."
        )
    
    # Idempotency: if we've already completed this payment, do not apply extension again.
    if (payment.status or "").lower() == "completed":
        return {
            "status": "success",
            "message": "Extension payment already verified",
            "booking_status": booking.status,
            "new_end_date": booking.end_date.isoformat() if booking.end_date else None
        }

    # Call PayChangu verification
    try:
        client, _ = _get_paychangu_client()
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, client.verify_transaction, payment.transaction_id)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=f"PayChangu client error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

    # Handle successful extension payment
    if response.get("status") == "success":
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        
        # Update booking end date and status
        additional_months = None
        if payment.meta and isinstance(payment.meta, dict):
            additional_months = payment.meta.get("additional_months")
        
        if additional_months:
            new_end_date = booking.end_date + relativedelta(months=additional_months)
            booking.end_date = new_end_date
            booking.status = 'confirmed'
            # Update duration_months to reflect the extension
            booking.duration_months = (booking.duration_months or 0) + additional_months
            
            # Update total_amount to include extension payment
            # Get sum of all previous completed payments
            previous_payments = db.query(PaymentModel).filter(
                PaymentModel.booking_id == booking.booking_id,
                PaymentModel.status == 'completed'
            ).all()
            
            previous_total = sum(p.amount for p in previous_payments)
            new_total_amount = previous_total + payment.amount
            booking.total_amount = float(new_total_amount)
            print(f"Updated booking total_amount to {new_total_amount} for extension (previous: {previous_total}, extension: {payment.amount})")
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        # Send extension confirmation email
        try:
            if additional_months:
                # Prepare extension data for email
                extension_data = {
                    'booking_id': str(booking.booking_id),
                    'student_first_name': current_user.first_name,
                    'student_last_name': current_user.last_name,
                    'student_email': current_user.email,
                    'hostel_name': booking.room.hostel.name if booking.room else 'Unknown',
                    'room_number': booking.room.room_number if booking.room else 'Unknown',
                    'room_type': booking.room.type if booking.room else 'Unknown',
                    'extension_payment_id': str(payment.payment_id),
                    'payment_date': _safe_format_datetime(payment.paid_at, "%B %d, %Y", "Payment Processing"),
                    'previous_checkout_date': payment.meta.get("original_end_date", "N/A") if payment.meta else 'N/A',
                    'new_checkout_date': _safe_format_datetime(booking.end_date, "%B %d, %Y", "N/A"),
                    'monthly_rent': str(booking.room.price_per_month) if booking.room else 'N/A',
                    'platform_fee': str(get_platform_fee(db)),
                    'extension_amount': str(payment.amount),
                    'new_total_amount': str(new_total_amount),
                    'payment_method': payment.payment_method,
                    'transaction_id': payment.transaction_id or 'N/A',
                }
                
                asyncio.create_task(
                    email_service.send_booking_extension_email(
                        email=current_user.email,
                        first_name=current_user.first_name,
                        booking_data=extension_data
                    )
                )
        except Exception as email_error:
            print(f"Failed to send extension email: {email_error}")
        
        # Send notifications after successful extension payment
        try:
            room = db.query(Room).filter(Room.room_id == booking.room_id).first()
            hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
            student_id = current_user.user_id
            landlord_id = hostel.landlord_id if hostel else None
            
            if hostel and room:
                # Send notification to student
                background_tasks.add_task(
                    send_notification_to_users,
                    db=db,
                    user_ids=[student_id],
                    title="Booking Extended Successfully!",
                    body=f"Your booking for Room {room.room_number} at {hostel.name} has been extended by {additional_months} month(s). Your new checkout date is {_safe_format_datetime(booking.end_date, '%B %d, %Y', 'N/A')}.",
                    notification_type="extension",
                    data={
                        "booking_id": str(booking.booking_id),
                        "payment_id": str(payment.payment_id),
                        "payment_type": "extension",
                        "status": "completed",
                        "additional_months": additional_months,
                        "new_end_date": booking.end_date.isoformat() if booking.end_date else None
                    }
                )
                
                # Send notification to landlord
                if landlord_id:
                    background_tasks.add_task(
                        send_notification_to_users,
                        db=db,
                        user_ids=[landlord_id],
                        title="Extension Payment Processing",
                        body=f"Extension payment of MWK {float(payment.amount):,.0f} for Room {room.room_number} at {hostel.name}. Payment being processed by Palevel will reflect within 24 hours.",
                        notification_type="extension",
                        data={
                            "booking_id": str(booking.booking_id),
                            "payment_id": str(payment.payment_id),
                            "amount": str(payment.amount),
                            "student_id": str(student_id),
                            "room_number": room.room_number,
                            "status": "completed"
                        }
                    )
        except Exception as e:
            print(f"Error sending extension notifications: {e}")
        
        return {
            "status": "success",
            "message": "Extension payment verified successfully",
            "new_end_date": booking.end_date.isoformat() if booking.end_date else None,
            "booking_status": booking.status
        }
    
    else:
        # Handle failed payment
        payment.status = 'failed'
        booking.status = 'payment_failed'
        db.add(payment)
        db.add(booking)
        db.commit()
        
        return {
            "status": "failed",
            "message": "Extension payment verification failed"
        }


@router.post("/verify-complete-payment/")
async def verify_complete_payment(
    request: Request,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Verify payment specifically for completing booking fee to full payment."""
    # Get request body
    try:
        request_body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON in request body")
    
    # Get transaction_id from request body
    transaction_id = request_body.get("payment_id")  # This is actually the transaction_id from PayChangu
    if not transaction_id:
        raise HTTPException(status_code=422, detail="payment_id field is required")
    
    # Get complete payment record by transaction_id (lock row if supported)
    payment_query = db.query(PaymentModel).filter(
        PaymentModel.transaction_id == transaction_id,
        PaymentModel.payment_type == "complete"
    )
    try:
        payment_query = payment_query.with_for_update()
    except Exception:
        pass

    payment = payment_query.first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Complete payment not found")
    
    # Get associated booking
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == payment.booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Associated booking not found or you don't have permission")
    
    if not payment.transaction_id:
        raise HTTPException(
            status_code=400, 
            detail="Complete payment was not initiated properly. No transaction ID found."
        )

    # Idempotency: if we've already applied this payment, don't apply it again.
    # This protects against polling/retries causing multiple updates.
    if (payment.status or "").lower() == "completed" or (booking.payment_type or "").lower() == "full":
        return {
            "status": "success",
            "message": "Complete payment already verified",
            "booking_status": booking.status,
            "payment_type": booking.payment_type
        }
    
    # Call PayChangu verification
    try:
        client, _ = _get_paychangu_client()
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, client.verify_transaction, payment.transaction_id)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=f"PayChangu client error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

    # Handle successful complete payment
    if response.get("status") == "success":
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        
        # Update booking payment type and status
        booking.payment_type = 'full'
        booking.status = 'confirmed'
        
        # Update total_amount to reflect full payment
        # Use stored duration_months from booking instead of calculating
        try:
            platform_fee = get_platform_fee(db)
            # Use stored duration_months from booking creation
            original_months = booking.duration_months
            full_amount = float((booking.room.price_per_month * Decimal(original_months)) + Decimal(str(platform_fee)))
            booking.total_amount = full_amount
            print(f"Updated booking total_amount to {full_amount} for complete payment (stored duration_months: {original_months})")
        except Exception as e:
            print(f"Error calculating full amount for booking: {e}")
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        # Send complete payment confirmation email
        try:
            complete_payment_data = {
                'booking_id': str(booking.booking_id),
                'student_first_name': current_user.first_name,
                'student_last_name': current_user.last_name,
                'student_email': current_user.email,
                'hostel_name': booking.room.hostel.name if booking.room else 'Unknown',
                'room_number': booking.room.room_number if booking.room else 'Unknown',
                'room_type': booking.room.type if booking.room else 'Unknown',
                'complete_payment_id': str(payment.payment_id),
                'payment_date': _safe_format_datetime(payment.paid_at, "%B %d, %Y", "Payment Processing"),
                'checkout_date': _safe_format_datetime(booking.end_date, "%B %d, %Y", "N/A"),
                'monthly_rent': str(booking.room.price_per_month) if booking.room else 'N/A',
                'platform_fee': str(get_platform_fee(db)),
                'complete_payment_amount': str(payment.amount),
                'payment_method': payment.payment_method,
                'transaction_id': payment.transaction_id,
            }
            
            # Send email in background
            background_tasks.add_task(
                email_service.send_complete_payment_confirmation,
                current_user.email,
                complete_payment_data
            )
        except Exception as e:
            print(f"Error sending complete payment confirmation email: {e}")
        
        # Send notifications after successful payment
        try:
            room = db.query(Room).filter(Room.room_id == booking.room_id).first()
            hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
            student_id = current_user.user_id
            landlord_id = hostel.landlord_id if hostel else None
            
            if hostel and room:
                # Send notification to student
                background_tasks.add_task(
                    send_notification_to_users,
                    db=db,
                    user_ids=[student_id],
                    title="Payment Completed Successfully",
                    body=f"Your complete payment for Room {room.room_number} at {hostel.name} has been processed. Your booking is now fully paid!",
                    notification_type="payment",
                    data={
                        "booking_id": str(booking.booking_id),
                        "payment_id": str(payment.payment_id),
                        "payment_type": "complete",
                        "status": "completed"
                    }
                )
                
                # Send notification to landlord
                if landlord_id:
                    background_tasks.add_task(
                        send_notification_to_users,
                        db=db,
                        user_ids=[landlord_id],
                        title="Complete Payment Processing",
                        body=f"Complete payment of MWK {float(payment.amount):,.0f} for Room {room.room_number} at {hostel.name}. Payment being processed by Palevel will reflect within 24 hours.",
                        notification_type="payment",
                        data={
                            "booking_id": str(booking.booking_id),
                            "payment_id": str(payment.payment_id),
                            "amount": str(payment.amount),
                            "student_id": str(student_id),
                            "room_number": room.room_number,
                            "status": "completed"
                        }
                    )
        except Exception as e:
            print(f"Error sending complete payment notifications: {e}")
        
        return {
            "message": "Complete payment verified successfully",
            "booking_id": str(booking.booking_id),
            "payment_id": str(payment.payment_id),
            "payment_status": "completed",
            "booking_status": booking.status,
            "payment_type": booking.payment_type
        }
    else:
        # Handle failed verification
        payment.status = 'failed'
        db.add(payment)
        db.commit()
        
        error_detail = response.get("message", str(response))
        raise HTTPException(
            status_code=400, 
            detail=f"Payment verification failed: {error_detail}"
        )


@router.post("/verify-my-payment/")
async def verify_my_payment(
    request: Request,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Verify payment for a student's own booking."""
    # Get request body
    try:
        request_body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON in request body")
    
    # Get booking_id from request body
    booking_id = request_body.get("booking_id")
    if not booking_id:
        raise HTTPException(status_code=422, detail="booking_id field is required")
    
    # Validate booking_id format
    try:
        booking_uuid = uuid.UUID(booking_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid booking ID format")
    
    # Get booking and verify it belongs to the current user
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_uuid,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission to access it")
    
    # Get payment record for this booking - prioritize extension payments
    payments = db.query(PaymentModel).filter(PaymentModel.booking_id == booking_uuid).all()
    if not payments:
        raise HTTPException(status_code=404, detail="Payment record not found for this booking")
    
    # Find the most recent payment, prioritizing extension payments
    extension_payments = [p for p in payments if p.payment_type == "extension"]
    if extension_payments:
        # Sort by paid date if available, otherwise by payment_id (UUID is time-ordered)
        payment = max(extension_payments, key=lambda p: (p.paid_at or datetime.min, p.payment_id))
    else:
        # Get the most recent payment of any type
        payment = max(payments, key=lambda p: (p.paid_at or datetime.min, p.payment_id))
    
    if not payment.transaction_id:
        # Mark booking as cancelled since payment was never initiated
        booking.status = 'cancelled'
        db.add(booking)
        db.commit()
        raise HTTPException(
            status_code=400, 
            detail="No transaction ID found for this payment. Payment was not initiated properly. Booking has been cancelled."
        )
    
    # Call the existing verify_payment function
    try:
        client, _ = _get_paychangu_client()
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    try:
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, client.verify_transaction, payment.transaction_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

    # Handle successful payment
    if response.get("status") == "success":
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        booking.status = 'confirmed'
        
        # Handle different payment types
        if payment.payment_type == "complete":
            # Update booking to full payment type and status
            booking.payment_type = 'full'
            booking.status = 'confirmed'
            
            # Update total_amount to reflect full payment
            # Use stored duration_months from booking instead of calculating
            try:
                platform_fee = get_platform_fee(db)
                # Use stored duration_months from booking creation
                original_months = booking.duration_months
                full_amount = float((booking.room.price_per_month * Decimal(original_months)) + Decimal(str(platform_fee)))
                booking.total_amount = full_amount
                print(f"Updated booking total_amount to {full_amount} for complete payment (stored duration_months: {original_months})")
            except Exception as e:
                print(f"Error calculating full amount for booking: {e}")

        # Update room occupancy
        room = db.query(Room).filter(Room.room_id == booking.room_id).with_for_update().first()
        if room:
            room.occupants = (room.occupants or 0) + 1
            db.add(room)

        db.add(payment)
        db.add(booking)

        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        # Get room, hostel, and student info for background notification
        room = db.query(Room).filter(Room.room_id == booking.room_id).first()
        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first() if room else None
        student = db.query(User).filter(User.user_id == booking.student_id).first()
        landlord_id = hostel.landlord_id if hostel else None
        
        # Send notifications in background
        if room and hostel and student:
            background_tasks.add_task(
                _send_payment_notifications,
                str(booking.booking_id),
                str(payment.payment_id),
                str(payment.amount),
                payment.transaction_id or "",
                booking.student_id,
                landlord_id,
                room.room_number,
                hostel.name,
                student.first_name,
                student.last_name
            )

        return {
            "status": "success", 
            "message": "Payment verified successfully. Your booking has been confirmed.",
            "booking_status": booking.status,
            "payment_status": payment.status
        }
    
    # Handle failed payment
    else:
        # Update payment and booking status for failed payment
        payment.status = 'failed'
        booking.status = 'payment_failed'
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        return {
            "status": "failed", 
            "message": "Payment verification failed. The payment was not successful.",
            "booking_status": booking.status,
            "payment_status": payment.status
        }
@router.get("/callback")
def paychangu_callback(tx_ref: str):
    print("🔔 CALLBACK RECEIVED:", tx_ref)

    # return empty success response
    return Response(status_code=204)

@router.get("/paychangu/return")
def return_page():
    return {"message": "Payment completed. You may close this page."}


@router.post("/extend/initiate/")
async def initiate_extension_payment(
    payload: dict,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initiate payment for booking extension."""
    try:
        client, Payment = _get_paychangu_client()
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    booking_id = payload.get("booking_id")
    additional_months = payload.get("additional_months")
    email = payload.get("email")
    phone = payload.get("phone_number")
    first_name = payload.get("first_name") or ""
    last_name = payload.get("last_name") or ""
    currency = payload.get("currency") or "MWK"

    if not booking_id or not additional_months or not email:
        raise HTTPException(status_code=400, detail="booking_id, additional_months and email are required")

    # Validate additional_months
    try:
        additional_months = int(additional_months)
        if additional_months < 1:
            raise ValueError()
    except (ValueError, TypeError):
        raise HTTPException(status_code=400, detail="additional_months must be a positive integer")

    # Get booking and verify it belongs to the current user
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission to access it")
    
    if booking.status.lower() not in ['confirmed', 'extension_in_progress']:
        raise HTTPException(status_code=400, detail="Only confirmed bookings or bookings with extension in progress can be extended")
    
    if booking.end_date < datetime.now().date():
        raise HTTPException(status_code=400, detail="Cannot extend a booking that has already ended")

    # Get room and hostel information
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room associated with booking not found")

    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel associated with room not found")

    # Calculate extension amount
    platform_fee = get_platform_fee(db)
    monthly_rent = room.price_per_month
    extension_amount = (monthly_rent * Decimal(additional_months)) + Decimal(platform_fee)

    tx_ref = f"ext_{booking_id}_{additional_months}_{int(time.time())}_{uuid.uuid4().hex[:6]}"

    payment = Payment(
        amount=float(extension_amount),
        currency=currency,
        email=email,
        first_name=first_name,
        last_name=last_name,
        callback_url=os.getenv("PAYMENT_CALLBACK_URL"),
        return_url=os.getenv("PAYMENT_RETURN_URL"),
        tx_ref=tx_ref,
        customization={
            "title": f"Booking Extension: {hostel.name}",
            "description": f"Extension payment for {additional_months} month(s) - Room {room.room_number}",
        },
        meta={
            "booking_id": str(booking.booking_id),
            "room_id": str(room.room_id),
            "hostel_id": str(hostel.hostel_id),
            "student_email": email,
            "additional_months": additional_months,
            "initiated_by": str(current_user.email),
            "phone_number": phone,
            "payment_type": "extension"
        },
    )

    try:
        # Run blocking initiate_transaction in a thread with a timeout
        future = _paychangu_executor.submit(client.initiate_transaction, payment)
        response = future.result(timeout=20)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to contact PayChangu: {e}")

    if isinstance(response, dict) and response.get("status") == "success":
        data = response.get("data") or {}
        payment_url = data.get("checkout_url")

        try:
            # Create extension payment record
            extension_payment = PaymentModel(
                booking_id=booking_id,
                amount=float(extension_amount),
                payment_method="paychangu",
                transaction_id=tx_ref,
                status="pending",
                payment_type="extension",
                meta={
                    "booking_id": str(booking.booking_id),
                    "room_id": str(room.room_id),
                    "hostel_id": str(hostel.hostel_id),
                    "student_email": email,
                    "additional_months": additional_months,
                    "initiated_by": str(current_user.email),
                    "phone_number": phone,
                    "payment_type": "extension"
                }
            )
            db.add(extension_payment)
            db.commit()
        except Exception as db_error:
            print(f"!!! WARNING: Failed to create extension payment record for tx_ref {tx_ref}: {db_error}")
            try:
                db.rollback()
            except Exception:
                pass

        return JSONResponse({
            "payment_url": payment_url,
            "tx_ref": tx_ref,
            "extension_amount": float(extension_amount),
            "additional_months": additional_months
        })
    else:
        error_detail = response.get("message", str(response))
        raise HTTPException(status_code=400, detail=f"PayChangu initiation failed: {error_detail}")


@router.post("/complete/initiate/")
async def initiate_complete_payment(
    payload: dict,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initiate payment for completing booking fee to full payment."""
    try:
        client, Payment = _get_paychangu_client()
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    booking_id = payload.get("booking_id")
    remaining_amount = payload.get("remaining_amount")
    email = payload.get("email")
    phone = payload.get("phone_number")
    first_name = payload.get("first_name") or ""
    last_name = payload.get("last_name") or ""
    currency = payload.get("currency") or "MWK"

    if not booking_id or not remaining_amount or not email:
        raise HTTPException(status_code=400, detail="booking_id, remaining_amount and email are required")

    # Validate remaining_amount
    try:
        remaining_amount = float(remaining_amount)
        if remaining_amount <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        raise HTTPException(status_code=400, detail="remaining_amount must be a positive number")

    # Get booking and verify it belongs to the current user
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission to access it")
    
    # Verify booking is in booking fee status
    if booking.payment_type.lower() != "booking_fee":
        raise HTTPException(status_code=400, detail="Only booking fee payments can be completed to full payment")
    
    if booking.status.lower() not in ['confirmed', 'pending', 'completing_payment']:
        raise HTTPException(status_code=400, detail="Booking must be confirmed, pending, or completing_payment to complete payment")
    
    if booking.end_date < datetime.now().date():
        raise HTTPException(status_code=400, detail="Cannot complete payment for a booking that has already ended")

    # Get room and hostel information
    room = db.query(Room).filter(Room.room_id == booking.room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room associated with booking not found")

    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel associated with room not found")

    tx_ref = f"complete_{booking_id}_{int(time.time())}_{uuid.uuid4().hex[:6]}"

    payment = Payment(
        amount=float(remaining_amount),
        currency=currency,
        email=email,
        first_name=first_name,
        last_name=last_name,
        callback_url=os.getenv("PAYMENT_CALLBACK_URL"),
        return_url=os.getenv("PAYMENT_RETURN_URL"),
        tx_ref=tx_ref,
        customization={
            "title": f"Complete Payment: {hostel.name}",
            "description": f"Complete payment for Room {room.room_number} - {hostel.name}",
        },
        meta={
            "booking_id": str(booking.booking_id),
            "room_id": str(room.room_id),
            "hostel_id": str(hostel.hostel_id),
            "student_email": email,
            "remaining_amount": remaining_amount,
            "initiated_by": str(current_user.email),
            "phone_number": phone,
            "payment_type": "complete"
        },
    )

    try:
        # Run blocking initiate_transaction in a thread with a timeout
        future = _paychangu_executor.submit(client.initiate_transaction, payment)
        response = future.result(timeout=20)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to contact PayChangu: {e}")

    if isinstance(response, dict) and response.get("status") == "success":
        data = response.get("data") or {}
        payment_url = data.get("checkout_url")

        try:
            # Create complete payment record
            complete_payment = PaymentModel(
                booking_id=booking_id,
                amount=float(remaining_amount),
                payment_method="paychangu",
                transaction_id=tx_ref,
                status="pending",
                payment_type="complete",
                meta={
                    "booking_id": str(booking.booking_id),
                    "room_id": str(room.room_id),
                    "hostel_id": str(hostel.hostel_id),
                    "student_email": email,
                    "remaining_amount": remaining_amount,
                    "initiated_by": str(current_user.email),
                    "phone_number": phone,
                    "payment_type": "complete"
                }
            )
            db.add(complete_payment)
            db.commit()
        except Exception as db_error:
            print(f"!!! WARNING: Failed to create complete payment record for tx_ref {tx_ref}: {db_error}")
            try:
                db.rollback()
            except Exception:
                pass

        return JSONResponse({
            "payment_url": payment_url,
            "tx_ref": tx_ref,
            "remaining_amount": float(remaining_amount)
        })
    else:
        error_detail = response.get("message", str(response))
        raise HTTPException(status_code=400, detail=f"PayChangu initiation failed: {error_detail}")


@router.post("/verify-stuck-extension-payment/")
async def verify_stuck_extension_payment(
    request: Request,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Verify extension payment when process is stuck - finds payment by booking ID."""
    # Get request body
    try:
        request_body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON in request body")
    
    # Get booking_id from request body
    booking_id = request_body.get("booking_id")
    if not booking_id:
        raise HTTPException(status_code=422, detail="booking_id field is required")
    
    # Get booking
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission")
    
    # Find the most recent extension payment for this booking
    payment = db.query(PaymentModel).filter(
        PaymentModel.booking_id == booking_id,
        PaymentModel.payment_type == "extension"
    ).order_by(PaymentModel.paid_at.desc().nullslast(), PaymentModel.payment_id.desc()).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="No extension payment found for this booking")
    
    if not payment.transaction_id:
        raise HTTPException(
            status_code=400, 
            detail="Extension payment was not initiated properly. No transaction ID found."
        )
    
    # Call PayChangu verification
    try:
        client, _ = _get_paychangu_client()
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, client.verify_transaction, payment.transaction_id)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=f"PayChangu client error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

    # Handle successful extension payment
    if response.get("status") == "success":
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        
        # Update booking end date and status
        additional_months = None
        if payment.meta and isinstance(payment.meta, dict):
            additional_months = payment.meta.get("additional_months")
        
        if additional_months:
            new_end_date = booking.end_date + relativedelta(months=additional_months)
            booking.end_date = new_end_date
            booking.status = 'confirmed'
            
            # Update total_amount to include extension payment
            previous_payments = db.query(PaymentModel).filter(
                PaymentModel.booking_id == booking.booking_id,
                PaymentModel.status == 'completed'
            ).all()
            
            previous_total = sum(p.amount for p in previous_payments)
            new_total_amount = previous_total + payment.amount
            booking.total_amount = float(new_total_amount)
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        return {
            "status": "success",
            "message": "Extension payment verified successfully",
            "booking_status": booking.status,
            "new_end_date": booking.end_date.isoformat() if booking.end_date else None
        }
    else:
        return {
            "status": "failed",
            "message": "Extension payment verification failed",
            "response": response
        }


@router.post("/verify-stuck-complete-payment/")
async def verify_stuck_complete_payment(
    request: Request,
    background_tasks: BackgroundTasks,
    current_user=Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Verify complete payment when process is stuck - finds payment by booking ID."""
    # Get request body
    try:
        request_body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON in request body")
    
    # Get booking_id from request body
    booking_id = request_body.get("booking_id")
    if not booking_id:
        raise HTTPException(status_code=422, detail="booking_id field is required")
    
    # Get booking
    booking = db.query(BookingModel).filter(
        BookingModel.booking_id == booking_id,
        BookingModel.student_id == current_user.user_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found or you don't have permission")
    
    # Find the most recent complete payment for this booking
    payment = db.query(PaymentModel).filter(
        PaymentModel.booking_id == booking_id,
        PaymentModel.payment_type == "complete"
    ).order_by(PaymentModel.paid_at.desc().nullslast(), PaymentModel.payment_id.desc()).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="No complete payment found for this booking")
    
    if not payment.transaction_id:
        raise HTTPException(
            status_code=400, 
            detail="Complete payment was not initiated properly. No transaction ID found."
        )
    
    # Call PayChangu verification
    try:
        client, _ = _get_paychangu_client()
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, client.verify_transaction, payment.transaction_id)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=f"PayChangu client error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

    # Handle successful complete payment
    if response.get("status") == "success":
        # Update payment status
        payment.status = 'completed'
        payment.paid_at = datetime.utcnow()
        
        # Update booking payment type and status
        booking.payment_type = 'full'
        booking.status = 'confirmed'
        
        # Update total_amount to reflect full payment
        try:
            platform_fee = get_platform_fee(db)
            original_months = booking.duration_months
            full_amount = float((booking.room.price_per_month * Decimal(original_months)) + Decimal(str(platform_fee)))
            booking.total_amount = full_amount
        except Exception as e:
            print(f"Error calculating full amount for booking: {e}")
        
        db.add(payment)
        db.add(booking)
        
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database update failed: {e}")
        
        return {
            "status": "success",
            "message": "Complete payment verified successfully",
            "booking_status": booking.status,
            "payment_type": booking.payment_type
        }
    else:
        return {
            "status": "failed",
            "message": "Complete payment verification failed",
            "response": response
        }
