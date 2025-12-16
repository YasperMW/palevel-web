<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AdminController extends Controller
{
    private $apiBaseUrl;

    public function __construct()
    {
        $this->apiBaseUrl = config('services.api.base_url', 'https://localhost:8000');
    }

    private function getApiHeaders()
    {
        $token = session('palevel_token');
        return [
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
        ];
    }

    private function fetchFromApi($endpoint)
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . $endpoint);

            if ($response->failed()) {
                Log::error('API Error: ' . $response->body());
                return null;
            }

            return $response->json();
        } catch (\Exception $e) {
            Log::error('API fetch error: ' . $e->getMessage());
            return null;
        }
    }

    // Helper functions for dashboard formatting
    public static function getActivityColor($level)
    {
        $colors = [
            'login' => 'bg-green-500',
            'booking' => 'bg-blue-500',
            'payment' => 'bg-purple-500',
            'user_action' => 'bg-yellow-500',
            'system' => 'bg-gray-500'
        ];
        return $colors[$level] ?? 'bg-gray-500';
    }

    public static function formatTimeAgo($dateString)
    {
        if (!$dateString) return 'Unknown';
        
        $date = new \DateTime($dateString);
        $now = new \DateTime();
        $interval = $now->diff($date);
        
        if ($interval->days == 0) {
            if ($interval->h == 0) {
                if ($interval->i == 0) {
                    return 'Just now';
                }
                return $interval->i . ' minutes ago';
            }
            return $interval->h . ' hours ago';
        } elseif ($interval->days < 7) {
            return $interval->days . ' days ago';
        }
        
        return $date->format('M d, Y');
    }

    public function dashboard()
    {
        try {
            // Return dashboard view - data will be loaded via JavaScript from FastAPI
            return view('dashboard.admin');

        } catch (\Exception $e) {
            Log::error('Dashboard error: ' . $e->getMessage());
            return view('dashboard.admin');
        }
    }

    // API endpoints for AJAX calls
    public function statsApi()
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/stats');

            if ($response->failed()) {
                return response()->json([
                    'users' => ['total' => 0, 'students' => 0, 'landlords' => 0, 'admins' => 0],
                    'properties' => ['total_hostels' => 0, 'active_hostels' => 0, 'total_rooms' => 0],
                    'bookings' => ['total' => 0, 'pending' => 0, 'confirmed' => 0, 'cancelled' => 0, 'recent' => 0],
                    'payments' => ['total_payments' => 0, 'total_revenue' => 0, 'platform_fee' => 0],
                    'activity' => ['recent_users' => 0]
                ]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Stats API error: ' . $e->getMessage());
            return response()->json([
                'users' => ['total' => 0, 'students' => 0, 'landlords' => 0, 'admins' => 0],
                'properties' => ['total_hostels' => 0, 'active_hostels' => 0, 'total_rooms' => 0],
                'bookings' => ['total' => 0, 'pending' => 0, 'confirmed' => 0, 'cancelled' => 0, 'recent' => 0],
                'payments' => ['total_payments' => 0, 'total_revenue' => 0, 'platform_fee' => 0],
                'activity' => ['recent_users' => 0]
            ]);
        }
    }

    public function studentsApi(Request $request)
    {
        try {
            $params = [
                'skip' => ($request->get('page', 1) - 1) * 50,
                'limit' => 50,
                'search' => $request->get('search'),
                'status' => $request->get('status')
            ];

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/students', $params);

            if ($response->failed()) {
                return response()->json(['students' => [], 'total' => 0]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Students API error: ' . $e->getMessage());
            return response()->json(['students' => [], 'total' => 0]);
        }
    }

    public function landlordsApi(Request $request)
    {
        try {
            $params = [
                'skip' => ($request->get('page', 1) - 1) * 50,
                'limit' => 50,
                'search' => $request->get('search'),
                'status' => $request->get('status')
            ];

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/landlords', $params);

            if ($response->failed()) {
                return response()->json(['landlords' => [], 'total' => 0]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Landlords API error: ' . $e->getMessage());
            return response()->json(['landlords' => [], 'total' => 0]);
        }
    }

    public function paymentsApi(Request $request)
    {
        try {
            $params = [
                'skip' => ($request->get('page', 1) - 1) * 50,
                'limit' => 50,
                'status' => $request->get('status'),
                'payment_type' => $request->get('payment_type'),
                'start_date' => $request->get('start_date'),
                'end_date' => $request->get('end_date')
            ];

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/payments', $params);

            if ($response->failed()) {
                return response()->json(['payments' => [], 'total' => 0]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Payments API error: ' . $e->getMessage());
            return response()->json(['payments' => [], 'total' => 0]);
        }
    }

    public function bookingsApi(Request $request)
    {
        try {
            $params = [
                'skip' => ($request->get('page', 1) - 1) * 50,
                'limit' => 50,
                'status' => $request->get('status'),
                'start_date' => $request->get('start_date'),
                'end_date' => $request->get('end_date')
            ];

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/bookings', $params);

            if ($response->failed()) {
                return response()->json(['bookings' => [], 'total' => 0]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Bookings API error: ' . $e->getMessage());
            return response()->json(['bookings' => [], 'total' => 0]);
        }
    }

    public function hostelsApi(Request $request)
    {
        try {
            $params = [
                'skip' => ($request->get('page', 1) - 1) * 50,
                'limit' => 50,
                'status' => $request->get('status'),
                'search' => $request->get('search')
            ];

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/hostels', $params);

            if ($response->failed()) {
                return response()->json(['hostels' => [], 'total' => 0]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Hostels API error: ' . $e->getMessage());
            return response()->json(['hostels' => [], 'total' => 0]);
        }
    }

    public function userDetailsApi()
    {
        try {
            // Get current user details from FastAPI server
            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/user-details');

            if ($response->failed()) {
                return response()->json(['error' => 'Failed to fetch user details from API'], 500);
            }

            $data = $response->json();
            return response()->json($data);

        } catch (\Exception $e) {
            Log::error('User details API error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch user details'], 500);
        }
    }

    public function logsApi(Request $request)
    {
        try {
            $params = [
                'skip' => ($request->get('page', 1) - 1) * 100,
                'limit' => 100,
                'level' => $request->get('level'),
                'start_date' => $request->get('start_date'),
                'end_date' => $request->get('end_date')
            ];

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/logs', $params);

            if ($response->failed()) {
                return response()->json(['logs' => [], 'total' => 0]);
            }

            return response()->json($response->json());

        } catch (\Exception $e) {
            Log::error('Logs API error: ' . $e->getMessage());
            return response()->json(['logs' => [], 'total' => 0]);
        }
    }

    public function students(Request $request)
    {
        try {
            // Return empty data for now to avoid slow API calls
            // TODO: Implement caching or optimize the /admin/students endpoint
            return view('admin.students', [
                'students' => [],
                'total' => 0,
                'currentPage' => $request->get('page', 1),
                'search' => $request->get('search'),
                'status' => $request->get('status')
            ]);

        } catch (\Exception $e) {
            Log::error('Students management error: ' . $e->getMessage());
            return back()->with('error', 'Failed to load students data');
        }
    }

    public function landlords(Request $request)
    {
        try {
            // Return empty data for now to avoid slow API calls
            // TODO: Implement caching or optimize the /admin/landlords endpoint
            return view('admin.landlords', [
                'landlords' => [],
                'total' => 0,
                'currentPage' => $request->get('page', 1),
                'search' => $request->get('search'),
                'status' => $request->get('status')
            ]);

        } catch (\Exception $e) {
            Log::error('Landlords management error: ' . $e->getMessage());
            return back()->with('error', 'Failed to load landlords data');
        }
    }

    public function payments(Request $request)
    {
        try {
            // Return empty data for now to avoid slow API calls
            // TODO: Implement caching or optimize the /admin/payments endpoint
            return view('admin.payments', [
                'payments' => [],
                'total' => 0,
                'currentPage' => $request->get('page', 1),
                'filters' => $request->only(['status', 'payment_type', 'start_date', 'end_date'])
            ]);

        } catch (\Exception $e) {
            Log::error('Payments management error: ' . $e->getMessage());
            return back()->with('error', 'Failed to load payments data');
        }
    }

    public function bookings(Request $request)
    {
        try {
            // Return empty data for now to avoid slow API calls
            // TODO: Implement caching or optimize the /admin/bookings endpoint
            return view('admin.bookings', [
                'bookings' => [],
                'total' => 0,
                'currentPage' => $request->get('page', 1),
                'filters' => $request->only(['status', 'start_date', 'end_date'])
            ]);

        } catch (\Exception $e) {
            Log::error('Bookings management error: ' . $e->getMessage());
            return back()->with('error', 'Failed to load bookings data');
        }
    }

    public function hostels(Request $request)
    {
        try {
            // Return empty data for now to avoid slow API calls
            // TODO: Implement caching or optimize the /admin/hostels endpoint
            return view('admin.hostels', [
                'hostels' => [],
                'total' => 0,
                'currentPage' => $request->get('page', 1),
                'search' => $request->get('search'),
                'status' => $request->get('status')
            ]);

        } catch (\Exception $e) {
            Log::error('Hostels management error: ' . $e->getMessage());
            return back()->with('error', 'Failed to load hostels data');
        }
    }

    public function logs(Request $request)
    {
        try {
            // Return empty data for now to avoid slow API calls
            // TODO: Implement caching or optimize the /admin/logs endpoint
            return view('admin.logs', [
                'logs' => [],
                'total' => 0,
                'currentPage' => $request->get('page', 1),
                'filters' => $request->only(['level', 'start_date', 'end_date'])
            ]);

        } catch (\Exception $e) {
            Log::error('Logs management error: ' . $e->getMessage());
            return back()->with('error', 'Failed to load logs data');
        }
    }

    public function updateUserStatus(Request $request, $userId)
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->put($this->apiBaseUrl . '/admin/users/' . $userId . '/status', [
                    'new_status' => $request->get('new_status')
                ]);

            if ($response->failed()) {
                return back()->with('error', 'Failed to update user status');
            }

            return back()->with('success', 'User status updated successfully');

        } catch (\Exception $e) {
            Log::error('Update user status error: ' . $e->getMessage());
            return back()->with('error', 'Failed to update user status');
        }
    }

    public function updateHostelStatus(Request $request, $hostelId)
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->put($this->apiBaseUrl . '/admin/hostels/' . $hostelId . '/status', [
                    'new_status' => $request->get('new_status')
                ]);

            if ($response->failed()) {
                return back()->with('error', 'Failed to update hostel status');
            }

            return back()->with('success', 'Hostel status updated successfully');

        } catch (\Exception $e) {
            Log::error('Update hostel status error: ' . $e->getMessage());
            return back()->with('error', 'Failed to update hostel status');
        }
    }

    public function config()
    {
        return view('admin.config');
    }

    public function verifications()
    {
        return view('admin.verifications', [
            'apiBaseUrl' => $this->apiBaseUrl
        ]);
    }

    public function updateConfig(Request $request, $configKey)
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->put($this->apiBaseUrl . '/admin/config/' . $configKey, [
                    'value' => $request->get('value')
                ]);

            if ($response->failed()) {
                return back()->with('error', 'Failed to update configuration');
            }

            return back()->with('success', 'Configuration updated successfully');

        } catch (\Exception $e) {
            Log::error('Update config error: ' . $e->getMessage());
            return back()->with('error', 'Failed to update configuration');
        }
    }

    public function configApi()
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/config');

            if ($response->failed()) {
                return response()->json(['error' => 'Failed to fetch configuration'], 500);
            }

            $data = $response->json();
            return response()->json($data);

        } catch (\Exception $e) {
            Log::error('Config API error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to load configuration'], 500);
        }
    }

    public function verificationsApi()
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/verifications');

            if ($response->failed()) {
                return response()->json(['error' => 'Failed to fetch verifications from API'], 500);
            }

            $data = $response->json();
            return response()->json($data);

        } catch (\Exception $e) {
            Log::error('Verifications API error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch verifications'], 500);
        }
    }

    public function updateVerificationStatus(Request $request, $verificationId)
    {
        try {
            $response = Http::withHeaders($this->getApiHeaders())
                ->asForm()
                ->put($this->apiBaseUrl . '/admin/verifications/' . $verificationId, [
                    'status' => $request->get('status')
                ]);

            if ($response->failed()) {
                return back()->with('error', 'Failed to update verification status');
            }

            return back()->with('success', 'Verification status updated successfully');

        } catch (\Exception $e) {
            Log::error('Update verification error: ' . $e->getMessage());
            return back()->with('error', 'Failed to update verification status');
        }
    }

    public function disbursementsApi(Request $request)
    {
        try {
            $skip = $request->get('skip', 0);
            $limit = $request->get('limit', 50);
            $search = $request->get('search', '');
            $status = $request->get('status', '');

            $params = [
                'skip' => $skip,
                'limit' => $limit
            ];

            if (!empty($search)) {
                $params['search'] = $search;
            }
            if (!empty($status)) {
                $params['status'] = $status;
            }

            $response = Http::withHeaders($this->getApiHeaders())
                ->get($this->apiBaseUrl . '/admin/disbursements', $params);

            if ($response->failed()) {
                return response()->json(['error' => 'Failed to fetch disbursements data'], 500);
            }

            $data = $response->json();
            return response()->json($data);

        } catch (\Exception $e) {
            Log::error('Disbursements API error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch disbursements'], 500);
        }
    }

    public function processDisbursement(Request $request)
    {
        try {
            $validated = $request->validate([
                'booking_id' => 'required|uuid',
                'landlord_id' => 'required|uuid',
                'amount' => 'required|numeric|min:0',
                'is_batch' => 'boolean'
            ]);

            $response = Http::withHeaders($this->getApiHeaders())
                ->post($this->apiBaseUrl . '/admin/disbursements/process', $validated);

            if ($response->failed()) {
                $errorData = $response->json();
                return response()->json([
                    'success' => false,
                    'message' => $errorData['detail'] ?? 'Failed to process disbursement'
                ], $response->status());
            }

            $data = $response->json();
            return response()->json($data);

        } catch (\Exception $e) {
            Log::error('Process disbursement error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to process disbursement'
            ], 500);
        }
    }

    public function processBatchDisbursement(Request $request)
    {
        try {
            $validated = $request->validate([
                'landlord_id' => 'required|uuid',
                'total_amount' => 'required|numeric|min:0',
                'total_bookings' => 'required|integer|min:1'
            ]);

            $response = Http::withHeaders($this->getApiHeaders())
                ->post($this->apiBaseUrl . '/admin/disbursements/batch', $validated);

            if ($response->failed()) {
                $errorData = $response->json();
                return response()->json([
                    'success' => false,
                    'message' => $errorData['detail'] ?? 'Failed to process batch disbursement'
                ], $response->status());
            }

            $data = $response->json();
            return response()->json($data);

        } catch (\Exception $e) {
            Log::error('Process batch disbursement error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to process batch disbursement'
            ], 500);
        }
    }

    public function disbursements()
    {
        return view('admin.disbursements', [
            'apiBaseUrl' => $this->apiBaseUrl
        ]);
    }
}
