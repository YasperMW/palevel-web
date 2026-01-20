# palevel-backend/endpoints/websocket.py
import asyncio
import jwt
import json
from typing import Dict, Set
import time

from fastapi import (
    WebSocket,
    WebSocketDisconnect,
    Query,
    status,
)
from sqlalchemy.orm import Session

from database import get_db
from endpoints.users import SECRET_KEY, ALGORITHM
from models import User


# =====================================================
# CONNECTION MANAGER
# =====================================================
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.online_users: Set[str] = set()
        self.connection_times: Dict[str, float] = {}  # Track connection time

    async def connect(self, websocket: WebSocket, user_id: str) -> bool:
        try:
            await websocket.accept()
            self.active_connections[user_id] = websocket
            self.online_users.add(user_id)
            self.connection_times[user_id] = time.time()
            print(f"✅ User connected: {user_id}. Online users: {len(self.online_users)}")
            return True
        except Exception as e:
            print(f"❌ WebSocket accept failed for {user_id}: {e}")
            return False

    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.online_users:
            self.online_users.remove(user_id)
        if user_id in self.connection_times:
            del self.connection_times[user_id]
        print(f"🔴 User disconnected: {user_id}. Online users: {len(self.online_users)}")

    def is_user_online(self, user_id: str) -> bool:
        # Check if user is connected AND connection is recent (within last 60 seconds)
        if user_id not in self.active_connections:
            return False
        
        # Check if connection is stale (no activity for 60 seconds)
        last_activity = self.connection_times.get(user_id, 0)
        if time.time() - last_activity > 60:
            print(f"⚠️ User {user_id} connection is stale, marking as offline")
            self.disconnect(user_id)
            return False
            
        return True

    async def send_personal_message(self, message: dict, user_id: str) -> bool:
        """
        Send message to specific user via WebSocket.
        Returns True if delivered, False if user is offline.
        """
        if not self.is_user_online(user_id):
            print(f"⚠️ User {user_id} is offline. Message not delivered via WebSocket.")
            return False

        websocket = self.active_connections.get(user_id)
        if not websocket:
            return False

        try:
            await websocket.send_json(message)
            # Update last activity time
            self.connection_times[user_id] = time.time()
            print(f"✅ Message delivered via WebSocket to {user_id}: {message.get('type')}")
            return True
        except Exception as e:
            print(f"❌ WebSocket send error to {user_id}: {e}")
            self.disconnect(user_id)
            return False


# ✅ SINGLE SHARED INSTANCE
manager = ConnectionManager()


# =====================================================
# WEBSOCKET ENDPOINT
# =====================================================
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: str = Query(...),
    token: str = Query(...),
    db: Session = get_db,
):
    """
    WebSocket endpoint for real-time messaging
    Required query params: user_id, token
    """
    print(f"🌐 New WebSocket connection attempt from user: {user_id}")
    
    # -----------------------------
    # TOKEN VALIDATION
    # -----------------------------
    if not token or not user_id:
        print(f"❌ Missing token or user_id. Closing connection.")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        # Decode JWT token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_user_id = payload.get("sub")

        if token_user_id != user_id:
            print(f"❌ Token user_id mismatch. Closing connection.")
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Verify user exists in database
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            print(f"❌ User {user_id} not found in database. Closing connection.")
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        print(f"✅ Token validated for user: {user_id} ({user.user_type})")

    except jwt.ExpiredSignatureError:
        print(f"❌ Token expired for user: {user_id}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    except jwt.InvalidTokenError as e:
        print(f"❌ Invalid token for user: {user_id}. Error: {e}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    except Exception as e:
        print(f"❌ Token validation error: {e}")
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)
        return

    # -----------------------------
    # CONNECT USER
    # -----------------------------
    connected = await manager.connect(websocket, user_id)
    if not connected:
        print(f"❌ Failed to connect user: {user_id}")
        await websocket.close(code=status.WS_1011_INTERNAL_ERROR)
        return

    # -----------------------------
    # MESSAGE HANDLING LOOP
    # -----------------------------
    try:
        while True:
            try:
                # Wait for message with timeout
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=30.0  # 30 second timeout
                )

                if data == "ping":
                    # Update activity time
                    manager.connection_times[user_id] = time.time()
                    # Respond to ping
                    await websocket.send_text("pong")
                elif data.startswith("{"):
                    # Update activity time for any message
                    manager.connection_times[user_id] = time.time()
                    # Handle JSON messages
                    try:
                        message_data = json.loads(data)
                        print(f"📨 Received message from {user_id}: {message_data}")
                    except json.JSONDecodeError:
                        print(f"⚠️ Invalid JSON from {user_id}")

            except asyncio.TimeoutError:
                # No data received, send ping to check connection
                try:
                    await websocket.send_text("ping")
                    # Wait for pong with shorter timeout
                    pong = await asyncio.wait_for(
                        websocket.receive_text(),
                        timeout=5.0
                    )
                    if pong == "pong":
                        # Update activity time
                        manager.connection_times[user_id] = time.time()
                    else:
                        raise WebSocketDisconnect()
                except asyncio.TimeoutError:
                    # No pong received, disconnect
                    print(f"⏰ No response from {user_id}, disconnecting")
                    raise WebSocketDisconnect()

    except WebSocketDisconnect:
        print(f"🔌 WebSocket disconnected normally: {user_id}")
    except Exception as e:
        print(f"❌ WebSocket error for {user_id}: {e}")
    finally:
        # Always clean up connection
        manager.disconnect(user_id)