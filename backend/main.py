from dotenv import load_dotenv

load_dotenv()
import os

from fastapi import FastAPI, Depends, Request, WebSocket, Query
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.middleware import Middleware
from sqlalchemy.orm import Session
import time
import asyncio
from typing import Callable, Optional
from contextlib import asynccontextmanager
from fastapi.routing import APIRoute
from database import engine, Base, db_session, get_db
from endpoints import users, hostels, rooms, media, config, bookings, browse
from endpoints import payments, health, verifications
from endpoints import messages, websocket
from endpoints import notifications, reviews, activities
from endpoints import payment_references, admin, oauth, pdf_service, banks, data_deletion
from endpoints.payments_manual_verification import router as manual_verification_router
from endpoints.websocket import websocket_endpoint

# Database tables are now created in the lifespan event

# Custom Timeout Middleware
class TimeoutMiddleware:
    def __init__(self, app, timeout=30):
        self.app = app
        self.timeout = timeout

    async def __call__(self, scope, receive, send):
        # Skip timeout for lifespan events and websockets
        if scope["type"] in ["lifespan", "websocket"]:
            return await self.app(scope, receive, send)
            
        try:
            task = asyncio.create_task(self.app(scope, receive, send))
            await asyncio.wait_for(task, timeout=self.timeout)
        except asyncio.TimeoutError:
            response = JSONResponse(
                status_code=504,
                content={"detail": "Request timeout"}
            )
            await response(scope, receive, send)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        # Create database tables if they don't exist
        Base.metadata.create_all(bind=engine)
        
        # Initialize default configuration if not exists
        with db_session() as db:
            try:
                from models import Configuration
                from sqlalchemy import exists
                
                # Check if platform_fee exists
                if not db.query(exists().where(Configuration.config_key == "platform_fee")).scalar():
                    # Create default platform fee
                    default_fee = Configuration(
                        config_key="platform_fee",
                        config_value=2500.00,
                        description="Default platform fee for each booking in MWK"
                    )
                    db.add(default_fee)
                    db.commit()
                    print("Initialized default platform fee")
                    
            except Exception as e:
                print(f"Error initializing default configuration: {str(e)}")
                db.rollback()
                # Re-raise the exception to fail startup
                raise
    except Exception as e:
        print(f"Startup failed: {str(e)}")
        raise

    yield
    # Shutdown logic (if any) goes here
    

# Initialize FastAPI app with middleware and lifespan
app = FastAPI(
    title="Palevel Accommodation Finder API",
    redirect_slashes=False,
    middleware=[
        Middleware(TimeoutMiddleware, timeout=30)  # 30 seconds timeout
    ],
    lifespan=lifespan
)

# Serve static files from the uploads directory
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Serve static assets (logos, images) for emails and PDFs
assets_dir = os.path.join(os.path.dirname(__file__), "lib", "assets")
if os.path.exists(assets_dir):
    app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")

# Test endpoint to verify assets are accessible
@app.get("/assets/test")
def test_assets():
    """Test endpoint to verify asset files exist"""
    images_dir = os.path.join(assets_dir, "images")
    if os.path.exists(images_dir):
        files = os.listdir(images_dir)
        return {
            "status": "ok",
            "assets_dir": assets_dir,
            "images_dir": images_dir,
            "files": files,
            "note": "Access files at /assets/images/filename.png (spaces in filenames need URL encoding)"
        }
    return {"status": "error", "message": "Images directory not found"}

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
   
)

# Root endpoint
@app.get("/")
def read_root():
    return {"message": "Palevel Accommodation Finder API", "version": "1.0.0"}

# User Management Endpoints
# Note: `/authenticate/` returns {"token": ..., "user": {...}} to match Flutter client expectations
app.post("/authenticate/")(users.authenticate)
app.post("/create_user_with_id/", response_model=users.UserRead)(users.create_user_with_id)
app.post("/create_user/", response_model=users.UserRead)(users.create_user)
app.post("/send-otp/")(users.send_otp)
app.post("/verify-otp/")(users.verify_otp)
# Verify token endpoint used by Flutter splash screen (expects JSON {"token": "..."})
app.post("/verify_token/")(users.verify_token)
app.put("/user/university/")(users.update_university)
app.put("/user/profile/")(users.update_profile)
# Password Reset Endpoints
app.post("/password-reset/request-otp")(users.request_password_reset_otp)
app.post("/password-reset/verify-otp")(users.verify_password_reset_otp)
app.post("/password-reset/set-new-password")(users.set_new_password)
app.get("/browse/uploads/")(browse.list_uploads_root)
@app.get("/user/profile/")
async def get_user_profile_endpoint(
    email: str = None,
    user_id: str = None,
    gender: str = None,
):
    return await users.get_user_profile(email=email, user_id=user_id, gender=gender)

