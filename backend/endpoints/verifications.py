from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
from datetime import datetime
import uuid
import os
import shutil
from endpoints.users import get_current_user, require_landlord
from models import User

router = APIRouter(
    prefix="/verifications",
    tags=["verifications"],
    responses={404: {"description": "Not found"}},
)

@router.get("/landlord-verification-status/{landlord_id}")
async def get_landlord_verification_status(
    landlord_id: str,
    db: Session = Depends(get_db)
):
    """
    Get the verification status of a landlord.
    
    Returns the current verification status, ID type, and timestamps if verified.
    """
    try:
        # Validate UUID format
        try:
            uuid.UUID(landlord_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid landlord ID format"
            )
        
        # Check if landlord exists
        landlord_exists = db.execute(
            text("SELECT 1 FROM users WHERE user_id = :user_id AND user_type = 'landlord'"),
            {"user_id": landlord_id}
        ).scalar()
        
        if not landlord_exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Landlord not found"
            )
        
        # Get verification status
        verification = db.execute(
            text("""
                SELECT 
                    status, 
                    id_type, 
                    verified_at, 
                    updated_at
                FROM verifications 
                WHERE landlord_id = :landlord_id
                ORDER BY updated_at DESC 
                LIMIT 1
            """),
            {"landlord_id": landlord_id}
        ).fetchone()
        
        if not verification:
            return JSONResponse(
                status_code=status.HTTP_200_OK,
                content={
                    "status": "not_submitted",
                    "message": "No verification record found"
                }
            )
        
        # Format the response
        response = {
            "status": verification[0] or "not_submitted",
            "id_type": verification[1],
            "verified_at": verification[2].isoformat() if verification[2] else None,
            "updated_at": verification[3].isoformat() if verification[3] else None
        }
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
       
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while fetching verification status"
        )


@router.post("/resubmit-national-id/")
async def resubmit_national_id(
    national_id_image: UploadFile = File(...),
    current_user: User = Depends(require_landlord),
    db: Session = Depends(get_db)
):
    """
    Resubmit national ID for verification.
    
    This endpoint allows landlords to resubmit their national ID when:
    - Their previous submission was rejected
    - They haven't submitted any ID yet
    
    The endpoint creates a new verification record with 'pending' status.
    """
    try:
        # Read file content for validation
        file_content = await national_id_image.read()
        
        # Validate file size (5MB limit)
        max_size = 5 * 1024 * 1024  # 5MB
        if len(file_content) > max_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Image size must be less than 5MB"
            )
        
        # Validate file type by checking content and extension
        allowed_extensions = ['.jpg', '.jpeg', '.png']
        original_name = getattr(national_id_image, "filename", "upload") or "upload"
        file_extension = os.path.splitext(original_name)[1].lower()
        
        # Check file extension
        if file_extension not in allowed_extensions:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be a JPG or PNG image"
            )
        
        # Additional validation: check file signature (magic bytes)
        is_valid_image = False
        if len(file_content) >= 4:
            # JPEG signature: FF D8 FF
            if file_content[0] == 0xFF and file_content[1] == 0xD8 and file_content[2] == 0xFF:
                is_valid_image = True
            # PNG signature: 89 50 4E 47
            elif (file_content[0] == 0x89 and file_content[1] == 0x50 and 
                  file_content[2] == 0x4E and file_content[3] == 0x47):
                is_valid_image = True
        
        if not is_valid_image:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be a valid image (JPG or PNG)"
            )
        
        # Reset file pointer for saving
        await national_id_image.seek(0)
        
        # Create uploads directory if it doesn't exist
        uploads_root = os.path.join(os.getcwd(), "uploads")
        ver_dir = os.path.join(uploads_root, "verifications", str(current_user.user_id))
        os.makedirs(ver_dir, exist_ok=True)
        
        # Generate unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        original_name = getattr(national_id_image, "filename", "upload") or "upload"
        filename = f"national_id_resubmit_{timestamp}_{original_name}"
        
        # Ensure filename has valid extension
        if not any(filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png']):
            filename += '.jpg'  # Default extension
        
        file_path = os.path.join(ver_dir, filename)
        
        # Save the file using the content we already read
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)
        
        # Create relative URL for database storage
        id_document_url = f"/uploads/verifications/{current_user.user_id}/{filename}"
        
        # Check if there's an existing verification record
        existing_verification = db.execute(
            text("""
                SELECT verification_id 
                FROM verifications 
                WHERE landlord_id = :landlord_id
                ORDER BY updated_at DESC 
                LIMIT 1
            """),
            {"landlord_id": str(current_user.user_id)}
        ).fetchone()
        
        if existing_verification:
            # Update existing verification record
            db.execute(
                text("""
                    UPDATE verifications 
                    SET 
                        id_document_url = :id_document_url,
                        status = 'pending',
                        updated_at = :updated_at,
                        verified_at = NULL
                    WHERE verification_id = :verification_id
                """),
                {
                    "id_document_url": id_document_url,
                    "updated_at": datetime.utcnow(),
                    "verification_id": existing_verification[0]
                }
            )
        else:
            # Create new verification record
            db.execute(
                text("""
                    INSERT INTO verifications 
                    (verification_id, landlord_id, id_type, id_document_url, status, updated_at)
                    VALUES 
                    (:verification_id, :landlord_id, 'national_id', :id_document_url, 'pending', :updated_at)
                """),
                {
                    "verification_id": str(uuid.uuid4()),
                    "landlord_id": str(current_user.user_id),
                    "id_document_url": id_document_url,
                    "updated_at": datetime.utcnow()
                }
            )
        
        db.commit()
        
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "message": "National ID resubmitted successfully",
                "status": "pending",
                "id_document_url": id_document_url
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        # Clean up uploaded file if there was an error
        if 'file_path' in locals() and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except:
                pass
        
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while resubmitting national ID: {str(e)}"
        )
