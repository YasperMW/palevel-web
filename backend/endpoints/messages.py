# palevel-backend/endpoints/messages.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc
from typing import List
from uuid import UUID as PyUUID, uuid4
import json
import logging
import re
from datetime import datetime, date

from database import get_db
from models import (
    Message,
    User,
    MessageCreate,
    MessageRead,
    Conversation,
    Hostel,
    Booking,
    Room,
)
from .users import get_current_user
from .websocket import manager
from .notifications import send_notification_to_users

router = APIRouter(prefix="/messages", tags=["messages"])

logger = logging.getLogger("message_visibility")

PHONE_PLACEHOLDER = "[HIDDEN CONTACT]"
URL_PLACEHOLDER = "[HIDDEN LINK]"
HIDDEN_NOTICE = "Contact details are hidden because there is no active paid booking between you and this landlord."

phone_pattern = re.compile(r"\+?\d[\d\s\-\(\)]{6,}")
url_pattern = re.compile(r"(https?://[^\s]+|www\.[^\s]+)", re.IGNORECASE)


def get_student_and_landlord(user_a: User, user_b: User):
    student = None
    landlord = None
    if user_a.user_type == "tenant" and user_b.user_type == "landlord":
        student = user_a
        landlord = user_b
    elif user_b.user_type == "tenant" and user_a.user_type == "landlord":
        student = user_b
        landlord = user_a
    return student, landlord


