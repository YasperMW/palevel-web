from fastapi import APIRouter, Depends, HTTPException, status, Request, Header, Form, UploadFile, File
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Dict, Any, Optional
import os

from models import (
    User, OAuthUserCreate, OAuthRoleSelection, UserRead, Verification
)
from database import get_db, db_session
from endpoints.users import create_access_token
import logging
import json
import firebase_admin
from firebase_admin import credentials, auth

logger = logging.getLogger(__name__)
router = APIRouter()

# Initialize Firebase Admin SDK
try:
    if not firebase_admin._apps:
        cred_path = os.getenv("FIREBASE_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized with credentials file")
        else:
            # Attempt to use default credentials or rely on environment variables
            # (GOOGLE_APPLICATION_CREDENTIALS)
            firebase_admin.initialize_app()
            logger.info("Firebase Admin SDK initialized with default credentials")
except Exception as e:
    logger.error(f"Failed to initialize Firebase Admin SDK: {e}")

def parse_display_name(display_name: str) -> tuple[str, str]:
    """Parse display name into first and last names."""
    if not display_name:
        return "Firebase", "User"
    
    # Split by space and handle multiple spaces
    name_parts = [part.strip() for part in display_name.split() if part.strip()]
    
    if len(name_parts) == 1:
        return name_parts[0], ""
    elif len(name_parts) == 2:
        return name_parts[0], name_parts[1]
    else:
        # For names with more than 2 parts, first word is first name, rest is last name
        return name_parts[0], " ".join(name_parts[1:])

class FirebaseSignInRequest(BaseModel):
    id_token: str
    email: str
    display_name: Optional[str] = None
    photo_url: Optional[str] = None

class FirebaseSignInResponse(BaseModel):
    needs_role_selection: bool
    user: Optional[UserRead] = None
    token: Optional[str] = None
    temporary_token: Optional[str] = None

@router.post("/firebase/signin", response_model=FirebaseSignInResponse)
async def firebase_signin(
    request: FirebaseSignInRequest,
    db: Session = Depends(get_db)
):
    """
    Authenticate user using Firebase ID token
    """
    try:
        # Verify Firebase ID token
        decoded_token = None
        uid = None
        
        # Check for mock auth in development
        if os.getenv("MOCK_FIREBASE_AUTH", "false").lower() == "true":
            logger.warning("Using MOCK Firebase Auth - DO NOT USE IN PRODUCTION")
            uid = f"mock_{request.email}"
            decoded_token = {
                "uid": uid,
                "email": request.email,
                "name": request.display_name,
                "picture": request.photo_url,
                "email_verified": True
            }
        else:
            try:
                decoded_token = auth.verify_id_token(request.id_token)
                uid = decoded_token['uid']
            except auth.InvalidIdTokenError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid Firebase ID token"
                )
            except auth.ExpiredIdTokenError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Expired Firebase ID token"
                )
            except auth.RevokedIdTokenError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Revoked Firebase ID token"
                )
            except Exception as e:
                logger.error(f"Firebase token verification failed: {e}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Token verification failed: {str(e)}"
                )

        # Use email from token if available and trusted
        token_email = decoded_token.get('email')
        if not token_email:
             raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Firebase token does not contain an email address"
            )
            
        if token_email != request.email:
             logger.warning(f"Request email {request.email} does not match token email {token_email}")
             # We trust the token email
             request.email = token_email

        # Check if user exists
        user = db.query(User).filter(User.email == request.email).first()
        
        if user is None:
            # Check if user exists by google_id (in case email changed but it's same account - unlikely for Google but possible)
            user = db.query(User).filter(User.google_id == uid).first()

        if user is None:
            # Create new user from Firebase
            first_name, last_name = parse_display_name(request.display_name or decoded_token.get('name') or "Firebase User")
            new_user = User(
                email=request.email,
                first_name=first_name,
                last_name=last_name,
                user_type="pending",  # Will be set during role selection
                google_id=uid,  # Use Firebase UID
                oauth_provider="google",  # Set OAuth provider
                is_oauth_user=True,  # Mark as OAuth user
                is_verified=True,  # Firebase users are pre-verified
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            
            # Return temporary token for role selection
            temp_token_data = {
                "sub": str(new_user.user_id),
                "role": "pending",
                "temp": True,
                "exp": datetime.utcnow() + timedelta(hours=24)
            }
            temp_token = create_access_token(temp_token_data)
            
            return FirebaseSignInResponse(
                needs_role_selection=True,
                user=None,
                token=None,
                temporary_token=temp_token
            )
        
        # Check if existing user is OAuth user or regular signup user
        elif not user.is_oauth_user:
            # Existing user is a regular signup user - deny OAuth login
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="This email is already registered with a regular account. Please use your password to login instead of OAuth."
            )
        
        elif user.user_type == "pending":
            # User exists and is OAuth user but needs role selection
            temp_token_data = {
                "sub": str(user.user_id),
                "role": "pending", 
                "temp": True,
                "exp": datetime.utcnow() + timedelta(hours=24)
            }
            temp_token = create_access_token(temp_token_data)
            
            return FirebaseSignInResponse(
                needs_role_selection=True,
                user=None,
                token=None,
                temporary_token=temp_token
            )
        
        else:
            # User exists and has role - return full token
            token_data = {
                "sub": str(user.user_id),
                "role": user.user_type
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
            }
            
            return FirebaseSignInResponse(
                needs_role_selection=False,
                user=user_dict,
                token=token,
                temporary_token=None
            )
            
    except Exception as e:
        logger.error(f"Firebase sign-in error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Firebase authentication failed: {str(e)}"
        )

