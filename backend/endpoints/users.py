from fastapi import Depends, HTTPException, BackgroundTasks, status, Form, UploadFile, File
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from models import (
    User, Authentication, UserRead, UserCreate, OTP, Verification
)
from database import get_db, db_session

from passlib.context import CryptContext
from passlib.exc import UnknownHashError
from email_service import email_service
import uuid
import os
import re
from jose import jwt, JWTError
from fastapi.security import OAuth2PasswordBearer

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

SECRET_KEY = os.getenv("JWT_SECRET_KEY", "palevel-default-secret")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60 * 24 * 7))

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/authenticate/")

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return token

def _prepare_password(password: str) -> str:
    if password is None:
        return ""
    b = password.encode("utf-8")
    if len(b) <= 72:
        return password
    b = b[:72]
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return b.decode("utf-8", errors="ignore")

def authenticate(auth: Authentication):
    with db_session() as db:
        user = db.query(User).filter(User.email == auth.email).first()

        # Check if this is an OAuth user trying to use password login
        if user and user.is_oauth_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This account uses Google OAuth. Please sign in with Google."
            )

        prepared = _prepare_password(auth.password)
        password_ok = False
        if not user:
            password_ok = False
        else:
            try:
                password_ok = pwd_context.verify(prepared, user.password_hash)
            except UnknownHashError:
                if prepared == (user.password_hash or ""):
                    try:
                        new_hash = pwd_context.hash(prepared)
                        user.password_hash = new_hash
                        db.add(user)
                        db.commit()
                        password_ok = True
                    except Exception:
                        password_ok = True
                else:
                    password_ok = False

        if not password_ok:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )

        token_data = {
            "sub": str(user.user_id),
            "role": user.user_type  # Use 'role' for consistency
        }
        token = create_access_token(token_data)

        user_dict = {
            "user_id": str(user.user_id),
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "full_name": f"{user.first_name} {user.last_name}",
            "user_type": user.user_type,
            "phone_number": user.phone_number,
            "university": user.university,
            "is_verified": bool(user.is_verified),
            "is_oauth_user": bool(user.is_oauth_user),
            "gender":user.gender,
        }

        return {"token": token, "user": user_dict}


async def verify_token(payload: dict):
    token = payload.get("token")
    if not token:
        raise HTTPException(status_code=400, detail="Token is required")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token payload")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token expired or invalid")

    with db_session() as db:
        user = db.query(User).filter(User.user_id == user_id).first()

        if not user:
            raise HTTPException(status_code=401, detail="User not found or has been deleted")
        if getattr(user, "is_blacklisted", False):
            raise HTTPException(status_code=401, detail="User account is blacklisted")

        user_dict = {
            "user_id": str(user.user_id),
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "full_name": f"{user.first_name} {user.last_name}",
            "user_type": user.user_type,
            "phone_number": user.phone_number,
            "university": user.university,
            "is_verified": bool(user.is_verified),
        }

        return user_dict

