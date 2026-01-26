@extends('layouts.app')

@section('title', 'My Bookings')

@section('content')
<div class="min-h-screen bg-gray-50">
    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        @if(isset($error))
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-6">
                {{ $error }}
            </div>
        @endif

        <!-- Booking Stats -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-teal-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">Total Bookings</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ count($bookings ?? []) }}</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-green-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">Confirmed</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ $confirmedBookings ?? 0 }}</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-yellow-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">Pending</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ $pendingBookings ?? 0 }}</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-red-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">Cancelled</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ $cancelledBookings ?? 0 }}</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bookings List -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200">
            <div class="p-6">
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-xl font-semibold text-gray-900">Your Bookings</h2>
                    <div class="flex items-center space-x-2">
                        <select class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500">
                            <option value="all">All Status</option>
                            <option value="confirmed">Confirmed</option>
                            <option value="pending">Pending</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                    </div>
                </div>
                
                @if(isset($bookings) && count($bookings) > 0)
                    <div class="space-y-4">
                        @foreach($bookings as $booking)
                            <div class="border border-gray-200 rounded-xl p-6 hover:shadow-md transition-shadow duration-200">
                                <div class="flex items-start justify-between">
                                    <div class="flex-1">
                                        <div class="flex items-center space-x-3 mb-3">
                                            <h3 class="text-lg font-semibold text-gray-900">{{ $booking['hostel_name'] ?? 'Hostel Name' }}</h3>
                                            <span class="px-3 py-1 text-xs font-semibold rounded-full 
                                                @if($booking['status'] === 'confirmed') bg-green-100 text-green-800
                                                @elseif($booking['status'] === 'pending') bg-yellow-100 text-yellow-800
                                                @else bg-red-100 text-red-800
                                                @endif">
                                                {{ ucfirst($booking['status'] ?? 'Unknown') }}
                                            </span>
                                        </div>
                                        
                                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                                            <div class="flex items-center text-sm text-gray-600">
                                                <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                                                </svg>
                                                Room: {{ $booking['room_number'] ?? 'Not specified' }}
                                            </div>
                                            <div class="flex items-center text-sm text-gray-600">
                                                <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                                                </svg>
                                                {{ \Carbon\Carbon::parse($booking['start_date'] ?? $booking['check_in_date'] ?? $booking['checkInDate'] ?? 'now')->format('M d, Y') }} - {{ \Carbon\Carbon::parse($booking['end_date'] ?? $booking['check_out_date'] ?? $booking['checkOutDate'] ?? 'now')->format('M d, Y') }}
                                            </div>
                                            <div class="flex items-center text-sm text-gray-600">
                                                <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                                </svg>
                                                MWK {{ number_format($booking['total_amount'], 2) }}
                                            </div>
                                        </div>
                                        
                                        <div class="flex items-center text-sm text-gray-500">
                                            <svg class="w-4 h-4 mr-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                                            </svg>
                                            Booked {{ \Carbon\Carbon::parse($booking['created_at'])->diffForHumans() }}
                                        </div>
                                    </div>
                                    
                                    <div class="flex flex-col space-y-2 ml-4">
                                        <a href="{{ route('student.bookings.show', ['bookingId' => $booking['booking_id'] ?? '']) }}" onclick="return handleViewDetailsClick(event, this)" class="px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 text-sm font-medium transition-colors duration-200 inline-flex items-center justify-center">
                                            <span class="view-details-label">View Details</span>
                                            <span class="view-details-spinner hidden ml-2">
                                                <svg class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path>
                                                </svg>
                                            </span>
                                        </a>
                                        @if(($booking['payment_type'] ?? '') === 'booking_fee')
                                            <button onclick="openCompletePaymentModal('{{ $booking['booking_id'] ?? '' }}')" class="px-4 py-2 border border-teal-300 text-teal-700 rounded-lg hover:bg-teal-50 text-sm font-medium transition-colors duration-200">
                                                Complete Payment
                                            </button>
                                        @elseif(($booking['payment_type'] ?? '') === 'full')
                                            <button onclick="openExtendBookingModal('{{ $booking['booking_id'] ?? '' }}')" class="px-4 py-2 border border-blue-300 text-blue-700 rounded-lg hover:bg-blue-50 text-sm font-medium transition-colors duration-200">
                                                Extend Booking
                                            </button>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                @else
                    <div class="text-center py-12">
                        <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                        </svg>
                        <p class="text-gray-500 text-lg">No bookings found</p>
                        <p class="text-gray-400 text-sm mt-2">Start by booking a hostel from the home page</p>
                        <a href="{{ route('student.home') }}" class="inline-flex items-center px-4 py-2 mt-4 bg-teal-600 text-white rounded-lg hover:bg-teal-700 text-sm font-medium transition-colors duration-200">
                            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
                            </svg>
                            Browse Hostels
                        </a>
                    </div>
                @endif
            </div>
        </div>
    </main>
