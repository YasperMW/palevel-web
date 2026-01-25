@extends('layouts.app')

@section('title', 'Booking Details')

@section('content')
@php
    $roomMedia = $booking['room']['media'] ?? [];
    $hostelMedia = $booking['room']['hostel']['media'] ?? [];
    $imageUrl = null;

    if (is_array($roomMedia) && count($roomMedia) > 0) {
        $imageUrl = \App\Helpers\MediaHelper::getMediaUrl($roomMedia[0]['url'] ?? null);
    }

    if (!$imageUrl && is_array($hostelMedia) && count($hostelMedia) > 0) {
        $imageUrl = \App\Helpers\MediaHelper::getMediaUrl($hostelMedia[0]['url'] ?? null);
    }

    $hostelName = $booking['room']['hostel']['name'] ?? $booking['hostel_name'] ?? 'Unknown Hostel';
    $roomNumber = $booking['room']['room_number'] ?? $booking['room_number'] ?? null;
    $roomType = $booking['room']['room_type'] ?? $booking['room_type'] ?? 'Unknown Type';

    $landlordFirst = $booking['room']['hostel']['landlord']['first_name'] ?? null;
    $landlordLast = $booking['room']['hostel']['landlord']['last_name'] ?? null;
    $landlordName = ($landlordFirst || $landlordLast) ? trim(($landlordFirst ?? '') . ' ' . ($landlordLast ?? '')) : 'N/A';

    $status = $booking['status'] ?? 'pending';
    $paymentType = $booking['payment_type'] ?? null;
    $paymentMethod = $booking['payment_method'] ?? $booking['payment_method_name'] ?? $booking['payments'][0]['payment_method'] ?? null;
    $transactionId = $booking['transaction_id'] ?? $booking['payments'][0]['transaction_reference'] ?? $booking['payments'][0]['reference'] ?? null;

    $checkIn = $booking['check_in_date'] ?? null;
    $checkOut = $booking['check_out_date'] ?? null;
    $durationMonths = $booking['duration_months'] ?? null;

    $totalAmount = $booking['total_amount'] ?? null;
    $baseRoomPrice = $booking['base_room_price'] ?? null;
    $platformFee = $booking['platform_fee'] ?? null;
@endphp

