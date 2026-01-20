from fastapi import Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from models import (
    User, Hostel, Room, Media,
    MediaRead
)
from database import get_db
import uuid
import os
import shutil

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

def save_upload_file(upload_file: UploadFile, entity_id: str, user_id: str = None, hostel_name: str = None, is_room_media: bool = False, room_number: str = None) -> str:
    """Save uploaded file with unique name and return the file path.
    
    Args:
        upload_file: The file to upload
        entity_id: ID of the entity (hostel or room)
        user_id: ID of the user uploading the file
        hostel_name: Name of the hostel (used for folder structure)
        is_room_media: Whether this is a room media file
        room_number: Room number (required if is_room_media is True)
    """
    # Create directory path
    dir_parts = [UPLOAD_DIR]
    if user_id:
        dir_parts.append(str(user_id))
        if hostel_name:
            # Remove special characters from hostel name for filesystem safety
            safe_hostel_name = "".join(c if c.isalnum() or c in (' ', '-', '_') else '_' for c in hostel_name).strip()
            dir_parts.append(safe_hostel_name)
            
            # Add room directory if this is room media
            if is_room_media and room_number:
                safe_room_number = "".join(c if c.isalnum() or c == '-' else '_' for c in room_number).strip()
                dir_parts.append(f"room_{safe_room_number}")
    
    # Create directory if it doesn't exist
    dir_path = os.path.join(*dir_parts)
    os.makedirs(dir_path, exist_ok=True)
    
    # Generate unique filename
    file_extension = upload_file.filename.split('.')[-1].lower() if '.' in upload_file.filename else 'jpg'
    unique_filename = f"{entity_id}_{uuid.uuid4().hex}.{file_extension}"
    file_path = os.path.join(dir_path, unique_filename)
    
    # Save file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
    
    # Return relative path from UPLOAD_DIR for storage in database
    return os.path.relpath(file_path, UPLOAD_DIR)


async def upload_hostel_media(
    hostel_id: str,
    file: UploadFile = File(...),
    media_type: str = Form(...),
    is_cover: bool = Form(False),
    display_order: int = Form(0),
    uploader_email: str = Form(...),
    db: Session = Depends(get_db)
):
    """Upload media file for a hostel."""
    
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    # Verify hostel exists
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    # Verify uploader is the landlord
    uploader = db.query(User).filter(
        User.email == uploader_email,
        User.user_type == 'landlord'
    ).first()
    
    if not uploader or uploader.user_id != hostel.landlord_id:
        raise HTTPException(
            status_code=403,
            detail="Only the hostel owner can upload media"
        )
    
    # Get uploader's user ID
    uploader = db.query(User).filter(User.email == uploader_email).first()
    if not uploader:
        raise HTTPException(status_code=404, detail="Uploader not found")
    
    # Save file with user and hostel folder structure
    file_path = save_upload_file(
        upload_file=file,
        entity_id=hostel_id,
        user_id=str(uploader.user_id),
        hostel_name=hostel.name
    )
    
    # If this is set as cover, unset any existing cover
    if is_cover:
        db.query(Media).filter(
            Media.hostel_id == hostel_uuid,
            Media.is_cover == True
        ).update({"is_cover": False})
    
    # Get file size
    file_size = os.path.getsize(file_path) if os.path.exists(file_path) else None
    
    # Create media record
    media_id = str(uuid.uuid4())
    media = Media(
        media_id=media_id,
        hostel_id=hostel_uuid,
        url=file_path,  # Changed from file_path to url
        file_name=file.filename,
        file_size=file_size,
        mime_type=file.content_type or 'application/octet-stream',
        media_type=media_type,
        uploaded_by=uploader.user_id,  # Changed from uploader_id to uploaded_by
        is_cover=is_cover,
        display_order=display_order
    )
    
    db.add(media)
    db.commit()
    db.refresh(media)
    
    return media