# Hostel Management Endpoints
app.post("/hostels/", response_model=hostels.HostelRead)(hostels.create_hostel)
app.post("/hostels/update_hostel/{hostel_id}")(hostels.update_hostel)
app.get("/hostels/all-hostels")(hostels.get_all_hostels)
app.get("/hostels/", response_model=list[hostels.HostelRead])(hostels.get_landlord_hostels)
app.get("/hostels/amenities/{hostel_id}")(hostels.get_hostel_amenities)
app.get("/hostels/{hostel_id}", response_model=hostels.HostelRead)(hostels.get_hostel)


app.get("/landlord/{landlord_email}/stats/")(hostels.get_landlord_stats)
app.post("/hostels/{hostel_id}/change_hostel_status")(hostels.change_hostel_status)

# Room Management Endpoints
app.post("/rooms/", response_model=rooms.RoomRead)(rooms.create_room)
app.get("/rooms", )(rooms.get_hostel_rooms)
app.get("/rooms/{room_id}", response_model=rooms.RoomRead)(rooms.get_room)
app.post("/rooms/{room_id}/update", response_model=rooms.RoomRead)(rooms.update_room)
app.delete("/rooms/{room_id}")(rooms.delete_room)

# Media Management Endpoints
app.post("/hostels/{hostel_id}/media/", response_model=media.MediaRead)(media.upload_hostel_media)
app.post("/rooms/{room_id}/media/", response_model=media.MediaRead)(media.upload_room_media)
app.get("/hostels/{hostel_id}/media", response_model=list[media.MediaRead])(media.get_hostel_media)
app.get("/rooms/{room_id}/media/", response_model=list[media.MediaRead])(media.get_room_media)
app.delete("/media/{media_id}")(media.delete_media)
app.put("/media/{media_id}/cover")(media.set_media_as_cover)

# Payment preferences endpoints
app.get("/user/payment-preferences/")(payment_references.get_payment_preferences)
app.post("/user/payment-methods/")(payment_references.add_payment_method)
app.put("/user/payment-methods/{payment_method_id}/set-preferred")(payment_references.set_preferred_payment_method)
app.delete("/user/payment-methods/{payment_method_id}")(payment_references.delete_payment_method)

# WebSocket endpoint
@app.websocket("/ws/{user_id}")
async def websocket_route(websocket: WebSocket, user_id: str, token: Optional[str] = Query(None), db: Session = Depends(get_db)):
    await websocket_endpoint(websocket, user_id, token, db)



# Include all routers
app.include_router(bookings.router)
app.include_router(browse.router)
app.include_router(payments.router, prefix="/payments", tags=["payments"])
app.include_router(manual_verification_router, prefix="/payments", tags=["payments"])
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(payment_references.router, tags=["payment-preferences"])
app.include_router(verifications.router, prefix="", tags=["verifications"])
app.include_router(config.router, prefix="/config")
app.include_router(messages.router)
app.include_router(notifications.router)
app.include_router(reviews.router)
app.include_router(activities.router)
app.include_router(admin.router, prefix="/admin", tags=["admin"])
app.include_router(oauth.router, prefix="/auth", tags=["oauth"])
app.include_router(pdf_service.router)
app.include_router(banks.router, tags=["banks"])
app.include_router(data_deletion.router, prefix="/api/data-deletion", tags=["data-deletion"])


def _add_slash_variants_for_all_routes(fastapi_app: FastAPI) -> None:
    existing_paths = set()
    for r in fastapi_app.router.routes:
        if hasattr(r, "path"):
            existing_paths.add(getattr(r, "path"))

    # Iterate over a snapshot since we'll be adding routes
    for route in list(fastapi_app.router.routes):
        if not isinstance(route, APIRoute):
            continue

        path = route.path
        if not isinstance(path, str):
            continue

        # Skip FastAPI's own docs/openapi endpoints if present
        if path in {"/openapi.json", "/docs", "/docs/", "/redoc", "/redoc/"}:
            continue

        if path == "/":
            continue

        if path.endswith("/"):
            alt_path = path.rstrip("/")
        else:
            alt_path = path + "/"

        if not alt_path or alt_path == path:
            continue

        if alt_path in existing_paths:
            continue

        fastapi_app.add_api_route(
            alt_path,
            route.endpoint,
            methods=list(route.methods or []),
            response_model=route.response_model,
            status_code=route.status_code,
            tags=route.tags,
            dependencies=route.dependencies,
            summary=route.summary,
            description=route.description,
            response_description=route.response_description,
            responses=route.responses,
            deprecated=route.deprecated,
            operation_id=route.operation_id,
            response_model_include=route.response_model_include,
            response_model_exclude=route.response_model_exclude,
            response_model_by_alias=route.response_model_by_alias,
            response_model_exclude_unset=route.response_model_exclude_unset,
            response_model_exclude_defaults=route.response_model_exclude_defaults,
            response_model_exclude_none=route.response_model_exclude_none,
            include_in_schema=False,
            name=route.name,
        )
        existing_paths.add(alt_path)


_add_slash_variants_for_all_routes(app)

# Add request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response


import os

print("PWD:", os.getcwd())
print("FILES:", os.listdir(os.getcwd()))
print("UPLOADS FILES:", os.listdir(os.path.join(os.getcwd(), "uploads")))