@router.post("/role-selection", response_model=dict)
async def complete_role_selection(
    role_data: OAuthRoleSelection,
    authorization: Optional[str] = Header(None, description="Authorization header with Bearer token"),
    db: Session = Depends(get_db)
):
    """Complete role selection for OAuth users with all required fields."""
    try:
        # Debug logging
        logger.info(f"Authorization header received: {authorization}")
        
        # Extract token from Authorization header
        if not authorization or not authorization.startswith("Bearer "):
            logger.error(f"Invalid authorization header: {authorization}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization token required"
            )
        
        token = authorization.split(" ")[1]
        
        # Verify temporary token and get user ID
        from jose import jwt, JWTError
        from endpoints.users import SECRET_KEY, ALGORITHM
        
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id = payload.get("sub")
            is_temp = payload.get("temp", False)
            
            if not user_id or not is_temp:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired temporary token"
                )
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Get user from database
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Validate required fields based on user type
        if role_data.user_type == "tenant" and not role_data.university:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="University is required for students"
            )
        
        if role_data.user_type == "landlord" and not role_data.national_id_image:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="National ID image is required for landlords"
            )
        
        # Update user with role selection and additional details
        user.user_type = role_data.user_type
        user.phone_number = role_data.phone_number
        user.university = role_data.university
        user.updated_at = datetime.utcnow()
        
        # Handle date of birth if provided
        if role_data.date_of_birth:
            try:
                user.date_of_birth = datetime.fromisoformat(role_data.date_of_birth.replace('Z', '+00:00')).date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date of birth format"
                )
        
        # Handle year of study for students
        if role_data.user_type == "tenant" and role_data.year_of_study:
            user.year_of_study = role_data.year_of_study
        
        # Handle gender for students
        if role_data.user_type == "tenant" and role_data.gender:
            user.gender = role_data.gender
        
        db.commit()
        db.refresh(user)
        
        # Handle national ID upload for landlords
        if role_data.user_type == "landlord" and role_data.national_id_image:
            try:
                verification = Verification(
                    landlord_id=user.user_id,
                    id_type="national_id",
                    id_document_url=role_data.national_id_image,
                    updated_at=datetime.utcnow()
                )
                db.add(verification)
                db.commit()
            except Exception as e:
                logger.error(f"Failed to save verification: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to save verification document"
                )
        
        # Create permanent token
        token_data = {
            "sub": str(user.user_id),
            "role": user.user_type
        }
        permanent_token = create_access_token(token_data)
        
        # Send welcome email after role completion
        from email_service import email_service
        import asyncio
        asyncio.create_task(email_service.send_welcome_email(user.email, user.first_name, user.user_type))
        
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
        
        return {
            "token": permanent_token,
            "user": user_dict
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in role selection: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to complete role selection"
        )

