@extends('layouts.admin')

@section('title', 'Disbursement Management')

@section('subtitle', 'Manage landlord payments and disbursements')

@section('content')
<div class="w-full py-6 px-6">
    <!-- Header -->
    <div class="bg-gradient-to-r from-green-600 to-green-700 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <i class="fas fa-money-bill-wave text-white text-xl"></i>
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">Disbursement Management</h1>
                    <p class="text-green-100">Manage landlord payments and disbursements</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span id="disbursements-count" class="text-white font-medium">0 Landlords</span>
                </div>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
            {{ session('success') }}
        </div>
    @endif

    @if(session('error'))
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {{ session('error') }}
        </div>
    @endif

    <!-- Filters -->
    <div class="bg-white shadow rounded-lg mb-6">
        <div class="px-4 py-5 sm:p-6">
            <form method="GET" action="{{ route('admin.disbursements') }}">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Search Landlord</label>
                        <input type="text" name="search" value="{{ request('search') }}" 
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-green-500 focus:border-green-500"
                               placeholder="Search by name or email">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                        <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-green-500 focus:border-green-500">
                            <option value="">All Status</option>
                            <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>Pending</option>
                            <option value="processed" {{ request('status') == 'processed' ? 'selected' : '' }}>Processed</option>
                        </select>
                    </div>
                    <div class="flex items-end">
                        <button type="submit" class="w-full bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500">
                            <i class="fas fa-filter mr-2"></i>Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Disbursements Table -->
    <div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Landlord Disbursements</h3>
        </div>
        
        <!-- Data container for lazy loading -->
        <div id="data-container" class="min-h-[400px]">
            <!-- Loading spinner will be shown here initially -->
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
// Disbursement Management specific JavaScript functions

