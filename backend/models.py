from uuid import UUID as PyUUID, uuid4

from pydantic import BaseModel, Field
from sqlalchemy import Column, String, Boolean, DateTime, text, ForeignKey, Numeric, Date, Integer, BigInteger, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from database import Base
from datetime import datetime, date


class Verification(Base):
    """SQLAlchemy model for the verifications table."""

    __tablename__ = "verifications"

    verification_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    landlord_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )
    id_type = Column(String(20), nullable=False)
    id_document_url = Column(String(255), nullable=True)
    status = Column(
        String(20),
        default="pending",
        nullable=False,
    )  # 'pending', 'approved', 'rejected'
    verified_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    # Relationship
    landlord = relationship("User", backref="verifications")


class User(Base):
    """SQLAlchemy model aligned with palevel.sql `users` table."""

    __tablename__ = "users"

    user_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )

    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=True)  # Nullable for OAuth users
    user_type = Column(String(20), nullable=False)  # 'tenant' | 'landlord' | 'admin'
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    phone_number = Column(String(50), nullable=True)
    university = Column(String(255), nullable=True)
    date_of_birth = Column(Date, nullable=True)  # For OAuth users
    year_of_study = Column(String(20), nullable=True)  # For students (1st Year, 2nd Year, etc.)
    gender = Column(String(20), nullable=True)  # User gender (male, female, other, prefer_not_to_say)
    
    # OAuth fields
    google_id = Column(String(255), unique=True, nullable=True, index=True)
    oauth_provider = Column(String(50), nullable=True)  # 'google', 'facebook', etc.
    oauth_access_token = Column(Text, nullable=True)
    oauth_refresh_token = Column(Text, nullable=True)
    is_oauth_user = Column(Boolean, default=False, server_default='false')

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
    is_verified = Column(Boolean, server_default=text("FALSE"))
    is_blacklisted = Column(Boolean, server_default=text("FALSE"))
    
    # Relationships
    payment_preferences = relationship("PaymentPreference", back_populates="user", cascade="all, delete-orphan")
    disbursements = relationship("Disbursement", back_populates="landlord", cascade="all, delete-orphan")


