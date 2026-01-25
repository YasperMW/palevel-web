@extends('layouts.admin')

@section('title', 'Verification Management')

@section('subtitle', 'Review and verify landlord identity documents')

@section('content')
<div class="w-full py-6 px-6">
    <!-- Header -->
    <div class="bg-gradient-to-r from-orange-600 to-orange-700 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <i class="fas fa-shield-alt text-white text-xl"></i>
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">Verification Management</h1>
                    <p class="text-orange-100">Review and verify landlord identity documents</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span id="verifications-count" class="text-white font-medium">0 Verifications</span>
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
            <form method="GET" action="{{ route('admin.verifications') }}">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                        <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500">
                            <option value="">All Status</option>
                            <option value="pending" {{ ($filters['status'] ?? '') == 'pending' ? 'selected' : '' }}>Pending</option>
                            <option value="approved" {{ ($filters['status'] ?? '') == 'approved' ? 'selected' : '' }}>Approved</option>
                            <option value="rejected" {{ ($filters['status'] ?? '') == 'rejected' ? 'selected' : '' }}>Rejected</option>
                        </select>
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

    <!-- Verifications Table -->
    <div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Verification Requests</h3>
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
// Verification Management specific JavaScript functions

// Render function for verifications table
function renderVerificationsTable(data) {
    const verifications = data.verifications || [];
    const total = data.total || 0;
    
    if (verifications.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-shield-alt text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No verifications found</h3>
                <p class="text-gray-500">No verification requests match your current filters.</p>
            </div>
        `;
    }
    
    // Calculate summary stats
    const pending = verifications.filter(v => v.status === 'pending');
    const approved = verifications.filter(v => v.status === 'approved');
    const rejected = verifications.filter(v => v.status === 'rejected');
    
    const summaryHtml = `
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-yellow-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-yellow-100 rounded-md p-2">
                        <i class="fas fa-clock text-yellow-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-yellow-800">Pending</p>
                        <p class="text-lg font-semibold text-yellow-900">${pending.length}</p>
                    </div>
                </div>
            </div>
            <div class="bg-green-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-green-100 rounded-md p-2">
                        <i class="fas fa-check-circle text-green-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-green-800">Approved</p>
                        <p class="text-lg font-semibold text-green-900">${approved.length}</p>
                    </div>
                </div>
            </div>
            <div class="bg-red-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-red-100 rounded-md p-2">
                        <i class="fas fa-times-circle text-red-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-red-800">Rejected</p>
                        <p class="text-lg font-semibold text-red-900">${rejected.length}</p>
                    </div>
                </div>
            </div>
            <div class="bg-orange-50 rounded-lg p-4">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-orange-100 rounded-md p-2">
                        <i class="fas fa-shield-alt text-orange-600"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-orange-800">Total</p>
                        <p class="text-lg font-semibold text-orange-900">${total}</p>
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
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Landlord</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Document</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Submitted</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Verified</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${verifications.map(verification => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${verification.landlord_name || 'N/A'}</div>
                                <div class="text-sm text-gray-500">${verification.landlord_email || 'N/A'}</div>
                                <div class="text-sm text-gray-500">${verification.landlord_phone || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${verification.id_type || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${verification.id_document_url ? 
                                    `<a href="{{ $apiBaseUrl }}${verification.id_document_url}" target="_blank" class="text-blue-600 hover:text-blue-800">
                                        <i class="fas fa-file-image mr-1"></i>View Document
                                    </a>` :
                                    '<div class="text-sm text-gray-500">No document</div>'
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    verification.status === 'approved' ? 'bg-green-100 text-green-800' :
                                    verification.status === 'rejected' ? 'bg-red-100 text-red-800' :
                                    'bg-yellow-100 text-yellow-800'
                                }">
                                    ${verification.status ? verification.status.charAt(0).toUpperCase() + verification.status.slice(1) : 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${verification.created_at ? new Date(verification.created_at).toLocaleString() : 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${verification.verified_at ? new Date(verification.verified_at).toLocaleString() : 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                ${verification.status === 'pending' ? 
                                    `<div class="flex space-x-2">
                                        <form action="{{ route('admin.verifications.update-status', ':id') }}" method="POST" class="inline" data-palevel-confirm="Approve this verification?">
                                            @csrf
                                            @method('PUT')
                                            <input type="hidden" name="status" value="approved">
                                            <button type="submit" class="text-green-600 hover:text-green-900">
                                                <i class="fas fa-check-circle mr-1"></i>Approve
                                            </button>
                                        </form>
                                        <form action="{{ route('admin.verifications.update-status', ':id') }}" method="POST" class="inline" data-palevel-confirm="Reject this verification?">
                                            @csrf
                                            @method('PUT')
                                            <input type="hidden" name="status" value="rejected">
                                            <button type="submit" class="text-red-600 hover:text-red-900">
                                                <i class="fas fa-times-circle mr-1"></i>Reject
                                            </button>
                                        </form>
                                    </div>` :
                                    '<span class="text-gray-400">No actions available</span>'
                                }
                            </td>
                        </tr>
                    `.replace(/:id/g, verification.verification_id)).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Load verifications data function
function loadVerificationsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get filter values
    const status = document.querySelector('select[name="status"]')?.value || '';
    
    // Build query parameters
    const params = new URLSearchParams({
        status: status
    });
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/verifications?${params.toString()}`, {
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
        hideLoadingSpinner(container, data, renderVerificationsTable);
        
        // Update verifications count in header
        const countElement = document.getElementById('verifications-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = `${total} Verification${total !== 1 ? 's' : ''}`;
        }
    })
    .catch(error => {
        console.error('Error loading verifications data:', error);
        const fallbackData = {'verifications': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderVerificationsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadVerificationsData();
    
    // Add event listeners for filters
    const filterInputs = document.querySelectorAll('select[name="status"]');
    filterInputs.forEach(input => {
        input.addEventListener('change', loadVerificationsData);
    });
    
    // Handle form submission
    const filterForm = document.querySelector('form[method="GET"]');
    if (filterForm) {
        filterForm.addEventListener('submit', function(e) {
            e.preventDefault();
            loadVerificationsData();
        });
    }
});
</script>
@endpush
