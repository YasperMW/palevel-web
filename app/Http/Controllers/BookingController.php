<?php

namespace App\Http\Controllers;

use App\Services\PalevelApiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Log;

class BookingController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    public function create($hostelId, $roomId)
    {
        try {
            // Get all rooms for this hostel to find the specific one
            // We use 'student' user_type to get availability info if needed
            $rooms = $this->apiService->getHostelRooms($hostelId, ['user_type' => 'student']);
            
            // Find the specific room
            $room = null;
            foreach ($rooms as $r) {
                $rId = $r['room_id'] ?? $r['id'] ?? '';
                if ($rId == $roomId) {
                    $room = $r;
                    break;
                }
            }

            if (!$room) {
                return redirect()->back()->with('error', 'Room not found');
            }
            
            // Get hostel details
            $hostel = $this->apiService->getHostel($hostelId);

            return view('student.booking', compact('room', 'hostel'));

        } catch (\Exception $e) {
            Log::error("Booking page load failed: " . $e->getMessage());
            return redirect()->back()->with('error', 'Failed to load booking page. Please try again.');
        }
    }

    public function showBookingDetail(string $bookingId)
    {
        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return redirect()->route('login')->with('error', 'Please login to view booking details');
            }

            $booking = $this->apiService->getBooking($bookingId, $token);
            if (!$booking) {
                return redirect()->route('student.bookings')->with('error', 'Booking not found');
            }

            return view('student.booking-detail', compact('booking'));

        } catch (\Exception $e) {
            Log::error("Booking detail load failed: " . $e->getMessage());
            return redirect()->route('student.bookings')->with('error', 'Failed to load booking details. Please try again.');
        }
    }

    public function apiUpdateExtensionStatus(string $bookingId, Request $request)
    {
        try {
            $request->validate([
                'additional_months' => 'required|integer|min:1'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $result = $this->apiService->updateExtensionStatus($bookingId, (int) $request->additional_months, $token);

            return response()->json(['success' => true, 'data' => $result]);

        } catch (\Exception $e) {
            Log::error("API update extension status failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function apiExtensionPricing(string $bookingId, Request $request)
    {
        try {
            $request->validate([
                'additional_months' => 'required|integer|min:1'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $result = $this->apiService->getExtensionPricing($bookingId, (int) $request->additional_months, $token);

            return response()->json(['success' => true, 'data' => $result]);

        } catch (\Exception $e) {
            Log::error("API extension pricing failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function apiInitiateExtensionPayment(Request $request)
    {
        try {
            $request->validate([
                'booking_id' => 'required|string',
                'additional_months' => 'required|integer|min:1',
                'email' => 'required|email',
                'phone_number' => 'nullable|string',
                'first_name' => 'nullable|string',
                'last_name' => 'nullable|string',
                'payment_method' => 'nullable|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $payload = $request->only([
                'booking_id',
                'additional_months',
                'email',
                'phone_number',
                'first_name',
                'last_name',
                'payment_method'
            ]);

            $result = $this->apiService->initiateExtensionPayment($payload, $token);

            return response()->json(['success' => true, 'data' => $result]);

        } catch (\Exception $e) {
            Log::error("API initiate extension payment failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function apiUpdateCompletePaymentStatus(string $bookingId, Request $request)
    {
        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $result = $this->apiService->updateCompletePaymentStatus($bookingId, $token);

            return response()->json(['success' => true, 'data' => $result]);

        } catch (\Exception $e) {
            Log::error("API update complete payment status failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function apiCompletePaymentPricing(string $bookingId, Request $request)
    {
        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $result = $this->apiService->getCompletePaymentPricing($bookingId, $token);

            return response()->json(['success' => true, 'data' => $result]);

        } catch (\Exception $e) {
            Log::error("API complete payment pricing failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function apiInitiateCompletePayment(Request $request)
    {
        try {
            $request->validate([
                'booking_id' => 'required|string',
                'remaining_amount' => 'required|numeric|min:0',
                'email' => 'required|email',
                'phone_number' => 'nullable|string',
                'first_name' => 'nullable|string',
                'last_name' => 'nullable|string',
                'payment_method' => 'nullable|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $payload = $request->only([
                'booking_id',
                'remaining_amount',
                'email',
                'phone_number',
                'first_name',
                'last_name',
                'payment_method'
            ]);

            $result = $this->apiService->initiateCompletePayment($payload, $token);

            return response()->json(['success' => true, 'data' => $result]);

        } catch (\Exception $e) {
            Log::error("API initiate complete payment failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    public function store(Request $request)
    {
        $request->validate([
            'room_id' => 'required|string',
            'check_in_date' => 'required|date|after:today',
            'duration_months' => 'required|integer|min:1',
            'payment_type' => 'required|in:full,booking_fee',
            'payment_method' => 'required|string'
        ]);

        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return redirect()->route('login')->with('error', 'Please login to book a room');
            }

            $bookingData = [
                'room_id' => $request->room_id,
                'check_in_date' => $request->check_in_date,
                'duration_months' => (int)$request->duration_months,
                'payment_type' => $request->payment_type,
                'payment_method' => $request->payment_method,
                'amount' => 0 // Backend calculates actual amount
            ];

            $this->apiService->createBooking($bookingData, $token);

            return redirect()->route('student.bookings')->with('success', 'Booking request submitted successfully!');

        } catch (\Exception $e) {
            Log::error("Booking submission failed: " . $e->getMessage());
            return back()->withInput()->with('error', 'Failed to submit booking: ' . $e->getMessage());
        }
    }

    public function showPayment($bookingId, Request $request)
    {
        try {
            // Get booking details from API
            $token = Session::get('palevel_token');
            if (!$token) {
                return redirect()->route('login')->with('error', 'Please login to make payment');
            }

            // Get booking details
            $booking = $this->apiService->getBooking($bookingId, $token);
            
            if (!$booking) {
                return redirect()->route('student.bookings')->with('error', 'Booking not found');
            }

            // Payment should already be initiated by frontend
            // Get payment URL from query parameter
            $paymentUrl = $request->query('paymentUrl');
            
            if (!$paymentUrl) {
                return back()->with('error', 'Payment URL not found. Please initiate payment again.');
            }

            $paymentFlow = 'standard';
            $displayAmount = $request->query('amount');
            
            // Just display the payment page with booking details and payment URL
            return view('student.payment', compact('booking', 'paymentUrl', 'paymentFlow', 'displayAmount'));

        } catch (\Exception $e) {
            Log::error("Payment page load failed: " . $e->getMessage());
            return redirect()->route('student.bookings')->with('error', 'Failed to load payment page: ' . $e->getMessage());
        }
    }

    public function showExtensionPayment($bookingId, Request $request)
    {
        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return redirect()->route('login')->with('error', 'Please login to make payment');
            }

            $booking = $this->apiService->getBooking($bookingId, $token);
            if (!$booking) {
                return redirect()->route('student.bookings')->with('error', 'Booking not found');
            }

            $paymentUrl = $request->query('paymentUrl');
            if (!$paymentUrl) {
                return back()->with('error', 'Payment URL not found. Please initiate payment again.');
            }

            $paymentFlow = 'extension';
            $displayAmount = $request->query('amount');

            return view('student.payment', compact('booking', 'paymentUrl', 'paymentFlow', 'displayAmount'));
        } catch (\Exception $e) {
            Log::error("Extension payment page load failed: " . $e->getMessage());
            return redirect()->route('student.bookings')->with('error', 'Failed to load payment page: ' . $e->getMessage());
        }
    }

    public function showCompletePayment($bookingId, Request $request)
    {
        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return redirect()->route('login')->with('error', 'Please login to make payment');
            }

            $booking = $this->apiService->getBooking($bookingId, $token);
            if (!$booking) {
                return redirect()->route('student.bookings')->with('error', 'Booking not found');
            }

            $paymentUrl = $request->query('paymentUrl');
            if (!$paymentUrl) {
                return back()->with('error', 'Payment URL not found. Please initiate payment again.');
            }

            $paymentFlow = 'complete';
            $displayAmount = $request->query('amount');

            return view('student.payment', compact('booking', 'paymentUrl', 'paymentFlow', 'displayAmount'));
        } catch (\Exception $e) {
            Log::error("Complete payment page load failed: " . $e->getMessage());
            return redirect()->route('student.bookings')->with('error', 'Failed to load payment page: ' . $e->getMessage());
        }
    }

    // API Methods for AJAX calls
    public function apiCreate(Request $request)
    {
        try {
            $request->validate([
                'room_id' => 'required|string',
                'check_in_date' => 'required|date|after:today',
                'duration_months' => 'required|integer|min:1',
                'amount' => 'required|numeric|min:0',
                'payment_type' => 'required|in:full,booking_fee',
                'payment_method' => 'required|string',
                'status' => 'required|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $bookingData = [
                'room_id' => $request->room_id,
                'check_in_date' => $request->check_in_date,
                'duration_months' => (int)$request->duration_months,
                'amount' => (float)$request->amount,
                'payment_type' => $request->payment_type,
                'payment_method' => $request->payment_method,
                'status' => $request->status
            ];

            $booking = $this->apiService->createBooking($bookingData, $token);

            return response()->json([
                'success' => true,
                'data' => $booking,
                'message' => 'Booking created successfully'
            ], 201);

        } catch (\Exception $e) {
            Log::error("API booking creation failed: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create booking: ' . $e->getMessage()
            ], 500);
        }
    }

    public function apiUserBookings(Request $request)
    {
        try {
            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $bookings = $this->apiService->getUserBookings($token);

            return response()->json([
                'success' => true,
                'data' => $bookings
            ]);

        } catch (\Exception $e) {
            Log::error("API user bookings failed: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch bookings: ' . $e->getMessage()
            ], 500);
        }
    }

    public function apiUserGender(Request $request)
    {
        try {
            // Get user details from session (stored during login)
            $user = Session::get('palevel_user_details');
            
            if (!$user) {
                // Fallback to API call if not in session
                $token = Session::get('palevel_token');
                if (!$token) {
                    return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
                }
                
                $user = $this->apiService->getCurrentUser($token);
                if ($user) {
                    Session::put('palevel_user_details', $user);
                }
            }
            
            $gender = $user['gender'] ?? '';

            return response($gender, 200);

        } catch (\Exception $e) {
            Log::error("API user gender failed: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch user gender: ' . $e->getMessage()
            ], 500);
        }
    }

    public function apiUserDetails(Request $request)
    {
        try {
            // Get user details from session (stored during login)
            $user = Session::get('palevel_user_details');
            
            if (!$user) {
                // Fallback to API call if not in session
                $token = Session::get('palevel_token');
                if (!$token) {
                    return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
                }
                
                $user = $this->apiService->getCurrentUser($token);
                if ($user) {
                    Session::put('palevel_user_details', $user);
                }
            }

            return response()->json([
                'success' => true,
                'data' => $user ?? []
            ]);

        } catch (\Exception $e) {
            Log::error("API user details failed: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch user details: ' . $e->getMessage()
            ], 500);
        }
    }

    public function apiInitiatePayment(Request $request)
    {
        try {
            $request->validate([
                'booking_id' => 'required|string',
                'amount' => 'required|numeric|min:0',
                'email' => 'required|email',
                'phone_number' => 'nullable|string',
                'first_name' => 'nullable|string',
                'last_name' => 'nullable|string',
                'currency' => 'required|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $paymentData = [
                'booking_id' => $request->booking_id,
                'amount' => (float)$request->amount,
                'email' => $request->email,
                'phone_number' => $request->phone_number,
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'currency' => $request->currency
            ];

            $payment = $this->apiService->initiatePayChanguPayment($paymentData, $token);

            return response()->json([
                'success' => true,
                'data' => $payment,
                'message' => 'Payment initiated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error("API payment initiation failed: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to initiate payment: ' . $e->getMessage()
            ], 500);
        }
    }

    public function apiVerifyPayment(Request $request)
    {
        // Log complete request details
        Log::info('API Payment Verification Request', [
            'headers' => $request->header(),
            'query' => $request->query(),
            'body' => $request->all(),
            'reference' => $request->reference
        ]);

        try {
            $request->validate([
                'reference' => 'required|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                Log::warning('Payment verification failed: User not authenticated');
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $reference = $request->reference;
            
            Log::info("Attempting to verify payment with reference: {$reference}");

            $payment = $this->apiService->verifyPayment($reference, $token);

            Log::info("Payment verification successful for reference: {$reference}", ['response' => $payment]);

            return response()->json([
                'success' => true,
                'data' => $payment,
                'message' => 'Payment verified successfully'
            ]);

        } catch (\Exception $e) {
            Log::error("API payment verification failed for reference {$request->reference}: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            
            // Extract status code if available in exception message or default to 500
            $statusCode = 500;
            if (preg_match('/API request failed: (\d+)/', $e->getMessage(), $matches)) {
                $statusCode = (int)$matches[1];
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to verify payment: ' . $e->getMessage()
            ], $statusCode);
        }
    }

    public function apiVerifyExtensionPayment(Request $request)
    {
        try {
            $request->validate([
                'payment_id' => 'required|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $paymentId = $request->payment_id;
            $result = $this->apiService->verifyExtensionPayment($paymentId, $token);
            $success = is_array($result) && (($result['status'] ?? null) === 'success');

            return response()->json([
                'success' => $success,
                'data' => $result,
                'message' => $success ? 'Extension payment verified successfully' : 'Extension payment not verified yet'
            ]);
        } catch (\Exception $e) {
            Log::error("API extension payment verification failed: " . $e->getMessage());

            $statusCode = 500;
            if (preg_match('/API request failed: (\d+)/', $e->getMessage(), $matches)) {
                $statusCode = (int)$matches[1];
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to verify extension payment: ' . $e->getMessage()
            ], $statusCode);
        }
    }

    public function apiVerifyCompletePayment(Request $request)
    {
        try {
            $request->validate([
                'payment_id' => 'required|string'
            ]);

            $token = Session::get('palevel_token');
            if (!$token) {
                return response()->json(['success' => false, 'message' => 'User not authenticated'], 401);
            }

            $paymentId = $request->payment_id;
            $result = $this->apiService->verifyCompletePayment($paymentId, $token);
            $success = is_array($result) && (($result['status'] ?? null) === 'success');

            return response()->json([
                'success' => $success,
                'data' => $result,
                'message' => $success ? 'Complete payment verified successfully' : 'Complete payment not verified yet'
            ]);
        } catch (\Exception $e) {
            Log::error("API complete payment verification failed: " . $e->getMessage());

            $statusCode = 500;
            if (preg_match('/API request failed: (\d+)/', $e->getMessage(), $matches)) {
                $statusCode = (int)$matches[1];
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to verify complete payment: ' . $e->getMessage()
            ], $statusCode);
        }
    }
}
