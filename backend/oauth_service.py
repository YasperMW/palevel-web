import os
import json
from typing import Optional, Dict, Any
from fastapi import HTTPException
from google_auth_oauthlib.flow import Flow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import secrets
import logging

logger = logging.getLogger(__name__)

class GoogleOAuthService:
    def __init__(self):
        self.client_id = os.getenv("GOOGLE_CLIENT_ID")
        self.client_secret = os.getenv("GOOGLE_CLIENT_SECRET")
        self.redirect_uri = os.getenv("GOOGLE_REDIRECT_URI", "http://localhost:8000/auth/google/callback")
        self.scopes = [
            "openid",
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/userinfo.profile"
        ]
        
        if not self.client_id or not self.client_secret:
            raise ValueError("GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET must be set in environment variables")
    
    def get_authorization_url(self) -> tuple[str, str]:
        """Generate Google OAuth authorization URL and state parameter."""
        try:
            flow = Flow.from_client_config(
                {
                    "web": {
                        "client_id": self.client_id,
                        "client_secret": self.client_secret,
                        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                        "token_uri": "https://oauth2.googleapis.com/token",
                        "redirect_uris": [self.redirect_uri]
                    }
                },
                scopes=self.scopes
            )
            
            flow.redirect_uri = self.redirect_uri
            
            # Generate state parameter for security
            state = secrets.token_urlsafe(32)
            
            authorization_url, _ = flow.authorization_url(
                access_type='offline',
                include_granted_scopes='true',
                state=state,
                prompt='consent'  # Force consent to get refresh token
            )
            
            return authorization_url, state
            
        except Exception as e:
            logger.error(f"Error generating authorization URL: {str(e)}")
            raise HTTPException(status_code=500, detail="Failed to generate authorization URL")
    
    async def fetch_user_info(self, code: str, state: str) -> Dict[str, Any]:
        """Exchange authorization code for user info."""
        try:
            flow = Flow.from_client_config(
                {
                    "web": {
                        "client_id": self.client_id,
                        "client_secret": self.client_secret,
                        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                        "token_uri": "https://oauth2.googleapis.com/token",
                        "redirect_uris": [self.redirect_uri]
                    }
                },
                scopes=self.scopes
            )
            
            flow.redirect_uri = self.redirect_uri
            
            # Exchange authorization code for tokens
            flow.fetch_token(code=code)
            
            # Get credentials
            credentials = flow.credentials
            
            # Get user info from Google
            service = build('oauth2', 'v2', credentials=credentials)
            user_info = service.userinfo().get().execute()
            
            return {
                "google_id": user_info.get("id"),
                "email": user_info.get("email"),
                "first_name": user_info.get("given_name", ""),
                "last_name": user_info.get("family_name", ""),
                "picture": user_info.get("picture"),
                "verified_email": user_info.get("verified_email", False),
                "access_token": credentials.token,
                "refresh_token": credentials.refresh_token,
                "expires_at": credentials.expiry.isoformat() if credentials.expiry else None
            }
            
        except Exception as e:
            logger.error(f"Error fetching user info: {str(e)}")
            raise HTTPException(status_code=400, detail="Failed to fetch user information from Google")
    
    def verify_state(self, stored_state: str, provided_state: str) -> bool:
        """Verify the state parameter to prevent CSRF attacks."""
        return stored_state == provided_state

# Global OAuth service instance
oauth_service = GoogleOAuthService()

# Store states temporarily (in production, use Redis or database)
oauth_states = {}
