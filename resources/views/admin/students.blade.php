@extends('layouts.admin')

@section('title', 'Students Management')

@section('subtitle', 'Manage and monitor student accounts')

@section('content')
<!-- Stats Overview -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Total Students</p>
                <p id="students-count" class="text-2xl font-bold text-gray-900">0</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-users text-blue-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Active Students</p>
                <p class="text-2xl font-bold text-green-600">{{ collect($students ?? [])->where('status', 'active')->count() }}</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-check-circle text-green-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">New This Month</p>
                <p class="text-2xl font-bold text-purple-600">{{ collect($students ?? [])->where('created_at', '>=', now()->subMonth())->count() }}</p>
            </div>
            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-user-plus text-purple-600"></i>
            </div>
        </div>
    </div>
    
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 mb-1">Total Bookings</p>
                <p class="text-2xl font-bold text-orange-600">{{ collect($students ?? [])->sum('booking_count') }}</p>
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
        <form method="GET" action="{{ route('admin.students') }}">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Search</label>
                        <input type="text" name="search" value="{{ $search ?? '' }}" 
                               placeholder="Search by name, email, or phone..."
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
                        <select name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                            <option value="">All Status</option>
                            <option value="active" {{ ($status ?? '') == 'active' ? 'selected' : '' }}>Active</option>
                            <option value="inactive" {{ ($status ?? '') == 'inactive' ? 'selected' : '' }}>Inactive</option>
                            <option value="suspended" {{ ($status ?? '') == 'suspended' ? 'selected' : '' }}>Suspended</option>
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
    </div>

    <!-- Students Table -->
    <div class="palevel-card bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Students List</h3>
        </div>
        
        <!-- Data container for lazy loading -->
        <div id="data-container" class="min-h-[400px]">
            <!-- Loading spinner will be shown here initially -->
        </div>
    </div>
@endsection

@push('scripts')
<script>
// Students Management specific JavaScript functions

// Render function for students table
function renderStudentsTable(data) {
    const students = data.students || [];
    const total = data.total || 0;
    
    if (students.length === 0) {
        return `
            <div class="text-center py-12">
                <i class="fas fa-graduation-cap text-gray-400 text-5xl mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No students found</h3>
                <p class="text-gray-500">No students match your current filters.</p>
            </div>
        `;
    }
    
    return `
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Student</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Contact</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">University</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Bookings</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Joined</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    ${students.map(student => `
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0 h-10 w-10">
                                        <div class="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                                            <span class="text-blue-600 font-medium">${student.first_name ? student.first_name.charAt(0).toUpperCase() : 'S'}</span>
                                        </div>
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900">${student.first_name || ''} ${student.last_name || ''}</div>
                                        <div class="text-sm text-gray-500">ID: ${student.user_id || 'N/A'}</div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${student.email || 'N/A'}</div>
                                <div class="text-sm text-gray-500">${student.phone || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${student.university || 'N/A'}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900">${student.booking_count || 0}</div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                                    student.status === 'active' ? 'bg-green-100 text-green-800' :
                                    student.status === 'inactive' ? 'bg-gray-100 text-gray-800' :
                                    student.status === 'suspended' ? 'bg-red-100 text-red-800' :
                                    'bg-gray-100 text-gray-800'
                                }">
                                    ${student.status ? student.status.charAt(0).toUpperCase() + student.status.slice(1) : 'Unknown'}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                ${student.created_at ? new Date(student.created_at).toLocaleDateString() : 'N/A'}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div class="flex space-x-2">
                                    <form method="POST" action="/admin/users/${student.user_id}/update-status" 
                                          onsubmit="return confirm('Are you sure you want to change this student\'s status?')">
                                        <input type="hidden" name="_token" value="${document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content')}">
                                        ${student.status === 'active' ? 
                                            '<input type="hidden" name="new_status" value="inactive"><button type="submit" class="text-yellow-600 hover:text-yellow-900" title="Deactivate"><i class="fas fa-pause"></i></button>' :
                                            '<input type="hidden" name="new_status" value="active"><button type="submit" class="text-green-600 hover:text-green-900" title="Activate"><i class="fas fa-play"></i></button>'
                                        }
                                    </form>
                                    <button class="text-blue-600 hover:text-blue-900" title="View Details">
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

// Load students data function
function loadStudentsData() {
    const container = document.getElementById('data-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    // Get URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const page = urlParams.get('page') || '1';
    const search = urlParams.get('search') || '';
    const status = urlParams.get('status') || '';
    
    // Make actual API call to get students data
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(`${API_BASE_URL}/admin/students?page=${page}&search=${search}&status=${status}`, {
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
        hideLoadingSpinner(container, data, renderStudentsTable);
        
        // Update students count in header
        const countElement = document.getElementById('students-count');
        if (countElement) {
            const total = data.total || 0;
            countElement.textContent = total;
        }
    })
    .catch(error => {
        console.error('Error loading students data:', error);
        const fallbackData = {'students': [], 'total': 0};
        hideLoadingSpinner(container, fallbackData, renderStudentsTable);
    });
}

// Initialize page loading
document.addEventListener('DOMContentLoaded', function() {
    loadStudentsData();
});
</script>
@endpush
