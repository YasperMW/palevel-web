@extends('layouts.admin')

@section('title', 'Admin Dashboard')

@section('subtitle', 'Platform administration and analytics')

@section('content')
<!-- Branded Header -->
<div class="palevel-gradient rounded-xl shadow-lg p-6 mb-8">
    <div class="flex items-center justify-between">
        <div class="flex items-center space-x-4">
            <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="Palevel" class="h-10 w-auto">
            </div>
            <div>
                <h1 class="text-3xl font-bold text-white">Admin Dashboard</h1>
                <p class="text-blue-100">Platform administration and analytics</p>
            </div>
        </div>
        <div class="hidden md:flex items-center space-x-2">
            <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                <span class="text-white font-medium">{{ now()->format('M d, Y') }}</span>
            </div>
        </div>
    </div>
</div>

<!-- Platform Stats Overview -->
<div id="stats-container">
    <!-- Stats will be loaded here via JavaScript -->
</div>

    <!-- Quick Actions -->
<div class="palevel-card bg-white rounded-xl shadow-lg p-6 mb-8">
    <div class="flex items-center justify-between mb-6">
        <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                <i class="fas fa-th-large text-blue-600 text-sm"></i>
            </div>
            <div>
                <h3 class="text-lg font-semibold text-gray-900">Quick Actions</h3>
                <p class="text-sm text-gray-500">Manage platform efficiently</p>
            </div>
        </div>
        <span class="px-3 py-1 bg-green-100 text-green-800 text-xs rounded-full">
            <i class="fas fa-bolt mr-1"></i>Fast Access
        </span>
    </div>
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <a href="{{ route('admin.students') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-blue-200 text-sm font-semibold rounded-lg shadow-sm text-blue-700 bg-blue-50 hover:border-blue-400 hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all">
            <i class="fas fa-graduation-cap mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Students</span>
        </a>
        <a href="{{ route('admin.landlords') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-green-200 text-sm font-semibold rounded-lg shadow-sm text-green-700 bg-green-50 hover:border-green-400 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-green-500 transition-all">
            <i class="fas fa-building mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Landlords</span>
        </a>
        <a href="{{ route('admin.payments') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-purple-200 text-sm font-semibold rounded-lg shadow-sm text-purple-700 bg-purple-50 hover:border-purple-400 hover:bg-purple-100 focus:outline-none focus:ring-2 focus:ring-purple-500 transition-all">
            <i class="fas fa-money-bill-wave mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Payments</span>
        </a>
        <a href="{{ route('admin.bookings') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-yellow-200 text-sm font-semibold rounded-lg shadow-sm text-yellow-700 bg-yellow-50 hover:border-yellow-400 hover:bg-yellow-100 focus:outline-none focus:ring-2 focus:ring-yellow-500 transition-all">
            <i class="fas fa-calendar-check mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Bookings</span>
        </a>
        <a href="{{ route('admin.hostels') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-indigo-200 text-sm font-semibold rounded-lg shadow-sm text-indigo-700 bg-indigo-50 hover:border-indigo-400 hover:bg-indigo-100 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all">
            <i class="fas fa-home mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Hostels</span>
        </a>
        <a href="{{ route('admin.logs') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-orange-200 text-sm font-semibold rounded-lg shadow-sm text-orange-700 bg-orange-50 hover:border-orange-400 hover:bg-orange-100 focus:outline-none focus:ring-2 focus:ring-orange-500 transition-all">
            <i class="fas fa-list-alt mr-2 group-hover:scale-110 transition-transform"></i>
            <span>System Logs</span>
        </a>
        <a href="{{ route('admin.config') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-gray-200 text-sm font-semibold rounded-lg shadow-sm text-gray-700 bg-gray-50 hover:border-gray-400 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-500 transition-all">
            <i class="fas fa-cog mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Settings</span>
        </a>
        <a href="{{ route('dashboard') }}" class="palevel-card group inline-flex items-center justify-center px-4 py-3 border-2 border-slate-200 text-sm font-semibold rounded-lg shadow-sm text-slate-700 bg-slate-50 hover:border-slate-400 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-slate-500 transition-all">
            <i class="fas fa-arrow-left mr-2 group-hover:scale-110 transition-transform"></i>
            <span>Main Dashboard</span>
        </a>
    </div>
