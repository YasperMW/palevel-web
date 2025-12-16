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
            return view('hostels.index', compact('hostels'));
        } catch (\Exception $e) {
            return view('hostels.index', ['hostels' => [], 'error' => 'Failed to load hostels']);
        }
    }

    public function show($id)
    {
        try {
            $hostel = $this->apiService->getHostel($id);
            $rooms = $this->apiService->getHostelRooms($id);
            
            return view('hostels.show', compact('hostel', 'rooms'));
        } catch (\Exception $e) {
            return redirect()->route('hostels.index')->with('error', 'Hostel not found');
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
            return redirect()->route('hostels.index')->with('error', 'Failed to load rooms');
        }
    }

    public function createRoom($hostelId)
    {
        try {
            $hostel = $this->apiService->getHostel($hostelId);
            return view('hostels.create-room', compact('hostel'));
        } catch (\Exception $e) {
            return redirect()->route('hostels.index')->with('error', 'Hostel not found');
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