</div>

<div id="extendBookingModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 hidden">
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-md mx-4">
        <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">Extend Booking</h3>
            <button type="button" onclick="closeExtendBookingModal()" class="text-gray-400 hover:text-gray-600">&times;</button>
        </div>
        <div class="p-6 space-y-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Additional months</label>
                <select id="extendMonths" class="w-full rounded-lg border-gray-300 focus:border-teal-500 focus:ring-teal-500" onchange="refreshExtensionPricing()">
                    <option value="1">1 month</option>
                    <option value="2">2 months</option>
                </select>
            </div>
            <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <p class="text-sm text-gray-600">Total extension amount</p>
                <p id="extendTotal" class="text-xl font-bold text-gray-900">MWK -</p>
                <p id="extendMeta" class="text-xs text-gray-500 mt-1"></p>
            </div>
            <div class="flex space-x-3">
                <button type="button" onclick="closeExtendBookingModal()" class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
                    Cancel
                </button>
                <button id="extendProceedBtn" type="button" onclick="confirmExtendBooking()" class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center justify-center" aria-busy="false">
                    <span class="extend-proceed-label">Proceed to Payment</span>
                    <span class="extend-proceed-spinner hidden ml-2 inline-flex items-center">
                        <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path>
                        </svg>
                    </span>
                </button>
            </div>
        </div>
    </div>
</div>

<div id="completePaymentModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 hidden">
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-md mx-4">
        <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">Complete Payment</h3>
            <button type="button" onclick="closeCompletePaymentModal()" class="text-gray-400 hover:text-gray-600">&times;</button>
        </div>
        <div class="p-6 space-y-4">
            <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <p class="text-sm text-gray-600">Remaining amount</p>
                <p id="completeRemaining" class="text-xl font-bold text-gray-900">MWK -</p>
                <p id="completeMeta" class="text-xs text-gray-500 mt-1"></p>
            </div>
            <div class="flex space-x-3">
                <button type="button" onclick="closeCompletePaymentModal()" class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
                    Cancel
                </button>
                <button id="completeProceedBtn" type="button" onclick="confirmCompletePayment()" class="flex-1 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 flex items-center justify-center" aria-busy="false">
                    <span class="complete-proceed-label">Proceed to Payment</span>
                    <span class="complete-proceed-spinner hidden ml-2 inline-flex items-center">
                        <svg class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path>
                        </svg>
                    </span>
                </button>
            </div>
        </div>
    </div>
</div>

<script>
let activeBookingId = null;
let cachedUserDetails = null;
let cachedCompletePricing = null;
let isExtendProceedInFlight = false;
let isCompleteProceedInFlight = false;

function setProceedButtonLoading(flow, isLoading) {
    const id = flow === 'extend' ? 'extendProceedBtn' : 'completeProceedBtn';
    const btn = document.getElementById(id);
    if (!btn) return;

    const label = btn.querySelector(flow === 'extend' ? '.extend-proceed-label' : '.complete-proceed-label');
    const spinner = btn.querySelector(flow === 'extend' ? '.extend-proceed-spinner' : '.complete-proceed-spinner');

    if (isLoading) {
        btn.disabled = true;
        btn.setAttribute('aria-busy', 'true');
        btn.classList.add('opacity-75', 'pointer-events-none');
        if (label) label.textContent = 'Loading...';
        if (spinner) spinner.classList.remove('hidden');
    } else {
        btn.disabled = false;
        btn.setAttribute('aria-busy', 'false');
        btn.classList.remove('opacity-75', 'pointer-events-none');
        if (label) label.textContent = 'Proceed to Payment';
        if (spinner) spinner.classList.add('hidden');
    }
}

