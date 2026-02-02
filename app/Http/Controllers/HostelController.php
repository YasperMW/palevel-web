<?php

namespace App\Http\Controllers;

use App\Services\PalevelApiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Validator;

class HostelController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    public function index()
    {
        try {
            $hostels = $this->apiService->getAllHostels();
            return view('student.hostels', compact('hostels'));
        } catch (\Exception $e) {
            return view('student.hostels', ['hostels' => [], 'error' => 'Failed to load hostels']);
        }
    }

    public function show($id)
    {
        // Debug: Log the received ID
        \Log::info("HostelController::show called with ID: " . $id);
        
        try {
            $hostel = $this->apiService->getHostel($id);
            \Log::info("API call successful for hostel ID: " . $id);
            
            // Normalize hostel data if wrapped
            if (isset($hostel['data']) && is_array($hostel['data'])) {
                $hostel = $hostel['data'];
            } elseif (isset($hostel['hostel']) && is_array($hostel['hostel'])) {
                $hostel = $hostel['hostel'];
            }

            \Illuminate\Support\Facades\Log::info('Hostel Data Debug:', ['hostel' => $hostel]);
            
            // Fetch additional data like the Flutter app does
            $rooms = [];
            $reviews = [];
            $totalRooms = 0;
            $availableRooms = 0;
            $averageRating = 0;
            $totalReviews = 0;
            
            try {
                // Get rooms like Flutter app
                $rooms = $this->apiService->getHostelRooms($id, ['user_type' => 'student']);
                $totalRooms = count($rooms);
                $availableRooms = count(array_filter($rooms, fn($r) => ($r['occupants'] ?? 0) < ($r['capacity'] ?? 1)));
            } catch (\Exception $e) {
                \Log::warning("Failed to load rooms for hostel {$id}: " . $e->getMessage());
            }
            
            try {
                // Get reviews like Flutter app
                $reviews = $this->apiService->getHostelReviews($id);
                $totalReviews = count($reviews);
                if ($totalReviews > 0) {
                    $averageRating = collect($reviews)->avg('rating') ?? 0;
                }
            } catch (\Exception $e) {
                \Log::warning("Failed to load reviews for hostel {$id}: " . $e->getMessage());
            }
            
            return view('student.hostel-detail', [
                'hostel' => $hostel,
                'rooms' => $rooms,
                'reviews' => $reviews,
                'landlord' => [], // Landlord info not critical for initial load
                'bookings' => [],
                'totalRooms' => $totalRooms,
                'availableRooms' => $availableRooms,
                'averageRating' => $averageRating,
                'totalReviews' => $totalReviews
            ]);
        } catch (\Exception $e) {
            \Log::error("HostelController::show failed: " . $e->getMessage());
            \Log::error("Exception details: " . $e->getTraceAsString());
            return redirect()->route('student.home')->with('error', 'Hostel not found');
        }
    }

    // API Methods for AJAX calls
    public function apiRooms($id)
    {
        try {
            $rooms = $this->apiService->getHostelRooms($id);
            
            // Calculate available rooms count
            $availableRooms = array_filter($rooms, fn($r) => $r['is_available'] ?? false);
            
            return response()->json([
                'rooms' => $rooms,
                'available_rooms_count' => count($availableRooms)
            ]);
        } catch (\Exception $e) {
            \Log::error("API Error getting rooms: " . $e->getMessage());
            return response()->json(['error' => 'Failed to load rooms'], 500);
        }
    }

    public function apiReviews($id)
    {
        try {
            $reviews = $this->apiService->getHostelReviews($id);
            
            // Calculate rating statistics
            $averageRating = $reviews ? collect($reviews)->avg('rating') : 0;
            $totalReviews = count($reviews);
            
            return response()->json([
                'reviews' => $reviews,
                'average_rating' => $averageRating,
                'total_reviews' => $totalReviews
            ]);
        } catch (\Exception $e) {
            \Log::error("API Error getting reviews: " . $e->getMessage());
            return response()->json(['error' => 'Failed to load reviews'], 500);
        }
    }

    public function apiLandlord($id)
    {
        try {
            $landlord = $this->apiService->getHostelLandlord($id);
            
            return response()->json($landlord);
        } catch (\Exception $e) {
            \Log::error("API Error getting landlord: " . $e->getMessage());
            return response()->json(['error' => 'Failed to load landlord information'], 500);
        }
    }

    public function create()
    {
        return view('hostels.create');
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'address' => 'required|string',
            'district' => 'required|string|max:255',
            'university' => 'required|string|max:255',
            'type' => 'required|in:Private,Shared,Self-contained',
            'description' => 'nullable|string',
            'price_per_month' => 'nullable|numeric|min:0',
            'booking_fee' => 'nullable|numeric|min:0',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        try {
            $token = Session::get('palevel_token');
            $hostelData = $request->all();
            
            $this->apiService->createHostel($hostelData, $token);
            
            return redirect()->route('landlord.dashboard')
                        ->with('success', 'Hostel created successfully!');

        } catch (\Exception $e) {
            return back()->with('error', 'Failed to create hostel. Please try again.')
                        ->withInput();
        }
    }

    public function rooms($hostelId)
    {
        try {
            $hostel = $this->apiService->getHostel($hostelId);
            $rooms = $this->apiService->getHostelRooms($hostelId);
            
            return view('hostels.rooms', compact('hostel', 'rooms'));
        } catch (\Exception $e) {
            return redirect()->route('student.home')->with('error', 'Failed to load rooms');
        }
    }

    public function createRoom($hostelId)
    {
        try {
            $hostel = $this->apiService->getHostel($hostelId);
            return view('hostels.create-room', compact('hostel'));
        } catch (\Exception $e) {
            return redirect()->route('student.home')->with('error', 'Hostel not found');
        }
    }

    public function storeRoom(Request $request, $hostelId)
    {
        $validator = Validator::make($request->all(), [
            'room_number' => 'required|string|max:50',
            'type' => 'required|in:single,double,shared,suite',
            'price_per_month' => 'required|numeric|min:0',
            'capacity' => 'required|integer|min:1',
            'availability_start_date' => 'nullable|date',
            'availability_end_date' => 'nullable|date|after:availability_start_date',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        try {
            $token = Session::get('palevel_token');
            $roomData = array_merge($request->all(), ['hostel_id' => $hostelId]);
            
            $this->apiService->createRoom($roomData, $token);
            
            return redirect()->route('hostels.rooms', $hostelId)
                        ->with('success', 'Room created successfully!');

        } catch (\Exception $e) {
            return back()->with('error', 'Failed to create room. Please try again.')
                        ->withInput();
        }
    }
}