// Render function for disbursements table
function renderDisbursementsTable(data) {
    const disbursements = data.disbursements || [];
    const summary = data.summary || {};
    
    if (disbursements.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-money-bill-wave text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No disbursements found</h3>
                <p class="text-gray-500">No disbursement records match your current filters.</p>
            </div>
        `;
    }
    
    // Summary cards
    const summaryHtml = `
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-blue-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-blue-100 rounded-md p-2">
                        <i class="fas fa-users text-blue-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-blue-800">Total Landlords</p>
                        <p class="text-lg font-semibold text-blue-900">${summary.total_landlords || 0}</p>
                    </div>
                </div>
            </div>
            <div class="bg-green-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-green-100 rounded-md p-2">
                        <i class="fas fa-calendar-check text-green-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-green-800">Total Bookings</p>
                        <p class="text-lg font-semibold text-green-900">${summary.total_bookings || 0}</p>
                    </div>
                </div>
            </div>
            <div class="bg-yellow-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-yellow-100 rounded-md p-2">
                        <i class="fas fa-coins text-yellow-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-yellow-800">Platform Fees</p>
                        <p class="text-lg font-semibold text-yellow-900">${(summary.total_platform_fee || 0).toFixed(2)}</p>
                    </div>
                </div>
            </div>
            <div class="bg-purple-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-purple-100 rounded-md p-2">
                        <i class="fas fa-hand-holding-usd text-purple-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-purple-800">Total Disbursement</p>
                        <p class="text-lg font-semibold text-purple-900">${(summary.total_disbursement || 0).toFixed(2)}</p>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Disbursements table
    const tableHtml = `
        <div class="space-y-6">
            ${disbursements.map(disbursement => {
                return `
                <div class="border border-gray-200 rounded-lg overflow-hidden">
                    <!-- Landlord Header -->
                    <div class="bg-gray-50 px-6 py-4 border-b border-gray-200">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center space-x-4">
                                <div class="flex-shrink-0">
                                    <div class="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center">
                                        <i class="fas fa-user text-green-600"></i>
                                    </div>
                                </div>
                                <div>
                                    <h4 class="text-lg font-medium text-gray-900">${disbursement.landlord_name}</h4>
                                    <p class="text-sm text-gray-500">${disbursement.landlord_email}</p>
                                    <p class="text-sm text-gray-500">${disbursement.landlord_phone}</p>
                                </div>
                            </div>
                            <div class="text-right">
                                <p class="text-sm text-gray-500">Total Disbursement</p>
                                <p class="text-xl font-bold text-green-600">${disbursement.total_disbursement.toFixed(2)}</p>
                                <button onclick="authorizeBatchDisbursement('${disbursement.landlord_id}', ${disbursement.total_disbursement}, ${disbursement.total_bookings})" 
                                        class="mt-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded text-sm font-medium"
                                        ${disbursement.bookings.every(b => b.disbursement_status === 'completed') ? 'disabled' : ''}>
                                    <i class="fas fa-money-check-alt mr-2"></i>Authorize All (${disbursement.total_bookings})
                                </button>
                            </div>
                        </div>
                        
                        <!-- Payment Preferences -->
                        <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="bg-white rounded p-3 border border-gray-200">
                                <p class="text-xs font-medium text-gray-500 mb-1">Mobile Number</p>
                                <p class="text-sm text-gray-900">${disbursement.payment_preference.mobile_number || 'Not set'}</p>
                            </div>
                            <div class="bg-white rounded p-3 border border-gray-200">
                                <p class="text-xs font-medium text-gray-500 mb-1">Bank Account</p>
                                <p class="text-sm text-gray-900">${disbursement.payment_preference.bank_name || 'Not set'}</p>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Bookings Table -->
                    <div class="p-6">
                        <h5 class="text-sm font-medium text-gray-900 mb-3">Booking Details (${disbursement.total_bookings} bookings)</h5>
                        <div class="overflow-x-auto">
                            <table class="w-full divide-y divide-gray-200">
                                <thead class="bg-gray-50">
                                    <tr>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Student</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Hostel/Room</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Booking Amount</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Platform Fee</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Disbursement</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                                        <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                                    </tr>
                                </thead>
                                <tbody class="bg-white divide-y divide-gray-200">
                                    ${disbursement.bookings.map(booking => `
                                        <tr class="hover:bg-gray-50">
                                            <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">${booking.student_name}</td>
                                            <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">
                                                <div>${booking.hostel_name}</div>
                                                <div class="text-xs text-gray-500">Room ${booking.room_number}</div>
                                            </td>
                                            <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">${booking.booking_amount.toFixed(2)}</td>
                                            <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-900">${booking.platform_fee.toFixed(2)}</td>
                                            <td class="px-4 py-2 whitespace-nowrap text-sm font-medium text-green-600">${booking.disbursement_amount.toFixed(2)}</td>
                                            <td class="px-4 py-2 whitespace-nowrap text-sm text-gray-500">
                                                ${booking.booking_date ? new Date(booking.booking_date).toLocaleDateString() : 'N/A'}
                                            </td>
                                            <td class="px-4 py-2 whitespace-nowrap">
                                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                                    booking.disbursement_status === 'completed' ? 'bg-green-100 text-green-800' :
                                                    booking.disbursement_status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                                    'bg-gray-100 text-gray-800'
                                                }">
                                                    ${booking.disbursement_status ? booking.disbursement_status.charAt(0).toUpperCase() + booking.disbursement_status.slice(1) : 'Unknown'}
                                                </span>
                                            </td>
                                            <td class="px-4 py-2 whitespace-nowrap text-sm font-medium">
                                                <button onclick="authorizeTransaction('${booking.booking_id}', '${disbursement.landlord_id}', ${booking.disbursement_amount})" 
                                                        class="text-blue-600 hover:text-blue-900 bg-blue-50 hover:bg-blue-100 px-3 py-1 rounded text-sm"
                                                        ${booking.disbursement_status === 'completed' ? 'disabled' : ''}>
                                                    <i class="fas fa-check-circle mr-1"></i>Authorize
                                                </button>
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                `;
            }).join('')}
        </div>
    `;
    
    return summaryHtml + tableHtml;
}

// Authorize individual transaction
function authorizeTransaction(bookingId, landlordId, amount) {
    if (!confirm(`Are you sure you want to authorize disbursement of ${amount.toFixed(2)} for this booking?`)) {
        return;
    }
    
    const button = event.target;
    const originalText = button.innerHTML;
    button.disabled = true;
    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Processing...';
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(API_BASE_URL + '/admin/disbursements/process', {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + (token || '')
        },
        body: JSON.stringify({
            booking_id: bookingId,
            landlord_id: landlordId,
            amount: amount,
            is_batch: false
        })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(data => {
        if (data.success) {
            showSuccessMessage(data.message);
            // Reload the data to update the UI
            loadDisbursementsData();
        } else {
            showErrorMessage(data.message || 'Failed to process disbursement');
        }
    })
    .catch(error => {
        console.error('Error processing disbursement:', error);
        showErrorMessage('Failed to process disbursement. Please try again.');
    })
    .finally(() => {
        button.disabled = false;
        button.innerHTML = originalText;
    });
}

// Authorize batch disbursement
function authorizeBatchDisbursement(landlordId, totalAmount, totalBookings) {
    if (!confirm(`Are you sure you want to authorize batch disbursement of ${totalAmount.toFixed(2)} for ${totalBookings} bookings?`)) {
        return;
    }
    
    const button = event.target;
    const originalText = button.innerHTML;
    button.disabled = true;
    button.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Processing...';
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(API_BASE_URL + '/admin/disbursements/batch', {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + (token || '')
        },
        body: JSON.stringify({
            landlord_id: landlordId,
            total_amount: totalAmount,
            total_bookings: totalBookings
        })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(data => {
        if (data.success) {
            showSuccessMessage(data.message);
            // Reload the data to update the UI
            loadDisbursementsData();
        } else {
            showErrorMessage(data.message || 'Failed to process batch disbursement');
        }
    })
    .catch(error => {
        console.error('Error processing batch disbursement:', error);
        showErrorMessage('Failed to process batch disbursement. Please try again.');
    })
    .finally(() => {
        button.disabled = false;
        button.innerHTML = originalText;
    });
}

// Show success message
function showSuccessMessage(message) {
    // Create or update success alert
    let alertDiv = document.querySelector('.alert-success');
    if (!alertDiv) {
        alertDiv = document.createElement('div');
        alertDiv.className = 'alert-success bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6';
        const container = document.querySelector('.w-full.py-6.px-6');
        const header = container.querySelector('.bg-gradient-to-r');
        container.insertBefore(alertDiv, header.nextSibling);
    }
    alertDiv.innerHTML = message;
    alertDiv.style.display = 'block';
    
    // Hide after 5 seconds
    setTimeout(() => {
        alertDiv.style.display = 'none';
    }, 5000);
}

// Show error message
function showErrorMessage(message) {
    // Create or update error alert
    let alertDiv = document.querySelector('.alert-error');
    if (!alertDiv) {
        alertDiv = document.createElement('div');
        alertDiv.className = 'alert-error bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6';
        const container = document.querySelector('.w-full.py-6.px-6');
        const header = container.querySelector('.bg-gradient-to-r');
        container.insertBefore(alertDiv, header.nextSibling);
    }
    alertDiv.innerHTML = message;
    alertDiv.style.display = 'block';
    
    // Hide after 10 seconds
    setTimeout(() => {
        alertDiv.style.display = 'none';
    }, 10000);
}

// Load disbursements data function
function loadDisbursementsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get filter values
    const search = document.querySelector('input[name="search"]')?.value || '';
    const status = document.querySelector('select[name="status"]')?.value || '';
    
    // Build query parameters
    const params = new URLSearchParams({
        search: search,
        status: status
    });
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/disbursements?${params.toString()}`, {
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
        hideLoadingSpinner(container, data, renderDisbursementsTable);
        
        // Update disbursements count in header
        const countElement = document.getElementById('disbursements-count');
        if (countElement) {
            const total = data.summary?.total_landlords || 0;
            countElement.textContent = `${total} Landlord${total !== 1 ? 's' : ''}`;
        }
    })
    .catch(error => {
        console.error('Error loading disbursements data:', error);
        const fallbackData = {'disbursements': [], 'summary': {}};
        hideLoadingSpinner(container, fallbackData, renderDisbursementsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadDisbursementsData();
    
    // Add event listeners for filters
    const filterInputs = document.querySelectorAll('input[name="search"], select[name="status"]');
    filterInputs.forEach(input => {
        input.addEventListener('change', loadDisbursementsData);
    });
    
    // Handle form submission
    const filterForm = document.querySelector('form[method="GET"]');
    if (filterForm) {
        filterForm.addEventListener('submit', function(e) {
            e.preventDefault();
            loadDisbursementsData();
        });
    }
});
</script>
@endpush