class OTP(Base):
    """SQLAlchemy model for one-time passwords used for account verification."""

    __tablename__ = "otps"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id"), nullable=False)
    code = Column(String(6), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_used = Column(Boolean, server_default=text("FALSE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    @staticmethod
    def generate_code() -> str:
        import secrets

        return "".join(secrets.choice("0123456789") for _ in range(6))


class Authentication(BaseModel):
    """Credentials for login/authentication."""

    email: str
    password: str

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    """Incoming payload for user signup.

    Flutter signup should send these fields.
    """

    first_name: str
    last_name: str
    email: str
    password: str  # plain text from client; will be hashed into password_hash
    phone_number: str | None = None
    user_type: str  # 'tenant' (student) | 'landlord' | 'admin'
    national_id_image: str | None = None  # Base64 encoded image or file path
    university: str | None = None
    gender: str | None = None

class OAuthUserCreate(BaseModel):
    """Incoming payload for OAuth user creation."""
    
    email: str
    first_name: str
    last_name: str
    google_id: str
    oauth_provider: str = "google"
    oauth_access_token: str | None = None
    oauth_refresh_token: str | None = None
    phone_number: str | None = None
    university: str | None = None


class OAuthRoleSelection(BaseModel):
    """Payload for role selection after OAuth login."""
    
    user_type: str = Field(..., pattern="^(tenant|landlord)$")
    phone_number: str | None = None
    university: str | None = None
    year_of_study: str | None = None
    date_of_birth: str | None = None  # ISO date string
    gender: str | None = None  # User gender (male, female, other, prefer_not_to_say)
    national_id_image: str | None = None  # Base64 encoded image or file path


class UserRead(BaseModel):
    """Data returned to clients after user creation/authentication."""

    user_id: PyUUID
    email: str
    user_type: str
    first_name: str
    last_name: str
    phone_number: str | None = None
    university: str | None = None
    is_verified: bool | None = None
    is_blacklisted: bool | None = None
    upload_error: str | None = None
    gender: str | None=None
    
    class Config:
        from_attributes = True


class Hostel(Base):
    """SQLAlchemy model for the hostels table."""

    __tablename__ = "hostels"

    hostel_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    landlord_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )
    name = Column(String(255), nullable=False)
    district = Column(String(255), nullable=False)
    university = Column(String(255), nullable=False)
    address = Column(String, nullable=False)
    type = Column(String(20), nullable=False, default='Private')  # 'Private', 'Shared', 'Self-contained'
    location = Column(String, nullable=False)  # Will store as "POINT(longitude latitude)"
    description = Column(String, nullable=True)
    booking_fee = Column(Numeric(10, 2), nullable=True)
    amenities = Column(JSONB, nullable=True)
    price_per_month = Column(Numeric(10, 2), nullable=True)
    total_rooms = Column(Integer, default=0)
    is_active = Column(Boolean, default=True, server_default='true')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    # Relationships
    landlord = relationship("User", backref="hostels")
    rooms = relationship("Room", back_populates="hostel", cascade="all, delete-orphan")
    media = relationship("Media", back_populates="hostel", cascade="all, delete-orphan")


class Room(Base):
    """SQLAlchemy model for the rooms table."""

    __tablename__ = "rooms"

    room_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    hostel_id = Column(
        UUID(as_uuid=True),
        ForeignKey("hostels.hostel_id", ondelete="CASCADE"),
        nullable=False,
    )
    room_number = Column(String(50), nullable=False)
    type = Column(String(20), nullable=False)  # 'single', 'double', 'shared', 'suite'
    capacity = Column(Integer, nullable=False, default=1, server_default='1')
    occupants = Column(Integer, nullable=False, default=0, server_default='0')
    price_per_month = Column(Numeric(10, 2), nullable=False)
    availability_start_date = Column(Date, nullable=True)
    availability_end_date = Column(Date, nullable=True)
    configuration = Column(JSONB, nullable=True)
    is_available = Column(Boolean, default=True, server_default='true')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    # Relationships
    hostel = relationship("Hostel", back_populates="rooms")
    media = relationship("Media", back_populates="room", cascade="all, delete-orphan")


class Media(Base):
    """SQLAlchemy model for the media table."""

    __tablename__ = "media"

    media_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    hostel_id = Column(
        UUID(as_uuid=True),
        ForeignKey("hostels.hostel_id", ondelete="CASCADE"),
        nullable=True,
    )
    room_id = Column(
        UUID(as_uuid=True),
        ForeignKey("rooms.room_id", ondelete="CASCADE"),
        nullable=True,
    )
    url = Column(String, nullable=False)
    file_name = Column(String, nullable=False)
    file_size = Column(BigInteger, nullable=True)
    mime_type = Column(String, nullable=False)
    media_type = Column(String, nullable=False)  # 'image', 'video'
    width = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    is_cover = Column(Boolean, default=False)
    display_order = Column(Integer, default=0)
    uploaded_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    hostel = relationship("Hostel", back_populates="media")
    room = relationship("Room", back_populates="media")
    uploader = relationship("User", backref="uploaded_media")


# Pydantic models for API
class HostelCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    address: str = Field(..., min_length=1)
    district: str = Field(..., min_length=1)
    university: str = Field(..., min_length=1)
    type: str = Field('Private', pattern='^(Private|Shared|Self-contained)$')
    description: str | None = None
    amenities: dict | None = None
    price_per_month: float | None = Field(None, ge=0, description="Default monthly price for rooms in this hostel")
    booking_fee: float | None = Field(0.0, ge=0, description="One-time booking fee for this hostel")
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class HostelUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    address: str | None = Field(None, min_length=1)
    district: str | None = Field(None, min_length=1)
    university: str | None = Field(None, min_length=1)
    type: str | None = Field(None, pattern='^(Private|Shared|Self-contained)$')
    description: str | None = None
    amenities: dict | None = None
    price_per_month: float | None = Field(None, ge=0, description="Default monthly price for rooms in this hostel")
    booking_fee: float | None = Field(None, ge=0, description="One-time booking fee for this hostel")
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)


class HostelRead(BaseModel):
    hostel_id: PyUUID
    landlord_id: PyUUID
    name: str
    address: str
    district: str
    university: str
    type: str = 'Private'
    description: str | None = None
    amenities: dict | None = None
    price_per_month: float | None = None
    booking_fee: float | None = 0.0
    created_at: datetime
    updated_at: datetime
    total_rooms: int | None = None
    occupied_rooms: int | None = None
    available_rooms: int | None = None
    is_active: bool = True
    cover_image_url: str | None = None

    class Config:
        from_attributes = True


class RoomCreate(BaseModel):
    room_number: str = Field(..., min_length=1, max_length=50)
    type: str = Field(..., pattern="^(single|double|shared|suite)$")
    price_per_month: float = Field(..., ge=0)
    availability_start_date: str | None = None  # ISO date string
    availability_end_date: str | None = None    # ISO date string
    configuration: dict | None = None
    is_available: bool = True


class RoomUpdate(BaseModel):
    room_number: str | None = Field(None, min_length=1, max_length=50)
    type: str | None = Field(None, pattern="^(single|double|shared|suite)$")
    price_per_month: float | None = Field(None, ge=0)
    availability_start_date: str | None = None
    availability_end_date: str | None = None
    configuration: dict | None = None
    is_available: bool | None = None


class RoomRead(BaseModel):
    room_id: PyUUID
    hostel_id: PyUUID
    room_number: str
    type: str
    price_per_month: float
    availability_start_date: date | None = None
    availability_end_date: date | None = None
    configuration: dict | None = None
    is_available: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class MediaRead(BaseModel):
    media_id: PyUUID
    hostel_id: PyUUID | None = None
    room_id: PyUUID | None = None
    url: str
    file_name: str
    file_size: int | None = None
    mime_type: str
    media_type: str
    width: int | None = None
    height: int | None = None
    duration_seconds: int | None = None
    is_cover: bool = False
    display_order: int = 0
    created_at: datetime

    class Config:
        from_attributes = True


class Booking(Base):
    """SQLAlchemy model for bookings table."""

    __tablename__ = "bookings"

    booking_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    room_id = Column(UUID(as_uuid=True), ForeignKey("rooms.room_id", ondelete="CASCADE"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    duration_months = Column(Integer, nullable=False, default=1)  # Store original booking duration in months
    status = Column(String(20), default="pending", nullable=False)
    payment_type = Column(String(20), nullable=False, default='full') 
    total_amount = Column(Numeric(10,2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    meta = Column(JSON, nullable=True)  # For storing additional booking metadata like extension details

    # Relationships
    student = relationship("User", backref="bookings")
    room = relationship("Room", backref="bookings")
    payments = relationship("Payment", back_populates="booking")
    disbursements = relationship("Disbursement", back_populates="booking")


class Payment(Base):
    """SQLAlchemy model for payments table."""

    __tablename__ = "payments"

    payment_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    booking_id = Column(UUID(as_uuid=True), ForeignKey("bookings.booking_id", ondelete="CASCADE"), nullable=False)
    amount = Column(Numeric(10,2), nullable=False)
    payment_type = Column(String(20), nullable=False, default='full')  # 'full' or 'booking_fee'
    payment_method = Column(String(20), nullable=False)
    transaction_id = Column(String(255), nullable=True)
    status = Column(String(20), default="pending", nullable=False)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    time_zone = Column(String, nullable=True)
    meta = Column(JSON, nullable=True)  # For storing additional payment metadata like extension months

    booking = relationship("Booking", back_populates="payments")


# Pydantic schemas for bookings and payments
class BookingCreate(BaseModel):
    student_id: PyUUID
    room_id: PyUUID
    start_date: date
    end_date: date | None = None  # Optional if duration_months provided
    duration_months: int | None = None  # Number of months for booking (optional)
    total_amount: float
    class Config:
        from_attributes = True


class BookingRead(BaseModel):
    booking_id: PyUUID
    student_id: PyUUID
    room_id: PyUUID
    start_date: date
    end_date: date
    duration_months: int
    status: str
    payment_type: str
    total_amount: float
    created_at: datetime
    class Config:
        from_attributes = True

class ReviewBase(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = Field(None, max_length=2000)


class ReviewCreate(ReviewBase):
    hostel_id: PyUUID
   


class ReviewRead(ReviewBase):
    review_id: PyUUID
    hostel_id: PyUUID
    student_id: PyUUID
    student_name: str | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class Configuration(Base):
    """SQLAlchemy model for system configurations."""
    __tablename__ = "configurations"

    config_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    config_key = Column(String(100), unique=True, nullable=False)
    config_value = Column(Numeric(10, 2), nullable=False)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


# Pydantic schemas for configurations
class ConfigCreate(BaseModel):
    """Schema for creating a new configuration."""
    config_key: str = Field(..., min_length=1, max_length=100)
    config_value: float = Field(..., ge=0)
    description: str | None = None


class ConfigUpdate(BaseModel):
    """Schema for updating a configuration."""
    config_value: float | None = Field(None, ge=0)
    description: str | None = None


class ConfigRead(BaseModel):
    """Schema for reading a configuration."""
    config_id: PyUUID
    config_key: str
    config_value: float
    description: str | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PaymentRead(BaseModel):
    payment_id: PyUUID
    booking_id: PyUUID
    amount: float
    payment_method: str
    transaction_id: str | None = None
    status: str
    paid_at: datetime | None = None
    class Config:
        from_attributes = True


# Add to models.py after the Payment model

class Message(Base):
    """SQLAlchemy model for messages between users."""
    
    __tablename__ = "messages"
    
    message_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    conversation_id = Column(
        UUID(as_uuid=True),
        index=True,
        nullable=False,
        comment="Unique ID for grouping messages between two users"
    )
    sender_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )
    receiver_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False, server_default='false')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

# Pydantic schemas for messages
class MessageBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)
    
class MessageCreate(MessageBase):
    receiver_id: PyUUID
    conversation_id: PyUUID | None = None  # Will be set by the API if not provided

class MessageRead(MessageBase):
    message_id: PyUUID
    conversation_id: PyUUID
    sender_id: PyUUID
    receiver_id: PyUUID
    is_read: bool
    created_at: datetime
    is_content_hidden: bool = False
    content_visibility_notice: str | None = None
    
    class Config:
        from_attributes = True

class Conversation(BaseModel):
    conversation_id: PyUUID
    other_user_id: PyUUID
    other_user_name: str
    other_user_initial: str
    last_message: str | None
    last_message_time: datetime | None
    unread_count: int = 0
    hostel_name: str | None = None
    room_number: str | None = None


# DeviceToken model for storing FCM tokens by user
from sqlalchemy import UniqueConstraint

class DeviceToken(Base):
    __tablename__ = "device_tokens"
    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("uuid_generate_v4()"))
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(512), nullable=False, unique=True, index=True)
    platform = Column(String(20), nullable=True)  # android/ios/web
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        UniqueConstraint('user_id', 'token', name='_user_token_uc'),
    )

    user = relationship("User", backref="device_tokens")


