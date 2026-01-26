@extends('layouts.app')

@section('title', 'Payment - PaLevel')

@section('content')
@php
    $amountToPay = (isset($displayAmount) && is_numeric($displayAmount))
        ? (float) $displayAmount
        : (float) ($booking['total_amount'] ?? 0);
@endphp
<div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <div class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <div class="flex items-center">
                    <a href="{{ route('student.bookings') }}" class="text-gray-600 hover:text-gray-900 transition-colors">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                        </svg>
                    </a>
                    <div class="ml-4">
                        <h1 class="text-xl font-semibold text-gray-900">Secure Payment</h1>
                        <p class="text-sm text-gray-600">Booking ID: #{{ $booking['booking_id'] }}</p>
                    </div>
                </div>
                <div class="flex items-center space-x-4">
                    <div class="text-right">
                        <p class="text-sm text-gray-600">Amount to Pay</p>
                        <p class="text-2xl font-bold text-teal-600">MWK {{ number_format($amountToPay) }}</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Payment Webview -->
            <div class="lg:col-span-2">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                    <div class="bg-gray-50 px-6 py-4 border-b border-gray-200">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center">
                                <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center mr-3">
                                    <svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                    </svg>
                                </div>
                                <div>
                                    <h2 class="text-lg font-semibold text-gray-900">PayChangu Payment Gateway</h2>
                                    <p class="text-sm text-gray-600">Complete your payment securely</p>
                                </div>
                            </div>
                            <button onclick="refreshPayment()" class="text-gray-400 hover:text-gray-600 transition-colors p-2">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                                </svg>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Payment Iframe -->
                    <div class="p-6 bg-gray-100">
                        <div class="w-full h-[600px] bg-white rounded-lg shadow-inner overflow-hidden">
                            <iframe 
                                id="paymentFrame"
                                src="{{ $paymentUrl }}" 
                                class="w-full h-full border-0"
                                sandbox="allow-same-origin allow-scripts allow-popups allow-forms"
                                onload="onPaymentLoad()"
                                onerror="onPaymentError()">
                            </iframe>
                        </div>
                    </div>
                    
                    <!-- Footer -->
                    <div class="bg-gray-50 px-6 py-4 border-t border-gray-200">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center text-sm text-gray-600">
                                <svg class="w-4 h-4 mr-2 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2h5.586l-1.293 1.293a1 1 0 00-1.414 1.414l3-3a1 1 0 001.414 0l3 3a1 1 0 00-1.414-1.414L11 11.586V14a1 1 0 11-2 0V9a1 1 0 112 0z" clip-rule="evenodd"></path>
                                </svg>
                                Secure payment powered by PayChangu
                            </div>
                            <div class="flex space-x-3">
                                <!-- Status button removed as per requirement -->
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Booking Details Sidebar -->
            <div class="lg:col-span-1">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Booking Details</h3>
                    
                    <div class="space-y-4">
                        <!-- Hostel Info -->
                        <div>
                            <p class="text-sm text-gray-600 mb-1">Hostel</p>
                            <p class="font-medium text-gray-900">{{ $booking['room']['hostel']['name'] ?? 'N/A' }}</p>
                        </div>
                        
                        <!-- Room Info -->
                        <div>
                            <p class="text-sm text-gray-600 mb-1">Room</p>
                            <p class="font-medium text-gray-900">{{ $booking['room']['room_number'] ?? 'N/A' }} ({{ $booking['room']['room_type'] ?? 'N/A' }})</p>
                        </div>
                        
                        <!-- Duration -->
                        <div>
                            <p class="text-sm text-gray-600 mb-1">Duration</p>
                            <p class="font-medium text-gray-900">{{ $booking['duration_months'] ?? 0 }} {{ $booking['duration_months'] > 1 ? 'months' : 'month' }}</p>
                        </div>
                        
                        <!-- Check-in Date -->
                        <div>
                            <p class="text-sm text-gray-600 mb-1">Check-in Date</p>
                            <p class="font-medium text-gray-900">{{ \Carbon\Carbon::parse($booking['check_in_date'])->format('d M Y') }}</p>
                        </div>
                        
                        <!-- Payment Type -->
                        <div>
                            <p class="text-sm text-gray-600 mb-1">Payment Type</p>
                            <p class="font-medium text-gray-900">{{ $booking['payment_type'] === 'full' ? 'Full Payment' : 'Booking Fee Only' }}</p>
                        </div>
                        
                        <!-- Amount Breakdown -->
                        <div class="border-t border-gray-200 pt-4">
                            <h4 class="text-sm font-semibold text-gray-900 mb-3">Payment Breakdown</h4>
                            <div class="space-y-2">
                                <div class="flex justify-between text-sm">
                                    <span class="text-gray-600">{{ $booking['payment_type'] === 'full' ? 'Room Rent' : 'Booking Fee' }}</span>
                                    <span class="font-medium">MWK {{ number_format(($booking['total_amount'] ?? 0) - 2500) }}</span>
                                </div>
                                <div class="flex justify-between text-sm">
                                    <span class="text-gray-600">Platform Fee</span>
                                    <span class="font-medium">MWK 2,500</span>
                                </div>
                                <div class="flex justify-between text-base font-semibold text-teal-600 pt-2 border-t border-gray-200">
                                    <span>Total Amount</span>
                                    <span>MWK {{ number_format($booking['total_amount'] ?? 0) }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Help Section -->
                <div class="bg-blue-50 rounded-xl border border-blue-200 p-6 mt-6">
                    <h3 class="text-lg font-semibold text-blue-900 mb-3">Need Help?</h3>
                    <div class="space-y-3">
                        <div class="flex items-start">
                            <svg class="w-5 h-5 text-blue-600 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                            </svg>
                            <div>
                                <p class="text-sm font-medium text-blue-900">Payment Issues?</p>
                                <p class="text-sm text-blue-700">If payment fails, try refreshing the page or contact support.</p>
                            </div>
                        </div>
                        <div class="flex items-start">
                            <svg class="w-5 h-5 text-blue-600 mr-2 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                            </svg>
                            <div>
                                <p class="text-sm font-medium text-blue-900">Contact Support</p>
                                <p class="text-sm text-blue-700">support@palevel.mw or +265 999 123 456</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Enhanced Loading Overlay -->
    <div id="loadingOverlay" class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden">
        <div class="bg-white rounded-xl p-8 max-w-md mx-4 text-center shadow-2xl">
            <div class="mb-6">
                <div id="loadingSpinner" class="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600 mx-auto mb-4"></div>
                <div id="successIcon" class="hidden">
                    <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                    </div>
                </div>
                <div id="errorIcon" class="hidden">
                    <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </div>
                </div>
            </div>
            <h3 class="text-lg font-semibold text-gray-900 mb-2" id="loadingTitle">Processing Payment</h3>
            <p class="text-gray-600 text-sm" id="loadingMessage">Please wait while we verify your payment...</p>
            <div class="mt-4">
                <div class="w-full bg-gray-200 rounded-full h-2">
                    <div id="progressBar" class="bg-teal-600 h-2 rounded-full transition-all duration-300" style="width: 0%"></div>
                </div>
            </div>
        </div>
    </div>

    <!-- Success Notification -->
    <div id="successNotification" class="fixed top-4 right-4 bg-green-50 border border-green-200 text-green-800 px-6 py-4 rounded-lg shadow-lg z-50 hidden transform transition-all duration-300">
        <div class="flex items-center">
            <svg class="w-6 h-6 mr-3 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <div>
                <h4 class="font-bold">Payment Successful!</h4>
                <p class="text-sm">Redirecting to your bookings...</p>
            </div>
        </div>
    </div>
</div>

<script>
let paymentStatusTimeout = null;
let verificationAttempts = 0;
const maxVerificationAttempts = 20; // Maximum attempts before timeout
let nextVerificationDelayMs = 2000;
const maxVerificationDelayMs = 30000;
const pageLoadedAt = Date.now();
let isVerificationInFlight = false;
const paymentFlow = '{{ $paymentFlow ?? 'standard' }}';
const bookingId = '{{ $booking['booking_id'] }}';
const urlParams = new URLSearchParams(window.location.search);
const paymentId = urlParams.get('paymentId') || (function() {
    try {
        const pending = JSON.parse(sessionStorage.getItem('pendingBooking'));
        return (pending && pending.bookingId == bookingId) ? pending.paymentId : null;
    } catch(e) { return null; }
})();
// Standard payments can verify by reference (tx_ref) or legacy bookingId.
// Extension/Complete payments must verify by tx_ref.
const verificationReference = paymentFlow === 'standard' ? (paymentId || bookingId) : paymentId;

let isPaymentCompleted = false;
let isPaymentVerified = false;

// Only setup iframe monitoring when page loads
document.addEventListener('DOMContentLoaded', function() {
    if (!verificationReference) {
        showError('Payment reference not found. Please initiate payment again.');
        return;
    }
    setupIframeMonitoring();
    // Start verification polling in the background so we don't depend on iframe events
    // (PayChangu may not postMessage and iframe URL may remain cross-origin).
    startBackgroundVerification();
});

function startBackgroundVerification() {
    // Give the user time to complete payment before we begin polling
    setTimeout(() => {
        if (!isPaymentVerified) {
            verifyPaymentStatus();
        }
    }, 45000);
}

function setupIframeMonitoring() {
    const iframe = document.getElementById('paymentFrame');
    let iframeLoadCount = 0;
    
    // Monitor iframe messages for payment completion
    window.addEventListener('message', function(event) {
        // Check if message is from PayChangu domain
        if (event.origin.includes('paychangu.com')) {
            console.log('Received message from PayChangu:', event.data);
            
            // If payment is completed, start verification
            if (event.data.status === 'completed' || event.data.status === 'success') {
                handlePaymentCompletion();
            }
        }
    });
    
    // Monitor iframe URL changes
    iframe.addEventListener('load', function() {
        iframeLoadCount++;
        try {
            const iframeUrl = iframe.contentWindow.location.href;
            console.log('Iframe URL:', iframeUrl);
            
            // If we can access the URL and it's on our origin, it means payment is done/returned
            // We assume any return to our domain indicates the payment flow has finished (success or cancel)
            // The verification step will determine the actual status
            if (iframeUrl && iframeUrl.startsWith(window.location.origin)) {
                console.log('Returned to origin, payment likely complete');
                handlePaymentCompletion();
            }
        } catch (e) {
            // Cross-origin error, ignore - likely still on payment gateway
            console.log('Cannot access iframe URL (cross-origin)');

            // If the iframe has navigated again after some time, it's likely the gateway
            // completed and moved to a success/redirect page. Trigger verification.
            if (!isPaymentCompleted && !isPaymentVerified) {
                const elapsed = Date.now() - pageLoadedAt;
                if (iframeLoadCount >= 2 && elapsed >= 20000) {
                    handlePaymentCompletion();
                }
            }
        }
    });
}

function handlePaymentCompletion() {
    if (isPaymentCompleted) return;
    
    console.log('Payment completion detected, starting verification...');
    isPaymentCompleted = true;
    
    // Hide the iframe and show verification state
    const iframe = document.getElementById('paymentFrame');
    iframe.style.display = 'none';
    
    // Show enhanced loading with verification states
    showVerificationLoading();
    
    // Start verification immediately
    verifyPaymentStatus();
}

function showVerificationLoading() {
    const overlay = document.getElementById('loadingOverlay');
    const title = document.getElementById('loadingTitle');
    const message = document.getElementById('loadingMessage');
    const spinner = document.getElementById('loadingSpinner');
    const progressBar = document.getElementById('progressBar');
    
    overlay.classList.remove('hidden');
    title.textContent = 'Verifying Payment';
    message.textContent = 'Payment completed! Verifying with our system...';
    spinner.classList.remove('hidden');
    
    // Start progress animation
    let progress = 0;
    const progressInterval = setInterval(() => {
        progress += 5;
        progressBar.style.width = Math.min(progress, 90) + '%';
        
        if (progress >= 90 || isPaymentVerified) {
            clearInterval(progressInterval);
        }
    }, 200);
}

function onPaymentLoad() {
    console.log('Payment iframe loaded successfully');
    hideLoading();
}

function onPaymentError() {
    console.error('Payment iframe failed to load');
    hideLoading();
    showError('Payment gateway failed to load. Please try again.');
}

function refreshPayment() {
    showLoading('Refreshing payment gateway...');
    const iframe = document.getElementById('paymentFrame');
    if (iframe) {
        iframe.src = iframe.src;
    }
}

async function verifyPaymentStatus() {
    if (isPaymentVerified) return;
    if (isVerificationInFlight) return;
    isVerificationInFlight = true;
    
    verificationAttempts++;
    updateVerificationProgress();
    
    try {
        let response;
        if (paymentFlow === 'standard') {
            response = await fetch(`/api/payments/verify?reference=${encodeURIComponent(verificationReference)}`, {
                headers: {
                    'Accept': 'application/json'
                }
            });
        } else {
            const url = paymentFlow === 'extension'
                ? '/api/payments/verify-extension'
                : '/api/payments/verify-complete';

            response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
                },
                body: JSON.stringify({ payment_id: verificationReference })
            });
        }
        
        const result = await response.json();
        console.log('Payment verification result:', result);

        const isVerified = paymentFlow === 'standard'
            ? (result.success || (result.status === 'success' && result.data?.status === 'completed') || result.status === 'completed')
            : !!result.success;

        if (isVerified) {
            // Payment successful
            handlePaymentSuccess();
        } else {
            // If not successful yet, schedule next check if within limits
            if (verificationAttempts < maxVerificationAttempts) {
                nextVerificationDelayMs = Math.min(Math.floor(nextVerificationDelayMs * 1.5), maxVerificationDelayMs);
                paymentStatusTimeout = setTimeout(verifyPaymentStatus, nextVerificationDelayMs);
            } else {
                handleVerificationTimeout();
            }
        }
    } catch (error) {
        console.log('Payment status check failed:', error);
        
        // Retry on error if within limits
        if (verificationAttempts < maxVerificationAttempts) {
            nextVerificationDelayMs = Math.min(Math.floor(nextVerificationDelayMs * 2), maxVerificationDelayMs);
            paymentStatusTimeout = setTimeout(verifyPaymentStatus, nextVerificationDelayMs);
        } else {
            handleVerificationTimeout();
        }
    } finally {
        isVerificationInFlight = false;
    }
}