@router.post("/role-selection-with-id", response_model=dict)
async def complete_role_selection_with_id(
    user_type: str = Form(...),
    phone_number: Optional[str] = Form(None),
    date_of_birth: Optional[str] = Form(None),
    university: Optional[str] = Form(None),
    year_of_study: Optional[str] = Form(None),
    gender: Optional[str] = Form(None),
    national_id_image: Optional[UploadFile] = File(None),
    authorization: Optional[str] = Header(None, description="Authorization header with Bearer token"),
    db: Session = Depends(get_db)
):
    """Complete role selection for OAuth users with file upload support."""
    try:
        # Debug logging
        logger.info(f"Authorization header received: {authorization}")
        
        # Extract token from Authorization header
        if not authorization or not authorization.startswith("Bearer "):
            logger.error(f"Invalid authorization header: {authorization}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization token required"
            )
        
        token = authorization.split(" ")[1]
        
        # Verify temporary token and get user ID
        from jose import jwt, JWTError
        from endpoints.users import SECRET_KEY, ALGORITHM
        
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id = payload.get("sub")
            is_temp = payload.get("temp", False)
            
            if not user_id or not is_temp:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired temporary token"
                )
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        # Get user from database
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Validate required fields based on user type
        if user_type == "tenant" and not university:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="University is required for students"
            )
        
        if user_type == "landlord" and not national_id_image:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="National ID image is required for landlords"
            )
        
        # Update user with role selection and additional details
        user.user_type = user_type
        user.phone_number = phone_number
        user.university = university
        user.updated_at = datetime.utcnow()
        
        # Handle date of birth if provided
        if date_of_birth:
            try:
                user.date_of_birth = datetime.fromisoformat(date_of_birth.replace('Z', '+00:00')).date()
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date of birth format"
                )
        
        # Handle year of study for students
        if user_type == "tenant" and year_of_study:
            user.year_of_study = year_of_study
        
        # Handle gender for students
        if user_type == "tenant" and gender:
            user.gender = gender
        
        db.commit()
        db.refresh(user)
        
        # Handle national ID upload for landlords
        if user_type == "landlord" and national_id_image:
            try:
                # Save uploaded file like regular signup process
                import uuid
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
                    updated_at=datetime.utcnow()
                )
                db.add(verification)
                db.commit()
            except Exception as e:
                logger.error(f"Failed to save verification: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to save verification document"
                )
        
        # Create permanent token
        token_data = {
            "sub": str(user.user_id),
            "role": user.user_type
        }
        permanent_token = create_access_token(token_data)
        
        # Send welcome email after role completion
        from email_service import email_service
        import asyncio
        asyncio.create_task(email_service.send_welcome_email(user.email, user.first_name, user.user_type))
        
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
        
        return {
            "token": permanent_token,
            "user": user_dict
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in role selection with ID: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to complete role selection"
        )

@router.post("/login", response_model=dict)
async def oauth_login_with_token(
    token_data: dict,
    db: Session = Depends(get_db)
):
    """Alternative OAuth login using access token from client."""
    try:
        access_token = token_data.get("access_token")
        if not access_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Access token is required"
            )
        
        # Verify token with Google and get user info
        # This would require additional validation logic
        # For now, we'll assume the token is valid and contains user info
        
        
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="This endpoint is not yet implemented. Use the web OAuth flow."
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in OAuth token login: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process OAuth login"
        )