def get_current_user(token: str = Depends(oauth2_scheme)):
    """Dependency to get current user from Bearer token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    db = next(get_db())
    try:
        user = db.query(User).filter(User.user_id == user_id).first()
        if user is None:
            raise credentials_exception
        return user
    finally:
        db.close()

def require_landlord(current_user: User = Depends(get_current_user)):
    """Dependency that requires the current user to be a landlord."""
    if current_user.user_type.lower() != 'landlord':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This resource is only available to landlords."
        )
    return current_user


async def update_university(payload: dict, current_user: User = Depends(get_current_user)):
    uni = payload.get("university")
    if uni is None:
        raise HTTPException(status_code=400, detail="university is required")

    with db_session() as db:
        db_user = db.query(User).filter(User.user_id == current_user.user_id).first()
        if not db_user:
            raise HTTPException(status_code=404, detail="User not found")
            
        db_user.university = uni
        db_user.updated_at = datetime.utcnow()
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        return {
            "user_id": str(db_user.user_id),
            "email": db_user.email,
            "university": db_user.university,
        }


async def update_profile(payload: dict, current_user: User = Depends(get_current_user)):
    first_name = payload.get("first_name")
    last_name = payload.get("last_name")
    phone_number = payload.get("phone_number")
    university = payload.get("university")
    password = payload.get("password")

    with db_session() as db:
        # Get the user from the database
        db_user = db.query(User).filter(User.user_id == current_user.user_id).first()
        if not db_user:
            raise HTTPException(status_code=404, detail="User not found")

        # For OAuth users, password is not required
        if not db_user.is_oauth_user:
            if not password:
                raise HTTPException(status_code=400, detail="Password is required to confirm changes")

            # Verify password for regular users
            prepared = _prepare_password(password)
            password_ok = False
            try:
                password_ok = pwd_context.verify(prepared, db_user.password_hash)
            except UnknownHashError:
                if prepared == (db_user.password_hash or ""):
                    try:
                        db_user.password_hash = pwd_context.hash(prepared)
                        db.add(db_user)
                        db.commit()
                        password_ok = True
                    except Exception:
                        password_ok = True
                else:
                    password_ok = False

            if not password_ok:
                raise HTTPException(status_code=400, detail="Incorrect password")

        # Update fields if provided
        if first_name is not None:
            db_user.first_name = first_name
        if last_name is not None:
            db_user.last_name = last_name
        if phone_number is not None:
            db_user.phone_number = phone_number
        if university is not None:
            db_user.university = university

        db_user.updated_at = datetime.utcnow()
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # Send profile update email
        from email_service import email_service
        import asyncio
        asyncio.create_task(email_service.send_profile_update_email(db_user.email, db_user.first_name))

        return {
            "user_id": str(db_user.user_id),
            "email": db_user.email,
            "first_name": db_user.first_name,
            "last_name": db_user.last_name,
            "phone_number": db_user.phone_number,
            "university": db_user.university,
            "updated_at": db_user.updated_at.isoformat() if db_user.updated_at else None,
        }


import logging

logger = logging.getLogger(__name__)

async def create_user_with_id(
    background_tasks: BackgroundTasks,
    first_name: str = Form(...),
    last_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    phone_number: str | None = Form(None),
    user_type: str = Form(...),
    national_id_image: UploadFile | None = File(None),
    university: str | None = Form(None),
):

    # Log incoming request data
    logger.info(
        "Received create_user_with_id request with data: %s",
        {
            "email": email,
            "user_type": user_type,
            "has_national_id": national_id_image is not None,
            "university_provided": university is not None,
            "phone_provided": phone_number is not None
        }
    )
    if not isinstance(email, str) or not email.strip():
        error_msg = "Email is required"
        logger.warning(f"Validation failed: {error_msg}")
        raise HTTPException(status_code=400, detail=error_msg)
    email = email.strip().lower()

    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email):
        error_msg = f"Invalid email format: {email}"
        logger.warning(f"Validation failed: {error_msg}")
        raise HTTPException(status_code=400, detail="Invalid email format")

    if not isinstance(password, str) or not password:
        error_msg = "Password is required"
        logger.warning(f"Validation failed: {error_msg}")
        raise HTTPException(status_code=400, detail=error_msg)
        
    pw = password
    pw_errors = []
    if len(pw) < 8:
        pw_errors.append("at least 8 characters")
    if not any(c.islower() for c in pw):
        pw_errors.append("a lowercase letter")
    if not any(c.isupper() for c in pw):
        pw_errors.append("an uppercase letter")
    if not any(c.isdigit() for c in pw):
        pw_errors.append("a digit")
    if not any(not c.isalnum() for c in pw):
        pw_errors.append("a special character")
    if pw_errors:
        error_msg = "Password must contain: " + ", ".join(pw_errors)
        logger.warning(f"Password validation failed: {error_msg}")
        raise HTTPException(
            status_code=400,
            detail=error_msg
        )

    allowed_types = {"tenant", "landlord", "admin"}
    if user_type not in allowed_types:
        error_msg = f"Invalid user_type: {user_type}. Must be one of {allowed_types}"
        logger.warning(error_msg)
        raise HTTPException(status_code=400, detail=f"user_type must be one of {allowed_types}")

    if not isinstance(first_name, str) or not first_name.strip():
        error_msg = "first_name is required"
        logger.warning(f"Validation failed: {error_msg}")
        raise HTTPException(status_code=400, detail=error_msg)
    if not isinstance(last_name, str) or not last_name.strip():
        error_msg = "last_name is required"
        logger.warning(f"Validation failed: {error_msg}")
        raise HTTPException(status_code=400, detail=error_msg)

    with db_session() as db:
        db_user = db.query(User).filter(User.email == email).first()
        if db_user:
            if not db_user.is_verified:
                logger.info(f"Found unverified user with email {email}, resending OTP")
                db.query(OTP).filter(OTP.user_id == db_user.user_id, OTP.is_used == False).update(
                    {"is_used": True}
                )
                db.commit()

                otp_code = str(uuid.uuid4().int)[:6]
                otp = OTP(
                    user_id=db_user.user_id,
                    code=otp_code,
                    created_at=datetime.utcnow(),
                    expires_at=datetime.utcnow() + timedelta(minutes=10),
                    is_used=False,
                )
                db.add(otp)
                db.commit()

                background_tasks.add_task(
                    email_service.send_otp_email,
                    email,
                    otp_code
                )

                return db_user
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User with this email already exists and is verified"
                )

        password_hash = pwd_context.hash(_prepare_password(password))

        user_id = str(uuid.uuid4())
        user = User(
            user_id=user_id,
            first_name=first_name,
            last_name=last_name,
            email=email,
            password_hash=password_hash,
            phone_number=phone_number,
            user_type=user_type,
            university=university,
            is_verified=False,
            is_blacklisted=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        if user_type == 'landlord' and national_id_image:
            logger.info("Processing landlord ID verification")
            try:
                uploads_root = os.path.join(os.getcwd(), "uploads")
                ver_dir = os.path.join(uploads_root, "verifications", str(user.user_id))
                os.makedirs(ver_dir, exist_ok=True)

                original_name = getattr(national_id_image, "filename", "upload") or "upload"
                _, ext = os.path.splitext(original_name)
                filename = f"{uuid.uuid4().hex}{ext}"
                file_path = os.path.join(ver_dir, filename)

                contents = await national_id_image.read()
                with open(file_path, "wb") as f:
                    f.write(contents)
                try:
                    await national_id_image.close()
                except Exception:
                    pass

                id_document_url = f"/uploads/verifications/{user.user_id}/{filename}"

                verification = Verification(
                    landlord_id=user.user_id,
                    id_type="national_id",
                    id_document_url=id_document_url,
                    status="pending",
                )
                db.add(verification)
                db.commit()
            except Exception as e:
                error_msg = f"Error processing ID image: {str(e)}"
                logger.error(error_msg, exc_info=True)
                db.rollback()
                user._upload_error = str(e)

        otp_code = str(uuid.uuid4().int)[:6]
        otp = OTP(
            user_id=user.user_id,
            code=otp_code,
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=10),
            is_used=False,
        )
        db.add(otp)
        db.commit()

        background_tasks.add_task(
            email_service.send_otp_email,
            email,
            otp_code
        )

        try:
            user.upload_error = getattr(user, "_upload_error", None)
            if hasattr(user, '_upload_error'):
                logger.warning(f"Upload error set on user: {user.upload_error}")
        except Exception as e:
            logger.error(f"Error setting upload error: {str(e)}")
            
        logger.info(f"Successfully created user with email: {email}, user_type: {user_type}")
        return user

        
def create_user(
    user: UserCreate,
    background_tasks: BackgroundTasks,
):
    with db_session() as db:
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            if not db_user.is_verified:
                db.query(OTP).filter(
                    OTP.user_id == db_user.user_id, 
                    OTP.is_used == False
                ).update({"is_used": True})
                db.commit()

                otp_code = str(uuid.uuid4().int)[:6]
                otp = OTP(
                    user_id=db_user.user_id,
                    code=otp_code,
                    created_at=datetime.utcnow(),
                    expires_at=datetime.utcnow() + timedelta(minutes=10),
                    is_used=False,
                )
                db.add(otp)
                db.commit()

                background_tasks.add_task(
                    email_service.send_otp_email,
                    user.email,
                    otp_code
                )

                return db_user
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User with this email already exists and is verified"
                )

        password_hash = pwd_context.hash(_prepare_password(user.password))
        user_id = str(uuid.uuid4())
        new_user = User(
            user_id=user_id,
            first_name=user.first_name,
            last_name=user.last_name,
            email=user.email,
            password_hash=password_hash,
            phone_number=user.phone_number,
            user_type=user.user_type,
            gender = user.gender,
            university=user.university,
            is_verified=False,
            is_blacklisted=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        otp_code = str(uuid.uuid4().int)[:6]
        otp = OTP(
            user_id=new_user.user_id,
            code=otp_code,
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=10),
            is_used=False,
        )
        db.add(otp)
        db.commit()

        background_tasks.add_task(
            email_service.send_otp_email,
            user.email,
            otp_code
        )

        return new_user

async def send_otp(
    payload: dict,
    background_tasks: BackgroundTasks,
):

    email = payload.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Email is required")

    with db_session() as db:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        db.query(OTP).filter(OTP.user_id == user.user_id, OTP.is_used == False).update(
            {"is_used": True}
        )
        db.commit()

        otp_code = str(uuid.uuid4().int)[:6]
        otp = OTP(
            user_id=user.user_id,
            code=otp_code,
            created_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(minutes=10),
            is_used=False,
        )
        db.add(otp)
        db.commit()

        background_tasks.add_task(
            email_service.send_otp_email,
            email,
            otp_code
        )

        return {"message": "OTP sent successfully"}


async def verify_otp(payload: dict):
    email = payload.get("email")
    otp_code = payload.get("otp")
    
    if not email or not otp_code:
        raise HTTPException(
            status_code=400,
            detail="Email and OTP are required"
        )

    with db_session() as db:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found"
            )

        otp = db.query(OTP).filter(
            OTP.user_id == user.user_id,
            OTP.code == otp_code,
            OTP.is_used == False,
            OTP.expires_at > datetime.utcnow()
        ).first()

        if not otp:
            raise HTTPException(
                status_code=400,
                detail="Invalid or expired OTP"
            )


        otp.is_used = True
        user.is_verified = True
        user.verified_at = datetime.utcnow()

        db.add(otp)
        db.add(user)
        db.commit()

        # Send welcome email after verification
        from email_service import email_service
        import asyncio
        asyncio.create_task(email_service.send_welcome_email(user.email, user.first_name, user.user_type))

        token_data = {
            "sub": str(user.user_id),
            "email": user.email,
            "user_type": user.user_type
        }
        token = create_access_token(token_data)

        return {
            "message": "OTP verified successfully",
            "token": token,
            "user": {
                "user_id": str(user.user_id),
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "user_type": user.user_type,
                "is_verified": user.is_verified
            }
        }

async def get_user_profile(
    email: str = None,
    user_id: str = None,
     gender: str = None,
):
    if not email and not user_id:
        raise HTTPException(
            status_code=400,
            detail="Either email or user_id must be provided"
        )

    with db_session() as db:
        query = db.query(User)
        
        if email:
            user = query.filter(User.email == email).first()
        else:
            user = query.filter(User.user_id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found"
            )

        return {
            "user_id": str(user.user_id),
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "full_name": f"{user.first_name} {user.last_name}",
            "user_type": user.user_type,
            "phone_number": user.phone_number,
            "university": user.university,
            "is_verified": user.is_verified,
            "gender": user.gender,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "updated_at": user.updated_at.isoformat() if user.updated_at else None
        }
    
async def request_password_reset_otp(identifier: str = Form(...)):
    """
    Request OTP for password reset. Identifier can be email or phone.
    """
    with db_session() as db:
        user = db.query(User).filter((User.email == identifier) | (User.phone_number == identifier)).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        code = OTP.generate_code()
        expires_at = datetime.utcnow() + timedelta(minutes=10)
        otp = OTP(user_id=user.user_id, code=code, expires_at=expires_at, is_used=False)
        db.add(otp)
        db.commit()
        
        # Send OTP via email
        from email_service import email_service
        import asyncio
        asyncio.create_task(email_service.send_otp_email(user.email, code))
        
        return {"message": "OTP sent", "otp_id": str(otp.id)}

async def verify_password_reset_otp(identifier: str = Form(...), code: str = Form(...)):
    """
    Verify OTP for password reset.
    """
    with db_session() as db:
        user = db.query(User).filter((User.email == identifier) | (User.phone_number == identifier)).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        otp = db.query(OTP).filter(OTP.user_id == user.user_id, OTP.code == code, OTP.is_used == False, OTP.expires_at > datetime.utcnow()).first()
        if not otp:
            raise HTTPException(status_code=400, detail="Invalid or expired OTP")
        otp.is_used = True
        db.commit()
        return {"message": "OTP verified"}

async def set_new_password(identifier: str = Form(...), new_password: str = Form(...)):
    """
    Set new password after OTP verification.
    """
    with db_session() as db:
        user = db.query(User).filter((User.email == identifier) | (User.phone_number == identifier)).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        user.password_hash = pwd_context.hash(new_password)
        db.commit()
        
        # Send password reset confirmation email
        from email_service import email_service
        import asyncio
        asyncio.create_task(email_service.send_password_reset_email(user.email, user.first_name))
        
        return {"message": "Password reset successful"}