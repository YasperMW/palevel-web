from fastapi import Depends, HTTPException, Form, status, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from models import (
    User, Hostel, Room, Media, Review, Verification,
    HostelCreate, HostelUpdate, HostelRead
)
from database import get_db, db_session
from endpoints.notifications import send_notification_to_users
import uuid
from typing import List, Optional
from fastapi import APIRouter

router = APIRouter(prefix="/hostels", tags=["hostels"])


# Background task function for sending new listing notifications
async def _send_new_listing_notifications(
    hostel_id: str,
    hostel_name: str,
    university: str,
    district: str,
    price_per_month: str | None,
    price_text: str
):
    """Background task to send new listing notifications to students"""
    try:
        with db_session() as db:
            # Get all students (tenants) who have the same university (case-insensitive)
            students = db.query(User).filter(
                User.user_type == 'tenant',
                func.lower(User.university) == func.lower(university),
                User.university.isnot(None),
                User.university != ''
            ).all()
            
            if students:
                student_ids = [student.user_id for student in students]
                
                # Send notification to all students
                await send_notification_to_users(
                    db=db,
                    user_ids=student_ids,
                    title="New Hostel Listing Available",
                    body=f"New hostel '{hostel_name}' has been listed near {university}. {price_text}. Check it out now!",
                    notification_type="system",
                    data={
                        "hostel_id": hostel_id,
                        "hostel_name": hostel_name,
                        "university": university,
                        "district": district,
                        "price_per_month": price_per_month,
                        "type": "new_listing"
                    }
                )
                print(f"Sent new listing notifications to {len(student_ids)} students at {university}")
    except Exception as e:
        print(f"Error sending new listing notifications: {e}")


async def create_hostel(
    background_tasks: BackgroundTasks,
    name: str = Form(...),
    address: str = Form(...),
    district: str = Form(...),
    university: str = Form(...),
    description: str = Form(None),
    amenities: str = Form("[]"),  # Accept as string and parse as JSON
    price_per_month: float = Form(None),
    booking_fee: float = Form(0.0),  # Default to 0 if not provided
    latitude: float = Form(...),
    longitude: float = Form(...),
    landlord_email: str = Form(...),
    type: str = Form(...),
    db: Session = Depends(get_db)
):
    """Create a new hostel for a landlord."""
    
    # Parse amenities from JSON string to list
    import json
    try:
        amenities_list = json.loads(amenities) if amenities else []
        if not isinstance(amenities_list, list):
            amenities_list = [amenities_list]  # Handle case where single amenity is sent
    except json.JSONDecodeError:
        amenities_list = [amenities] if amenities else []  # Fallback to single item list if not valid JSON
    
    # Get landlord by email
    landlord = db.query(User).filter(
        User.email == landlord_email,
        User.user_type == 'landlord'
    ).first()
    
    if not landlord:
        raise HTTPException(
            status_code=404,
            detail="Landlord not found or user is not a landlord"
        )
    
    # Create hostel with location point
    hostel_id = str(uuid.uuid4())
    location_point = f"POINT({longitude} {latitude})"
    
    db_hostel = Hostel(
        hostel_id=hostel_id,
        landlord_id=landlord.user_id,
        name=name,
        district=district,
        university=university,
        address=address,
        type=type,
        description=description,
        amenities=amenities_list,  # Use the parsed amenities_list
        price_per_month=price_per_month,
        booking_fee=booking_fee,  # Add booking_fee to the Hostel model
        location=location_point,
        created_at=func.now(),
        updated_at=func.now()
    )
    
    db.add(db_hostel)
    db.commit()
    db.refresh(db_hostel)
    
    # Prepare data for background notification task
    hostel_id_str = str(db_hostel.hostel_id)
    price_text = f"MWK {float(price_per_month):,.0f}/month" if price_per_month else "Price on request"
    price_str = str(price_per_month) if price_per_month else None
    
    # Send notifications in background (don't block the response)
    background_tasks.add_task(
        _send_new_listing_notifications,
        hostel_id_str,
        name,
        university,
        district,
        price_str,
        price_text
    )
    
    # Ensure amenities is a dictionary in the response
    amenities = {}
    if db_hostel.amenities is not None:
        if isinstance(db_hostel.amenities, list):
            amenities = {item: True for item in db_hostel.amenities if item}
        elif isinstance(db_hostel.amenities, dict):
            amenities = {k: bool(v) for k, v in db_hostel.amenities.items() if k}
    
    return {
        "hostel_id": str(db_hostel.hostel_id),
        "landlord_id": str(db_hostel.landlord_id),
        "name": db_hostel.name,
        "district": db_hostel.district,
        "university": db_hostel.university,
        "address": db_hostel.address,
        "description": db_hostel.description,
        "amenities": amenities,
        "price_per_month": float(db_hostel.price_per_month) if db_hostel.price_per_month is not None else None,
        "booking_fee": float(db_hostel.booking_fee) if db_hostel.booking_fee is not None else 0.0,
        "latitude": latitude,
        "longitude": longitude,
        "created_at": db_hostel.created_at,
        "updated_at": db_hostel.updated_at,
        "total_rooms": 0,
        "occupied_rooms": 0,
        "available_rooms": 0,
        "cover_image_url": None
    }