<div class="min-h-screen bg-gray-50">
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
                        <h1 class="text-xl font-semibold text-gray-900">Booking Details</h1>
                        <p class="text-sm text-gray-600">Booking ID: #{{ $booking['booking_id'] ?? 'N/A' }}</p>
                    </div>
                </div>
                <div>
                    <span class="px-3 py-1 text-xs font-semibold rounded-full
                        @if($status === 'confirmed') bg-green-100 text-green-800
                        @elseif($status === 'pending') bg-yellow-100 text-yellow-800
                        @elseif($status === 'extension_in_progress') bg-blue-100 text-blue-800
                        @elseif($status === 'pending_extension') bg-indigo-100 text-indigo-800
                        @elseif($status === 'completing_payment') bg-purple-100 text-purple-800
                        @else bg-red-100 text-red-800
                        @endif">
                        {{ ucfirst(str_replace('_', ' ', $status)) }}
                    </span>
                </div>
            </div>
        </div>
    </div>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div class="lg:col-span-2 space-y-6">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                    <div class="h-64 bg-gray-100">
                        @if($imageUrl)
                            <img src="{{ $imageUrl }}" class="w-full h-full object-cover" alt="{{ $hostelName }}">
                        @else
                            <div class="w-full h-full flex items-center justify-center">
                                <svg class="w-16 h-16 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                                </svg>
                            </div>
                        @endif
                    </div>

                    <div class="p-6">
                        <h2 class="text-2xl font-bold text-gray-900">{{ $hostelName }}</h2>
                        <p class="text-gray-600 mt-1">
                            @if($roomNumber)
                                Room {{ $roomNumber }}
                            @else
                                Room
                            @endif
                            - {{ $roomType }}
                        </p>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
                            <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                                <p class="text-xs font-semibold text-gray-500">Check-in</p>
                                <p class="text-base font-semibold text-gray-900">{{ $checkIn ?? 'N/A' }}</p>
                            </div>
                            <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                                <p class="text-xs font-semibold text-gray-500">Check-out</p>
                                <p class="text-base font-semibold text-gray-900">{{ $checkOut ?? 'N/A' }}</p>
                            </div>
                            <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                                <p class="text-xs font-semibold text-gray-500">Duration</p>
                                <p class="text-base font-semibold text-gray-900">
                                    @if($durationMonths)
                                        {{ $durationMonths }} {{ $durationMonths > 1 ? 'months' : 'month' }}
                                    @else
                                        N/A
                                    @endif
                                </p>
                            </div>
                            <div class="p-4 bg-gray-50 rounded-lg border border-gray-200">
                                <p class="text-xs font-semibold text-gray-500">Landlord</p>
                                <p class="text-base font-semibold text-gray-900">{{ $landlordName }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Payment Details</h3>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <p class="text-sm text-gray-600">Payment Type</p>
                            <p class="font-semibold text-gray-900">{{ $paymentType ? ucfirst(str_replace('_', ' ', $paymentType)) : 'N/A' }}</p>
                        </div>
                        <div>
                            <p class="text-sm text-gray-600">Payment Method</p>
                            <p class="font-semibold text-gray-900">{{ $paymentMethod ? ucfirst(str_replace('_', ' ', $paymentMethod)) : 'N/A' }}</p>
                        </div>
                        <div>
                            <p class="text-sm text-gray-600">Transaction ID</p>
                            <p class="font-semibold text-gray-900 break-all">{{ $transactionId ?? 'N/A' }}</p>
                        </div>
                        <div>
                            <p class="text-sm text-gray-600">Total Amount</p>
                            <p class="font-semibold text-teal-600">{{ $totalAmount !== null ? 'MWK ' . number_format($totalAmount, 0) : 'N/A' }}</p>
                        </div>
                    </div>

                    <div class="mt-6 border-t border-gray-200 pt-4">
                        <h4 class="text-sm font-semibold text-gray-900 mb-3">Breakdown</h4>
                        <div class="space-y-2">
                            <div class="flex justify-between text-sm">
                                <span class="text-gray-600">Base Room Price</span>
                                <span class="font-medium">{{ $baseRoomPrice !== null ? 'MWK ' . number_format($baseRoomPrice, 0) : 'N/A' }}</span>
                            </div>
                            <div class="flex justify-between text-sm">
                                <span class="text-gray-600">Platform Fee</span>
                                <span class="font-medium">{{ $platformFee !== null ? 'MWK ' . number_format($platformFee, 0) : 'N/A' }}</span>
                            </div>
                            <div class="flex justify-between text-base font-semibold text-teal-600 pt-2 border-t border-gray-200">
                                <span>Total</span>
                                <span>{{ $totalAmount !== null ? 'MWK ' . number_format($totalAmount, 0) : 'N/A' }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Receipt</h3>
                    <button onclick="downloadReceipt('{{ $booking['booking_id'] ?? '' }}')" id="receiptDownloadBtn" class="w-full px-4 py-3 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-lg hover:from-teal-700 hover:to-teal-800 font-medium text-sm transition-all duration-200 flex items-center justify-center">
                        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10"></path>
                        </svg>
                        <span id="receiptBtnText">Download Receipt (PDF)</span>
                    </button>
                </div>
            </div>

            <div class="lg:col-span-1 space-y-6">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Actions</h3>

                    <div class="space-y-3">
                        <a href="{{ route('student.bookings') }}" class="block text-center px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50">
                            Back to Bookings
                        </a>

                        @if(($booking['payment_type'] ?? '') === 'booking_fee')
                            <a href="{{ route('student.bookings') }}" class="block text-center px-4 py-2 border border-teal-300 text-teal-700 rounded-lg hover:bg-teal-50">
                                Complete Payment
                            </a>
                        @elseif(($booking['payment_type'] ?? '') === 'full')
                            <a href="{{ route('student.bookings') }}" class="block text-center px-4 py-2 border border-blue-300 text-blue-700 rounded-lg hover:bg-blue-50">
                                Extend Booking
                            </a>
                        @endif
                    </div>
                </div>

                <div class="bg-blue-50 rounded-xl border border-blue-200 p-6">
                    <h3 class="text-lg font-semibold text-blue-900 mb-2">Need Help?</h3>
                    <p class="text-sm text-blue-700">If your booking details look incorrect, try refreshing or contact support.</p>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

<script>
async function downloadReceipt(bookingId) {
    const btn = document.getElementById('receiptDownloadBtn');
    const btnText = document.getElementById('receiptBtnText');
    if (!btn || !btnText) return;

    const originalHtml = btn.innerHTML;
    try {
        btn.disabled = true;
        btn.classList.add('opacity-75', 'cursor-not-allowed');
        btnText.textContent = 'Downloading...';

        const response = await fetch(`/pdf/booking-receipt/${encodeURIComponent(bookingId)}`, {
            method: 'GET',
            headers: {
                'Accept': 'application/pdf',
                'X-Requested-With': 'XMLHttpRequest'
            }
        });

        if (!response.ok) {
            throw new Error(`Failed to download receipt: ${response.status}`);
        }

        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        const disposition = response.headers.get('content-disposition');
        let filename = 'booking_receipt.pdf';
        if (disposition && disposition.includes('filename=')) {
            const match = disposition.match(/filename="?([^"]+)"?/);
            if (match && match[1]) filename = match[1];
        }
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
    } catch (e) {
        PalevelDialog.error('Failed to download receipt: ' + (e.message || e));
    } finally {
        btn.disabled = false;
        btn.classList.remove('opacity-75', 'cursor-not-allowed');
        btnText.textContent = 'Download Receipt (PDF)';
    }
}
</script>
