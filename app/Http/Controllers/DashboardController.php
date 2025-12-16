<?php

namespace App\Http\Controllers;

use App\Services\PalevelApiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class DashboardController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    public function index()
    {
        $user = Session::get('palevel_user');
        $token = Session::get('palevel_token');

        if (!$user || !$token) {
            return redirect()->route('login');
        }

        return match($user['user_type']) {
            'admin' => $this->adminDashboard($token),
            'landlord' => $this->landlordDashboard($user, $token),
            'tenant' => $this->tenantDashboard($user, $token),
            default => redirect()->route('login')
        };
    }

    private function adminDashboard($token)
    {
        try {
            $stats = [
                'total_users' => 0,
                'total_hostels' => 0,
                'total_bookings' => 0,
                'total_revenue' => 0,
            ];

            // Get all hostels for stats
            $hostels = $this->apiService->getAllHostels();
            $stats['total_hostels'] = count($hostels);

            return view('dashboard.admin', compact('stats'));

        } catch (\Exception $e) {
            return view('dashboard.admin', ['stats' => [], 'error' => 'Failed to load dashboard data']);
        }
    }

    private function landlordDashboard($user, $token)
    {
        try {
            // Get landlord's hostels
            $hostels = $this->apiService->getLandlordHostels($token);
            
            // Get landlord statistics
            $stats = $this->apiService->getLandlordStats($user['email'], $token);

            // Get recent bookings
            $bookings = $this->apiService->getBookings($token, ['limit' => 10]);

            return view('dashboard.landlord', compact('hostels', 'stats', 'bookings'));

        } catch (\Exception $e) {
            return view('dashboard.landlord', [
                'hostels' => [], 
                'stats' => [], 
                'bookings' => [],
                'error' => 'Failed to load dashboard data'
            ]);
        }
    }

    private function tenantDashboard($user, $token)
    {
        try {
            // Get all available hostels
            $hostels = $this->apiService->getAllHostels();
            
            // Get tenant's bookings
            $bookings = $this->apiService->getBookings($token, ['student_id' => $user['user_id']]);

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'], $token);

            return view('dashboard.tenant', compact('hostels', 'bookings', 'notifications'));

        } catch (\Exception $e) {
            return view('dashboard.tenant', [
                'hostels' => [], 
                'bookings' => [], 
                'notifications' => [],
                'error' => 'Failed to load dashboard data'
            ]);
        }
    }

    public function profile()
    {
        $user = Session::get('palevel_user');
        
        try {
            $profile = $this->apiService->getUserProfile(email: $user['email']);
            return view('profile.show', compact('profile'));

        } catch (\Exception $e) {
            return view('profile.show', ['profile' => $user, 'error' => 'Failed to load profile data']);
        }
    }

    public function updateProfile(Request $request)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone_number' => 'nullable|string|max:20',
            'university' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator);
        }

        // Note: Profile update would need to be implemented in the backend API
        return back()->with('success', 'Profile updated successfully!');
    }
}
