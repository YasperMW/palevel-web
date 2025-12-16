<?php

use Illuminate\Support\Facades\Route;
use App\Services\PalevelApiService;

// Test route for API connection
Route::get('/test-api', function () {
    try {
        $apiService = app(PalevelApiService::class);
        
        // Test the API root endpoint
        $response = $apiService->makeRequest('GET', '/');
        
        return response()->json([
            'status' => 'success',
            'message' => 'API connection successful',
            'api_response' => $response
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'API connection failed',
            'error' => $e->getMessage()
        ]);
    }
});

// Test route for user creation
Route::get('/test-create-user', function () {
    try {
        $apiService = app(PalevelApiService::class);
        
        $testUserData = [
            'first_name' => 'Test',
            'last_name' => 'User',
            'email' => 'test' . time() . '@example.com',
            'password' => 'password123',
            'phone_number' => '+265123456789',
            'user_type' => 'tenant',
            'university' => 'Test University',
            'year_of_study' => '1st Year'
        ];
        
        $response = $apiService->createUser($testUserData);
        
        return response()->json([
            'status' => 'success',
            'message' => 'User creation successful',
            'user_data' => $testUserData,
            'api_response' => $response
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'User creation failed',
            'error' => $e->getMessage()
        ]);
    }
});

// Test route for authentication
Route::get('/test-auth', function () {
    try {
        $apiService = app(PalevelApiService::class);
        
        $response = $apiService->authenticate('test@example.com', 'password123');
        
        return response()->json([
            'status' => 'success',
            'message' => 'Authentication successful',
            'api_response' => $response
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'Authentication failed',
            'error' => $e->getMessage()
        ]);
    }
});
