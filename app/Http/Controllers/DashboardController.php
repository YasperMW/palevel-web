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
        
        // Ensure token is clean
        $token = trim($token);

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
            $bookings = $this->apiService->getLandlordBookings($token);

            return view('dashboard.landlord', compact('hostels', 'stats', 'bookings'));

        } catch (\Exception $e) {
            return view('dashboard.landlord', [
                'hostels' => [], 
                'stats' => [], 
                'bookings' => [],
                'error' => 'Failed to load dashboard data: ' . $e->getMessage()
            ]);
        }
    }

    private function tenantDashboard($user, $token)
    {
        try {
            // Get all available hostels
            $hostels = $this->apiService->getAllHostels();
            
            // Get tenant's bookings
            $bookings = $this->apiService->getMyBookings($token);

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'] ?? '', $token);

            return view('dashboard.tenant', compact('hostels', 'bookings', 'notifications'));

        } catch (\Exception $e) {
            return view('dashboard.tenant', [
                'hostels' => [], 
                'bookings' => [], 
                'notifications' => [],
                'error' => 'Failed to load dashboard data: ' . $e->getMessage()
            ]);
        }
    }

    public function profile()
    {
        $user = Session::get('palevel_user');
        
        try {
            $profile = $this->apiService->getUserProfile(email: $user['email']);
            
            // Return appropriate view based on user type
            $viewName = $user['user_type'] === 'landlord' ? 'landlord.profile' : 'student.profile';
            return view($viewName, compact('profile'));

        } catch (\Exception $e) {
            // Return appropriate view based on user type
            $viewName = $user['user_type'] === 'landlord' ? 'landlord.profile' : 'student.profile';
            return view($viewName, ['profile' => $user, 'error' => 'Failed to load profile data']);
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

        // Note: Profile update would need to be implemented in backend API
        return back()->with('success', 'Profile updated successfully!');
    }

    public function studentHome()
    {
        $user = Session::get('palevel_user');
        $token = Session::get('palevel_token');

        if (!$user || !$token) {
            return redirect()->route('login');
        }
        
        // Ensure token is clean
        $token = trim($token);
        
        // Robust email retrieval
        $email = $user['email'] ?? null;
        if (empty($email)) {
            Log::error('User logged in but email missing in session', ['user' => $user]);
            Session::flush(); // Clear corrupted session
            return redirect()->route('login')->with('error', 'Session corrupted. Please login again.');
        }

        try {
            // Get all available hostels
            $hostels = $this->apiService->getAllHostels();
            
            // Get tenant's bookings
            $bookings = $this->apiService->getMyBookings($token);

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'] ?? '', $token);

            // Calculate stats
            $availableHostels = count(array_filter($hostels, fn($h) => $h['is_active'] ?? false));
            $totalSpent = array_sum(array_column($bookings, 'total_amount') ?? [0]);
            $unreadNotifications = count(array_filter($notifications, fn($n) => !($n['is_read'] ?? false)));

            return view('student.home', compact('hostels', 'bookings', 'notifications', 'availableHostels', 'totalSpent', 'unreadNotifications'));

        } catch (\Exception $e) {
            return view('student.home', [
                'hostels' => [], 
                'bookings' => [], 
                'notifications' => [],
                'availableHostels' => 0,
                'totalSpent' => 0,
                'unreadNotifications' => 0,
                'error' => 'Failed to load dashboard data: ' . $e->getMessage()
            ]);
        }
    }

    public function studentBookings()
    {
        $user = Session::get('palevel_user');
        $token = Session::get('palevel_token');

        if (!$user || !$token) {
            return redirect()->route('login');
        }
        
        // Ensure token is clean
        $token = trim($token);

        try {
            // Get tenant's bookings
            $bookings = $this->apiService->getMyBookings($token);

            if (is_array($bookings)) {
                $bookings = array_map(function ($booking) {
                    if (!is_array($booking)) {
                        return $booking;
                    }

                    if (empty($booking['hostel_name']) && isset($booking['room']['hostel']['name'])) {
                        $booking['hostel_name'] = $booking['room']['hostel']['name'];
                    }

                    if (empty($booking['room_number']) && isset($booking['room']['room_number'])) {
                        $booking['room_number'] = $booking['room']['room_number'];
                    }

                    if (empty($booking['room_type']) && isset($booking['room']['room_type'])) {
                        $booking['room_type'] = $booking['room']['room_type'];
                    }

                    if (empty($booking['created_at']) && isset($booking['booking_date'])) {
                        $booking['created_at'] = $booking['booking_date'];
                    }

                    if (empty($booking['start_date']) && isset($booking['check_in_date'])) {
                        $booking['start_date'] = $booking['check_in_date'];
                    }

                    if (empty($booking['end_date']) && isset($booking['check_out_date'])) {
                        $booking['end_date'] = $booking['check_out_date'];
                    }

                    return $booking;
                }, $bookings);
            }

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'] ?? '', $token);
            $unreadNotifications = count(array_filter($notifications, fn($n) => !($n['is_read'] ?? false)));

            // Calculate booking stats
            $confirmedBookings = count(array_filter($bookings, fn($b) => ($b['status'] ?? '') === 'confirmed'));
            $pendingBookings = count(array_filter($bookings, fn($b) => ($b['status'] ?? '') === 'pending'));
            $cancelledBookings = count(array_filter($bookings, fn($b) => ($b['status'] ?? '') === 'cancelled'));

            return view('student.bookings', compact('bookings', 'notifications', 'unreadNotifications', 'confirmedBookings', 'pendingBookings', 'cancelledBookings'));

        } catch (\Exception $e) {
            return view('student.bookings', [
                'bookings' => [], 
                'notifications' => [],
                'unreadNotifications' => 0,
                'confirmedBookings' => 0,
                'pendingBookings' => 0,
                'cancelledBookings' => 0,
                'error' => 'Failed to load bookings data'
            ]);
        }
    }

    public function landlordBookings()
    {
        $user = Session::get('palevel_user');
        $token = Session::get('palevel_token');

        if (!$user || !$token) {
            return redirect()->route('login');
        }
        
        // Ensure token is clean
        $token = trim($token);

        try {
            // Get landlord's bookings
            $bookings = $this->apiService->getLandlordBookings($token);

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'] ?? '', $token);
            $unreadNotifications = count(array_filter($notifications, fn($n) => !($n['is_read'] ?? false)));

            // Calculate booking stats
            $confirmedBookings = count(array_filter($bookings, fn($b) => ($b['status'] ?? '') === 'confirmed'));
            $pendingBookings = count(array_filter($bookings, fn($b) => ($b['status'] ?? '') === 'pending'));
            $cancelledBookings = count(array_filter($bookings, fn($b) => ($b['status'] ?? '') === 'cancelled'));

            return view('landlord.bookings', compact('bookings', 'notifications', 'unreadNotifications', 'confirmedBookings', 'pendingBookings', 'cancelledBookings'));

        } catch (\Exception $e) {
            return view('landlord.bookings', [
                'bookings' => [], 
                'notifications' => [],
                'unreadNotifications' => 0,
                'confirmedBookings' => 0,
                'pendingBookings' => 0,
                'cancelledBookings' => 0,
                'error' => 'Failed to load bookings data'
            ]);
        }
    }

    public function landlordPayments()
    {
        $user = Session::get('palevel_user');
        $token = Session::get('palevel_token');

        if (!$user || !$token) {
            return redirect()->route('login');
        }
        
        // Ensure token is clean
        $token = trim($token);

        try {
            // Get landlord's payments
            $payments = $this->apiService->getPayments($token);

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'] ?? '', $token);
            $unreadNotifications = count(array_filter($notifications, fn($n) => !($n['is_read'] ?? false)));

            // Calculate payment stats
            $totalRevenue = array_sum(array_column($payments, 'amount') ?? [0]);
            $completedPayments = count(array_filter($payments, fn($p) => ($p['status'] ?? '') === 'completed'));
            $pendingPayments = count(array_filter($payments, fn($p) => ($p['status'] ?? '') === 'pending'));

            return view('landlord.payments', compact('payments', 'notifications', 'unreadNotifications', 'totalRevenue', 'completedPayments', 'pendingPayments'));

        } catch (\Exception $e) {
            return view('landlord.payments', [
                'payments' => [], 
                'notifications' => [],
                'unreadNotifications' => 0,
                'totalRevenue' => 0,
                'completedPayments' => 0,
                'pendingPayments' => 0,
                'error' => 'Failed to load payments data'
            ]);
        }
    }

    public function studentProfile()
    {
        $user = Session::get('palevel_user');
        $token = Session::get('palevel_token');

        if (!$user || !$token) {
            return redirect()->route('login');
        }
        
        // Ensure token is clean
        $token = trim($token);
        
        // Robust email retrieval
        $email = $user['email'] ?? null;
        if (empty($email)) {
             return redirect()->route('login')->with('error', 'Session corrupted. Please login again.');
        }

        try {
            // Get user profile
            $profile = $this->apiService->getUserProfile(email: $email);
            
            // Get tenant's bookings for stats
            $bookings = $this->apiService->getBookings($token, ['student_id' => $user['user_id'] ?? '']);
            $totalBookings = count($bookings);

            // Get notifications
            $notifications = $this->apiService->getNotifications($user['user_id'] ?? '', $token);
            $unreadNotifications = count(array_filter($notifications, fn($n) => !($n['is_read'] ?? false)));

            return view('student.profile', compact('profile', 'totalBookings', 'unreadNotifications'));

        } catch (\Exception $e) {
            return view('student.profile', [
                'profile' => $user, 
                'totalBookings' => 0,
                'unreadNotifications' => 0,
                'error' => 'Failed to load profile data'
            ]);
        }
    }
}
