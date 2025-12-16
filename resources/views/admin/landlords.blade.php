@extends('layouts.admin')

@section('title', 'Landlords Management')

@section('subtitle', 'Manage and monitor landlord accounts and properties')

@section('content')
<div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="bg-gradient-to-r from-green-600 to-green-700 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <i class="fas fa-building text-white text-xl"></i>
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">Landlords Management</h1>
                    <p class="text-green-100">Manage and monitor landlord accounts and properties</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span id="landlords-count" class="text-white font-medium">0 Landlords</span>
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

    <!-- Filters and Search -->
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6 mb-6">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Filters</h3>
            <button class="text-green-600 hover:text-green-800 text-sm">
                <i class="fas fa-filter mr-1"></i> Advanced Filters
            </button>
        </div>
            <form method="GET" action="{{ route('admin.landlords') }}">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Search</label>
                        <input type="text" name="search" value="{{ $search ?? '' }}" 
                               placeholder="Search by name, email, or phone..."
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-green-500 focus:border-green-500">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                        <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-green-500 focus:border-green-500">
                            <option value="">All Status</option>
                            <option value="active" {{ ($status ?? '') == 'active' ? 'selected' : '' }}>Active</option>
                            <option value="inactive" {{ ($status ?? '') == 'inactive' ? 'selected' : '' }}>Inactive</option>
                            <option value="suspended" {{ ($status ?? '') == 'suspended' ? 'selected' : '' }}>Suspended</option>
                        </select>
                    </div>
                    <div class="flex items-end">
                        <button type="submit" class="w-full palevel-gradient text-white px-4 py-2 rounded-md hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-green-500">
                            <i class="fas fa-search mr-2"></i>Search
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Landlords Table -->
    <div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Landlords List</h3>
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
// Landlords Management specific JavaScript functions

// Render function for landlords table
function renderLandlordsTable(data) {
    const landlords = data.landlords || [];
    const total = data.total || 0;
    
    if (landlords.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-building text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No landlords found</h3>
                <p class="text-gray-500">No landlords match your current filters.</p>
            </div>
        `;
    }
    
    return `
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Landlord</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Contact</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Properties</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Verification</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Joined</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${landlords.map(landlord => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0 h-10 w-10">
                                        <div class="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center">
                                            <span class="text-green-600 font-medium">${landlord.first_name ? landlord.first_name.charAt(0).toUpperCase() : 'L'}</span>
                                        </div>
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900">${landlord.first_name || ''} ${landlord.last_name || ''}</div>
                                        <div class="text-sm text-gray-500">ID: ${landlord.user_id || 'N/A'}</div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${landlord.email || 'N/A'}</div>
                                <div class="text-sm text-gray-500">${landlord.phone || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">
                                    <div>${landlord.hostel_count || 0} Total</div>
                                    <div class="text-green-600">${landlord.active_hostel_count || 0} Active</div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    landlord.status === 'active' ? 'bg-green-100 text-green-800' :
                                    landlord.status === 'inactive' ? 'bg-gray-100 text-gray-800' :
                                    landlord.status === 'suspended' ? 'bg-red-100 text-red-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${landlord.status ? landlord.status.charAt(0).toUpperCase() + landlord.status.slice(1) : 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    landlord.verification_status === 'approved' ? 'bg-green-100 text-green-800' :
                                    landlord.verification_status === 'rejected' ? 'bg-red-100 text-red-800' :
                                    landlord.verification_status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${landlord.verification_status ? landlord.verification_status.charAt(0).toUpperCase() + landlord.verification_status.slice(1) : 'Not Submitted'}
                                </span>
                                ${landlord.verification_status === 'pending' ? 
                                    `<a href="/admin/verifications" class="ml-2 text-blue-600 hover:text-blue-800 text-xs">
                                        <i class="fas fa-external-link-alt mr-1"></i>Verify
                                    </a>` : ''
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${landlord.created_at ? new Date(landlord.created_at).toLocaleDateString() : 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div class="flex space-x-2">
                                    <form method="POST" action="/admin/users/${landlord.user_id}/update-status" 
                                          onsubmit="return confirm('Are you sure you want to change this landlord\'s status?')">
                                        <input type="hidden" name="_token" value="${document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content')}">
                                        ${landlord.status === 'active' ? 
                                            '<input type="hidden" name="new_status" value="inactive"><button type="submit" class="text-yellow-600 hover:text-yellow-900" title="Deactivate"><i class="fas fa-pause"></i></button>' :
                                            '<input type="hidden" name="new_status" value="active"><button type="submit" class="text-green-600 hover:text-green-900" title="Activate"><i class="fas fa-play"></i></button>'
                                        }
                                    </form>
                                    <a href="/admin/hostels?landlord_id=${landlord.user_id}" 
                                       class="text-blue-600 hover:text-blue-900" title="View Properties">
                                        <i class="fas fa-building"></i>
                                    </a>
                                    <button class="text-green-600 hover:text-green-900" title="View Details">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
}

// Load landlords data function
function loadLandlordsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const page = urlParams.get('page') || '1';
    const search = urlParams.get('search') || '';
    const status = urlParams.get('status') || '';
    
    // Make actual API call to get landlords data
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/landlords?page=${page}&search=${search}&status=${status}`, {
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
        hideLoadingSpinner(container, data, renderLandlordsTable);
        
        // Update landlords count in header
        const countElement = document.getElementById('landlords-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = `${total} Landlord${total !== 1 ? 's' : ''}`;
        }
    })
    .catch(error => {
        console.error('Error loading landlords data:', error);
        const fallbackData = {'landlords': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderLandlordsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadLandlordsData();
});
</script>
@endpush
