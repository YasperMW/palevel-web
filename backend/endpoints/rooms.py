import os
import shutil
from fastapi import Depends, HTTPException, Form, Query, status, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from models import (
    User, Hostel, Room, Booking,
    RoomCreate, RoomUpdate, RoomRead, Media
)
from database import get_db
import uuid
from typing import Optional





# Update the create_room function
async def create_room(
    hostel_id: str = Form(...),
    room_number: str = Form(...),
    room_type: str = Form(...),
    capacity: int = Form(...),
    price_per_month: float = Form(None),
    landlord_email: str = Form(...),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """Create a new room in a hostel with an optional image."""
    
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    # Verify landlord owns the hostel
    landlord = db.query(User).filter(
        User.email == landlord_email,
        User.user_type == 'landlord'
    ).first()
    
    if not landlord or landlord.user_id != hostel.landlord_id:
        raise HTTPException(
            status_code=403,
            detail="Only the hostel owner can add rooms"
        )
    
    # Use hostel's price_per_month if not provided
    final_price = price_per_month if price_per_month is not None else hostel.price_per_month
    if final_price is None:
        raise HTTPException(
            status_code=400,
            detail="Price per month is required for the first room. Please set a default price for the hostel first."
        )
    
    # Create room
    room_id = str(uuid.uuid4())
    
    # Create directory path with hostel name and room number
    UPLOAD_DIR = "uploads"
    
    # Clean and sanitize hostel name and room number for filesystem safety
    def sanitize_filename(name: str) -> str:
        # Remove or replace invalid characters
        return "".join([c if c.isalnum() or c in ' _-.' else '_' for c in name]).strip()
    
    hostel_name_safe = sanitize_filename(hostel.name)
    room_number_safe = sanitize_filename(room_number)
    
    # Create directory structure: uploads/hostel_name/room_number
    dir_path = os.path.join(UPLOAD_DIR, hostel_name_safe, f"room_{room_number_safe}")
    os.makedirs(dir_path, exist_ok=True)
    
    # Create room record
    db_room = Room(
        room_id=room_id,
        hostel_id=hostel_uuid,
        room_number=room_number,
        type=room_type.lower(),
        capacity=capacity,
        price_per_month=final_price,
        is_available=True,
        created_at=func.now(),
        updated_at=func.now()
    )
    
    db.add(db_room)
    
    # Update the hostel's room count
    hostel.total_rooms += 1
    
    # Handle image upload if provided
    if image:
        try:
            # Get file extension from the uploaded file
            file_extension = os.path.splitext(image.filename)[1].lower() if '.' in image.filename else '.jpg'
            unique_filename = f"room_{room_id}{file_extension}"
            file_path = os.path.join(dir_path, unique_filename)
            
            # Save the file
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image.file, buffer)
            
            # Create media record
            media_id = str(uuid.uuid4())
            relative_path = os.path.join(hostel_name_safe, f"room_{room_number_safe}", unique_filename).replace('\\', '/')
            media = Media(
                media_id=media_id,
                room_id=room_id,
                url=relative_path,  # Use url field instead of file_path
                file_name=unique_filename,
                file_size=os.path.getsize(file_path) if os.path.exists(file_path) else None,
                mime_type=image.content_type or 'image/jpeg',
                media_type='image',
                is_cover=True,
                uploaded_by=landlord.user_id,  # Use uploaded_by instead of uploader_id
                created_at=func.now()
            )
            db.add(media)
            
            # Associate media with the room
            db_room.image_url = relative_path  # Store the relative path in the room record
            
        except Exception as e:
            # If there's an error with the image, delete the room
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail=f"Error processing image: {str(e)}"
            )
    
    try:
        db.commit()
        db.refresh(db_room)
        return db_room
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error saving room: {str(e)}"
        )

