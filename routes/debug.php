<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

// Debug route to test API connection
Route::get('/debug-api', function () {
    try {
        $apiUrl = config('palevel.api_url');
        $timeout = config('palevel.api_timeout');
        
        Log::info("Testing API connection to: " . $apiUrl);
        
        // Test basic HTTP connection
        $response = Http::timeout(5)
            ->get($apiUrl . '/');
            
        if ($response->successful()) {
            return response()->json([
                'status' => 'success',
                'api_url' => $apiUrl,
                'timeout' => $timeout,
                'response_status' => $response->status(),
                'response_body' => $response->json()
            ]);
        } else {
            return response()->json([
                'status' => 'error',
                'api_url' => $apiUrl,
                'timeout' => $timeout,
                'response_status' => $response->status(),
                'response_body' => $response->body()
            ]);
        }
        
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'exception',
            'error' => $e->getMessage(),
            'api_url' => config('palevel.api_url'),
            'timeout' => config('palevel.api_timeout')
        ]);
    }
});

// Test with different timeout values
Route::get('/debug-timeout', function () {
    try {
        $apiUrl = config('palevel.api_url');
        
        // Test with very short timeout
        $response = Http::timeout(2)
            ->get($apiUrl . '/');
            
        return response()->json([
            'status' => 'success',
            'message' => 'Connection successful with 2s timeout',
            'response' => $response->json()
        ]);
        
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'Connection failed even with 2s timeout',
            'error' => $e->getMessage()
        ]);
    }
});

// Test without timeout
Route::get('/debug-no-timeout', function () {
    try {
        $apiUrl = config('palevel.api_url');
        
        // Test without timeout
        $response = Http::get($apiUrl . '/');
            
        return response()->json([
            'status' => 'success',
            'message' => 'Connection successful without timeout',
            'response' => $response->json()
        ]);
        
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'Connection failed without timeout',
            'error' => $e->getMessage()
        ]);
    }
});