# Notification model for persistent notification storage
class Notification(Base):
    """SQLAlchemy model for persistent notifications."""
    
    __tablename__ = "notifications"
    
    notification_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type = Column(
        String(20),
        nullable=False,
        default="other",
        server_default="other",
    )  # 'booking', 'message', 'payment', 'maintenance', 'review', 'system', 'other'
    title = Column(String(255), nullable=True)
    body = Column(Text, nullable=True)
    data = Column(JSONB, nullable=True, default={}, server_default=text("'{}'::jsonb"))
    is_read = Column(Boolean, default=False, server_default='false', nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    
    # Relationships
    user = relationship("User", backref="notifications")


# Pydantic schemas for notifications
class NotificationCreate(BaseModel):
    """Schema for creating a new notification."""
    user_id: PyUUID
    type: str = Field(default="other", pattern="^(booking|message|payment|maintenance|review|system|other)$")
    title: str | None = Field(None, max_length=255)
    body: str | None = None
    data: dict | None = None


class NotificationUpdate(BaseModel):
    """Schema for updating a notification (e.g., marking as read)."""
    is_read: bool | None = None


class NotificationRead(BaseModel):
    """Schema for reading a notification."""
    notification_id: PyUUID
    user_id: PyUUID
    type: str
    title: str | None = None
    body: str | None = None
    data: dict | None = None
    is_read: bool
    created_at: datetime

class Review(Base):
    __tablename__ = "reviews"

    review_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuid_generate_v4()"),
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )
    hostel_id = Column(
        UUID(as_uuid=True),
        ForeignKey("hostels.hostel_id", ondelete="CASCADE"),
        nullable=False,
    )
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    user = relationship("User", backref="reviews")
    hostel = relationship("Hostel", backref="reviews")

    @property
    def student_id(self):
        return self.user_id

    @student_id.setter
    def student_id(self, value):
        self.user_id = value

    @property
    def student_name(self):
        if self.user is None:
            return None
        first = getattr(self.user, "first_name", "") or ""
        last = getattr(self.user, "last_name", "") or ""
        full = f"{first} {last}".strip()
        return full or None


