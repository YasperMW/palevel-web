@extends('layouts.admin')

@section('title', 'Payments Management')

@section('content')
<div class="w-full py-6 px-6">
    <!-- Header -->
    <div class="bg-gradient-to-r from-purple-600 to-purple-700 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <i class="fas fa-money-bill-wave text-white text-xl"></i>
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">Payments Management</h1>
                    <p class="text-purple-100">Monitor and manage all platform transactions</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span id="payments-count" class="text-white font-medium">0 Payments</span>
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
            <form method="GET" action="{{ route('admin.payments') }}">
                <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                        <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500">
                            <option value="">All Status</option>
                            <option value="completed" {{ ($filters['status'] ?? '') == 'completed' ? 'selected' : '' }}>Completed</option>
                            <option value="pending" {{ ($filters['status'] ?? '') == 'pending' ? 'selected' : '' }}>Pending</option>
                            <option value="failed" {{ ($filters['status'] ?? '') == 'failed' ? 'selected' : '' }}>Failed</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Payment Type</label>
                        <select name="payment_type" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500">
                            <option value="">All Types</option>
                            <option value="full" {{ ($filters['payment_type'] ?? '') == 'full' ? 'selected' : '' }}>Full Payment</option>
                            <option value="booking_fee" {{ ($filters['payment_type'] ?? '') == 'booking_fee' ? 'selected' : '' }}>Booking Fee</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Start Date</label>
                        <input type="date" name="start_date" value="{{ $filters['start_date'] ?? '' }}" 
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">End Date</label>
                        <input type="date" name="end_date" value="{{ $filters['end_date'] ?? '' }}" 
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-purple-500 focus:border-purple-500">
                    </div>
                    <div class="flex items-end">
                        <button type="submit" class="w-full bg-purple-600 text-white px-4 py-2 rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500">
                            <i class="fas fa-filter mr-2"></i>Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Payments Table -->
    <div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Payments List</h3>
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
// Payments Management specific JavaScript functions

// Render function for payments table
function renderPaymentsTable(data) {
    const payments = data.payments || [];
    const total = data.total || 0;
    
    if (payments.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-money-bill-wave text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No payments found</h3>
                <p class="text-gray-500">No payments match your current filters.</p>
            </div>
        `;
    }
    
    // Calculate summary stats
    const completed = payments.filter(p => p.status === 'completed');
    const pending = payments.filter(p => p.status === 'pending');
    const failed = payments.filter(p => p.status === 'failed');
    
    const summaryHtml = `
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-green-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-green-100 rounded-md p-2">
                        <i class="fas fa-check-circle text-green-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-green-800">Completed</p>
                        <p class="text-lg font-semibold text-green-900">
                            MWK ${completed.reduce((sum, p) => sum + (p.amount || 0), 0).toFixed(2)}
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-yellow-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-yellow-100 rounded-md p-2">
                        <i class="fas fa-clock text-yellow-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-yellow-800">Pending</p>
                        <p class="text-lg font-semibold text-yellow-900">
                            MWK ${pending.reduce((sum, p) => sum + (p.amount || 0), 0).toFixed(2)}
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-red-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-red-100 rounded-md p-2">
                        <i class="fas fa-times-circle text-red-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-red-800">Failed</p>
                        <p class="text-lg font-semibold text-red-900">
                            MWK ${failed.reduce((sum, p) => sum + (p.amount || 0), 0).toFixed(2)}
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-purple-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-purple-100 rounded-md p-2">
                        <i class="fas fa-chart-line text-purple-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-purple-800">Total</p>
                        <p class="text-lg font-semibold text-purple-900">
                            MWK ${payments.reduce((sum, p) => sum + (p.amount || 0), 0).toFixed(2)}
                        </p>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    return summaryHtml + `
        <div class="overflow-x-auto -mx-6 px-6">
            <table class="w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Payment ID</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Student</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Property</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Method</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${payments.map(payment => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${payment.payment_id ? payment.payment_id.substring(0, 8) + '...' : 'N/A'}</div>
                                <div class="text-sm text-gray-500">${payment.transaction_id || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${payment.student ? 
                                    `<div class="text-sm text-gray-900">${payment.student.name || 'N/A'}</div>
                                     <div class="text-sm text-gray-500">${payment.student.email || 'N/A'}</div>` :
                                    '<div class="text-sm text-gray-500">N/A</div>'
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${payment.hostel ? 
                                    `<div class="text-sm text-gray-900">${payment.hostel}</div>
                                     <div class="text-sm text-gray-500">Room ${payment.room || 'N/A'}</div>` :
                                    '<div class="text-sm text-gray-500">N/A</div>'
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm font-medium text-gray-900">MWK ${(payment.amount || 0).toFixed(2)}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    payment.payment_type === 'full' ? 'bg-blue-100 text-blue-800' :
                                    payment.payment_type === 'booking_fee' ? 'bg-yellow-100 text-yellow-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${payment.payment_type === 'full' ? 'Full' :
                                      payment.payment_type === 'booking_fee' ? 'Booking Fee' :
                                      payment.payment_type || 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${payment.payment_method ? payment.payment_method.charAt(0).toUpperCase() + payment.payment_method.slice(1) : 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    payment.status === 'completed' ? 'bg-green-100 text-green-800' :
                                    payment.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                    payment.status === 'failed' ? 'bg-red-100 text-red-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${payment.status ? payment.status.charAt(0).toUpperCase() + payment.status.slice(1) : 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${payment.paid_at ? new Date(payment.paid_at).toLocaleString() :
                                  payment.created_at ? new Date(payment.created_at).toLocaleString() : 'N/A'}
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Load payments data function
function loadPaymentsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get filter values
    const status = document.querySelector('select[name="status"]')?.value || '';
    const paymentType = document.querySelector('select[name="payment_type"]')?.value || '';
    const paymentMethod = document.querySelector('select[name="payment_method"]')?.value || '';
    const startDate = document.querySelector('input[name="start_date"]')?.value || '';
    const endDate = document.querySelector('input[name="end_date"]')?.value || '';
    
    // Build query parameters
    const params = new URLSearchParams({
        status: status,
        payment_type: paymentType,
        payment_method: paymentMethod,
        start_date: startDate,
        end_date: endDate
    });
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/payments?${params.toString()}`, {
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
        hideLoadingSpinner(container, data, renderPaymentsTable);
        
        // Update payments count in header
        const countElement = document.getElementById('payments-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = `${total} Payment${total !== 1 ? 's' : ''}`;
        }
    })
    .catch(error => {
        console.error('Error loading payments data:', error);
        const fallbackData = {'payments': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderPaymentsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadPaymentsData();
    
    // Add event listeners for filters
    const filterInputs = document.querySelectorAll('select[name="status"], select[name="payment_type"], select[name="payment_method"], input[name="start_date"], input[name="end_date"]');
    filterInputs.forEach(input => {
        input.addEventListener('change', loadPaymentsData);
    });
    
    // Handle form submission
    const filterForm = document.querySelector('form[method="GET"]');
    if (filterForm) {
        filterForm.addEventListener('submit', function(e) {
            e.preventDefault();
            loadPaymentsData();
        });
    }
});
</script>
@endpush
