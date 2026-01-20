import requests
import os
import json
import sys

# Configuration
BASE_URL = "http://localhost:8000"
AUTH_ENDPOINT = f"{BASE_URL}/auth/firebase/signin"
ROLE_ENDPOINT = f"{BASE_URL}/auth/role-selection"

def test_firebase_signin_new_user():
    print("Testing Firebase Sign-In for New User (Mock)...")
    
    # Mock data
    payload = {
        "id_token": "mock_token_123",
        "email": "test_google_user@example.com",
        "display_name": "Test Google User",
        "photo_url": "http://example.com/photo.jpg"
    }
    
    try:
        response = requests.post(AUTH_ENDPOINT, json=payload)
        
        if response.status_code == 200:
            data = response.json()
            print("Sign-In Successful!")
            print(json.dumps(data, indent=2))
            
            if data.get("needs_role_selection"):
                print("User needs role selection. Proceeding...")
                temp_token = data.get("temporary_token")
                test_role_selection(temp_token)
            else:
                print("User already has role.")
                
        else:
            print(f"Sign-In Failed: {response.status_code}")
            print(response.text)
            
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to backend server. Is it running?")

def test_role_selection(temp_token):
    print("\nTesting Role Selection...")
    
    headers = {
        "Authorization": f"Bearer {temp_token}"
    }
    
    payload = {
        "user_type": "tenant",
        "phone_number": "+1234567890",
        "university": "Test University",
        "year_of_study": "1st Year",
        "gender": "male"
    }
    
    response = requests.post(ROLE_ENDPOINT, json=payload, headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print("Role Selection Successful!")
        print(json.dumps(data, indent=2))
    else:
        print(f"Role Selection Failed: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    # Ensure MOCK_FIREBASE_AUTH is set in the server environment, not just here.
    # But we can't easily control server env from here if it's already running.
    # We'll assume the server is started with MOCK_FIREBASE_AUTH=true.
    test_firebase_signin_new_user()
