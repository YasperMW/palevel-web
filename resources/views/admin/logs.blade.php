@extends('layouts.admin')

@section('title', 'System Logs')

@section('content')
<div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="bg-gradient-to-r from-orange-600 to-orange-700 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <i class="fas fa-list-alt text-white text-xl"></i>
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">System Logs</h1>
                    <p class="text-orange-100">Monitor system activity and audit trails</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span id="logs-count" class="text-white font-medium">0 Logs</span>
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
            <form method="GET" action="{{ route('admin.logs') }}">
                <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Activity Type</label>
                        <select name="level" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500">
                            <option value="">All Types</option>
                            <option value="login" {{ ($filters['level'] ?? '') == 'login' ? 'selected' : '' }}>Login</option>
                            <option value="booking" {{ ($filters['level'] ?? '') == 'booking' ? 'selected' : '' }}>Booking</option>
                            <option value="payment" {{ ($filters['level'] ?? '') == 'payment' ? 'selected' : '' }}>Payment</option>
                            <option value="user_action" {{ ($filters['level'] ?? '') == 'user_action' ? 'selected' : '' }}>User Action</option>
                            <option value="system" {{ ($filters['level'] ?? '') == 'system' ? 'selected' : '' }}>System</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Start Date</label>
                        <input type="date" name="start_date" value="{{ $filters['start_date'] ?? '' }}" 
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">End Date</label>
                        <input type="date" name="end_date" value="{{ $filters['end_date'] ?? '' }}" 
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500">
                    </div>
                    <div class="flex items-end">
                        <button type="submit" class="w-full bg-orange-600 text-white px-4 py-2 rounded-md hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-orange-500">
                            <i class="fas fa-filter mr-2"></i>Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Logs Table -->
    <div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Activity Logs</h3>
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
// System Logs specific JavaScript functions

// Render function for logs table
function renderLogsTable(data) {
    const logs = data.logs || [];
    const total = data.total || 0;
    
    if (logs.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-list-alt text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No logs found</h3>
                <p class="text-gray-500">No logs match your current filters.</p>
            </div>
        `;
    }
    
    // Calculate activity summary
    const logins = logs.filter(l => l.activity_type === 'login');
    const bookings = logs.filter(l => l.activity_type === 'booking');
    const payments = logs.filter(l => l.activity_type === 'payment');
    const system = logs.filter(l => l.activity_type === 'system');
    
    const summaryHtml = `
        <!-- Activity Summary -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-blue-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-blue-100 rounded-md p-2">
                        <i class="fas fa-sign-in-alt text-blue-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-blue-800">Logins</p>
                        <p class="text-lg font-semibold text-blue-900">${logins.length}</p>
                    </div>
                </div>
            </div>
            <div class="bg-green-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-green-100 rounded-md p-2">
                        <i class="fas fa-calendar-check text-green-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-green-800">Bookings</p>
                        <p class="text-lg font-semibold text-green-900">${bookings.length}</p>
                    </div>
                </div>
            </div>
            <div class="bg-purple-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-purple-100 rounded-md p-2">
                        <i class="fas fa-credit-card text-purple-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-purple-800">Payments</p>
                        <p class="text-lg font-semibold text-purple-900">${payments.length}</p>
                    </div>
                </div>
            </div>
            <div class="bg-orange-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-orange-100 rounded-md p-2">
                        <i class="fas fa-cogs text-orange-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-orange-800">System</p>
                        <p class="text-lg font-semibold text-orange-900">${system.length}</p>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    return summaryHtml + `
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">IP Address</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User Agent</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${logs.map(log => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${log.created_at ? new Date(log.created_at).toLocaleString() : 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    log.activity_type === 'login' ? 'bg-blue-100 text-blue-800' :
                                    log.activity_type === 'booking' ? 'bg-green-100 text-green-800' :
                                    log.activity_type === 'payment' ? 'bg-purple-100 text-purple-800' :
                                    log.activity_type === 'user_action' ? 'bg-yellow-100 text-yellow-800' :
                                    log.activity_type === 'system' ? 'bg-orange-100 text-orange-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${log.activity_type ? log.activity_type.charAt(0).toUpperCase() + log.activity_type.slice(1).replace('_', ' ') : log.activity_type || 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${log.user_id ? 
                                    `<div class="text-sm text-gray-900">User ${log.user_id.substring(0, 8)}...</div>` :
                                    '<div class="text-sm text-gray-500">System</div>'
                                }
                            </td>
                            <td class="px-6 py-4">
                                <div class="text-sm text-gray-900 max-w-xs truncate" title="${log.description || 'N/A'}">
                                    ${log.description || 'N/A'}
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${log.ip_address || 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-500 max-w-xs truncate" title="${log.user_agent || 'N/A'}">
                                    ${log.user_agent ? log.user_agent.substring(0, 50) + '...' : 'N/A'}
                                </div>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Load logs data function
function loadLogsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const page = urlParams.get('page') || '1';
    const level = urlParams.get('level') || '';
    const startDate = urlParams.get('start_date') || '';
    const endDate = urlParams.get('end_date') || '';
    
    // Make actual API call to get logs data
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/logs?page=${page}&level=${level}&start_date=${startDate}&end_date=${endDate}`, {
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
        hideLoadingSpinner(container, data, renderLogsTable);
        
        // Update logs count in header
        const countElement = document.getElementById('logs-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = `${total} Log${total !== 1 ? 's' : ''}`;
        }
    })
    .catch(error => {
        console.error('Error loading logs data:', error);
        const fallbackData = {'logs': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderLogsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadLogsData();
});
</script>
@endpush
