<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\GoogleAuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HostelController;
use App\Http\Controllers\LandingController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\SignupController;

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
Route::prefix('landlord')->name('landlord.')->middleware('auth.palevel:landlord')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/hostels/create', [HostelController::class, 'create'])->name('hostels.create');
    Route::post('/hostels', [HostelController::class, 'store'])->name('hostels.store');
    Route::get('/hostels/{id}/rooms/create', [HostelController::class, 'createRoom'])->name('hostels.create-room');
    Route::post('/hostels/{id}/rooms', [HostelController::class, 'storeRoom'])->name('hostels.store-room');
});

// Tenant Routes
Route::prefix('tenant')->name('tenant.')->middleware('auth.palevel:tenant')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
});

// Common Routes
Route::middleware('auth.palevel')->group(function () {
    Route::get('/profile', [DashboardController::class, 'profile'])->name('profile');
    Route::put('/profile', [DashboardController::class, 'updateProfile'])->name('profile.update');
    
    // Hostel Routes (accessible by all authenticated users)
    Route::get('/hostels', [HostelController::class, 'index'])->name('hostels.index');
    Route::get('/hostels/{id}', [HostelController::class, 'show'])->name('hostels.show');
    Route::get('/hostels/{id}/rooms', [HostelController::class, 'rooms'])->name('hostels.rooms');
});
