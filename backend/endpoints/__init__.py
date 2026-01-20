from .users import (
    authenticate,
    create_user,
    create_user_with_id,
    send_otp,
    verify_otp,
    get_user_profile as get_user_profile_func,
    UserRead,
    UserCreate
)
from .config import router as config_router, get_platform_fee, get_config_value

# Alias for backward compatibility
get_user_profile = get_user_profile_func

from .hostels import (
    create_hostel,
    get_landlord_hostels,
    get_hostel,
    update_hostel,
    get_landlord_stats,
    HostelRead,
    HostelCreate,
    HostelUpdate
)

from .rooms import (
    create_room,
    get_hostel_rooms,
    get_room,
    update_room,
    delete_room,
    RoomRead,
    RoomCreate,
    RoomUpdate
)

from .media import (
    upload_hostel_media,
    get_hostel_media,
    delete_media,
    set_media_as_cover
)


from .notifications import send_notification_to_users

__all__ = [
    # Config
    'config_router',
    'get_platform_fee',
    'get_config_value',

    # Users
    'authenticate',
    'create_user',
    'create_user_with_id',
    'send_otp',
    'verify_otp',
    'get_user_profile',
    'UserRead',
    'UserCreate',

    # Hostels
    'create_hostel',
    'get_landlord_hostels',
    'get_hostel',
    'update_hostel',
    'delete_hostel',
    'get_landlord_stats',
    'HostelRead',
    'HostelCreate',
    'HostelUpdate',

    # Rooms
    'create_room',
    'get_hostel_rooms',
    'get_room',
    'update_room',
    'delete_room',
    'RoomRead',
    'RoomCreate',
    'RoomUpdate',

    # Media
    'upload_hostel_media',
    'get_hostel_media',
    'delete_media',
    'set_media_as_cover',

    # ✅ Notifications
    'send_notification_to_users',
]
