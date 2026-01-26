@extends('layouts.app')

@section('title', 'Data Deletion Request')

@php
    $currentUser = Session::get('palevel_user');
@endphp

@section('content')
<div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="text-center mb-12">
            <h1 class="text-4xl font-bold text-gray-900 mb-4">
                Data Deletion Request
            </h1>
            <p class="text-lg text-gray-600 max-w-2xl mx-auto">
                We respect your privacy and provide you with control over your personal data. 
                Use this form to request the deletion of your data from our systems.
            </p>
        </div>

        <!-- Alert Messages -->
        @if(session('success'))
            <div class="mb-8 bg-green-50 border border-green-200 rounded-lg p-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-green-800">{{ session('success') }}</p>
                    </div>
                </div>
            </div>
        @endif

        @if(session('error'))
            <div class="mb-8 bg-red-50 border border-red-200 rounded-lg p-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-red-800">{{ session('error') }}</p>
                    </div>
                </div>
            </div>
        @endif

        <!-- Data Information Section -->
        <div class="bg-white shadow-lg rounded-lg p-8 mb-8">
            <h2 class="text-2xl font-semibold text-gray-900 mb-6">
                What Data Will Be Deleted?
            </h2>
            
            <div class="space-y-6">
                <!-- Personal Information -->
                <div class="border-l-4 border-blue-500 pl-4">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                        <i class="fas fa-user text-blue-500 mr-2"></i>
                        Personal Information
                    </h3>
                    <ul class="text-gray-600 space-y-1">
                        <li>• Full name and contact details</li>
                        <li>• Email address and phone number</li>
                        <li>• Profile information and bio</li>
                        <li>• Profile picture and uploaded documents</li>
                    </ul>
                </div>

                <!-- Account Data -->
                <div class="border-l-4 border-green-500 pl-4">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                        <i class="fas fa-cog text-green-500 mr-2"></i>
                        Account Data
                    </h3>
                    <ul class="text-gray-600 space-y-1">
                        <li>• Account credentials and authentication data</li>
                        <li>• Account preferences and settings</li>
                        <li>• Login history and session data</li>
                        <li>• Account status and verification records</li>
                    </ul>
                </div>

                <!-- Activity Data -->
                <div class="border-l-4 border-purple-500 pl-4">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                        <i class="fas fa-history text-purple-500 mr-2"></i>
                        Activity Data
                    </h3>
                    <ul class="text-gray-600 space-y-1">
                        <li>• Booking history and records</li>
                        <li>• Search history and preferences</li>
                        <li>• Reviews and ratings submitted</li>
                        <li>• Messages and communications</li>
                    </ul>
                </div>

                <!-- Financial Data -->
                <div class="border-l-4 border-yellow-500 pl-4">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                        <i class="fas fa-credit-card text-yellow-500 mr-2"></i>
                        Financial Data
                    </h3>
                    <ul class="text-gray-600 space-y-1">
                        <li>• Payment information (stored securely)</li>
                        <li>• Transaction history</li>
                        <li>• Billing addresses and invoices</li>
                        <li>• Refund records and disputes</li>
                    </ul>
                </div>
            </div>

            <!-- Important Notice -->
            <div class="mt-8 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                        </svg>
                    </div>
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-yellow-800">Important Notice</h3>
                        <div class="mt-2 text-sm text-yellow-700">
                            <p>Once your data is deleted, this action cannot be undone. You will lose access to your account and all associated data. Some data may be retained for legal or regulatory requirements.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Deletion Request Form -->
        <div class="bg-white shadow-lg rounded-lg p-8">
            <h2 class="text-2xl font-semibold text-gray-900 mb-6">
                Submit Deletion Request
            </h2>

            <form action="{{ route('data.deletion.submit') }}" method="POST" class="space-y-6">
                @csrf

                <!-- Personal Information -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label for="name" class="block text-sm font-medium text-gray-700 mb-2">
                            Full Name <span class="text-red-500">*</span>
                        </label>
                        <input type="text" id="name" name="name" required
                               class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                               value="{{ old('name', $currentUser['first_name'] . ' ' . $currentUser['last_name']) }}" placeholder="Enter your full name">
                        @error('name')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>

                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700 mb-2">
                            Email Address <span class="text-red-500">*</span>
                        </label>
                        <input type="email" id="email" name="email" required readonly
                               class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-gray-50"
                               value="{{ old('email', $currentUser['email']) }}" placeholder="your.email@example.com">
                        <p class="mt-1 text-xs text-gray-500">Email is locked to your account for security</p>
                        @error('email')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>

                <div>
                    <label for="phone" class="block text-sm font-medium text-gray-700 mb-2">
                        Phone Number <span class="text-red-500">*</span>
                    </label>
                    <input type="tel" id="phone" name="phone" required
                           class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                           value="{{ old('phone', $currentUser['phone'] ?? '') }}" placeholder="+265 999 123 456">
                    @error('phone')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Data Categories -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-3">
                        Select Data Categories to Delete <span class="text-red-500">*</span>
                    </label>
                    <div class="space-y-3">
                        <div class="flex items-center">
                            <input type="checkbox" id="personal" name="data_categories[]" value="personal"
                                   class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                            <label for="personal" class="ml-3 text-sm text-gray-700">
                                Personal Information (name, email, phone, profile)
                            </label>
                        </div>
                        <div class="flex items-center">
                            <input type="checkbox" id="account" name="data_categories[]" value="account"
                                   class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                            <label for="account" class="ml-3 text-sm text-gray-700">
                                Account Data (credentials, settings, preferences)
                            </label>
                        </div>
                        <div class="flex items-center">
                            <input type="checkbox" id="activity" name="data_categories[]" value="activity"
                                   class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                            <label for="activity" class="ml-3 text-sm text-gray-700">
                                Activity Data (bookings, searches, reviews, messages)
                            </label>
                        </div>
                        <div class="flex items-center">
                            <input type="checkbox" id="financial" name="data_categories[]" value="financial"
                                   class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                            <label for="financial" class="ml-3 text-sm text-gray-700">
                                Financial Data (payment information, transaction history)
                            </label>
                        </div>
                    </div>
                    @error('data_categories')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Reason for Deletion -->
                <div>
                    <label for="reason" class="block text-sm font-medium text-gray-700 mb-2">
                        Reason for Deletion Request <span class="text-red-500">*</span>
                    </label>
                    <textarea id="reason" name="reason" rows="4" required
                              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                              placeholder="Please explain why you want your data deleted...">{{ old('reason') }}</textarea>
                    @error('reason')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Confirmation -->
                <div class="bg-red-50 border border-red-200 rounded-lg p-4">
                    <div class="flex items-start">
                        <div class="flex-shrink-0 mt-1">
                            <input type="checkbox" id="confirmation" name="confirmation" value="1"
                                   class="h-4 w-4 text-red-600 border-gray-300 rounded focus:ring-red-500">
                        </div>
                        <div class="ml-3">
                            <label for="confirmation" class="text-sm text-red-800">
                                I understand that once my data is deleted, this action cannot be undone. 
                                I will lose access to my account and all associated data, and this process may take up to 30 days to complete.
                            </label>
                            @error('confirmation')
                                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                        </div>
                    </div>
                </div>

                <!-- Submit Button -->
                <div class="flex justify-end space-x-4">
                    <a href="{{ url('/') }}" class="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors">
                        Cancel
                    </a>
                    <button type="submit" id="submitBtn"
                            class="px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium flex items-center">
                        <span id="submitText">Submit Deletion Request</span>
                        <svg id="loadingSpinner" class="hidden animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                    </button>
                </div>
            </form>
        </div>

        <!-- Additional Information -->
        <div class="mt-8 text-center text-sm text-gray-500">
            <p>For questions about data deletion, please contact our support team at support@palevel.com</p>
            <p class="mt-2">We will process your request within 30 days as required by data protection regulations.</p>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.querySelector('form');
    const submitBtn = document.getElementById('submitBtn');
    const submitText = document.getElementById('submitText');
    const loadingSpinner = document.getElementById('loadingSpinner');

    // Show any existing messages using existing PalevelDialog
    @if(session('success'))
        window.PalevelDialog.info('{{ session('success') }}', 'Success');
    @endif

    @if(session('error'))
        window.PalevelDialog.error('{{ session('error') }}', 'Error');
    @endif

    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Show loading state
        submitBtn.disabled = true;
        submitText.textContent = 'Submitting...';
        loadingSpinner.classList.remove('hidden');
        
        // Get form data
        const formData = new FormData(form);
        
        // Submit via fetch API
        fetch(form.action, {
            method: 'POST',
            body: formData,
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'Accept': 'text/html'
            }
        })
        .then(response => {
            if (response.redirected) {
                // If the response is a redirect, follow it
                window.location.href = response.url;
            } else {
                return response.text();
            }
        })
        .then(html => {
            if (html) {
                // If we got HTML content, it means there was an error
                // Parse the HTML to extract error messages
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                
                // Look for error messages
                const errorElements = doc.querySelectorAll('.bg-red-100');
                if (errorElements.length > 0) {
                    const errorMessage = errorElements[0].textContent.trim();
                    window.PalevelDialog.error(errorMessage, 'Error');
                } else {
                    window.PalevelDialog.error('There was an error submitting your request. Please try again.', 'Error');
                }
                
                // Reset loading state
                submitBtn.disabled = false;
                submitText.textContent = 'Submit Deletion Request';
                loadingSpinner.classList.add('hidden');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            // Show error message using existing dialog
            window.PalevelDialog.error('There was an error submitting your request. Please try again.', 'Error');
            
            // Reset loading state
            submitBtn.disabled = false;
            submitText.textContent = 'Submit Deletion Request';
            loadingSpinner.classList.add('hidden');
        });
    });

    // Handle confirmation checkbox
    const confirmationCheckbox = document.getElementById('confirmation');
    const dataCategoryCheckboxes = document.querySelectorAll('input[name="data_categories[]"]');
    
    function validateForm() {
        const hasDataCategories = Array.from(dataCategoryCheckboxes).some(cb => cb.checked);
        const hasConfirmation = confirmationCheckbox.checked;
        
        submitBtn.disabled = !(hasDataCategories && hasConfirmation);
    }
    
    confirmationCheckbox.addEventListener('change', validateForm);
    dataCategoryCheckboxes.forEach(checkbox => {
        checkbox.addEventListener('change', validateForm);
    });
    
    // Initial validation
    validateForm();
});
</script>
@endsection