function updateVerificationProgress() {
    const message = document.getElementById('loadingMessage');
    const progressBar = document.getElementById('progressBar');
    
    const progress = Math.min((verificationAttempts / maxVerificationAttempts) * 100, 90);
    progressBar.style.width = progress + '%';
    
    // Update message based on attempt count
    if (verificationAttempts <= 3) {
        message.textContent = 'Contacting payment provider...';
    } else if (verificationAttempts <= 6) {
        message.textContent = 'Confirming payment details...';
    } else if (verificationAttempts <= 10) {
        message.textContent = 'Updating your booking status...';
    } else {
        message.textContent = 'Finalizing verification...';
    }
}

function handlePaymentSuccess() {
    isPaymentVerified = true;
    nextVerificationDelayMs = 2000;
    if (paymentStatusTimeout) {
        clearTimeout(paymentStatusTimeout);
        paymentStatusTimeout = null;
    }
    
    // Update UI to show success
    const title = document.getElementById('loadingTitle');
    const message = document.getElementById('loadingMessage');
    const spinner = document.getElementById('loadingSpinner');
    const successIcon = document.getElementById('successIcon');
    const progressBar = document.getElementById('progressBar');
    
    title.textContent = 'Payment Verified!';
    message.textContent = 'Your payment has been successfully processed.';
    spinner.classList.add('hidden');
    successIcon.classList.remove('hidden');
    progressBar.style.width = '100%';
    
    // Show success notification
    setTimeout(() => {
        showSuccessNotification();
        
        // Redirect to bookings after 3 seconds
        setTimeout(() => {
            window.location.href = '{{ route("student.bookings") }}';
        }, 3000);
    }, 1500);
}

