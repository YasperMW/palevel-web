<?php

namespace App\Http\Controllers;

use App\Services\PalevelApiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Log;

class GoogleAuthController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    public function handleGoogleCallback(Request $request)
    {
        $request->validate([
            'id_token' => 'required|string',
            'email' => 'required|email',
            'display_name' => 'nullable|string',
            'photo_url' => 'nullable|string',
            'user_type' => 'nullable|string|in:tenant,landlord'
        ]);

        try {
            // Call API to verify Firebase token (same as Flutter)
            $response = $this->apiService->googleAuthenticate([
                'id_token' => $request->id_token,
                'email' => $request->email,
                'display_name' => $request->display_name,
                'photo_url' => $request->photo_url
            ]);

            if (isset($response['needs_role_selection']) && $response['needs_role_selection'] === true) {
                // Store temporary token and user data in session for role selection (matches Flutter)
                Session::put('temp_oauth_token', $response['temporary_token']);
                Session::put('temp_oauth_user', [
                    'email' => $request->email,
                    'display_name' => $request->display_name,
                    'photo_url' => $request->photo_url,
                ]);
                
                // Redirect to appropriate OAuth completion page based on user type selection
                $userType = $request->input('user_type', 'tenant'); // Default to tenant if not specified
                $redirectUrl = $userType === 'landlord' 
                    ? route('signup.oauth.landlord') 
                    : route('signup.oauth.student');
                
                return response()->json([
                    'success' => true,
                    'needs_role_selection' => true,
                    'redirect' => $redirectUrl
                ]);
            }

            if (isset($response['token']) && isset($response['user'])) {
                // Login successful - user already exists and has role
                Session::put('palevel_token', $response['token']);
                Session::put('palevel_user', $response['user']);

                $user = $response['user'];
                $redirectUrl = $this->getDashboardRouteForUser($user);

                return response()->json([
                    'success' => true,
                    'redirect' => $redirectUrl
                ]);
            }

            return response()->json(['success' => false, 'error' => 'Authentication failed'], 401);

        } catch (\Exception $e) {
            Log::error('Google Auth Error: ' . $e->getMessage());
            
            // Try to extract the actual error message from the exception
            $errorMessage = 'Authentication failed';
            $statusCode = 500;
            
            // Check if it's an HTTP response with error details
            if (method_exists($e, 'getResponse') && $e->getResponse()) {
                $responseContent = json_decode($e->getResponse()->getBody()->getContents(), true);
                if (isset($responseContent['detail'])) {
                    $errorMessage = $this->mapGoogleErrorMessage($responseContent['detail']);
                    $statusCode = $e->getResponse()->getStatusCode();
                }
            } elseif (strpos($e->getMessage(), 'Firebase authentication failed:') !== false) {
                // Extract the actual error from the backend response
                $backendError = str_replace('Firebase authentication failed: ', '', $e->getMessage());
                $errorMessage = $this->mapGoogleErrorMessage($backendError);
                $statusCode = 400;
            }
            
            return response()->json([
                'success' => false, 
                'error' => $errorMessage
            ], $statusCode);
        }
    }

    /**
     * Get appropriate dashboard route based on user role and permissions
     */
    private function getDashboardRouteForUser(array $user): string
    {
        $userType = $user['user_type'] ?? 'tenant';
        
        switch ($userType) {
            case 'admin':
                return route('admin.dashboard');
                
            case 'landlord':
                return route('landlord.dashboard');
                
            case 'tenant':
                return route('tenant.dashboard');
                
            default:
                return route('dashboard');
        }
    }

    /**
     * Map backend Google OAuth error messages to user-friendly messages
     */
    private function mapGoogleErrorMessage(string $errorMessage): string
    {
        $errorMappings = [
            'This email is already registered with a regular account. Please use your password to login instead of OAuth.' =>
                'Email already in use. Sign in with your password instead',
            'Invalid Firebase ID token' =>
                'Invalid authentication. Please try signing in again',
            'Expired Firebase ID token' =>
                'Session expired. Please try signing in again',
            'Revoked Firebase ID token' =>
                'Authentication revoked. Please try signing in again',
            'Firebase token does not contain an email address' =>
                'Invalid account. Please try again or use a different account',
            'Token verification failed' =>
                'Authentication failed. Please try again',
            'Firebase authentication failed:' =>
                'Authentication failed. Please try again'
        ];

        // Check for exact matches first
        if (isset($errorMappings[$errorMessage])) {
            return $errorMappings[$errorMessage];
        }

        // Check for partial matches
        foreach ($errorMappings as $backendError => $userMessage) {
            if (strpos($errorMessage, $backendError) !== false || strpos($backendError, $errorMessage) !== false) {
                return $userMessage;
            }
        }

        // Default fallback for any Firebase-related errors
        if (stripos($errorMessage, 'firebase') !== false || 
            stripos($errorMessage, 'token') !== false ||
            stripos($errorMessage, 'authentication') !== false) {
            return 'Google sign-in failed. Please try again';
        }

        // Return original message if no mapping found
        return $errorMessage;
    }
}
