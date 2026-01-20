from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import os
import json
import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError
from sqlalchemy.orm import Session
from sqlalchemy import select, update, desc, and_, or_
from models import DeviceToken, User, Notification, NotificationRead
from database import get_db
import uuid
import logging
import asyncio

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
try:
    # Get service account key from environment variable
    firebase_credentials = os.getenv('FIREBASE_CREDENTIALS')
    if not firebase_credentials:
        raise ValueError('FIREBASE_CREDENTIALS environment variable not set')
        
    # Parse the JSON string from environment variable
    cred_dict = json.loads(firebase_credentials)
    
    # Initialize the app with the service account credentials
    cred = credentials.Certificate(cred_dict)
    firebase_admin.initialize_app(cred)
    logger.info('Firebase Admin SDK initialized successfully')
except Exception as e:
    logger.error(f'Error initializing Firebase Admin SDK: {str(e)}')
    raise

router = APIRouter(
    prefix='/notifications',
    tags=['notifications']
)

# Pydantic models
class RegisterTokenRequest(BaseModel):
    user_id: str
    token: str
    platform: Optional[str] = 'android'  # or 'ios'

class NotificationPayload(BaseModel):
    user_ids: List[str]
    title: str
    body: str
    type: Optional[str] = "other"  # 'booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other'
    data: Optional[dict] = {}

