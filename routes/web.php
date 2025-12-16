<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HostelController;
use App\Http\Controllers\LandingController;
use App\Http\Controllers\AdminController;

// Include test routes (remove in production)
require __DIR__.'/test.php';

// Include debug routes (remove in production)
require __DIR__.'/debug.php';

// Landing Page (Root)
Route::get('/', [LandingController::class, 'index'])->name('landing');

// Authentication Routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);

// Registration Routes
Route::get('/register', [AuthController::class, 'showRegisterChoice'])->name('register.choice');
Route::get('/register/student', [AuthController::class, 'showStudentRegister'])->name('register.student');
Route::get('/register/landlord', [AuthController::class, 'showLandlordRegister'])->name('register.landlord');
Route::post('/register', [AuthController::class, 'register'])->name('register');
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

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