@router.get("/all-hostels")
def get_all_hostels(db: Session = Depends(get_db)):
    """Get all hostels for students with their media and landlord details."""
    
    # Get all active hostels whose landlords have approved verification status
    hostels = db.query(Hostel).join(Verification, Hostel.landlord_id == Verification.landlord_id).filter(
        Hostel.is_active == True,
        Verification.status == 'approved'
    ).all()
    
    # Fetch all coordinates in a single query for better performance
    hostel_ids = [str(h.hostel_id) for h in hostels]
    coordinates_map = {}
    if hostel_ids:
        # Use IN clause with tuple for PostgreSQL
        placeholders = ','.join([':id' + str(i) for i in range(len(hostel_ids))])
        params = {f'id{i}': hostel_id for i, hostel_id in enumerate(hostel_ids)}
        coord_results = db.execute(
            text(f"SELECT hostel_id::text, ST_X(location::geometry) as longitude, ST_Y(location::geometry) as latitude FROM hostels WHERE hostel_id::text IN ({placeholders})"),
            params
        ).fetchall()
        coordinates_map = {str(row.hostel_id): (float(row.longitude) if row.longitude is not None else 0.0, float(row.latitude) if row.latitude is not None else 0.0) for row in coord_results}
    
    result = []
    for hostel in hostels:
        # Count rooms
        rooms = db.query(Room).filter(Room.hostel_id == hostel.hostel_id).all()
        available_rooms = sum(1 for room in rooms if room.is_available and room.occupants < room.capacity)
        total_rooms = len(rooms)
        occupied_rooms = total_rooms - available_rooms
        
        # Get all media for the hostel
        media_files = db.query(Media).filter(
            Media.hostel_id == hostel.hostel_id
        ).order_by(Media.display_order, Media.created_at).all()
        
        # Get landlord details
        landlord = db.query(User).filter(User.user_id == hostel.landlord_id).first()
        
        landlord_name = f"{landlord.first_name} {landlord.last_name}" if landlord and landlord.first_name and landlord.last_name else "Unknown Landlord"
        landlord_phone = landlord.phone_number if landlord else "+265 888 123 456"

        # Aggregate reviews for this hostel
        reviews_stats = db.query(
            func.coalesce(func.avg(Review.rating), 0).label("avg_rating"),
            func.count(Review.review_id).label("reviews_count"),
        ).filter(Review.hostel_id == hostel.hostel_id).first()

        average_rating = float(reviews_stats.avg_rating or 0)
        reviews_count = int(reviews_stats.reviews_count or 0)
        
        # Extract coordinates from the pre-fetched coordinates map
        hostel_id_str = str(hostel.hostel_id)
        if hostel_id_str in coordinates_map:
            longitude, latitude = coordinates_map[hostel_id_str]
        else:
            # Fallback: try to parse as WKT string if it's already in that format
            try:
                if hostel.location and isinstance(hostel.location, str) and hostel.location.startswith('POINT('):
                    coords = hostel.location.replace('POINT(', '').replace(')', '').split()
                    longitude = float(coords[0]) if len(coords) > 0 else 0.0
                    latitude = float(coords[1]) if len(coords) > 1 else 0.0
                else:
                    longitude = 0.0
                    latitude = 0.0
            except Exception:
                longitude = 0.0
                latitude = 0.0
        
        # Ensure amenities is a dictionary
        amenities = {}
        if hostel.amenities is not None:
            if isinstance(hostel.amenities, list):
                amenities = {item: True for item in hostel.amenities if item}
            elif isinstance(hostel.amenities, dict):
                amenities = {k: bool(v) for k, v in hostel.amenities.items() if k}
        
        # If amenities is None or empty after processing, use an empty dict
        result.append({
            "hostel_id": str(hostel.hostel_id),
            "landlord_id": str(hostel.landlord_id),
            "landlord_name": landlord_name,
            "landlord_phone": landlord_phone,
            "name": hostel.name,
            "district": hostel.district,
            "university": hostel.university,
            "address": hostel.address,
            "description": hostel.description,
            "type": hostel.type,
            "amenities": amenities,
            "price_per_month": float(hostel.price_per_month) if hostel.price_per_month is not None else None,
            "booking_fee": float(hostel.booking_fee) if hostel.booking_fee is not None else 0.0,
            "latitude": latitude,
            "longitude": longitude,
            "created_at": hostel.created_at,
            "updated_at": hostel.updated_at,
            "total_rooms": total_rooms,
            "occupied_rooms": occupied_rooms,
            "available_rooms": available_rooms,
            "is_active": bool(getattr(hostel, "is_active", True)),
            "average_rating": average_rating,
            "reviews_count": reviews_count,
            "media": [
                {
                    "media_id": str(m.media_id),
                    "url": m.url,
                    "file_name": m.file_name,
                    "media_type": m.media_type,
                    "is_cover": m.is_cover,
                    "display_order": m.display_order,
                    "created_at": m.created_at
                } for m in media_files
            ]
        })
    
    return result


