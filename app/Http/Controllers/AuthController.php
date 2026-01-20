<?php

namespace App\Http\Controllers;

use App\Services\PalevelApiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    public function showLogin()
    {
        if (Session::has('palevel_token')) {
            $user = Session::get('palevel_user');
            return redirect($this->getDashboardRouteForUser($user));
        }

        return view('auth.login');
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|min:6',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        try {
            $response = $this->apiService->authenticate(
                $request->email,
                $request->password
            );

            $token = $response['token'];
            $user = $response['user'];

            // Store user session
            Session::put('palevel_token', $token);
            Session::put('palevel_user', $user);

            // Redirect based on user type
            return match($user['user_type']) {
                'admin' => redirect()->route('admin.dashboard'),
                'landlord' => redirect()->route('landlord.dashboard'),
                'tenant' => redirect()->route('tenant.dashboard'),
                default => redirect()->route('dashboard')
            };

        } catch (\Exception $e) {
            return back()->with('error', 'Invalid credentials. Please try again.')
                        ->withInput();
        }
    }

    public function register(Request $request)
    {
        $userType = $request->user_type;
        
        // Base validation rules
        $rules = [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6|confirmed',
            'phone_number' => 'nullable|string|max:20',
            'user_type' => 'required|in:tenant,landlord',
            'terms' => 'required',
        ];

        // Add student-specific validation
        if ($userType === 'tenant') {
            $rules['university'] = 'required|string|max:255';
            $rules['year_of_study'] = 'required|string|max:50';
        }

        // Add landlord-specific validation
        if ($userType === 'landlord') {
            $rules['id_document'] = 'required|file|mimes:jpg,jpeg,png,pdf|max:5120';
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        try {
            $userData = [
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'email' => $request->email,
                'password' => $request->password,
                'phone_number' => $request->phone_number,
                'user_type' => $userType,
            ];

            // Add student-specific data
            if ($userType === 'tenant') {
                $userData['university'] = $request->university;
                $userData['year_of_study'] = $request->year_of_study;
            }

            // Add landlord-specific data
            if ($userType === 'landlord' && $request->hasFile('id_document')) {
                $userData['national_id_image'] = $request->file('id_document');
            }

            $user = $this->apiService->createUser($userData);

            return redirect()->route('login')
                        ->with('success', 'Registration successful! Please login.');

        } catch (\Exception $e) {
            Log::error('Registration error: ' . $e->getMessage());
            return back()->with('error', 'Registration failed. Please try again.')
                        ->withInput();
        }
    }

    public function logout(Request $request)
    {
        Session::forget(['palevel_token', 'palevel_user']);
        return redirect()->route('login')->with('success', 'Logged out successfully.');
    }

    /**
     * Get appropriate dashboard route based on user role and permissions
     */
    private function getDashboardRouteForUser(?array $user): string
    {
        if (!$user) {
            return route('dashboard');
        }
        
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
}