</div>

    <!-- Recent Activity & Recent Signups -->
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
    <!-- Recent Activity -->
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Recent Activity</h3>
            <button onclick="loadRecentActivity()" class="text-blue-600 hover:text-blue-800 text-sm">
                <i class="fas fa-refresh mr-1"></i> Refresh
            </button>
        </div>
        <div id="recent-activity-container" class="space-y-4">
            <!-- Recent activity will be loaded here via JavaScript -->
        </div>
    </div>

    <!-- Recent Signups -->
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Recent Signups</h3>
            <button onclick="loadRecentSignups()" class="text-green-600 hover:text-green-800 text-sm">
                <i class="fas fa-refresh mr-1"></i> Refresh
            </button>
        </div>
        <div id="recent-signups-container" class="space-y-4">
            <!-- Recent signups will be loaded here via JavaScript -->
        </div>
    </div>
</div>

    <!-- System Status -->
    <div class="palevel-card bg-white rounded-xl shadow-lg p-6">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">System Status</h3>
            <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">All Systems Operational</span>
        </div>
        <div class="space-y-4">
            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <div class="w-3 h-3 bg-green-500 rounded-full mr-3"></div>
                    <span class="text-sm font-medium text-gray-900">API Server</span>
                </div>
                <span class="text-sm text-green-600">Operational</span>
            </div>
            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <div class="w-3 h-3 bg-green-500 rounded-full mr-3"></div>
                    <span class="text-sm font-medium text-gray-900">Database</span>
                </div>
                <span class="text-sm text-green-600">Healthy</span>
            </div>
            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <div class="w-3 h-3 bg-green-500 rounded-full mr-3"></div>
                    <span class="text-sm font-medium text-gray-900">File Storage</span>
                </div>
                <span class="text-sm text-green-600">Available</span>
            </div>
            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <div class="w-3 h-3 bg-yellow-500 rounded-full mr-3"></div>
                    <span class="text-sm font-medium text-gray-900">Email Service</span>
                </div>
                <span class="text-sm text-yellow-600">Delayed</span>
            </div>
        </div>
    </div>
</div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mt-8">
        <!-- User Distribution -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">User Distribution</h3>
                <div class="space-y-3">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <div class="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
                            <span class="text-sm text-gray-600">Tenants</span>
                        </div>
                        <span class="text-sm font-medium text-gray-900">65%</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <div class="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                            <span class="text-sm text-gray-600">Landlords</span>
                        </div>
                        <span class="text-sm font-medium text-gray-900">30%</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <div class="w-3 h-3 bg-purple-500 rounded-full mr-2"></div>
                            <span class="text-sm text-gray-600">Admins</span>
                        </div>
                        <span class="text-sm font-medium text-gray-900">5%</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Popular Universities -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Popular Universities</h3>
                <div class="space-y-3">
                    <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-600">UNIMA</span>
                        <span class="text-sm font-medium text-gray-900">45 hostels</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-600">MUST</span>
                        <span class="text-sm font-medium text-gray-900">32 hostels</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-600">LUANAR</span>
                        <span class="text-sm font-medium text-gray-900">28 hostels</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Recent Bookings -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Recent Bookings</h3>
                <div class="space-y-3">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm font-medium text-gray-900">Today</p>
                            <p class="text-xs text-gray-500">12 bookings</p>
                        </div>
                        <span class="text-sm text-green-600">+15%</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm font-medium text-gray-900">This Week</p>
                            <p class="text-xs text-gray-500">68 bookings</p>
                        </div>
                        <span class="text-sm text-green-600">+8%</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-sm font-medium text-gray-900">This Month</p>
                            <p class="text-xs text-gray-500">245 bookings</p>
                        </div>
                        <span class="text-sm text-green-600">+22%</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Admin Dashboard specific JavaScript functions