@router.get("/")
def get_landlord_hostels(
    landlord_email: str,
    db: Session = Depends(get_db)
):
    """Get all hostels for a specific landlord with their media."""
    
    # Get landlord by email
    landlord = db.query(User).filter(
        User.email == landlord_email,
        User.user_type == 'landlord'
    ).first()
    
    if not landlord:
        raise HTTPException(
            status_code=404,
            detail="Landlord not found or user is not a landlord"
        )
    
    # Get hostels with additional stats
    hostels = db.query(Hostel).filter(Hostel.landlord_id == landlord.user_id).all()
    
    result = []
    for hostel in hostels:
        # Count rooms
        total_rooms = db.query(Room).filter(Room.hostel_id == hostel.hostel_id).count()
        occupied_rooms = db.query(Room).filter(
            Room.hostel_id == hostel.hostel_id,
            Room.is_available == False
        ).count()
        
        # Get all media for the hostel
        media_files = db.query(Media).filter(
            Media.hostel_id == hostel.hostel_id
        ).order_by(Media.display_order, Media.created_at).all()
        
        # Find cover image
        cover_media = next((m for m in media_files if m.is_cover), None)
        
        # Extract coordinates from PostGIS geography using ST_X and ST_Y
        try:
            # Query coordinates directly from database using PostGIS functions
            coord_result = db.execute(
                text("SELECT ST_X(location::geometry) as longitude, ST_Y(location::geometry) as latitude FROM hostels WHERE hostel_id = :hostel_id"),
                {"hostel_id": str(hostel.hostel_id)}
            ).first()
            
            if coord_result:
                longitude = float(coord_result.longitude) if coord_result.longitude is not None else None
                latitude = float(coord_result.latitude) if coord_result.latitude is not None else None
            else:
                longitude = None
                latitude = None
        except Exception as e:
            # Fallback: try to parse as WKT string if it's already in that format
            if hostel.location and isinstance(hostel.location, str) and hostel.location.startswith('POINT('):
                coords_str = hostel.location[6:-1]  # Remove "POINT(" and ")"
                coords = coords_str.split()
                longitude = float(coords[0]) if len(coords) > 0 else None
                latitude = float(coords[1]) if len(coords) > 1 else None
            else:
                longitude = None
                latitude = None
        
        # Ensure amenities is a dictionary in the response
        amenities = {}
        if hostel.amenities is not None:
            if isinstance(hostel.amenities, list):
                amenities = {item: True for item in hostel.amenities if item}
            elif isinstance(hostel.amenities, dict):
                amenities = {k: bool(v) for k, v in hostel.amenities.items() if k}
        
        hostel_data = {
            "hostel_id": str(hostel.hostel_id),
            "landlord_id": str(hostel.landlord_id),
            "name": hostel.name,
            "district": hostel.district,
            "university": hostel.university,
            "address": hostel.address,
            "description": hostel.description,
            "amenities": amenities,
            "price_per_month": float(hostel.price_per_month) if hostel.price_per_month is not None else None,
            "booking_fee": float(hostel.booking_fee) if hostel.booking_fee is not None else 0.0,
            "latitude": latitude,
            "longitude": longitude,
            "created_at": hostel.created_at,
            "updated_at": hostel.updated_at,
            "total_rooms": total_rooms,
            "occupied_rooms": occupied_rooms,
            "available_rooms": total_rooms - occupied_rooms,
            "is_active": bool(getattr(hostel, "is_active", True)),
            "media": [
                {
                    "media_id": str(m.media_id),
                    "url": m.url,
                    "file_name": m.file_name,
                    "media_type": m.media_type,
                    "is_cover": m.is_cover,
                    "display_order": m.display_order,
                    "created_at": m.created_at
                } for m in media_files
            ]
        }
        
        result.append(hostel_data)
    
    return result