function handleViewDetailsClick(event, el) {
    try {
        const label = el.querySelector('.view-details-label');
        const spinner = el.querySelector('.view-details-spinner');

        if (el.dataset.loading === '1') {
            event.preventDefault();
            return false;
        }

        el.dataset.loading = '1';
        el.classList.add('opacity-75', 'pointer-events-none');
        if (label) label.textContent = 'Loading...';
        if (spinner) spinner.classList.remove('hidden');

        // allow navigation
        return true;
    } catch (e) {
        return true;
    }
}

async function getUserDetails() {
    if (cachedUserDetails) return cachedUserDetails;
    const res = await fetch('/api/user/details', { headers: { 'Accept': 'application/json' } });
    const json = await res.json();
    if (!json.success) throw new Error(json.message || 'Failed to load user details');
    cachedUserDetails = json.data;
    return cachedUserDetails;
}

function csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
}

function openExtendBookingModal(bookingId) {
    activeBookingId = bookingId;
    document.getElementById('extendBookingModal').classList.remove('hidden');
    refreshExtensionPricing();
}

function closeExtendBookingModal() {
    document.getElementById('extendBookingModal').classList.add('hidden');
    activeBookingId = null;
}

async function refreshExtensionPricing() {
    if (!activeBookingId) return;
    const months = parseInt(document.getElementById('extendMonths').value || '1', 10);
    const totalEl = document.getElementById('extendTotal');
    const metaEl = document.getElementById('extendMeta');
    totalEl.textContent = 'MWK ...';
    metaEl.textContent = '';

    try {
        const res = await fetch(`/api/bookings/${encodeURIComponent(activeBookingId)}/extension-pricing?additional_months=${months}`, {
            headers: { 'Accept': 'application/json' }
        });
        const json = await res.json();
        if (!json.success) throw new Error(json.message || 'Failed to fetch extension pricing');
        const data = json.data || {};
        const total = data.total_amount ?? data.total ?? null;
        totalEl.textContent = total != null ? `MWK ${Number(total).toLocaleString()}` : 'MWK -';
        const monthly = data.monthly_price ?? null;
        const fee = data.platform_fee ?? null;
        metaEl.textContent = [
            monthly != null ? `Monthly: MWK ${Number(monthly).toLocaleString()}` : null,
            fee != null ? `Platform fee: MWK ${Number(fee).toLocaleString()}` : null
        ].filter(Boolean).join(' | ');
    } catch (e) {
        totalEl.textContent = 'MWK -';
        metaEl.textContent = String(e.message || e);
    }
}

async function confirmExtendBooking() {
    if (!activeBookingId) return;
    if (isExtendProceedInFlight) return;
    const bookingId = activeBookingId;
    const months = parseInt(document.getElementById('extendMonths').value || '1', 10);
    try {
        isExtendProceedInFlight = true;
        setProceedButtonLoading('extend', true);
        const user = await getUserDetails();

        const statusRes = await fetch(`/api/bookings/${encodeURIComponent(activeBookingId)}/extension-status-update`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': csrfToken()
            },
            body: JSON.stringify({ additional_months: months })
        });
        const statusJson = await statusRes.json();
        if (!statusJson.success) throw new Error(statusJson.message || 'Failed to update extension status');

        const payRes = await fetch('/api/payments/extend/initiate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': csrfToken()
            },
            body: JSON.stringify({
                booking_id: activeBookingId,
                additional_months: months,
                email: user.email,
                phone_number: user.phone_number || user.phoneNumber || '',
                first_name: user.first_name || user.firstName || '',
                last_name: user.last_name || user.lastName || '',
                payment_method: 'paychangu'
            })
        });
        const payJson = await payRes.json();
        if (!payJson.success) throw new Error(payJson.message || 'Failed to initiate extension payment');

        const data = payJson.data || {};
        const paymentUrl = data.payment_url;
        const paymentId = data.tx_ref;
        const amount = data.extension_amount;

        if (!paymentUrl) throw new Error('Payment URL not received');
        closeExtendBookingModal();
        window.location.href = `/student/payment/extend/${encodeURIComponent(bookingId)}?paymentUrl=${encodeURIComponent(paymentUrl)}&paymentId=${encodeURIComponent(paymentId || '')}&amount=${encodeURIComponent(amount || '')}`;
    } catch (e) {
        PalevelDialog.error(String(e.message || e));
    } finally {
        isExtendProceedInFlight = false;
        setProceedButtonLoading('extend', false);
    }
}