# Pydantic schemas for verifications
class VerificationBase(BaseModel):
    id_type: str = Field(..., min_length=1, max_length=20)
    id_document_url: str | None = None
    status: str = Field('pending', pattern='^(pending|approved|rejected)$')

class VerificationCreate(VerificationBase):
    landlord_id: PyUUID

class VerificationUpdate(BaseModel):
    status: str = Field(..., pattern='^(pending|approved|rejected)$')
    verified_at: datetime | None = None

class VerificationRead(VerificationBase):
    verification_id: PyUUID
    landlord_id: PyUUID
    verified_at: datetime | None = None
    updated_at: datetime
    
    # Include landlord information
    landlord: UserRead | None = None

    class Config:
        from_attributes = True


class VerificationWithLandlord(VerificationRead):
    """Verification schema with landlord details for admin."""
    landlord_name: str | None = None
    landlord_email: str | None = None
    landlord_phone: str | None = None


# SQLAlchemy model for payment preferences
class PaymentPreference(Base):
    __tablename__ = "payment_preferences"
    
    payment_reference_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    mobile_number = Column(String(20), nullable=True)
    account_number = Column(String(50), nullable=True)
    account_name = Column(String(100), nullable=True)
    bank_name = Column(String(100), nullable=True)
    # Store the PayChangu bank identifier (UUID) for bank transfer payouts
    bank_uuid = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_preferred = Column(Boolean, default=False)
    
    # Relationship to User
    user = relationship("User", back_populates="payment_preferences")