// Render function for admin stats
function renderAdminStats(stats) {
    return `
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div class="palevel-card bg-white rounded-xl shadow-lg p-6 border-l-4 border-blue-500">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500 mb-1">Total Users</p>
                        <p class="text-2xl font-bold text-gray-900">${stats.users.total || 0}</p>
                        <div class="flex items-center mt-2 text-xs text-gray-500">
                            <span class="text-blue-600 font-medium">${stats.users.students || 0} students</span>
                            <span class="mx-1">•</span>
                            <span class="text-green-600 font-medium">${stats.users.landlords || 0} landlords</span>
                        </div>
                    </div>
                    <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                        <i class="fas fa-users text-blue-600"></i>
                    </div>
                </div>
            </div>

            <div class="palevel-card bg-white rounded-xl shadow-lg p-6 border-l-4 border-green-500">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500 mb-1">Total Hostels</p>
                        <p class="text-2xl font-bold text-gray-900">${stats.properties.total_hostels || 0}</p>
                        <div class="flex items-center mt-2 text-xs text-gray-500">
                            <span class="text-green-600 font-medium">${stats.properties.active_hostels || 0} active</span>
                        </div>
                    </div>
                    <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                        <i class="fas fa-building text-green-600"></i>
                    </div>
                </div>
            </div>

            <div class="palevel-card bg-white rounded-xl shadow-lg p-6 border-l-4 border-yellow-500">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500 mb-1">Total Bookings</p>
                        <p class="text-2xl font-bold text-gray-900">${stats.bookings.total || 0}</p>
                        <div class="flex items-center mt-2 text-xs text-gray-500">
                            <span class="text-yellow-600 font-medium">${stats.bookings.pending || 0} pending</span>
                            <span class="mx-1">•</span>
                            <span class="text-green-600 font-medium">${stats.bookings.confirmed || 0} confirmed</span>
                        </div>
                    </div>
                    <div class="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                        <i class="fas fa-calendar-check text-yellow-600"></i>
                    </div>
                </div>
            </div>

            <div class="palevel-card bg-white rounded-xl shadow-lg p-6 border-l-4 border-purple-500">
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-gray-500 mb-1">Platform Revenue</p>
                        <p class="text-2xl font-bold text-gray-900">MWK ${Number(stats.payments.total_revenue || 0).toFixed(2)}</p>
                        <div class="flex items-center mt-2 text-xs text-gray-500">
                            <span class="text-purple-600 font-medium">${stats.payments.total_payments || 0} payments</span>
                        </div>
                    </div>
                    <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                        <i class="fas fa-money-bill-wave text-purple-600"></i>
                    </div>
                </div>
            </div>
        </div>
    `;
}

// Load admin stats function
function loadAdminStats() {
    const container = document.getElementById('stats-container');
    if (!container) return;
    
    showLoadingSpinner(container);
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(API_BASE_URL + '/admin/stats', {
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
        hideLoadingSpinner(container, data, renderAdminStats);
    })
    .catch(error => {
        console.error('Error loading admin stats:', error);
        const fallbackStats = {
            'users': {'total': 0, 'students': 0, 'landlords': 0, 'admins': 0},
            'properties': {'total_hostels': 0, 'active_hostels': 0, 'total_rooms': 0},
            'bookings': {'total': 0, 'pending': 0, 'confirmed': 0, 'cancelled': 0, 'recent': 0},
            'payments': {'total_payments': 0, 'total_revenue': 0, 'platform_fee': 0},
            'activity': {'recent_users': 0}
        };
        hideLoadingSpinner(container, fallbackStats, renderAdminStats);
    });
}

