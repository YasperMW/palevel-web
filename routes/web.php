<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\GoogleAuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HostelController;
use App\Http\Controllers\LandingController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\SignupController;
use App\Http\Controllers\BookingController;

// Include test routes (remove in production)
require __DIR__.'/test.php';

// Include debug routes (remove in production)
require __DIR__.'/debug.php';

// Landing Page (Root)
Route::get('/', [LandingController::class, 'index'])->name('landing');

// Authentication Routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/auth/google/callback', [GoogleAuthController::class, 'handleGoogleCallback'])->name('auth.google.callback');

// Password Reset Routes
Route::get('forgot-password', function () {
    return view('auth.passwords.email');
})->name('password.request');

Route::post('forgot-password', function () {
    return back()->with('status', 'We have emailed your password reset link!');
})->name('password.email');

Route::get('reset-password/{token}', function ($token) {
    return view('auth.passwords.reset', ['token' => $token]);
})->name('password.reset');

Route::post('reset-password', function () {
    return redirect()->route('login')->with('status', 'Your password has been reset!');
})->name('password.update');

// Registration Routes (legacy GET pages redirect to enhanced signup flow)
Route::get('/register', function(){ return redirect()->route('signup.flow'); })->name('register.choice');
Route::get('/register/student', function(){ return redirect()->route('signup.personal', ['userType' => 'tenant']); })->name('register.student');
Route::get('/register/landlord', function(){ return redirect()->route('signup.personal', ['userType' => 'landlord']); })->name('register.landlord');
Route::post('/register', [SignupController::class, 'completeSignup'])->name('register');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Enhanced web signup flow (mirrors mobile multi-step flow)
Route::get('/signup', [SignupController::class, 'showSignupFlow'])->name('signup.flow');
Route::get('/signup/{userType}/personal', [SignupController::class, 'showPersonalInfo'])->name('signup.personal');
Route::post('/signup/personal', [SignupController::class, 'storePersonalInfo'])->name('signup.personal.store');
Route::get('/signup/verify', [SignupController::class, 'showOtpVerification'])->name('signup.verify');
Route::post('/signup/verify', [SignupController::class, 'verifyOtp'])->name('signup.verify.post');
Route::post('/signup/resend-otp', [SignupController::class, 'resendOtp'])->name('signup.resend_otp');
Route::get('/signup/profile', [SignupController::class, 'showProfileSetup'])->name('signup.profile');
Route::post('/signup/complete', [SignupController::class, 'completeSignup'])->name('signup.complete');
Route::get('/signup/universities', [SignupController::class, 'getUniversities'])->name('signup.universities');

// OAuth completion routes (skip OTP, use pre-filled data)
Route::get('/signup/oauth/student', [SignupController::class, 'showOAuthStudentCompletion'])->name('signup.oauth.student');
Route::get('/signup/oauth/landlord', [SignupController::class, 'showOAuthLandlordCompletion'])->name('signup.oauth.landlord');
Route::post('/signup/oauth/complete/student', [SignupController::class, 'completeOAuthStudent'])->name('signup.oauth.complete.student');
Route::post('/signup/oauth/complete/landlord', [SignupController::class, 'completeOAuthLandlord'])->name('signup.oauth.complete.landlord');

// Dashboard Routes
Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard')
    ->middleware('auth.palevel');

// Admin Routes
Route::prefix('admin')->name('admin.')->middleware('auth.palevel:admin')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'dashboard'])->name('dashboard');
    Route::get('/students', [AdminController::class, 'students'])->name('students');
    Route::get('/landlords', [AdminController::class, 'landlords'])->name('landlords');
    Route::get('/payments', [AdminController::class, 'payments'])->name('payments');
    Route::get('/bookings', [AdminController::class, 'bookings'])->name('bookings');
    Route::get('/hostels', [AdminController::class, 'hostels'])->name('hostels');
    Route::get('/logs', [AdminController::class, 'logs'])->name('logs');
    Route::get('/config', [AdminController::class, 'config'])->name('config');
    Route::get('/verifications', [AdminController::class, 'verifications'])->name('verifications');
    Route::get('/disbursements', [AdminController::class, 'disbursements'])->name('disbursements');
    
    // API Routes for AJAX calls
    Route::get('/stats-api', [AdminController::class, 'statsApi'])->name('stats-api');
    Route::get('/students-api', [AdminController::class, 'studentsApi'])->name('students-api');
    Route::get('/landlords-api', [AdminController::class, 'landlordsApi'])->name('landlords-api');
    Route::get('/payments-api', [AdminController::class, 'paymentsApi'])->name('payments-api');
    Route::get('/bookings-api', [AdminController::class, 'bookingsApi'])->name('bookings-api');
    Route::get('/hostels-api', [AdminController::class, 'hostelsApi'])->name('hostels-api');
    Route::get('/logs-api', [AdminController::class, 'logsApi'])->name('logs-api');
    Route::get('/config-api', [AdminController::class, 'configApi'])->name('config-api');
    Route::get('/user-details-api', [AdminController::class, 'userDetailsApi'])->name('user-details-api');
    Route::get('/verifications-api', [AdminController::class, 'verificationsApi'])->name('verifications-api');
    Route::get('/disbursements-api', [AdminController::class, 'disbursementsApi'])->name('disbursements-api');
    Route::post('/disbursements/process-api', [AdminController::class, 'processDisbursement'])->name('disbursements.process-api');
    Route::post('/disbursements/batch-api', [AdminController::class, 'processBatchDisbursement'])->name('disbursements.batch-api');
    
    // Update routes
    Route::put('/users/{user_id}/status', [AdminController::class, 'updateUserStatus'])->name('users.update-status');
    Route::put('/hostels/{hostel_id}/status', [AdminController::class, 'updateHostelStatus'])->name('hostels.update-status');
    Route::put('/config/{config_key}', [AdminController::class, 'updateConfig'])->name('config.update');
    Route::put('/verifications/{verification_id}/status', [AdminController::class, 'updateVerificationStatus'])->name('verifications.update-status');
});