function openCompletePaymentModal(bookingId) {
    activeBookingId = bookingId;
    cachedCompletePricing = null;
    document.getElementById('completePaymentModal').classList.remove('hidden');
    refreshCompletePaymentPricing();
}

function closeCompletePaymentModal() {
    document.getElementById('completePaymentModal').classList.add('hidden');
    activeBookingId = null;
    cachedCompletePricing = null;
}

async function refreshCompletePaymentPricing() {
    if (!activeBookingId) return;
    const remainingEl = document.getElementById('completeRemaining');
    const metaEl = document.getElementById('completeMeta');
    remainingEl.textContent = 'MWK ...';
    metaEl.textContent = '';

    try {
        const res = await fetch(`/api/bookings/${encodeURIComponent(activeBookingId)}/complete-payment-pricing`, {
            headers: { 'Accept': 'application/json' }
        });
        const json = await res.json();
        if (!json.success) throw new Error(json.message || 'Failed to fetch pricing');
        const data = json.data || {};
        cachedCompletePricing = data;

        const remaining = data.remaining_amount ?? null;
        remainingEl.textContent = remaining != null ? `MWK ${Number(remaining).toLocaleString()}` : 'MWK -';
        const months = data.remaining_months ?? null;
        const rent = data.monthly_rent ?? null;
        metaEl.textContent = [
            months != null ? `Remaining months: ${months}` : null,
            rent != null ? `Monthly rent: MWK ${Number(rent).toLocaleString()}` : null
        ].filter(Boolean).join(' | ');
    } catch (e) {
        remainingEl.textContent = 'MWK -';
        metaEl.textContent = String(e.message || e);
    }
}

async function confirmCompletePayment() {
    if (!activeBookingId) return;
    if (isCompleteProceedInFlight) return;
    const bookingId = activeBookingId;
    try {
        isCompleteProceedInFlight = true;
        setProceedButtonLoading('complete', true);
        const user = await getUserDetails();
        if (!cachedCompletePricing) {
            await refreshCompletePaymentPricing();
        }

        const remainingAmount = (cachedCompletePricing && cachedCompletePricing.remaining_amount) ? cachedCompletePricing.remaining_amount : 0;

        const statusRes = await fetch(`/api/bookings/${encodeURIComponent(activeBookingId)}/complete-payment-status-update`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': csrfToken()
            },
            body: JSON.stringify({})
        });
        const statusJson = await statusRes.json();
        if (!statusJson.success) throw new Error(statusJson.message || 'Failed to update complete payment status');

        const payRes = await fetch('/api/payments/complete/initiate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': csrfToken()
            },
            body: JSON.stringify({
                booking_id: activeBookingId,
                remaining_amount: remainingAmount,
                email: user.email,
                phone_number: user.phone_number || user.phoneNumber || '',
                first_name: user.first_name || user.firstName || '',
                last_name: user.last_name || user.lastName || '',
                payment_method: 'paychangu'
            })
        });
        const payJson = await payRes.json();
        if (!payJson.success) throw new Error(payJson.message || 'Failed to initiate complete payment');

        const data = payJson.data || {};
        const paymentUrl = data.payment_url;
        const paymentId = data.tx_ref;
        const amount = data.remaining_amount;

        if (!paymentUrl) throw new Error('Payment URL not received');
        closeCompletePaymentModal();
        window.location.href = `/student/payment/complete/${encodeURIComponent(bookingId)}?paymentUrl=${encodeURIComponent(paymentUrl)}&paymentId=${encodeURIComponent(paymentId || '')}&amount=${encodeURIComponent(amount || '')}`;
    } catch (e) {
        PalevelDialog.error(String(e.message || e));
    } finally {
        isCompleteProceedInFlight = false;
        setProceedButtonLoading('complete', false);
    }
}
</script>
@endsection
