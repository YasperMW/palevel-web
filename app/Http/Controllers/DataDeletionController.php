<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Mail\DataDeletionRequest;
use App\Services\PalevelApiService;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;

class DataDeletionController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    public function show()
    {
        return view('data-deletion');
    }

    public function submit(Request $request)
    {
        // Get current logged-in user
        $currentUser = session('palevel_user');
        
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'phone' => 'required|string|max:20',
            'reason' => 'required|string',
            'confirmation' => 'required|accepted',
            'data_categories' => 'required|array|min:1',
            'data_categories.*' => 'string',
        ]);

        // Validate that the email matches the current user's email
        if (strtolower($validated['email']) !== strtolower($currentUser['email'])) {
            return back()->withInput()
                ->with('error', 'You can only submit a data deletion request for your own account. Please use your registered email address.');
        }

        try {
            // Prepare data for API
            $apiData = [
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'reason' => $validated['reason'],
                'data_categories' => $validated['data_categories'],
                'confirmation' => $validated['confirmation'] === '1' || $validated['confirmation'] === true,
            ];

            // Get auth token
            $token = session('palevel_token');
            $headers = [];
            
            if ($token) {
                $headers['Authorization'] = "Bearer {$token}";
            }

            // Send to FastAPI backend
            $response = $this->apiService->makeRequest('POST', '/api/data-deletion/request', $apiData, $headers);

            // Log the successful submission
            Log::info('Data deletion request submitted successfully', [
                'email' => $validated['email'],
                'name' => $validated['name'],
                'data_categories' => $validated['data_categories'],
                'timestamp' => now(),
                'api_response' => $response
            ]);

            return redirect()->route('data.deletion')
                ->with('success', 'Your data deletion request has been submitted successfully. We will process your request within 30 days and contact you at your provided email address.');

        } catch (RequestException $e) {
            $responseBody = $e->hasResponse() ? $e->getResponse()->getBody()->getContents() : 'No response body';
            
            Log::error('Failed to submit data deletion request to API', [
                'error' => $e->getMessage(),
                'response_code' => $e->hasResponse() ? $e->getResponse()->getStatusCode() : 'No response',
                'response_body' => $responseBody,
                'request_data' => $validated
            ]);

            return back()->withInput()
                ->with('error', 'There was an error submitting your request to our servers. Please try again or contact support directly.');

        } catch (\Exception $e) {
            Log::error('Unexpected error submitting data deletion request', [
                'error' => $e->getMessage(),
                'request_data' => $validated
            ]);

            return back()->withInput()
                ->with('error', 'An unexpected error occurred. Please try again or contact support directly.');
        }
    }
}