async def upload_room_media(
    room_id: str,
    file: UploadFile = File(...),
    media_type: str = Form(...),
    is_cover: bool = Form(False),
    display_order: int = Form(0),
    uploader_email: str = Form(...),
    db: Session = Depends(get_db)
):
    """Upload media file for a room."""
    
    try:
        room_uuid = uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
    
    # Verify room exists and get hostel
    room = db.query(Room).filter(Room.room_id == room_uuid).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    
    # Verify uploader is the landlord
    uploader = db.query(User).filter(
        User.email == uploader_email,
        User.user_type == 'landlord'
    ).first()
    
    if not uploader or uploader.user_id != hostel.landlord_id:
        raise HTTPException(
            status_code=403,
            detail="Only the hostel owner can upload media"
        )
    
    # Get uploader's user ID
    uploader = db.query(User).filter(User.email == uploader_email).first()
    if not uploader:
        raise HTTPException(status_code=404, detail="Uploader not found")
    
    # Get room and hostel information
    room = db.query(Room).filter(Room.room_id == room_uuid).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
        
    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found for this room")
    
    # Save file with user, hostel, and room folder structure
    file_path = save_upload_file(
        upload_file=file,
        entity_id=room_id,
        user_id=str(uploader.user_id),
        hostel_name=hostel.name,
        is_room_media=True,
        room_number=room.room_number
    )
    
    # If this is set as cover, unset any existing cover
    if is_cover:
        db.query(Media).filter(
            Media.room_id == room_uuid,
            Media.is_cover == True
        ).update({"is_cover": False})
    
    # Get file size
    file_size = os.path.getsize(file_path) if os.path.exists(file_path) else None
    
    # Create media record
    media_id = str(uuid.uuid4())
    media = Media(
        media_id=media_id,
        room_id=room_uuid,
        url=file_path,  # Changed from file_path to url
        file_name=file.filename,
        file_size=file_size,
        mime_type=file.content_type or 'application/octet-stream',
        media_type=media_type,
        uploaded_by=uploader.user_id,  # Changed from uploader_id to uploaded_by
        is_cover=is_cover,
        display_order=display_order
    )
    
    db.add(media)
    db.commit()
    db.refresh(media)
    
    return media


def get_hostel_media(hostel_id: str, db: Session = Depends(get_db)):
    """Get all media for a hostel."""
    
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    # Verify hostel exists
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    media_files = db.query(Media).filter(
        Media.hostel_id == hostel_uuid
    ).order_by(Media.display_order, Media.created_at).all()
    
    return media_files


def get_room_media(room_id: str, db: Session = Depends(get_db)):
    """Get all media for a room."""
    
    try:
        room_uuid = uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
    
    # Verify room exists
    room = db.query(Room).filter(Room.room_id == room_uuid).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    media_files = db.query(Media).filter(
        Media.room_id == room_uuid
    ).order_by(Media.display_order, Media.created_at).all()
    
    return media_files


def delete_media(media_id: str, db: Session = Depends(get_db)):
    """Delete a media file."""
    
    try:
        media_uuid = uuid.UUID(media_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid media ID format")
    
    media = db.query(Media).filter(Media.media_id == media_uuid).first()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
    
    # Delete physical file
    full_path = os.path.join(UPLOAD_DIR, media.url) if media.url else None
    if full_path and os.path.exists(full_path):
        try:
            os.remove(full_path)
            # Try to remove the directory if it's empty
            dir_path = os.path.dirname(full_path)
            if os.path.exists(dir_path) and not os.listdir(dir_path):
                os.rmdir(dir_path)
                # Try to remove the user directory if it's empty
                user_dir = os.path.dirname(dir_path)
                if os.path.exists(user_dir) and not os.listdir(user_dir):
                    os.rmdir(user_dir)
        except Exception as e:
            # Log the error but don't fail the request
            print(e)
            
    
    # Delete database record
    db.delete(media)
    db.commit()
    
    return {"message": "Media deleted successfully"}


def set_media_as_cover(media_id: str, db: Session = Depends(get_db)):
    """Set a media file as the cover image/video."""
    
    try:
        media_uuid = uuid.UUID(media_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid media ID format")
    
    media = db.query(Media).filter(Media.media_id == media_uuid).first()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found")
    
    # Unset any existing cover for the same entity
    if media.hostel_id:
        db.query(Media).filter(
            Media.hostel_id == media.hostel_id,
            Media.is_cover == True
        ).update({"is_cover": False})
    elif media.room_id:
        db.query(Media).filter(
            Media.room_id == media.room_id,
            Media.is_cover == True
        ).update({"is_cover": False})
    
    # Set this media as cover
    media.is_cover = True
    db.commit()
    
    return {"message": "Media set as cover successfully"}