def get_hostel(hostel_id: str, db: Session = Depends(get_db)):
    """Get a specific hostel by ID with its media."""
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    # Get hostel media
    media_files = db.query(Media).filter(
        Media.hostel_id == hostel_uuid
    ).order_by(Media.display_order, Media.created_at).all()
    
    # Count rooms
    total_rooms = db.query(Room).filter(Room.hostel_id == hostel.hostel_id).count()
    occupied_rooms = db.query(Room).filter(
        Room.hostel_id == hostel.hostel_id,
        Room.is_available == False
    ).count()
    
    # Extract coordinates from PostGIS geography using ST_X and ST_Y
    try:
        # Query coordinates directly from database using PostGIS functions
        coord_result = db.execute(
            text("SELECT ST_X(location::geometry) as longitude, ST_Y(location::geometry) as latitude FROM hostels WHERE hostel_id = :hostel_id"),
            {"hostel_id": str(hostel.hostel_id)}
        ).first()
        
        if coord_result:
            longitude = float(coord_result.longitude) if coord_result.longitude is not None else None
            latitude = float(coord_result.latitude) if coord_result.latitude is not None else None
        else:
            longitude = None
            latitude = None
    except Exception as e:
        # Fallback: try to parse as WKT string if it's already in that format
        if hostel.location and isinstance(hostel.location, str) and hostel.location.startswith('POINT('):
            coords_str = hostel.location[6:-1]  # Remove "POINT(" and ")"
            coords = coords_str.split()
            longitude = float(coords[0]) if len(coords) > 0 else None
            latitude = float(coords[1]) if len(coords) > 1 else None
        else:
            longitude = None
            latitude = None
    
    # Ensure amenities is a dictionary
    amenities = {}
    if hostel.amenities is not None:
        if isinstance(hostel.amenities, list):
            amenities = {item: True for item in hostel.amenities if item}
        elif isinstance(hostel.amenities, dict):
            amenities = {k: bool(v) for k, v in hostel.amenities.items() if k}
    # If amenities is None or empty after processing, use an empty dict
        
    return {
        "hostel_id": str(hostel.hostel_id),
        "landlord_id": str(hostel.landlord_id),
        "name": hostel.name,
        "district": hostel.district,
        "university": hostel.university,
        "address": hostel.address,
        "description": hostel.description,
        "amenities": amenities,
        "price_per_month": float(hostel.price_per_month) if hostel.price_per_month is not None else None,
        "booking_fee": float(hostel.booking_fee) if hostel.booking_fee is not None else 0.0,
        "latitude": latitude,
        "longitude": longitude,
        "created_at": hostel.created_at,
        "updated_at": hostel.updated_at,
        "total_rooms": total_rooms,
        "occupied_rooms": occupied_rooms,
        "available_rooms": total_rooms - occupied_rooms,
        "media": [
            {
                "media_id": str(m.media_id),
                "url": m.url,
                "file_name": m.file_name,
                "media_type": m.media_type,
                "is_cover": m.is_cover,
                "display_order": m.display_order,
                "created_at": m.created_at
            } for m in media_files
        ]
    }


