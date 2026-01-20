from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from uuid import UUID

from database import get_db
from models import (
    Review as ReviewModel,
    ReviewBase,
    ReviewCreate,
    ReviewRead,
    Booking as BookingModel,
    Hostel,
    Room,
    User,
)
from endpoints.users import get_current_user

router = APIRouter(prefix="/reviews", tags=["reviews"])

@router.post("/booking/{booking_id}", response_model=ReviewRead)
async def create_or_update_review_for_booking(
    booking_id: UUID,
    payload: ReviewBase,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create or update a review for a specific booking by the current student.

    Constraints:
    - Only the student who owns the booking can review it.
    - Only allowed if booking is confirmed or completed (status != 'cancelled'/'rejected').
    - One review per booking (updates if it already exists).
    """

    booking = (
        db.query(BookingModel)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .filter(
            BookingModel.booking_id == booking_id,
            BookingModel.student_id == current_user.user_id,
        )
        .first()
    )

    if not booking:
        raise HTTPException(404, "Booking not found for current user")

    if booking.status.lower() in {"cancelled", "rejected"}:
        raise HTTPException(400, "Cannot review a cancelled or rejected booking")

    hostel_id = booking.room.hostel.hostel_id

    # one review per (user, hostel)
    existing = (
        db.query(ReviewModel)
        .filter(
            ReviewModel.user_id == current_user.user_id,
            ReviewModel.hostel_id == hostel_id,
        )
        .first()
    )

    if existing:
        existing.rating = payload.rating
        existing.comment = payload.comment
        existing.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(existing)
        return ReviewRead.from_orm(existing)

    review = ReviewModel(
        user_id=current_user.user_id,
        hostel_id=hostel_id,
        rating=payload.rating,
        comment=payload.comment,
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return ReviewRead.from_orm(review)


@router.get("/hostel/{hostel_id}", response_model=list[ReviewRead])
async def list_reviews_for_hostel(
    hostel_id: UUID,
    db: Session = Depends(get_db),
):
    """Return all reviews for a particular hostel (for future use on hostel detail)."""

    reviews = db.query(ReviewModel).filter(ReviewModel.hostel_id == hostel_id).order_by(ReviewModel.created_at.desc()).all()
    return [ReviewRead.from_orm(r) for r in reviews]


@router.get("/booking/{booking_id}", response_model=ReviewRead | None)
async def get_review_for_booking(
    booking_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Fetch the current student's review for a specific booking if it exists."""

    booking = (
        db.query(BookingModel)
        .join(Room, BookingModel.room_id == Room.room_id)
        .join(Hostel, Room.hostel_id == Hostel.hostel_id)
        .filter(
            BookingModel.booking_id == booking_id,
            BookingModel.student_id == current_user.user_id,
        )
        .first()
    )

    if not booking:
        raise HTTPException(404, "Booking not found for current user")

    hostel_id = booking.room.hostel.hostel_id

    review = (
        db.query(ReviewModel)
        .filter(
            ReviewModel.user_id == current_user.user_id,
            ReviewModel.hostel_id == hostel_id,
        )
        .first()
    )
    if not review:
        return None

    return ReviewRead.from_orm(review)
   

   