def get_visibility_context(db: Session, user_a: User, user_b: User):
    student, landlord = get_student_and_landlord(user_a, user_b)
    if not student or not landlord:
        return {
            "booking_status": "not_applicable",
            "has_active_paid_booking": True,
            "student_id": None,
            "landlord_id": None,
        }
    # Import Payment model for the query
    from models import Payment
    
    today = date.today()
    booking_exists_clause = (
        db.query(Booking)
        .join(Room, Booking.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .join(Payment, Booking.booking_id == Payment.booking_id)
        .filter(
            Booking.student_id == student.user_id,
            Hostel.landlord_id == landlord.user_id,
            Booking.status == "confirmed",
            Payment.status == "completed",
            Booking.start_date <= today,
            Booking.end_date >= today,
        )
        .exists()
    )
    has_active = db.query(booking_exists_clause).scalar()
    return {
        "booking_status": "active_paid_booking" if has_active else "no_active_paid_booking",
        "has_active_paid_booking": bool(has_active),
        "student_id": str(student.user_id),
        "landlord_id": str(landlord.user_id),
    }


def mask_phone_numbers(text: str) -> str:
    def replacer(match: re.Match) -> str:
        matched = match.group(0)
        digits = [c for c in matched if c.isdigit()]
        if len(digits) >= 7:
            return PHONE_PLACEHOLDER
        return matched

    return phone_pattern.sub(replacer, text)


def mask_urls(text: str) -> str:
    return url_pattern.sub(URL_PLACEHOLDER, text)


def apply_content_filtering(raw: str, has_active_booking: bool):
    if has_active_booking:
        return raw, False, None
    filtered = mask_phone_numbers(raw)
    filtered = mask_urls(filtered)
    if filtered != raw:
        return filtered, True, HIDDEN_NOTICE
    return raw, False, None


def log_visibility_decision(action: str, message: Message, viewer_id, visibility_context: dict, is_hidden: bool):
    try:
        log_payload = {
            "action": action,
            "message_id": str(message.message_id),
            "conversation_id": str(message.conversation_id),
            "viewer_id": str(viewer_id),
            "sender_id": str(message.sender_id),
            "receiver_id": str(message.receiver_id),
            "booking_status": visibility_context.get("booking_status"),
            "has_active_paid_booking": visibility_context.get("has_active_paid_booking"),
            "decision_time": datetime.utcnow().isoformat(),
            "is_content_hidden": is_hidden,
        }
        logger.info(json.dumps(log_payload))
    except Exception:
        logger.exception("Failed to log message visibility decision")


# =====================================================
# CREATE MESSAGE
# =====================================================
@router.post("/", response_model=MessageRead)
async def create_message(
    message: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Send a new message.
    - Creates message in database
    - Sends real-time WebSocket notifications
    - Updates conversation lists
    - Sends push notification if receiver is offline
    """
    print(f"📤 Creating message from {current_user.user_id} to {message.receiver_id}")
    
    # -----------------------------
    # VALIDATE RECEIVER
    # -----------------------------
    receiver = db.query(User).filter(User.user_id == message.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")

    if receiver.user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Cannot send message to yourself")

    visibility_context = get_visibility_context(db, current_user, receiver)

    # -----------------------------
    # CREATE MESSAGE
    # -----------------------------
    conversation_id = message.conversation_id or uuid4()

    db_message = Message(
        conversation_id=conversation_id,
        sender_id=current_user.user_id,
        receiver_id=message.receiver_id,
        content=message.content,
        is_read=False,
        created_at=datetime.utcnow()
    )

    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    print(f"✅ Message created: {db_message.message_id}")

    filtered_content, is_hidden, notice = apply_content_filtering(
        db_message.content, visibility_context.get("has_active_paid_booking", True)
    )

    # -----------------------------
    # PREPARE MESSAGE PAYLOAD
    # -----------------------------
    message_body = {
        "id": str(db_message.message_id),
        "conversation_id": str(conversation_id),
        "sender_id": str(db_message.sender_id),
        "sender_type": current_user.user_type,
        "receiver_id": str(db_message.receiver_id),
        "receiver_type": receiver.user_type,
        "content": filtered_content,
        "created_at": db_message.created_at.isoformat(),
        "is_read": False,
        "is_delivered": False,
        "is_content_hidden": is_hidden,
        "content_visibility_notice": notice,
    }
    message_payload_receiver = {
        "type": "new_message",
        "message": message_body,
        "conversation_id": str(conversation_id),
    }
    message_payload_sender = {
        "type": "new_message",
        "message": message_body,
        "conversation_id": str(conversation_id),
    }

    log_visibility_decision(
        "deliver_message",
        db_message,
        message.receiver_id,
        visibility_context,
        is_hidden,
    )
    log_visibility_decision(
        "deliver_message",
        db_message,
        current_user.user_id,
        visibility_context,
        is_hidden,
    )

    # -----------------------------
    # SEND TO RECEIVER (REAL-TIME)
    # -----------------------------
    receiver_online = manager.is_user_online(str(message.receiver_id))
    delivered_to_receiver = False
    
    if receiver_online:
        print(f"👤 Receiver {message.receiver_id} is online, sending via WebSocket")
        delivered_to_receiver = await manager.send_personal_message(
            message_payload_receiver,
            str(message.receiver_id),
        )
        
        # Send delivery receipt to sender
        if delivered_to_receiver:
            delivery_payload = {
                "type": "message_delivered",
                "conversation_id": str(conversation_id),
                "message_id": str(db_message.message_id),
            }
            await manager.send_personal_message(
                delivery_payload,
                str(current_user.user_id),
            )
            print(f"✅ Message delivered to {message.receiver_id}")
    else:
        print(f"👤 Receiver {message.receiver_id} is offline")

    # -----------------------------
    # SEND TO SENDER (FOR REAL-TIME UPDATE IN CHAT)
    # -----------------------------
    await manager.send_personal_message(
        message_payload_sender,
        str(current_user.user_id),
    )
    print(f"✅ Message sent to sender {current_user.user_id}")

    # -----------------------------
    # UPDATE CONVERSATION LISTS FOR BOTH USERS
    # -----------------------------
    conversation_payload = {
        "type": "conversation_updated",
        "conversation_id": str(conversation_id),
        "last_message": filtered_content,
        "last_message_time": db_message.created_at.isoformat(),
        "last_message_sender_id": str(current_user.user_id),
        "sender_name": f"{current_user.first_name} {current_user.last_name}",
        "is_content_hidden": is_hidden,
        "content_visibility_notice": notice,
    }
    
    # Notify receiver
    await manager.send_personal_message(
        conversation_payload,
        str(message.receiver_id),
    )
    
    # Notify sender
    await manager.send_personal_message(
        conversation_payload,
        str(current_user.user_id),
    )
    
    print(f"✅ Conversation lists updated for both users")

    # -----------------------------
    # SEND PUSH NOTIFICATION (IF RECEIVER OFFLINE)
    # -----------------------------
    if not receiver_online:
        print(f"📱 Sending push notification to {message.receiver_id}")
        await send_notification_to_users(
            db=db,
            user_ids=[message.receiver_id],
            title=f"New message from {current_user.first_name}",
            body=filtered_content[:120],
            notification_type="message",
            data={
                "conversation_id": str(conversation_id),
                "sender_id": str(current_user.user_id),
                "message_id": str(db_message.message_id),
                "sender_name": f"{current_user.first_name} {current_user.last_name}",
                "content": filtered_content[:100],
            },
        )
        log_visibility_decision(
            "push_notification",
            db_message,
            message.receiver_id,
            visibility_context,
            is_hidden,
        )

    # Return the message with all necessary data
    return {
        "id": str(db_message.message_id),
        "message_id": str(db_message.message_id),
        "conversation_id": str(conversation_id),
        "sender_id": str(db_message.sender_id),
        "sender_type": current_user.user_type,
        "receiver_id": str(db_message.receiver_id),
        "receiver_type": receiver.user_type,
        "content": filtered_content,
        "created_at": db_message.created_at.isoformat(),
        "is_read": False,
        "is_delivered": False,
        "is_content_hidden": is_hidden,
        "content_visibility_notice": notice,
    }


# =====================================================
# GET CONVERSATIONS
# =====================================================
@router.get("/conversations/", response_model=List[Conversation])
async def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get all conversations for the current user.
    Each conversation includes the latest message and unread count.
    """
    print(f"📋 Getting conversations for user: {current_user.user_id}")
    
    # Get all unique conversations for this user
    subquery = (
        db.query(Message.conversation_id)
        .filter(
            or_(
                Message.sender_id == current_user.user_id,
                Message.receiver_id == current_user.user_id,
            )
        )
        .distinct()
        .subquery()
    )

    # Get the latest message for each conversation
    latest_messages = (
        db.query(Message)
        .filter(Message.conversation_id.in_(subquery))
        .order_by(Message.conversation_id, desc(Message.created_at))
        .distinct(Message.conversation_id)
        .all()
    )

    conversations = []

    for msg in latest_messages:
        # Determine the other user in the conversation
        other_user_id = (
            msg.receiver_id
            if msg.sender_id == current_user.user_id
            else msg.sender_id
        )

        other_user = db.query(User).filter(User.user_id == other_user_id).first()
        if not other_user:
            continue

        # Get hostel name if other user is a landlord
        hostel_name = None
        if other_user.user_type == "landlord":
            hostel = (
                db.query(Hostel)
                .filter(Hostel.landlord_id == other_user_id)
                .first()
            )
            if hostel:
                hostel_name = hostel.name

        # Count unread messages in this conversation
        unread_count = (
            db.query(Message)
            .filter(
                Message.conversation_id == msg.conversation_id,
                Message.receiver_id == current_user.user_id,
                Message.is_read == False,
            )
            .count()
        )

        visibility_context = get_visibility_context(db, current_user, other_user)
        last_message_filtered, is_hidden, notice = apply_content_filtering(
            msg.content, visibility_context.get("has_active_paid_booking", True)
        )
        log_visibility_decision(
            "conversation_preview",
            msg,
            current_user.user_id,
            visibility_context,
            is_hidden,
        )

        conversations.append(
            Conversation(
                conversation_id=msg.conversation_id,
                other_user_id=other_user_id,
                other_user_name=f"{other_user.first_name} {other_user.last_name}",
                other_user_initial=other_user.first_name[0].upper()
                if other_user.first_name
                else "U",
                hostel_name=hostel_name,
                last_message=last_message_filtered,
                last_message_time=msg.created_at.isoformat(),
                last_message_sender_id=msg.sender_id,
                unread_count=unread_count,
            )
        )

    print(f"✅ Found {len(conversations)} conversations for {current_user.user_id}")
    return conversations


# =====================================================
# GET MESSAGES
# =====================================================
@router.get("/{conversation_id}/", response_model=List[MessageRead])
async def get_messages(
    conversation_id: PyUUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get all messages in a conversation.
    Automatically marks messages as read when viewed by receiver.
    """
    print(f"📨 Getting messages for conversation: {conversation_id}, user: {current_user.user_id}")
    
    # Get all messages in the conversation
    messages = (
        db.query(Message)
        .filter(
            Message.conversation_id == conversation_id,
            or_(
                Message.sender_id == current_user.user_id,
                Message.receiver_id == current_user.user_id,
            ),
        )
        .order_by(Message.created_at)
        .all()
    )

    if not messages:
        raise HTTPException(status_code=404, detail="Conversation not found")

    first_message = messages[0]
    other_user_id = (
        first_message.receiver_id
        if first_message.sender_id == current_user.user_id
        else first_message.sender_id
    )
    other_user = db.query(User).filter(User.user_id == other_user_id).first()
    if other_user:
        visibility_context = get_visibility_context(db, current_user, other_user)
    else:
        visibility_context = {
            "booking_status": "not_applicable",
            "has_active_paid_booking": True,
            "student_id": None,
            "landlord_id": None,
        }

    # Mark messages as read for current user
    updated = False
    unread_message_ids = []
    
    for msg in messages:
        if msg.receiver_id == current_user.user_id and not msg.is_read:
            msg.is_read = True
            unread_message_ids.append(str(msg.message_id))
            updated = True

    if updated:
        db.commit()
        print(f"✅ Marked {len(unread_message_ids)} messages as read")

        if unread_message_ids:
            from collections import defaultdict
            sender_messages = defaultdict(list)
            
            for msg in messages:
                if str(msg.message_id) in unread_message_ids and msg.sender_id != current_user.user_id:
                    sender_messages[msg.sender_id].append(str(msg.message_id))
            
            for sender_id, message_ids in sender_messages.items():
                read_payload = {
                    "type": "message_read",
                    "conversation_id": str(conversation_id),
                    "message_ids": message_ids,
                    "read_by": str(current_user.user_id),
                    "read_at": datetime.utcnow().isoformat(),
                }
                
                await manager.send_personal_message(
                    read_payload,
                    str(sender_id),
                )
                print(f"✅ Sent read receipt to sender {sender_id} for {len(message_ids)} messages")

    response_messages: List[MessageRead] = []
    for msg in messages:
        filtered_content, is_hidden, notice = apply_content_filtering(
            msg.content, visibility_context.get("has_active_paid_booking", True)
        )
        log_visibility_decision(
            "fetch_message",
            msg,
            current_user.user_id,
            visibility_context,
            is_hidden,
        )
        response_messages.append(
            MessageRead(
                message_id=msg.message_id,
                conversation_id=msg.conversation_id,
                sender_id=msg.sender_id,
                receiver_id=msg.receiver_id,
                content=filtered_content,
                is_read=msg.is_read,
                created_at=msg.created_at,
                is_content_hidden=is_hidden,
                content_visibility_notice=notice,
            )
        )

    return response_messages


# =====================================================
# MARK AS READ
# =====================================================
@router.post("/{conversation_id}/read/")
async def mark_as_read(
    conversation_id: PyUUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Manually mark all messages in a conversation as read.
    """
    print(f"📖 Marking conversation {conversation_id} as read for user {current_user.user_id}")
    
    # Get all unread messages for current user in this conversation
    messages = db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.receiver_id == current_user.user_id,
        Message.is_read == False,
    ).all()

    if not messages:
        return {"status": "success", "marked_count": 0, "message": "No unread messages"}

    message_ids = [str(msg.message_id) for msg in messages]
    
    # Mark messages as read
    db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.receiver_id == current_user.user_id,
        Message.is_read == False,
    ).update({Message.is_read: True})
    
    db.commit()

    print(f"✅ Marked {len(messages)} messages as read")

    # Send read receipt to sender(s)
    if messages:
        # Group messages by sender
        from collections import defaultdict
        sender_messages = defaultdict(list)
        
        for msg in messages:
            sender_messages[msg.sender_id].append(str(msg.message_id))
        
        # Send read receipt to each sender
        for sender_id, message_ids in sender_messages.items():
            if sender_id == current_user.user_id:
                continue  # Skip messages sent by self
                
            read_payload = {
                "type": "message_read",
                "conversation_id": str(conversation_id),
                "message_ids": message_ids,
                "read_by": str(current_user.user_id),
                "read_at": datetime.utcnow().isoformat(),
            }
            
            await manager.send_personal_message(
                read_payload,
                str(sender_id),
            )
            print(f"✅ Sent read receipt to sender {sender_id}")

    return {"status": "success", "marked_count": len(messages)}


# =====================================================
# CHECK ONLINE STATUS
# =====================================================
@router.get("/users/{user_id}/online")
async def check_user_online(
    user_id: str,
    current_user: User = Depends(get_current_user),
):
    """
    Check if a user is currently online.
    """
    is_online = manager.is_user_online(user_id)
    return {"user_id": user_id, "is_online": is_online}


# =====================================================
# GET UNREAD COUNT
# =====================================================
@router.get("/unread/count")
async def get_unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get total count of unread messages for current user.
    """
    unread_count = (
        db.query(Message)
        .filter(
            Message.receiver_id == current_user.user_id,
            Message.is_read == False,
        )
        .count()
    )
    
    return {"user_id": current_user.user_id, "unread_count": unread_count}
