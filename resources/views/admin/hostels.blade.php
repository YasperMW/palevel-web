@extends('layouts.admin')

@section('title', 'Hostels Management')

@section('subtitle', 'Manage and monitor all hostel properties and listings')

@section('content')
<!-- Stats Overview -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Total Hostels</p>
                <p id="hostels-count" class="text-2xl font-bold text-gray-900">0</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-building text-blue-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Active Hostels</p>
                <p id="active-hostels-count" class="text-2xl font-bold text-green-600">0</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-check-circle text-green-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Total Rooms</p>
                <p id="total-rooms-count" class="text-2xl font-bold text-purple-600">0</p>
            </div>
            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-door-open text-purple-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Total Bookings</p>
                <p id="total-bookings-count" class="text-2xl font-bold text-orange-600">0</p>
            </div>
            <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-calendar-check text-orange-600"></i>
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
    <form method="GET" action="{{ route('admin.hostels') }}">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Search</label>
                <input type="text" name="search" value="{{ $search ?? '' }}" 
                       placeholder="Search by name, location, or landlord..."
                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                    <option value="">All Status</option>
                    <option value="active" {{ ($status ?? '') == 'active' ? 'selected' : '' }}>Active</option>
                    <option value="inactive" {{ ($status ?? '') == 'inactive' ? 'selected' : '' }}>Inactive</option>
                </select>
            </div>
            <div class="flex items-end">
                <button type="submit" class="w-full palevel-gradient text-white px-4 py-2 rounded-md hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <i class="fas fa-search mr-2"></i>Search
                </button>
            </div>
        </div>
    </form>
</div>

<!-- Hostels Table -->
<div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
    <div class="px-6 py-4 border-b border-gray-200">
        <h3 class="text-lg font-semibold text-gray-900">Hostels List</h3>
    </div>
    
    <!-- Data container for lazy loading -->
    <div id="data-container" class="min-h-[400px]">
        <!-- Loading spinner will be shown here initially -->
    </div>
</div>
@endsection

@push('scripts')
<script>
// Hostels Management specific JavaScript functions

// Render function for hostels table
function renderHostelsTable(data) {
    const hostels = data.hostels || [];
    const total = data.total || 0;
    
    if (hostels.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-building text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No hostels found</h3>
                <p class="text-gray-500">No hostels match your current filters.</p>
            </div>
        `;
    }
    
    return `
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hostel</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Landlord</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rooms</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Bookings</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${hostels.map(hostel => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0 h-10 w-10">
                                        <div class="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center">
                                            <span class="text-indigo-600 font-medium">${hostel.name ? hostel.name.charAt(0).toUpperCase() : 'H'}</span>
                                        </div>
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900">${hostel.name || 'N/A'}</div>
                                        <div class="text-sm text-gray-500">ID: ${hostel.hostel_id || 'N/A'}</div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                ${hostel.landlord ? 
                                    `<div class="text-sm text-gray-900">${hostel.landlord.first_name || ''} ${hostel.landlord.last_name || ''}</div>
                                     <div class="text-sm text-gray-500">${hostel.landlord.email || 'N/A'}</div>` :
                                    '<div class="text-sm text-gray-500">N/A</div>'
                                }
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${hostel.location || 'N/A'}</div>
                                <div class="text-sm text-gray-500">${hostel.university || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${hostel.room_count || 0} rooms</div>
                                <div class="text-sm text-gray-500">${hostel.available_rooms || 0} available</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${hostel.booking_count || 0} total</div>
                                <div class="text-sm text-gray-500">${hostel.active_booking_count || 0} active</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    hostel.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                                }">
                                    ${hostel.is_active ? 'Active' : 'Inactive'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div class="flex space-x-2">
                                    <button class="text-blue-600 hover:text-blue-900" title="View Details">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                    <button class="text-green-600 hover:text-green-900" title="Edit">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    ${hostel.is_active ? 
                                        `<button class="text-yellow-600 hover:text-yellow-900" title="Deactivate">
                                            <i class="fas fa-pause"></i>
                                        </button>` :
                                        `<button class="text-green-600 hover:text-green-900" title="Activate">
                                            <i class="fas fa-play"></i>
                                        </button>`
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

// Load hostels data function
function loadHostelsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const page = urlParams.get('page') || '1';
    const search = urlParams.get('search') || '';
    const status = urlParams.get('status') || '';
    
    // Make actual API call to get hostels data
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/hostels?page=${page}&search=${search}&status=${status}`, {
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
        hideLoadingSpinner(container, data, renderHostelsTable);
        
        // Update hostels count in header
        const countElement = document.getElementById('hostels-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = total;
        }
        
        // Update other statistics
        const hostels = data.hostels || [];
        const activeHostelsCount = hostels.filter(h => h.status === 'active').length;
        const totalRoomsCount = hostels.reduce((sum, h) => sum + (h.room_count || 0), 0);
        const totalBookingsCount = hostels.reduce((sum, h) => sum + (h.booking_count || 0), 0);
        
        const activeHostelsElement = document.getElementById('active-hostels-count');
        if (activeHostelsElement) {
            activeHostelsElement.textContent = activeHostelsCount;
        }
        
        const totalRoomsElement = document.getElementById('total-rooms-count');
        if (totalRoomsElement) {
            totalRoomsElement.textContent = totalRoomsCount;
        }
        
        const totalBookingsElement = document.getElementById('total-bookings-count');
        if (totalBookingsElement) {
            totalBookingsElement.textContent = totalBookingsCount;
        }
    })
    .catch(error => {
        console.error('Error loading hostels data:', error);
        const fallbackData = {'hostels': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderHostelsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadHostelsData();
});
</script>
@endpush
