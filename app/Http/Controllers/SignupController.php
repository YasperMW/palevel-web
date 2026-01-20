<?php

namespace App\Http\Controllers;

use App\Services\PalevelApiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class SignupController extends Controller
{
    private PalevelApiService $apiService;

    public function __construct(PalevelApiService $apiService)
    {
        $this->apiService = $apiService;
    }

    /**
     * Display the signup role selection page
     */
    public function showSignupFlow()
    {
        if (Session::has('palevel_token')) {
            return redirect()->route('dashboard');
        }
        
        return view('auth.signup.signup-flow');
    }

    /**
     * Display the personal information step
     */
    public function showPersonalInfo($userType)
    {
        if (Session::has('palevel_token')) {
            return redirect()->route('dashboard');
        }

        if (!in_array($userType, ['tenant', 'landlord'])) {
            return redirect()->route('signup.flow')->with('error', 'Invalid user type');
        }

        // Check if this is OAuth completion flow
        $isOAuthFlow = Session::has('temp_oauth_token');
        $oauthUserData = Session::get('temp_oauth_user', []);

        return view('auth.signup.personal-info', [
            'userType' => $userType,
            'isOAuthFlow' => $isOAuthFlow,
            'oauthUserData' => $oauthUserData
        ]);
    }

    /**
     * Process and validate personal information
     * Returns OTP verification page or errors
     */
    public function storePersonalInfo(Request $request)
    {
        $userType = $request->input('user_type');
        
        if (!in_array($userType, ['tenant', 'landlord'])) {
            return response()->json(['error' => 'Invalid user type'], 400);
        }

        // Validate input
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255|min:2',
            'last_name' => 'required|string|max:255|min:2',
            'email' => 'required|email|max:255',
            'phone_number' => 'required|string|min:10|max:20',
            'user_type' => 'required|in:tenant,landlord',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Store all signup data in session for Flutter-style flow
        Session::put('signup_data', [
            'first_name' => $request->first_name,
            'last_name' => $request->last_name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'user_type' => $userType,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Personal info saved',
            'nextStep' => 'profile-setup'
        ]);
    }

    /**
     * Display the OTP verification step
     */
    public function showOtpVerification()
    {
        if (!Session::has('signup_data')) {
            return redirect()->route('signup.flow')->with('error', 'Please start signup again');
        }

        $signupData = Session::get('signup_data');
        return view('auth.signup.otp-verification', [
            'email' => $signupData['email']
        ]);
    }

    /**
     * Verify OTP and proceed to profile setup
     */
    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'otp' => 'required|string|size:6|regex:/^[0-9]{6}$/',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $signupData = Session::get('signup_data');
            $email = $signupData['email'];

            // Verify OTP with backend - matches Flutter exactly
            $response = $this->apiService->verifyOtp($email, $request->otp);

            if (!empty($response['token']) && !empty($response['user'])) {
                // Store authenticated session
                Session::put('palevel_token', $response['token']);
                Session::put('palevel_user', $response['user']);

                // Clear signup session data
                Session::forget(['signup_data']);

                return response()->json([
                    'success' => true,
                    'message' => 'Email verified and logged in',
                    'redirect' => $this->getDashboardRouteForUser($response['user'])
                ]);
            }

            return response()->json([
                'success' => false,
                'error' => $response['detail'] ?? 'Invalid OTP'
            ], 400);

        } catch (\Exception $e) {
            Log::error('OTP verification error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'error' => 'OTP verification failed'
            ], 400);
        }
    }

    /**
     * Resend OTP to email
     */
    public function resendOtp(Request $request)
    {
        try {
            $signupData = Session::get('signup_data');
            
            if (!$signupData) {
                return response()->json([
                    'success' => false,
                    'error' => 'Session expired'
                ], 400);
            }

            $response = $this->apiService->sendOtp(
                $signupData['email'],
                $signupData['first_name'],
                $signupData['last_name'],
                $signupData['phone_number'],
                $signupData['user_type']
            );

            return response()->json([
                'success' => true,
                'message' => 'OTP resent to your email'
            ]);

        } catch (\Exception $e) {
            Log::error('Resend OTP error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'error' => 'Failed to resend OTP'
            ], 400);
        }
    }

    /**
     * Display the profile setup step
     */
    public function showProfileSetup()
    {
        // Allow access if either OTP verified or OAuth flow
        $hasValidAccess = Session::has('otp_verified') || Session::has('temp_oauth_token');
        
        if (!$hasValidAccess) {
            return redirect()->route('signup.flow')->with('error', 'Please complete verification first');
        }

        $userType = Session::get('signup_user_type');
        $isOAuthFlow = Session::has('temp_oauth_token');
        $oauthUserData = Session::get('temp_oauth_user', []);
        
        return view('auth.signup.profile-setup', [
            'userType' => $userType,
            'email' => Session::get('signup_email'),
            'firstName' => Session::get('signup_first_name'),
            'lastName' => Session::get('signup_last_name'),
            'phone' => Session::get('signup_phone'),
            'isOAuthFlow' => $isOAuthFlow,
            'oauthUserData' => $oauthUserData
        ]);
    }

    /**
     * Complete signup with password and profile information
     */
    public function completeSignup(Request $request)
    {
        $isOAuthFlow = Session::has('temp_oauth_token');
        
        // Validate password (only for non-OAuth flow)
        $passwordRules = [];
        if (!$isOAuthFlow) {
            $passwordRules = [
                'password' => [
                    'required',
                    'string',
                    'min:8',
                    'confirmed',
                    'regex:/[a-z]/',     // lowercase
                    'regex:/[A-Z]/',     // uppercase
                    'regex:/[0-9]/',     // digit
                    'regex:/[!@#$%^&*]/', // special char
                ],
            ];
        }

        $validator = Validator::make($request->all(), $passwordRules);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Validate profile fields based on user type
        $profileRules = [
            'gender' => 'nullable|in:Male,Female,Prefer not to say',
            'date_of_birth' => 'nullable|date|before:today',
        ];

        if (Session::get('signup_user_type') === 'tenant') {
            $profileRules['university'] = 'required|string|max:255';
            $profileRules['year_of_study'] = 'required|in:1st Year,2nd Year,3rd Year,4th Year,Postgraduate';
        }
        
            if (Session::get('signup_user_type') === 'landlord') {
                $profileRules['national_id_image'] = 'required|file|mimes:jpg,jpeg,png,pdf|max:5120';
            }

        $profileValidator = Validator::make($request->all(), $profileRules);

        if ($profileValidator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $profileValidator->errors()
            ], 422);
        }

        try {
            $isOAuthFlow = Session::has('temp_oauth_token');
            
            if ($isOAuthFlow) {
                // OAuth flow - complete role selection with temporary token
                $tempToken = Session::get('temp_oauth_token');
                
                $roleData = [
                    'user_type' => Session::get('signup_user_type'),
                    'gender' => $request->input('gender'),
                    'date_of_birth' => $request->input('date_of_birth'),
                ];

                if (Session::get('signup_user_type') === 'tenant') {
                    $roleData['university'] = $request->university;
                    $roleData['year_of_study'] = $request->year_of_study;
                }

                // If landlord provided an ID image, attach the uploaded file
                if ($request->hasFile('national_id_image')) {
                    $roleData['national_id_image'] = $request->file('national_id_image');
                }

                $response = $this->apiService->completeRoleSelection($roleData, $tempToken);

                if (isset($response['token']) && isset($response['user'])) {
                    // Clear temporary OAuth data
                    Session::forget(['temp_oauth_token', 'temp_oauth_user']);
                    
                    // Store permanent session
                    Session::put('palevel_token', $response['token']);
                    Session::put('palevel_user', $response['user']);

                    return response()->json([
                        'success' => true,
                        'message' => 'Registration completed successfully',
                        'redirect' => $this->getDashboardRouteForUser($response['user'])
                    ]);
                }
            } else {
                // Regular signup flow - match Flutter exactly
                $signupData = Session::get('signup_data');
                
                // Build user data matching Flutter payload
                $userData = [
                    'first_name' => $signupData['first_name'],
                    'last_name' => $signupData['last_name'],
                    'email' => $signupData['email'],
                    'phone_number' => $signupData['phone_number'],
                    'password' => $request->password,
                    'user_type' => $signupData['user_type'],
                    'gender' => $request->input('gender'),
                    'date_of_birth' => $request->input('date_of_birth'),
                ];

                if ($signupData['user_type'] === 'tenant') {
                    $userData['university'] = $request->university;
                    $userData['year_of_study'] = $request->year_of_study;
                    
                    // Use Flutter endpoint for students
                    $response = $this->apiService->createUser($userData);
                } else {
                    // Landlord - use Flutter endpoint with ID image
                    $nationalIdImage = $request->hasFile('national_id_image') ? $request->file('national_id_image') : null;
                    $response = $this->apiService->createUserWithId($userData, $nationalIdImage);
                }

                // Flutter flow: after successful creation, redirect to OTP verification
                if ($response && !isset($response['detail'])) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Account created. OTP sent to your email.',
                        'nextStep' => 'otp-verification',
                        'redirect' => route('signup.verify')
                    ]);
                } else {
                    throw new \Exception($response['detail'] ?? 'Failed to create account');
                }
            }

        } catch (\Exception $e) {
            Log::error('Signup completion error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'error' => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Display OAuth student completion page
     */
    public function showOAuthStudentCompletion()
    {
        if (!Session::has('temp_oauth_token')) {
            return redirect()->route('signup.flow')->with('error', 'Invalid OAuth session');
        }

        $oauthUserData = Session::get('temp_oauth_user', []);
        
        return view('auth.signup.oauth-student', [
            'oauthUserData' => $oauthUserData
        ]);
    }

    /**
     * Display OAuth landlord completion page
     */
    public function showOAuthLandlordCompletion()
    {
        if (!Session::has('temp_oauth_token')) {
            return redirect()->route('signup.flow')->with('error', 'Invalid OAuth session');
        }

        $oauthUserData = Session::get('temp_oauth_user', []);
        
        return view('auth.signup.oauth-landlord', [
            'oauthUserData' => $oauthUserData
        ]);
    }

    /**
     * Complete OAuth student signup
     */
    public function completeOAuthStudent(Request $request)
    {
        if (!Session::has('temp_oauth_token')) {
            return response()->json(['success' => false, 'error' => 'Invalid OAuth session'], 400);
        }

        $validator = Validator::make($request->all(), [
            'university' => 'required|string|max:255',
            'year_of_study' => 'required|in:1st Year,2nd Year,3rd Year,4th Year,Postgraduate',
            'phone_number' => 'required|string|min:10|max:20',
            'gender' => 'nullable|in:Male,Female,Prefer not to say',
            'date_of_birth' => 'nullable|date|before:today',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $tempToken = Session::get('temp_oauth_token');
            
            // Match Flutter's completeRoleSelection payload structure
            $roleData = [
                'user_type' => 'tenant',
                'university' => $request->university,
                'year_of_study' => $request->year_of_study,
                'phone_number' => $request->phone_number,
                'gender' => $request->input('gender'),
                'date_of_birth' => $request->input('date_of_birth'),
            ];

            $response = $this->apiService->completeRoleSelection($roleData, $tempToken);

            if (isset($response['token']) && isset($response['user'])) {
                // Clear temporary OAuth data
                Session::forget(['temp_oauth_token', 'temp_oauth_user']);
                
                // Store permanent session
                Session::put('palevel_token', $response['token']);
                Session::put('palevel_user', $response['user']);

                return response()->json([
                    'success' => true,
                    'message' => 'Student account completed successfully',
                    'redirect' => $this->getDashboardRouteForUser($response['user'])
                ]);
            }

            return response()->json([
                'success' => false,
                'error' => $response['detail'] ?? 'Failed to complete student setup'
            ], 400);

        } catch (\Exception $e) {
            Log::error('OAuth student completion error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'error' => 'Failed to complete student setup'
            ], 400);
        }
    }

    /**
     * Complete OAuth landlord signup
     */
    public function completeOAuthLandlord(Request $request)
    {
        if (!Session::has('temp_oauth_token')) {
            return response()->json(['success' => false, 'error' => 'Invalid OAuth session'], 400);
        }

        $validator = Validator::make($request->all(), [
            'national_id_image' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120',
            'phone_number' => 'required|string|min:10|max:20',
            'gender' => 'nullable|in:Male,Female,Prefer not to say',
            'date_of_birth' => 'nullable|date|before:today',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $tempToken = Session::get('temp_oauth_token');
            
            // Match Flutter's completeRoleSelection payload structure
            $roleData = [
                'user_type' => 'landlord',
                'phone_number' => $request->phone_number,
                'gender' => $request->input('gender'),
                'date_of_birth' => $request->input('date_of_birth'),
            ];

            // Attach the uploaded ID image
            if ($request->hasFile('national_id_image')) {
                $roleData['national_id_image'] = $request->file('national_id_image');
            }

            $response = $this->apiService->completeRoleSelection($roleData, $tempToken);

            if (isset($response['token']) && isset($response['user'])) {
                // Clear temporary OAuth data
                Session::forget(['temp_oauth_token', 'temp_oauth_user']);
                
                // Store permanent session
                Session::put('palevel_token', $response['token']);
                Session::put('palevel_user', $response['user']);

                return response()->json([
                    'success' => true,
                    'message' => 'Landlord account completed successfully',
                    'redirect' => $this->getDashboardRouteForUser($response['user'])
                ]);
            }

            return response()->json([
                'success' => false,
                'error' => $response['detail'] ?? 'Failed to complete landlord setup'
            ], 400);

        } catch (\Exception $e) {
            Log::error('OAuth landlord completion error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'error' => 'Failed to complete landlord setup'
            ], 400);
        }
    }

    /**
     * Get universities list for dropdown
     */
    public function getUniversities()
    {
        $universities = [
            "University of Malawi (UNIMA)",
            "Malawi University of Science and Technology (MUST)",
            "Lilongwe University of Agriculture and Natural Resources (LUANAR)",
            "Mzuzu University (MZUNI)",
            "Malawi University of Business and Applied Sciences (MUBAS)",
            "Kamuzu University of Health Sciences (KUHeS)",
            "Malawi College of Accountancy (MCA)",
            "Malawi School of Government (MSG)",
            "Domasi College of Education (DCE)",
            "Nalikule College of Education (NCE)",
            "Malawi College of Health Sciences (MCHS)",
            "Mikolongwe College of Veterinary Sciences (MCVS)",
            "Malawi College of Forestry and Wildlife (MCFW)",
            "Malawi Institute of Tourism (MIT)",
            "Marine College (MC)",
            "Civil Aviation Training Centre (CATC)",
            "Montfort Special Needs Education Centre (MSNEC)",
            "National College of Information Technology (NACIT)",
            "Guidance, Counselling and Youth Development Centre for Africa (GCYDCA)",
            "Catholic University of Malawi (CUNIMA)",
            "DMI St John the Baptist University (DMI)",
            "Nkhoma University (NKHUNI)",
            "Malawi Assemblies of God University (MAGU)",
            "Daeyang University (DU)",
            "Malawi Adventist University (MAU)",
            "Pentecostal Life University (PLU)",
            "African Bible College (ABC)",
            "University of Livingstonia (UNILIA)",
            "Exploits University (EU)",
            "University of Lilongwe (UNILIL)",
            "Millennium University (MU)",
            "Lake Malawi Anglican University (LAMAU)",
            "Unicaf University Malawi (UNICAF)",
            "Blantyre International University (BIU)",
            "ShareWORLD Open University (SWOU)",
            "Skyway University (SU)",
            "University of Blantyre Synod (UBS)",
            "Jubilee University (JU)",
            "Marble Hill University (MHU)",
            "Zomba Theological College (ZTC)",
            "Emmanuel University (EMUNI)",
            "ESAMI (ESAMI)",
            "Evangelical Bible College of Malawi (EBCoM)",
            "University of Hebron (UOH)",
            "Malawi Institute of Journalism (MIJ)",
            "International Open University (IOU)",
            "International College of Business and Management (ICBM)",
            "St John of God College of Health Sciences (SJOG)",
            "PACT College (PACT)",
            "K & M School of Accountancy (KM)"
        ];

        return response()->json($universities);
    }

    /**
     * Get appropriate dashboard route based on user role and permissions
     */
    private function getDashboardRouteForUser(array $user): string
    {
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