// Landlord Routes
Route::prefix('landlord')->name('landlord.')->middleware(['auth.palevel:landlord', 'user.profile'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/hostels/create', [HostelController::class, 'create'])->name('hostels.create');
    Route::post('/hostels', [HostelController::class, 'store'])->name('hostels.store');
    Route::get('/hostels/{id}/rooms/create', [HostelController::class, 'createRoom'])->name('hostels.create-room');
    Route::post('/hostels/{id}/rooms', [HostelController::class, 'storeRoom'])->name('hostels.store-room');
    Route::get('/bookings', [DashboardController::class, 'landlordBookings'])->name('bookings');
    Route::get('/payments', [DashboardController::class, 'landlordPayments'])->name('payments');
});

// Student Routes
Route::prefix('student')->name('student.')->middleware(['auth.palevel:tenant', 'user.profile'])->group(function () {
    Route::get('/home', [DashboardController::class, 'studentHome'])->name('home');
    Route::get('/bookings', [DashboardController::class, 'studentBookings'])->name('bookings');
    Route::get('/bookings/{bookingId}', [BookingController::class, 'showBookingDetail'])->name('bookings.show');
    Route::get('/profile', [DashboardController::class, 'studentProfile'])->name('profile');
    Route::get('/payment/{bookingId}', [BookingController::class, 'showPayment'])->name('payment');
    Route::get('/payment/extend/{bookingId}', [BookingController::class, 'showExtensionPayment'])->name('payment.extend');
    Route::get('/payment/complete/{bookingId}', [BookingController::class, 'showCompletePayment'])->name('payment.complete');
});

// Tenant Routes (Redirect to Student Dashboard)
Route::prefix('tenant')->name('tenant.')->middleware('auth.palevel:tenant')->group(function () {
    Route::get('/dashboard', function() {
        return redirect()->route('student.home');
    })->name('dashboard');
});

// Common Routes
Route::middleware('auth.palevel')->group(function () {
    // API Routes for hostel details (AJAX calls) - must come first to take precedence
    Route::prefix('api/hostels')->group(function () {
        Route::get('{id}/rooms', [HostelController::class, 'apiRooms'])->name('api.hostels.rooms');
        Route::get('{id}/reviews', [HostelController::class, 'apiReviews'])->name('api.hostels.reviews');
        Route::get('{id}/landlord', [HostelController::class, 'apiLandlord'])->name('api.hostels.landlord');
    });
    
    // API Routes for bookings
    Route::prefix('api')->group(function () {
        Route::post('/bookings', [BookingController::class, 'apiCreate'])->name('api.bookings.create');
        Route::get('/user/bookings', [BookingController::class, 'apiUserBookings'])->name('api.user.bookings');
        Route::get('/user/gender', [BookingController::class, 'apiUserGender'])->name('api.user.gender');
        Route::get('/user/details', [BookingController::class, 'apiUserDetails'])->name('api.user.details');
        Route::post('/bookings/{bookingId}/extension-status-update', [BookingController::class, 'apiUpdateExtensionStatus'])->name('api.bookings.extension-status-update');
        Route::get('/bookings/{bookingId}/extension-pricing', [BookingController::class, 'apiExtensionPricing'])->name('api.bookings.extension-pricing');
        Route::post('/payments/extend/initiate', [BookingController::class, 'apiInitiateExtensionPayment'])->name('api.payments.extend.initiate');
        Route::post('/bookings/{bookingId}/complete-payment-status-update', [BookingController::class, 'apiUpdateCompletePaymentStatus'])->name('api.bookings.complete-payment-status-update');
        Route::get('/bookings/{bookingId}/complete-payment-pricing', [BookingController::class, 'apiCompletePaymentPricing'])->name('api.bookings.complete-payment-pricing');
        Route::post('/payments/complete/initiate', [BookingController::class, 'apiInitiateCompletePayment'])->name('api.payments.complete.initiate');
        Route::post('/payments/paychangu/initiate', [BookingController::class, 'apiInitiatePayment'])->name('api.payments.paychangu.initiate');
        Route::get('/payments/verify', [BookingController::class, 'apiVerifyPayment'])->name('api.payments.verify');
        Route::post('/payments/verify-extension', [BookingController::class, 'apiVerifyExtensionPayment'])->name('api.payments.verify-extension');
        Route::post('/payments/verify-complete', [BookingController::class, 'apiVerifyCompletePayment'])->name('api.payments.verify-complete');
    });
    
    // Reviews API routes (for direct backend calls)
    Route::prefix('reviews')->group(function () {
        Route::get('hostel/{id}', [HostelController::class, 'apiReviews'])->name('reviews.hostel');
    });
    
    // Hostel Routes (web views)
    Route::get('/hostels', [HostelController::class, 'index'])->name('hostels.index');
    Route::get('/hostels/{id}', [HostelController::class, 'show'])->name('hostels.show');
    Route::get('/hostels/{id}/rooms', [HostelController::class, 'rooms'])->name('hostels.rooms');
    
    Route::get('/profile', [DashboardController::class, 'profile'])->name('profile');
    Route::put('/profile', [DashboardController::class, 'updateProfile'])->name('profile.update');
});

Route::get('/download', function() {
    return view('download');
})->name('download.app');