@router.post("/update_hostel/{hostel_id}")
async def update_hostel(
    hostel_id: str,
    name: str = Form(None),
    address: str = Form(None),
    district: str = Form(None),
    university: str = Form(None),
    description: str = Form(None),
    amenities: List[str] = Form(None),
    booking_fee: float = Form(None),
    latitude: float = Form(None),
    longitude: float = Form(None),
    type: str = Form(None),
    db: Session = Depends(get_db)
):
    """Update a hostel."""
    
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    # Update fields
    if name is not None:
        hostel.name = name
    if address is not None:
        hostel.address = address
    if district is not None:
        hostel.district = district
    if university is not None:
        hostel.university = university
    if description is not None:
        hostel.description = description
    if booking_fee is not None:
        hostel.booking_fee = booking_fee
    if type is not None:
        hostel.type = type
    if amenities is not None:
        # Convert list of amenities to a dictionary with boolean values
        if isinstance(amenities, list):
            amenities_dict = {item: True for item in amenities} if amenities else {}
            hostel.amenities = amenities_dict
        else:
            hostel.amenities = amenities
    if latitude is not None and longitude is not None:
        location_point = f"POINT({longitude} {latitude})"
        hostel.location = location_point
    
    hostel.updated_at = func.now()
    db.commit()
    db.refresh(hostel)
    
    return get_hostel(hostel_id, db)


def change_hostel_status(hostel_id: str, db: Session = Depends(get_db)):
    """Soft delete / toggle activation status for a hostel.

    Instead of permanently deleting the record, flip the is_active flag so that
    students will no longer see inactive hostels, while landlords can still
    manage and optionally reactivate them.
    """
    
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")

    # Toggle active status instead of hard-deleting
    current = bool(getattr(hostel, "is_active", True))
    hostel.is_active = not current
    hostel.updated_at = func.now()
    db.commit()

    if hostel.is_active:
        return {"message": "Hostel activated successfully"}
    else:
        return {"message": "Hostel deactivated successfully"}
    return {"message": "Hostel deactivated successfully"}


def get_hostel_amenities(hostel_id: str, db: Session = Depends(get_db)):
    """Get amenities for a specific hostel."""
    try:
        hostel_uuid = uuid.UUID(hostel_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid hostel ID format")
    
    hostel = db.query(Hostel).filter(Hostel.hostel_id == hostel_uuid).first()
    
    if not hostel:
        raise HTTPException(status_code=404, detail="Hostel not found")
    
    # Ensure amenities is a dictionary in the response
    amenities = {}
    if hostel.amenities is not None:
        if isinstance(hostel.amenities, list):
            amenities = {item: True for item in hostel.amenities if item}
        elif isinstance(hostel.amenities, dict):
            amenities = {k: bool(v) for k, v in hostel.amenities.items() if k}
    
    return {
        "hostel_id": str(hostel.hostel_id),
        "name": hostel.name,
        "amenities": amenities
    }


def get_landlord_stats(landlord_email: str, db: Session = Depends(get_db)):
    """Get statistics for a landlord including property count, room count, and occupancy rate."""
    # Verify the landlord exists
    landlord = db.query(User).filter(
        User.email == landlord_email,
        User.user_type == 'landlord'
    ).first()
    
    if not landlord:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Landlord not found or user is not a landlord"
        )
    
    # Get total properties
    total_properties = db.query(Hostel).filter(
        Hostel.landlord_id == landlord.user_id
    ).count()
    
    # Get total rooms and occupied rooms across all hostels
    result = db.query(
        func.count(Room.room_id).label('total_rooms'),
        func.sum(Room.occupants).label('total_occupants'),
        func.sum(Room.capacity).label('total_capacity')
    ).join(
        Hostel, Hostel.hostel_id == Room.hostel_id
    ).filter(
        Hostel.landlord_id == landlord.user_id
    ).first()
    
    total_rooms = result.total_rooms or 0
    total_occupants = result.total_occupants or 0
    total_capacity = result.total_capacity or 1  # Avoid division by zero
    
    # Calculate occupancy rate (percentage of occupied beds)
    occupancy_rate = (total_occupants / total_capacity) * 100 if total_capacity > 0 else 0
    
    return {
        'total_properties': total_properties,
        'total_rooms': total_rooms,
        'total_occupants': total_occupants,
        'total_capacity': total_capacity,
        'occupancy_rate': round(occupancy_rate, 2)  # Round to 2 decimal places
    }



