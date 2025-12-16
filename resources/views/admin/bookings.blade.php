@extends('layouts.admin')

@section('title', 'Bookings Management')

@section('subtitle', 'Manage and monitor all booking requests and reservations')

@section('content')
<!-- Stats Overview -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Total Bookings</p>
                <p id="bookings-count" class="text-2xl font-bold text-gray-900">0</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-calendar-check text-blue-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Pending</p>
                <p id="pending-count" class="text-2xl font-bold text-yellow-600">0</p>
            </div>
            <div class="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-clock text-yellow-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Confirmed</p>
                <p id="confirmed-count" class="text-2xl font-bold text-green-600">0</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-check-circle text-green-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Cancelled</p>
                <p id="cancelled-count" class="text-2xl font-bold text-red-600">0</p>
            </div>
            <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-times-circle text-red-600"></i>
            </div>
        </div>
    </div>
</div>

<!-- Filters and Search -->
<div class="palevel-card bg-white rounded-xl shadow-lg p-6 mb-6">
    <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900">Filters</h3>
        <button class="text-blue-600 hover:text-blue-800 text-sm">
            <i class="fas fa-filter mr-1"></i> Advanced Filters
        </button>
    </div>
    <form method="GET" action="{{ route('admin.bookings') }}">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                    <option value="">All Status</option>
                    <option value="pending" {{ ($status ?? '') == 'pending' ? 'selected' : '' }}>Pending</option>
                    <option value="confirmed" {{ ($status ?? '') == 'confirmed' ? 'selected' : '' }}>Confirmed</option>
                    <option value="cancelled" {{ ($status ?? '') == 'cancelled' ? 'selected' : '' }}>Cancelled</option>
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Start Date</label>
                <input type="date" name="start_date" value="{{ $start_date ?? '' }}" 
                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">End Date</label>
                <input type="date" name="end_date" value="{{ $end_date ?? '' }}" 
                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
            </div>
            <div class="flex items-end">
                <button type="submit" class="w-full palevel-gradient text-white px-4 py-2 rounded-md hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <i class="fas fa-search mr-2"></i>Search
                </button>
            </div>
        </div>
    </form>
</div>

<!-- Bookings Table -->
<div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
    <div class="px-6 py-4 border-b border-gray-200">
        <h3 class="text-lg font-semibold text-gray-900">Bookings List</h3>
    </div>
    
    <!-- Data container for lazy loading -->
    <div id="data-container" class="min-h-[400px]">
        <!-- Loading spinner will be shown here initially -->
    </div>
</div>
@endsection

@push('scripts')
<script>
// Bookings Management specific JavaScript functions

// Render function for bookings table
function renderBookingsTable(data) {
    const bookings = data.bookings || [];
    const total = data.total || 0;
    
    if (bookings.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-calendar-check text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No bookings found</h3>
                <p class="text-gray-500">No bookings match your current filters.</p>
            </div>
        `;
    }
    
    return `
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Booking ID</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Student</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Property</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Duration</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${bookings.map(booking => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${booking.booking_id ? booking.booking_id.substring(0, 8) + '...' : 'N/A'}</div>
                                <div class="text-sm text-gray-500">ID: ${booking.id || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${booking.student ? 
                                    `<div class="text-sm text-gray-900">${booking.student.first_name || ''} ${booking.student.last_name || ''}</div>
                                     <div class="text-sm text-gray-500">${booking.student.email || 'N/A'}</div>` :
                                    '<div class="text-sm text-gray-500">N/A</div>'
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${booking.hostel ? 
                                    `<div class="text-sm text-gray-900">${booking.hostel.name || booking.hostel}</div>
                                     <div class="text-sm text-gray-500">Room ${booking.room ? booking.room.room_number : 'N/A'}</div>` :
                                    '<div class="text-sm text-gray-500">N/A</div>'
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm font-medium text-gray-900">MWK ${(booking.total_amount || 0).toFixed(2)}</div>
                                <div class="text-sm text-gray-500">MWK ${(booking.booking_fee || 0).toFixed(2)} fee</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${booking.duration || 1} month(s)</div>
                                <div class="text-sm text-gray-500">${booking.start_date ? new Date(booking.start_date).toLocaleDateString() : 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    booking.status === 'confirmed' ? 'bg-green-100 text-green-800' :
                                    booking.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                    booking.status === 'cancelled' ? 'bg-red-100 text-red-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${booking.status ? booking.status.charAt(0).toUpperCase() + booking.status.slice(1) : 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${booking.created_at ? new Date(booking.created_at).toLocaleDateString() : 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div class="flex space-x-2">
                                    <button class="text-blue-600 hover:text-blue-900" title="View Details">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                    ${booking.status === 'pending' ? 
                                        `<button class="text-green-600 hover:text-green-900" title="Confirm">
                                            <i class="fas fa-check"></i>
                                        </button>` : ''
                                    }
                                    ${booking.status === 'pending' || booking.status === 'confirmed' ? 
                                        `<button class="text-red-600 hover:text-red-900" title="Cancel">
                                            <i class="fas fa-times"></i>
                                        </button>` : ''
                                    }
                                </div>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Load bookings data function
function loadBookingsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const page = urlParams.get('page') || '1';
    const status = urlParams.get('status') || '';
    const startDate = urlParams.get('start_date') || '';
    const endDate = urlParams.get('end_date') || '';
    
    // Make actual API call to get bookings data
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/bookings?page=${page}&status=${status}&start_date=${startDate}&end_date=${endDate}`, {
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + (token || '')
        }
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(data => {
        hideLoadingSpinner(container, data, renderBookingsTable);
        
        // Update bookings count in header
        const countElement = document.getElementById('bookings-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = total;
        }
        
        // Update status counts
        const bookings = data.bookings || [];
        const pendingCount = bookings.filter(b => b.status === 'pending').length;
        const confirmedCount = bookings.filter(b => b.status === 'confirmed').length;
        const cancelledCount = bookings.filter(b => b.status === 'cancelled').length;
        
        const pendingElement = document.getElementById('pending-count');
        if (pendingElement) {
            pendingElement.textContent = pendingCount;
        }
        
        const confirmedElement = document.getElementById('confirmed-count');
        if (confirmedElement) {
            confirmedElement.textContent = confirmedCount;
        }
        
        const cancelledElement = document.getElementById('cancelled-count');
        if (cancelledElement) {
            cancelledElement.textContent = cancelledCount;
        }
    })
    .catch(error => {
        console.error('Error loading bookings data:', error);
        const fallbackData = {'bookings': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderBookingsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadBookingsData();
});
</script>
@endpush