function handleVerificationTimeout() {
    if (paymentStatusTimeout) {
        clearTimeout(paymentStatusTimeout);
        paymentStatusTimeout = null;
    }

    // If we're polling in the background while the user is still in the payment flow,
    // don't interrupt them with timeout UI. Keep retrying quietly.
    if (!isPaymentCompleted) {
        verificationAttempts = 0;
        paymentStatusTimeout = setTimeout(verifyPaymentStatus, 5000);
        return;
    }
    
    // Update UI to show error
    const title = document.getElementById('loadingTitle');
    const message = document.getElementById('loadingMessage');
    const spinner = document.getElementById('loadingSpinner');
    const errorIcon = document.getElementById('errorIcon');
    
    title.textContent = 'Verification Timeout';
    message.textContent = 'Payment verification is taking longer than expected. Please check manually.';
    spinner.classList.add('hidden');
    errorIcon.classList.remove('hidden');
    
    // Show manual check option
    setTimeout(() => {
        hideLoading();
        PalevelDialog.confirm('Payment verification is taking longer than expected. Would you like to check manually or try again?', 'Confirm')
            .then((ok) => {
                if (!ok) return;
                // Reset attempts and try again
                verificationAttempts = 0;
                showLoading('Checking payment status...');
                verifyPaymentStatus();
            });
    }, 2000);
}

function showLoading(message = 'Processing...') {
    const overlay = document.getElementById('loadingOverlay');
    const title = document.getElementById('loadingTitle');
    const messageEl = document.getElementById('loadingMessage');
    const spinner = document.getElementById('loadingSpinner');
    const successIcon = document.getElementById('successIcon');
    const errorIcon = document.getElementById('errorIcon');
    
    title.textContent = 'Processing';
    messageEl.textContent = message;
    spinner.classList.remove('hidden');
    successIcon.classList.add('hidden');
    errorIcon.classList.add('hidden');
    overlay.classList.remove('hidden');
}

function hideLoading() {
    document.getElementById('loadingOverlay').classList.add('hidden');
}

function showSuccessNotification() {
    const notification = document.getElementById('successNotification');
    notification.classList.remove('hidden');
    notification.classList.add('animate-pulse');
    
    setTimeout(() => {
        notification.classList.remove('animate-pulse');
    }, 1000);
}

function showError(message) {
    PalevelDialog.error(message);
}

// Clean up timeout when page unloads
window.addEventListener('beforeunload', function() {
    if (paymentStatusTimeout) {
        clearTimeout(paymentStatusTimeout);
    }
});
</script>
@endsection