# Pydantic schemas for payment preferences
class PaymentPreferenceBase(BaseModel):
    mobile_number: str | None = None
    account_number: str | None = None
    account_name: str | None = None
    bank_name: str | None = None
    bank_uuid: str | None = None
    is_preferred: bool = False

class PaymentPreferenceCreate(PaymentPreferenceBase):
    user_id: PyUUID

class PaymentPreferenceUpdate(BaseModel):
    mobile_number: str | None = None
    account_number: str | None = None
    account_name: str | None = None
    bank_name: str | None = None
    bank_uuid: str | None = None
    is_preferred: bool | None = None

class PaymentPreferenceRead(PaymentPreferenceBase):
    payment_reference_id: PyUUID
    user_id: PyUUID
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class PaymentPreferenceWithUser(PaymentPreferenceRead):
    """Payment preference schema with user details."""
    user_name: str | None = None
    user_email: str | None = None



# SQLAlchemy model for disbursements to landlords
class Disbursement(Base):
    __tablename__ = "disbursements"
    
    disbursement_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    booking_id = Column(UUID(as_uuid=True), ForeignKey("bookings.booking_id", ondelete="CASCADE"), nullable=False)
    landlord_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    platform_fee = Column(Numeric(10, 2), nullable=False)
    disbursement_amount = Column(Numeric(10, 2), nullable=False)
    status = Column(String(20), default='pending')  # 'pending', 'processing', 'completed', 'failed'
    payment_reference = Column(String(100), nullable=True)
    payment_method = Column(String(50), nullable=True)  # 'mobile_money', 'bank_transfer'
    processed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    failure_reason = Column(Text, nullable=True)
    
    # Relationships
    booking = relationship("Booking", back_populates="disbursements")
    landlord = relationship("User", back_populates="disbursements")


# Pydantic schemas for Disbursement
class DisbursementCreate(BaseModel):
    booking_id: PyUUID
    landlord_id: PyUUID
    amount: float
    platform_fee: float
    disbursement_amount: float
    payment_method: str | None = None
    # Optional overrides for transfer details (allow admin UI to pass override values)
    bank_uuid: str | None = None
    bank_account_number: str | None = None
    bank_account_name: str | None = None
    mobile_number: str | None = None
    mobile_account_name: str | None = None
    # Optional operator reference id required by PayChangu for mobile payouts
    mobile_money_operator_ref_id: str | None = None

    class Config:
        from_attributes = True


class DisbursementRead(BaseModel):
    disbursement_id: PyUUID
    booking_id: PyUUID
    landlord_id: PyUUID
    amount: float
    platform_fee: float
    disbursement_amount: float
    status: str
    payment_reference: str | None = None
    payment_method: str | None = None
    processed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    failure_reason: str | None = None
    
    # Include related data
    booking: dict | None = None
    landlord: dict | None = None

    class Config:
        from_attributes = True


class DisbursementUpdate(BaseModel):
    status: str
    payment_reference: str | None = None
    processed_at: datetime | None = None
    failure_reason: str | None = None

    class Config:
        from_attributes = True


class BatchDisbursementCreate(BaseModel):
    """Schema for batch disbursement requests from the admin UI."""
    landlord_id: PyUUID
    total_amount: float | None = None
    total_bookings: int | None = None
    bank_uuid: str | None = None

    class Config:
        from_attributes = True