def get_hostel_rooms(
    hostel_id: str = Query(...),
    user_type: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """Get all available rooms for a specific hostel with their images."""
    
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    # Verify hostel exists
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    # Base query for rooms
    query = db.query(Room).filter(Room.hostel_id == hostel_uuid)
    
    # If the user is a student, only show rooms with available capacity
    if user_type == 'student':
        query = query.filter(Room.occupants < Room.capacity)
    
    rooms = query.all()
    
    # Get all room IDs
    room_ids = [str(room.room_id) for room in rooms]
    
    # Get all images for these rooms in a single query
    images = {}
    if room_ids:
        media_list = db.query(Media).filter(
            Media.room_id.in_(room_ids),
            Media.media_type == 'image'
        ).all()
        
        # Create a mapping of room_id to image URL
        for media in media_list:
            room_id_str = str(media.room_id)
            clean_url = media.url.replace('\\', '/')
            if not clean_url.startswith('uploads/'):
                clean_url = f'uploads/{clean_url}'
            images[room_id_str] = f"/{clean_url}"

    # Add image URLs to each room
    result = []
    for room in rooms:
        room_data = {
            'room_id': str(room.room_id),
            'hostel_id': str(room.hostel_id),
            'room_number': room.room_number,
            'type': room.type,
            'capacity': room.capacity,
            'occupants': room.occupants,
            'price_per_month': float(room.price_per_month),
            'booking_fee': float(hostel.booking_fee) if hostel.booking_fee is not None else None,
            'availability_start_date': room.availability_start_date.isoformat() if room.availability_start_date else None,
            'availability_end_date': room.availability_end_date.isoformat() if room.availability_end_date else None,
            'configuration': room.configuration,
            'is_available': room.is_available,
            'created_at': room.created_at.isoformat(),
            'updated_at': room.updated_at.isoformat(),
            'image_url': images.get(str(room.room_id))
        }
        result.append(room_data)
    
    return result

def get_room(room_id: str, db: Session = Depends(get_db)):
    """Get a specific room by ID with its image."""
    
    try:
        room_uuid = uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
    
    room = db.query(Room).filter(Room.room_id == room_uuid).first()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # Get the room's image if it exists
    image = db.query(Media).filter(
        Media.room_id == room_uuid,
        Media.media_type == 'image'
    ).first()
    
    # Add image URL to the response
    room_data = room.__dict__
    if image:
        room_data['image_url'] = f"/{image.url}"  # Add the base URL in your frontend
    
    return room_data


async def update_room(
    room_id: str,
    room_number: str = Form(None),
    room_type: str = Form(None),
    capacity: int = Form(None),
    price_per_month: float = Form(None),
    is_occupied: bool = Form(None),
    image: Optional[UploadFile] = File(None),
    landlord_email: str = Form(None),  # Required if updating image
    db: Session = Depends(get_db)
):
    """Update a room and optionally its image."""
    
    try:
        room_uuid = uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
    
    room = db.query(Room).filter(Room.room_id == room_uuid).first()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # Update fields if provided
    if room_number is not None:
        room.room_number = room_number
    if room_type is not None:
        room.type = room_type.lower()  # Use correct field name and convert to lowercase
    if capacity is not None:
        room.capacity = capacity
    if price_per_month is not None:
        room.price_per_month = price_per_month
    if is_occupied is not None:
        # Update occupants based on is_occupied status
        if is_occupied:
            # If marking as occupied, set occupants to room capacity and mark as unavailable
            room.occupants = room.capacity
            room.is_available = False
        else:
            # If marking as unoccupied, set occupants to 0 and mark as available
            room.occupants = 0
            room.is_available = True
    
    # Handle image update if provided
    if image:
        if not landlord_email:
            raise HTTPException(status_code=400, detail="Landlord email is required when updating room image")
            
        # Get uploader's user ID
        uploader = db.query(User).filter(User.email == landlord_email).first()
        if not uploader:
            raise HTTPException(status_code=404, detail="Uploader not found")
            
        # Get hostel for this room
        hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
        if not hostel:
            raise HTTPException(status_code=404, detail="Hostel not found for this room")
            
        # Delete existing room image if it exists
        existing_media = db.query(Media).filter(
            Media.room_id == room.room_id,
            Media.media_type == 'image'
        ).first()
        
        if existing_media:
            # Delete the file
            import os
            file_path = os.path.join("uploads", existing_media.url)
            if os.path.exists(file_path):
                os.remove(file_path)
            # Delete the media record
            db.delete(existing_media)
        
        # Save the new image
        from endpoints.media import save_upload_file
        
        # Create directory path
        import os
        UPLOAD_DIR = "uploads"
        dir_path = os.path.join(UPLOAD_DIR, str(uploader.user_id), f"hostel_{hostel.hostel_id}")
        os.makedirs(dir_path, exist_ok=True)
        
        # Generate unique filename
        file_extension = image.filename.split('.')[-1].lower() if '.' in image.filename else 'jpg'
        unique_.filename = f"room_{room.room_id}.{file_extension}"
        file_path = os.path.join(dir_path, unique_filename)
        
        # Save file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Create media record
        media = Media(
            media_id=str(uuid.uuid4()),
            room_id=room.room_id,
            url=os.path.relpath(file_path, UPLOAD_DIR),
            file_name=image.filename,
            file_size=os.path.getsize(file_path) if os.path.exists(file_path) else None,
            mime_type=image.content_type or 'image/jpeg',
            media_type='image',
            is_cover=True,
            uploaded_by=uploader.user_id
        )
        db.add(media)
    
    room.updated_at = func.now()
    db.commit()
    db.refresh(room)
    
    return room

def delete_room(room_id: str, db: Session = Depends(get_db)):
    """Delete a room and update the hostel's room count."""
    
    try:
        room_uuid = uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
    
    room = db.query(Room).filter(Room.room_id == room_uuid).first()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # Check for existing bookings
    existing_bookings = db.query(Booking).filter(Booking.room_id == room_uuid).all()
    if existing_bookings:
        booking_count = len(existing_bookings)
        active_bookings = [b for b in existing_bookings if b.status in ['pending', 'confirmed', 'active']]
        
        if active_bookings:
            raise HTTPException(
                status_code=409, 
                detail=f"Cannot delete room with {len(active_bookings)} active booking(s). Please cancel or complete bookings first."
            )
        elif existing_bookings:
            # If only historical bookings exist, we can proceed but should inform
            # For now, treat any bookings as blocking for safety
            raise HTTPException(
                status_code=409,
                detail=f"Cannot delete room with {booking_count} booking(s) in the system. Please handle bookings first."
            )
    
    # Get the hostel to update the room count
    hostel = db.query(Hostel).filter(Hostel.hostel_id == room.hostel_id).first()
    
    # Delete the room
    db.delete(room)
    
    # Update the hostel's room count if the hostel exists
    if hostel and hostel.total_rooms > 0:
        hostel.total_rooms -= 1
    
    db.commit()
    
    return {"message": "Room deleted successfully"}
