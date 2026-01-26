@php
    $currentUser = Session::get('palevel_user');
    $profileData = isset($profile) ? $profile : $currentUser;
@endphp

@extends('layouts.app')

@section('title', 'Landlord Profile')

@section('content')
<div class="min-h-screen bg-gray-50">
    <!-- Green Header - Matching Landlord Theme -->
    <header class="bg-gradient-to-r from-green-600 to-green-400 shadow-lg">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-24">
                <!-- Logo and Title Section -->
                <div class="flex items-center space-x-4">
                    <div class="bg-white/10 backdrop-blur-sm rounded-xl p-3 border border-white/20">
                        <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="h-10 w-auto">
                    </div>
                    <div>
                        <h1 class="text-2xl font-bold text-white">Profile</h1>
                        <p class="text-green-100">Manage your personal information</p>
                    </div>
                </div>
                
                <!-- Notification Icon -->
                <div class="relative">
                    <button class="bg-white/10 backdrop-blur-sm rounded-xl p-3 border border-white/20 hover:bg-white/20 transition-colors duration-200">
                        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
                        </svg>
                        @if(isset($unreadNotifications) && $unreadNotifications > 0)
                            <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                                {{ $unreadNotifications > 9 ? '9+' : $unreadNotifications }}
                            </span>
                        @endif
                    </button>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        @if(isset($error))
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-6">
                {{ $error }}
            </div>
        @endif

        @if(isset($success))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded-lg mb-6">
                {{ $success }}
            </div>
        @endif

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Profile Overview Card -->
            <div class="lg:col-span-1">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <div class="text-center">
                        <!-- Profile Picture -->
                        <div class="relative inline-block">
                            <div class="w-24 h-24 bg-gradient-to-r from-green-500 to-green-400 rounded-full flex items-center justify-center text-white text-2xl font-bold">
                                {{ substr($profileData['first_name'] ?? 'L', 0, 1) }}{{ substr($profileData['last_name'] ?? 'Landlord', 0, 1) }}
                            </div>
                            <button class="absolute bottom-0 right-0 bg-green-600 text-white rounded-full p-2 hover:bg-green-700 transition-colors duration-200">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"></path>
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                </svg>
                            </button>
                        </div>
                        
                        <!-- User Info -->
                        <h2 class="mt-4 text-xl font-semibold text-gray-900">
                            {{ $profileData['first_name'] ?? 'First' }} {{ $profileData['last_name'] ?? 'Last' }}
                        </h2>
                        <p class="text-gray-500">{{ $profileData['email'] ?? 'email@example.com' }}</p>
                        <div class="mt-2 inline-flex px-3 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                            Property Manager
                        </div>
                        
                        <!-- Stats -->
                        <div class="mt-6 space-y-3">
                            <div class="flex items-center justify-between">
                                <span class="text-sm text-gray-500">Member Since</span>
                                <span class="text-sm font-medium text-gray-900">{{ $profileData['created_at'] ? \Carbon\Carbon::parse($profileData['created_at'])->format('M Y') : 'Unknown' }}</span>
                            </div>
                            <div class="flex items-center justify-between">
                                <span class="text-sm text-gray-500">Total Properties</span>
                                <span class="text-sm font-medium text-gray-900">{{ $totalHostels ?? 0 }}</span>
                            </div>
                            <div class="flex items-center justify-between">
                                <span class="text-sm text-gray-500">Account Status</span>
                                <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                                    Active
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Profile Form -->
            <div class="lg:col-span-2">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200">
                    <div class="p-6 border-b border-gray-200">
                        <h3 class="text-lg font-semibold text-gray-900">Personal Information</h3>
                        <p class="text-sm text-gray-500 mt-1">Update your personal details and contact information</p>
                    </div>
                    
                    <form action="{{ route('profile.update') }}" method="POST" class="p-6">
                        @csrf
                        @method('PUT')
                        
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-2">First Name</label>
                                <input type="text" name="first_name" value="{{ $profileData['first_name'] ?? '' }}" 
                                       class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                       placeholder="Enter your first name">
                            </div>
                            
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
                                <input type="text" name="last_name" value="{{ $profileData['last_name'] ?? '' }}" 
                                       class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                       placeholder="Enter your last name">
                            </div>
                            
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-2">Email Address</label>
                                <input type="email" name="email" value="{{ $profileData['email'] ?? '' }}" 
                                       class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                       placeholder="Enter your email">
                            </div>
                            
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-2">Phone Number</label>
                                <input type="tel" name="phone_number" value="{{ $profileData['phone_number'] ?? '' }}" 
                                       class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                       placeholder="Enter your phone number">
                            </div>
                            
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-2">Company Name</label>
                                <input type="text" name="company_name" value="{{ $profileData['company_name'] ?? '' }}" 
                                       class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                       placeholder="Enter your company name">
                            </div>
                            
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-2">Business License</label>
                                <input type="text" value="{{ $profileData['business_license'] ?? '' }}" 
                                       class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                       placeholder="Enter your business license number">
                            </div>
                        </div>
                        
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">Bio</label>
                            <textarea rows="4" name="bio"
                                      class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500"
                                      placeholder="Tell us about your property management experience">{{ $profileData['bio'] ?? '' }}</textarea>
                        </div>
                        
                        <div class="flex items-center justify-end space-x-4">
                            <button type="button" class="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium transition-colors duration-200">
                                Cancel
                            </button>
                            <button type="submit" class="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium transition-colors duration-200">
                                Save Changes
                            </button>
                        </div>
                    </form>
                </div>

                <!-- Security Settings -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 mt-8">
                    <div class="p-6">
                        <h3 class="text-lg font-semibold text-gray-900 mb-6">Security Settings</h3>
                        
                        <div class="space-y-4">
                            <div class="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
                                <div class="flex items-center space-x-3">
                                    <div class="bg-green-100 rounded-lg p-2">
                                        <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path>
                                        </svg>
                                    </div>
                                    <div>
                                        <h4 class="text-sm font-medium text-gray-900">Change Password</h4>
                                        <p class="text-sm text-gray-500">Update your password regularly</p>
                                    </div>
                                </div>
                                <button class="text-green-600 hover:text-green-700 text-sm font-medium">
                                    Change
                                </button>
                            </div>
                            
                            <div class="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
                                <div class="flex items-center space-x-3">
                                    <div class="bg-green-100 rounded-lg p-2">
                                        <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
                                        </svg>
                                    </div>
                                    <div>
                                        <h4 class="text-sm font-medium text-gray-900">Two-Factor Authentication</h4>
                                        <p class="text-sm text-gray-500">Add an extra layer of security</p>
                                    </div>
                                </div>
                                <button class="text-green-600 hover:text-green-700 text-sm font-medium">
                                    Enable
                                </button>
                            </div>
                            
                            <div class="flex items-center justify-between p-4 border border-red-200 bg-red-50 rounded-lg">
                                <div class="flex items-center space-x-3">
                                    <div class="bg-red-100 rounded-lg p-2">
                                        <svg class="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                                        </svg>
                                    </div>
                                    <div>
                                        <h4 class="text-sm font-medium text-gray-900">Data Deletion Request</h4>
                                        <p class="text-sm text-gray-500">Request permanent deletion of your account and data</p>
                                    </div>
                                </div>
                                <a href="{{ route('data.deletion') }}" class="text-red-600 hover:text-red-700 text-sm font-medium">
                                    Request Deletion
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>
@endsection