# Device token registration endpoint
@router.post('/register-token')
async def register_device_token(req: RegisterTokenRequest, db: Session = Depends(get_db)):
    # Parse user_id as UUID type
    try:
        user_id = uuid.UUID(req.user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID")
    
    # Check if user exists
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Upsert logic
    try:
        q = db.query(DeviceToken).filter(DeviceToken.user_id == user_id, DeviceToken.token == req.token).one_or_none()
        if q:
            # Update platform, updated_at
            q.platform = req.platform
            db.commit()
            return {"status": "Token updated", "user_id": req.user_id, "token": req.token}
        else:
            dt = DeviceToken(user_id=user_id, token=req.token, platform=req.platform)
            db.add(dt)
            db.commit()
            return {"status": "Token registered", "user_id": req.user_id, "token": req.token}
    except Exception as e:
        db.rollback()
        logger.error(f"Error registering device token for user {req.user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to register device token")

# Device token unregistration endpoint
@router.delete('/unregister-token')
async def unregister_device_token(req: RegisterTokenRequest, db: Session = Depends(get_db)):
    # Parse user_id as UUID type
    try:
        user_id = uuid.UUID(req.user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID")
    
    # Check if user exists
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    try:
        # Find and delete the device token
        q = db.query(DeviceToken).filter(DeviceToken.user_id == user_id, DeviceToken.token == req.token).one_or_none()
        if q:
            db.delete(q)
            db.commit()
            return {"status": "Token unregistered", "user_id": req.user_id, "token": req.token}
        else:
            return {"status": "Token not found", "user_id": req.user_id, "token": req.token}
    except Exception as e:
        db.rollback()
        logger.error(f"Error unregistering device token for user {req.user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to unregister device token")

# FCM sending utility using Firebase Admin SDK
async def send_fcm_push(token: str, title: str, body: str, data: Optional[dict] = None) -> Dict[str, Any]:
    """
    Send a push notification using Firebase Admin SDK
    
    Args:
        token: The FCM registration token of the target device
        title: Notification title
        body: Notification body
        data: Optional data payload
        
    Returns:
        Dict containing the message ID or error information
    """
    if not token:
        raise ValueError("Token cannot be empty")
        
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        token=token,
        data=data or {},
    )
    
    try:
        # Run blocking Firebase call in a thread executor to avoid blocking the event loop
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(None, messaging.send, message)
        logger.info(f"Successfully sent message: {response}")
        return {"success": True, "message_id": response, "status": "Message sent successfully"}
    except ValueError as e:
        logger.error(f"Invalid argument error: {e}")
        return {"success": False, "error": f"Invalid argument: {str(e)}", "status": "Failed to send message"}
    except FirebaseError as e:
        logger.error(f"Firebase error: {e}")
        return {"success": False, "error": f"Firebase error: {str(e)}", "status": "Failed to send message"}
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return {"success": False, "error": f"Unexpected error: {str(e)}", "status": "Failed to send message"}

# Helper function to send notifications (can be imported by other modules)
async def send_notification_to_users(
    db: Session,
    user_ids: List[uuid.UUID],
    title: str,
    body: str,
    notification_type: str = "other",
    data: Optional[dict] = None
) -> Dict[str, Any]:
    """
    Helper function to send notifications to multiple users and save them to the database.
    This function can be imported and used by other endpoints.
    
    Args:
        db: Database session
        user_ids: List of user UUIDs to send notifications to
        title: Notification title
        body: Notification body
        notification_type: Type of notification (booking, payment, message, etc.)
        data: Optional additional data payload
        
    Returns:
        Dict with status and counts
    """
    if not user_ids:
        return {"status": "skipped", "message": "No users to notify"}
    
    # Validate notification type
    valid_types = ['booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other']
    notification_type = notification_type if notification_type in valid_types else 'other'
    
    # Get device tokens for all users
    tokens = db.query(DeviceToken).filter(DeviceToken.user_id.in_(user_ids)).all()
    
    if not tokens:
        logger.warning(f"No device tokens found for users: {user_ids}")
    
    # Prepare FCM data payload with type included
    # FCM requires all data values to be strings
    fcm_data = {}
    if data:
        for key, value in data.items():
            fcm_data[str(key)] = str(value) if value is not None else ""
    fcm_data['type'] = notification_type
    
    notifications_created = []
    fcm_responses = []
    
    try:
        # Map to store created notifications by user_id
        user_notification_map = {}

        # Create notification records in database for all users
        for user_id in user_ids:
            notification = Notification(
                user_id=user_id,
                type=notification_type,
                title=title,
                body=body,
                data=fcm_data,
                is_read=False
            )
            db.add(notification)
            # Store reference to notification object
            user_notification_map[user_id] = notification
            notifications_created.append(user_id)
        
        # Commit all notifications to database
        db.commit()
        
        # Refresh notifications to get the generated IDs
        for notif in user_notification_map.values():
            db.refresh(notif)
            
        logger.info(f"Created {len(notifications_created)} notification records in database")
        
        # Send FCM push notifications
        for t in tokens:
            try:
                # Create a copy of fcm_data for this user
                user_fcm_data = fcm_data.copy()
                
                # Add notification_id to the payload if available
                if t.user_id in user_notification_map:
                    user_fcm_data['notification_id'] = str(user_notification_map[t.user_id].notification_id)
                
                resp = await send_fcm_push(t.token, title, body, user_fcm_data)
                fcm_responses.append({"user_id": str(t.user_id), "result": resp})
            except Exception as e:
                logger.error(f"Error sending FCM to token {t.token}: {str(e)}")
                fcm_responses.append({"user_id": str(t.user_id), "error": str(e)})
        
        return {
            "status": "success",
            "notifications_saved": len(notifications_created),
            "fcm_sent": len([r for r in fcm_responses if r.get("result", {}).get("success")]),
            "fcm_responses": fcm_responses
        }
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error in send_notification_to_users: {str(e)}")
        return {
            "status": "error",
            "error": str(e),
            "notifications_saved": 0
        }


# Push notification trigger endpoint
@router.post('/send')
async def send_notification(payload: NotificationPayload, db: Session = Depends(get_db)):
    # Parse UUIDs, skip bad ones
    parsed_user_ids = []
    for uid in payload.user_ids:
        try:
            parsed_user_ids.append(uuid.UUID(uid))
        except Exception:
            continue
    
    if not parsed_user_ids:
        raise HTTPException(status_code=400, detail="No valid user_ids provided")
    
    # Use the helper function
    result = await send_notification_to_users(
        db=db,
        user_ids=parsed_user_ids,
        title=payload.title,
        body=payload.body,
        notification_type=payload.type,
        data=payload.data
    )
    
    if result["status"] == "error":
        raise HTTPException(status_code=500, detail=f"Error sending notifications: {result.get('error')}")
    
    return {
        "status": "done",
        "notifications_saved": result["notifications_saved"],
        "fcm_responses": result["fcm_responses"]
    }

# ============================================
# Notification Management Endpoints
# ============================================

@router.get('', response_model=Dict[str, Any])
async def get_notifications(
    user_id: str = Query(..., description="User ID to fetch notifications for"),
    is_read: Optional[bool] = Query(None, description="Filter by read status (true/false)"),
    type: Optional[str] = Query(None, description="Filter by notification type"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of notifications to return"),
    offset: int = Query(0, ge=0, description="Number of notifications to skip"),
    db: Session = Depends(get_db)
):
    """
    Get notifications for a user with optional filtering and pagination.
    
    Query Parameters:
    - user_id: Required. The user ID to fetch notifications for
    - is_read: Optional. Filter by read status (true/false)
    - type: Optional. Filter by notification type (booking, message, payment, etc.)
    - limit: Optional. Maximum number of notifications (default: 50, max: 100)
    - offset: Optional. Number of notifications to skip for pagination (default: 0)
    """
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID")
    
    # Verify user exists
    user = db.query(User).filter(User.user_id == user_uuid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Build query - ensure we only get notifications for this specific user
    query = db.query(Notification).filter(Notification.user_id == user_uuid)
    
    # Apply filters
    if is_read is not None:
        query = query.filter(Notification.is_read == is_read)
    
    if type:
        valid_types = ['booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other']
        if type in valid_types:
            query = query.filter(Notification.type == type)
    
    # Get total count before pagination
    total_count = query.count()
    
    # Apply ordering (newest first) and pagination
    notifications = query.order_by(desc(Notification.created_at)).offset(offset).limit(limit).all()
    
    # Get unread count
    unread_count = db.query(Notification).filter(
        Notification.user_id == user_uuid,
        Notification.is_read == False
    ).count()
    
    # Convert SQLAlchemy objects to dictionaries before validation
    notification_dicts = [{
        'notification_id': n.notification_id,
        'user_id': n.user_id,
        'type': n.type,
        'title': n.title,
        'body': n.body,
        'data': n.data or {},
        'is_read': n.is_read,
        'created_at': n.created_at
    } for n in notifications]
    
    return {
        "notifications": [NotificationRead.model_validate(n).model_dump() for n in notification_dicts],
        "total": total_count,
        "unread_count": unread_count,
        "limit": limit,
        "offset": offset
    }


@router.get('/{notification_id}', response_model=NotificationRead)
async def get_notification(
    notification_id: str,
    user_id: str = Query(..., description="User ID to verify ownership"),
    db: Session = Depends(get_db)
):
    """
    Get a specific notification by ID.
    Verifies that the notification belongs to the specified user.
    """
    try:
        notif_uuid = uuid.UUID(notification_id)
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID format")
    
    notification = db.query(Notification).filter(
        Notification.notification_id == notif_uuid,
        Notification.user_id == user_uuid
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    return NotificationRead.model_validate(notification)


@router.put('/{notification_id}/read', response_model=NotificationRead)
async def mark_notification_read(
    notification_id: str,
    user_id: str = Query(..., description="User ID to verify ownership"),
    db: Session = Depends(get_db)
):
    """
    Mark a specific notification as read.
    Verifies that the notification belongs to the specified user.
    """
    try:
        notif_uuid = uuid.UUID(notification_id)
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID format")
    
    notification = db.query(Notification).filter(
        Notification.notification_id == notif_uuid,
        Notification.user_id == user_uuid
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    
    logger.info(f"Marked notification {notification_id} as read for user {user_id}")
    return NotificationRead.model_validate(notification)


@router.put('/read-all', response_model=Dict[str, Any])
async def mark_all_notifications_read(
    user_id: str = Query(..., description="User ID to mark all notifications as read"),
    type: Optional[str] = Query(None, description="Optional: Only mark notifications of this type as read"),
    db: Session = Depends(get_db)
):
    """
    Mark all notifications as read for a user.
    Optionally filter by notification type.
    """
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID")
    
    # Build query
    query = db.query(Notification).filter(
        Notification.user_id == user_uuid,
        Notification.is_read == False
    )
    
    # Apply type filter if provided
    if type:
        valid_types = ['booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other']
        if type in valid_types:
            query = query.filter(Notification.type == type)
    
    # Update all matching notifications
    updated_count = query.update({"is_read": True}, synchronize_session=False)
    db.commit()
    
    logger.info(f"Marked {updated_count} notifications as read for user {user_id}")
    return {
        "status": "success",
        "updated_count": updated_count,
        "message": f"Marked {updated_count} notification(s) as read"
    }


@router.delete('/{notification_id}', response_model=Dict[str, str])
async def delete_notification(
    notification_id: str,
    user_id: str = Query(..., description="User ID to verify ownership"),
    db: Session = Depends(get_db)
):
    """
    Delete a specific notification.
    Verifies that the notification belongs to the specified user.
    """
    try:
        notif_uuid = uuid.UUID(notification_id)
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID format")
    
    notification = db.query(Notification).filter(
        Notification.notification_id == notif_uuid,
        Notification.user_id == user_uuid
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    db.delete(notification)
    db.commit()
    
    logger.info(f"Deleted notification {notification_id} for user {user_id}")
    return {
        "status": "success",
        "message": "Notification deleted successfully"
    }


@router.delete('', response_model=Dict[str, Any])
async def delete_notifications(
    user_id: str = Query(..., description="User ID to delete notifications for"),
    is_read: Optional[bool] = Query(None, description="Optional: Only delete read/unread notifications"),
    type: Optional[str] = Query(None, description="Optional: Only delete notifications of this type"),
    delete_all: bool = Query(False, description="If true, delete all notifications (ignores other filters)"),
    db: Session = Depends(get_db)
):
    """
    Delete notifications for a user with optional filtering.
    
    Query Parameters:
    - user_id: Required. The user ID to delete notifications for
    - is_read: Optional. Only delete read (true) or unread (false) notifications
    - type: Optional. Only delete notifications of this type
    - delete_all: Optional. If true, delete all notifications (default: false)
    """
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID")
    
    # Build query
    if delete_all:
        query = db.query(Notification).filter(Notification.user_id == user_uuid)
    else:
        query = db.query(Notification).filter(Notification.user_id == user_uuid)
        
        # Apply filters
        if is_read is not None:
            query = query.filter(Notification.is_read == is_read)
        
        if type:
            valid_types = ['booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other']
            if type in valid_types:
                query = query.filter(Notification.type == type)
    
    # Get count before deletion
    deleted_count = query.count()
    
    # Delete notifications
    query.delete(synchronize_session=False)
    db.commit()
    
    logger.info(f"Deleted {deleted_count} notification(s) for user {user_id}")
    return {
        "status": "success",
        "deleted_count": deleted_count,
        "message": f"Deleted {deleted_count} notification(s)"
    }


@router.get('/stats/summary', response_model=Dict[str, Any])
async def get_notification_stats(
    user_id: str = Query(..., description="User ID to get notification statistics for"),
    db: Session = Depends(get_db)
):
    """
    Get notification statistics for a user.
    Returns counts by type and read status.
    """
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user_id UUID")
    
    # Get total count
    total_count = db.query(Notification).filter(Notification.user_id == user_uuid).count()
    
    # Get unread count
    unread_count = db.query(Notification).filter(
        Notification.user_id == user_uuid,
        Notification.is_read == False
    ).count()
    
    # Get counts by type
    type_counts = {}
    valid_types = ['booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other']
    for notif_type in valid_types:
        count = db.query(Notification).filter(
            Notification.user_id == user_uuid,
            Notification.type == notif_type
        ).count()
        if count > 0:
            type_counts[notif_type] = count
    
    return {
        "user_id": user_id,
        "total_count": total_count,
        "unread_count": unread_count,
        "read_count": total_count - unread_count,
        "type_counts": type_counts
    }


# ---- USAGE NOTES ----
# Call /notifications/register-token from your Flutter app on login/register to save the device token.
# Call /notifications/send from booking/payment event in your backend to notify affected users.
# 
# Notification Management Endpoints:
# - GET /notifications?user_id={uuid} - Get notifications with optional filters (is_read, type, limit, offset)
# - GET /notifications/{notification_id}?user_id={uuid} - Get a specific notification
# - PUT /notifications/{notification_id}/read?user_id={uuid} - Mark a notification as read
# - PUT /notifications/read-all?user_id={uuid}&type={type} - Mark all notifications as read (optionally filtered by type)
# - DELETE /notifications/{notification_id}?user_id={uuid} - Delete a specific notification
# - DELETE /notifications?user_id={uuid}&is_read={bool}&type={type}&delete_all={bool} - Delete notifications with filters
# - GET /notifications/stats/summary?user_id={uuid} - Get notification statistics