// Load recent activity function
function loadRecentActivity() {
    const container = document.getElementById('recent-activity-container');
    if (!container) return;
    
    container.innerHTML = '<div class="text-center py-4"><i class="fas fa-spinner fa-spin text-blue-600 text-2xl"></i><p class="text-sm text-gray-500 mt-2">Loading...</p></div>';
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(API_BASE_URL + '/admin/logs?limit=10', {
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
        renderRecentActivity(data.logs || []);
    })
    .catch(error => {
        console.error('Error loading recent activity:', error);
        container.innerHTML = '<div class="text-center py-4"><i class="fas fa-exclamation-triangle text-red-600 text-2xl"></i><p class="text-sm text-gray-500 mt-2">Failed to load activity</p></div>';
    });
}

// Load recent signups function
function loadRecentSignups() {
    const container = document.getElementById('recent-signups-container');
    if (!container) return;
    
    container.innerHTML = '<div class="text-center py-4"><i class="fas fa-spinner fa-spin text-green-600 text-2xl"></i><p class="text-sm text-gray-500 mt-2">Loading...</p></div>';
    
    const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
    
    fetch(API_BASE_URL + '/admin/students?limit=5&sort=created_at', {
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
        renderRecentSignups(data.students || []);
    })
    .catch(error => {
        console.error('Error loading recent signups:', error);
        container.innerHTML = '<div class="text-center py-4"><i class="fas fa-exclamation-triangle text-red-600 text-2xl"></i><p class="text-sm text-gray-500 mt-2">Failed to load signups</p></div>';
    });
}

// Render recent activity function
function renderRecentActivity(activities) {
    const container = document.getElementById('recent-activity-container');
    if (!container) return;
    
    if (activities.length === 0) {
        container.innerHTML = `
            <div class="text-center py-4">
                <i class="fas fa-list-alt text-gray-400 text-3xl mb-2"></i>
                <p class="text-sm text-gray-500">No recent activity</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = activities.map(activity => `
        <div class="flex items-start">
            <div class="flex-shrink-0">
                <div class="w-2 h-2 ${getActivityColor(activity.level || 'system')} rounded-full mt-2"></div>
            </div>
            <div class="ml-3">
                <p class="text-sm text-gray-900">${activity.action || 'System activity'}</p>
                <p class="text-xs text-gray-500">${activity.user_name || 'System'} • ${formatTimeAgo(activity.created_at)}</p>
            </div>
        </div>
    `).join('');
}

// Render recent signups function
function renderRecentSignups(signups) {
    const container = document.getElementById('recent-signups-container');
    if (!container) return;
    
    if (signups.length === 0) {
        container.innerHTML = `
            <div class="text-center py-4">
                <i class="fas fa-user-plus text-gray-400 text-3xl mb-2"></i>
                <p class="text-sm text-gray-500">No recent signups</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = signups.map(signup => `
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div class="flex items-center">
                <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mr-3">
                    <i class="fas fa-user text-blue-600 text-xs"></i>
                </div>
                <div>
                    <p class="text-sm font-medium text-gray-900">${signup.first_name} ${signup.last_name}</p>
                    <p class="text-xs text-gray-500">${signup.email}</p>
                </div>
            </div>
            <div class="text-right">
                <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">
                    ${signup.user_type}
                </span>
                <p class="text-xs text-gray-500 mt-1">${formatTimeAgo(signup.created_at)}</p>
            </div>
        </div>
    `).join('');
}

// Helper functions
function getActivityColor(level) {
    const colors = {
        'login': 'bg-green-500',
        'booking': 'bg-blue-500',
        'payment': 'bg-purple-500',
        'user_action': 'bg-yellow-500',
        'system': 'bg-gray-500'
    };
    return colors[level] || 'bg-gray-500';
}

function formatTimeAgo(dateString) {
    if (!dateString) return 'Unknown';
    
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now - date) / 1000);
    
    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return Math.floor(seconds / 60) + ' minutes ago';
    if (seconds < 86400) return Math.floor(seconds / 3600) + ' hours ago';
    if (seconds < 604800) return Math.floor(seconds / 86400) + ' days ago';
    
    return date.toLocaleDateString();
}

// Initialize lazy loading when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Load admin stats after page loads
    setTimeout(() => {
        loadAdminStats();
    }, 100);
});
</script>
@endsection
