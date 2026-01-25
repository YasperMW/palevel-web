<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="api-token" content="{{ session('palevel_token') }}">
    <title>@yield('title', 'Admin Dashboard') - Palevel</title>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script>
        // Fallback if CDN fails
        if (typeof jQuery === 'undefined') {
            document.write('<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"><\/script>');
        }
    </script>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/palevel-dialog.css') }}">
    <script src="{{ asset('js/palevel-dialog.js') }}" defer></script>
    <style>
        /* Palevel Theme Colors */
        :root {
            --palevel-primary: #2563eb;
            --palevel-primary-dark: #1d4ed8;
            --palevel-secondary: #10b981;
            --palevel-accent: #f59e0b;
            --palevel-danger: #ef4444;
            --palevel-sidebar-bg: #1e293b;
            --palevel-sidebar-hover: #334155;
            --palevel-sidebar-active: #3b82f6;
            --palevel-brand-blue: #0066cc;
            --palevel-brand-light: #4d94ff;
        }
        
        .palevel-gradient {
            background: linear-gradient(135deg, var(--palevel-brand-blue) 0%, var(--palevel-primary) 100%);
        }
        
        .palevel-gradient-alt {
            background: linear-gradient(135deg, var(--palevel-primary) 0%, var(--palevel-secondary) 100%);
        }
        
        .sidebar-item {
            transition: all 0.3s ease;
        }
        
        .sidebar-item:hover {
            background-color: var(--palevel-sidebar-hover);
            transform: translateX(4px);
        }
        
        .sidebar-item.active {
            background-color: var(--palevel-sidebar-active);
            border-left: 4px solid white;
        }
        
        .palevel-card {
            transition: all 0.3s ease;
        }
        
        .palevel-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body class="bg-gray-50 font-sans">
    <div class="flex h-screen">
        <!-- Sidebar -->
        <aside class="w-64 bg-slate-900 text-white flex flex-col">
            <!-- Logo -->
            <div class="p-6 border-b border-slate-700">
                <div class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-white rounded-lg flex items-center justify-center shadow-lg">
                        <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="Palevel" class="h-8 w-auto">
                    </div>
                    <div>
                        <h1 class="text-xl font-bold text-white">Palevel</h1>
                        <p class="text-xs text-slate-400">Admin Panel</p>
                    </div>
                </div>
            </div>
            
            <!-- Navigation -->
            <nav class="flex-1 p-4 space-y-2">
                <a href="{{ route('admin.dashboard') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                    <i class="fas fa-tachometer-alt w-5"></i>
                    <span>Dashboard</span>
                </a>
                
                <a href="{{ route('admin.students') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.students') ? 'active' : '' }}">
                    <i class="fas fa-graduation-cap w-5"></i>
                    <span>Students</span>
                </a>
                
                <a href="{{ route('admin.landlords') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.landlords') ? 'active' : '' }}">
                    <i class="fas fa-building w-5"></i>
                    <span>Landlords</span>
                </a>
                
                <!-- Verification sub-item under Landlords -->
                <a href="{{ route('admin.verifications') }}" 
                   class="sidebar-item flex items-center space-x-3 px-8 py-2 rounded-lg text-white text-sm {{ request()->routeIs('admin.verifications') ? 'active' : '' }}">
                    <i class="fas fa-shield-alt w-4"></i>
                    <span>Verifications</span>
                </a>
                
                <a href="{{ route('admin.hostels') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.hostels') ? 'active' : '' }}">
                    <i class="fas fa-home w-5"></i>
                    <span>Hostels</span>
                </a>
                
                <a href="{{ route('admin.bookings') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.bookings') ? 'active' : '' }}">
                    <i class="fas fa-calendar-check w-5"></i>
                    <span>Bookings</span>
                </a>
                
                <a href="{{ route('admin.payments') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.payments') ? 'active' : '' }}">
                    <i class="fas fa-money-bill-wave w-5"></i>
                    <span>Payments</span>
                </a>
                
                <!-- Disbursements sub-item under Payments -->
                <a href="{{ route('admin.disbursements') }}" 
                   class="sidebar-item flex items-center space-x-3 px-8 py-2 rounded-lg text-white text-sm {{ request()->routeIs('admin.disbursements') ? 'active' : '' }}">
                    <i class="fas fa-hand-holding-usd w-4"></i>
                    <span>Disbursements</span>
                </a>
                
                <a href="{{ route('admin.logs') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.logs') ? 'active' : '' }}">
                    <i class="fas fa-list-alt w-5"></i>
                    <span>System Logs</span>
                </a>
                
                <a href="{{ route('admin.config') }}" 
                   class="sidebar-item flex items-center space-x-3 px-4 py-3 rounded-lg text-white {{ request()->routeIs('admin.config') ? 'active' : '' }}">
                    <i class="fas fa-cog w-5"></i>
                    <span>Settings</span>
                </a>
            </nav>
            
            <!-- User Profile -->
            <div class="p-4 border-t border-slate-700">
                <div class="flex items-center space-x-3">
                    <!-- User Avatar with Initials -->
                    <div class="relative">
                        <div class="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg">
                            <span id="user-initials" class="text-white font-semibold text-sm">
                                <!-- Will be populated by JavaScript -->
                            </span>
                        </div>
                        <!-- Online Status Indicator -->
                        <div class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-slate-900 rounded-full"></div>
                    </div>
                    
                    <!-- User Info -->
                    <div class="flex-1 min-w-0">
                        <p id="user-name" class="text-sm font-medium text-white">
                            <!-- Will be populated by JavaScript -->
                        </p>
                        <p id="user-email" class="text-xs text-slate-400 truncate">
                            <!-- Will be populated by JavaScript -->
                        </p>
                    </div>
                    
                    <!-- Action Buttons -->
                    <div class="flex items-center space-x-1">
                        <!-- Profile Button -->
                        <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700 rounded-lg transition-all duration-200" 
                                title="View Profile" 
                                onclick="window.location.href='/profile'">
                            <i class="fas fa-user text-sm"></i>
                        </button>
                        
                        <!-- Logout Button -->
                        <form action="{{ route('logout') }}" method="POST" class="inline">
                            @csrf
                            <button type="submit" 
                                    class="p-2 text-slate-400 hover:text-red-400 hover:bg-slate-700 rounded-lg transition-all duration-200" 
                                    title="Logout">
                                <i class="fas fa-sign-out-alt text-sm"></i>
                            </button>
                        </form>
                    </div>
                </div>
                
                <!-- Admin Badge -->
                <div class="mt-3 pt-3 border-t border-slate-700">
                    <div class="flex justify-center">
                        <span class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-medium bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg">
                            <i class="fas fa-shield-alt mr-2"></i>System Administrator
                        </span>
                    </div>
                </div>
            </div>
        </aside>
        
        <!-- Main Content -->
        <main class="flex-1 overflow-y-auto">
            <!-- Top Bar -->
            <header class="bg-white shadow-sm border-b border-gray-200">
                <div class="px-6 py-4 flex items-center justify-between">
                    <div>
                        <h2 class="text-2xl font-bold text-gray-900">@yield('title', 'Admin Dashboard')</h2>
                        <p class="text-sm text-gray-500">@yield('subtitle', 'Platform administration')</p>
                    </div>
                    <div class="flex items-center space-x-4">
                        <!-- Notifications -->
                        <div class="relative">
                            <button class="text-gray-400 hover:text-gray-600">
                                <i class="fas fa-bell"></i>
                            </button>
                            <span class="absolute -top-1 -right-1 w-2 h-2 bg-red-500 rounded-full"></span>
                        </div>
                        
                        <!-- Back to Main Dashboard -->
                        <a href="{{ route('dashboard') }}" 
                           class="inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                            <i class="fas fa-arrow-left mr-2"></i>
                            Main Dashboard
                        </a>
                    </div>
                </div>
            </header>
            
            <!-- Page Content -->
            <div class="p-6">
                @if(session('success'))
                    <div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg mb-6 flex items-center">
                        <i class="fas fa-check-circle mr-2"></i>
                        {{ session('success') }}
                    </div>
                @endif
                
                @if(session('error'))
                    <div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg mb-6 flex items-center">
                        <i class="fas fa-exclamation-circle mr-2"></i>
                        {{ session('error') }}
                    </div>
                @endif
                
                @yield('content')
            </div>
        </main>
    </div>
    
    <script>
        // Active state management
        document.addEventListener('DOMContentLoaded', function() {
            const currentPath = window.location.pathname;
            const sidebarItems = document.querySelectorAll('.sidebar-item');
            
            sidebarItems.forEach(item => {
                if (item.getAttribute('href') === currentPath) {
                    item.classList.add('active');
                }
            });
        });

        // Make API base URL available to JavaScript
        const API_BASE_URL = '{{ config("services.api.base_url", "https://localhost:8000") }}';
        
        // Loading spinner functions
        function showLoadingSpinner(container) {
            container.innerHTML = `
                <div class="flex justify-center items-center py-12">
                    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                    <span class="ml-3 text-gray-600">Loading data...</span>
                </div>
            `;
        }

        function hideLoadingSpinner(container, data, templateFunction) {
            container.innerHTML = templateFunction(data);
        }

        // Load user details for footer
        function loadUserDetails() {
            const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');
            
            fetch(API_BASE_URL + '/admin/user-details', {
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
                if (data.error) {
                    console.error('Error loading user details:', data.error);
                    // Fallback to static display
                    document.getElementById('user-name').textContent = 'Admin User';
                    document.getElementById('user-email').textContent = 'admin@palevel.com';
                    document.getElementById('user-initials').textContent = 'AU';
                    return;
                }

                // Update user details in footer
                const firstName = data.first_name || 'Admin';
                const lastName = data.last_name || 'User';
                const email = data.email || 'admin@palevel.com';
                
                document.getElementById('user-name').textContent = `${firstName} ${lastName}`;
                document.getElementById('user-email').textContent = email;
                document.getElementById('user-initials').textContent = 
                    `${firstName.charAt(0).toUpperCase()}${lastName.charAt(0).toUpperCase()}`;
            })
            .catch(error => {
                console.error('Error fetching user details:', error);
                // Fallback to static display
                document.getElementById('user-name').textContent = 'Admin User';
                document.getElementById('user-email').textContent = 'admin@palevel.com';
                document.getElementById('user-initials').textContent = 'AU';
            });
        }

      



        // Initialize page loading based on current route
        document.addEventListener('DOMContentLoaded', function() {
            // Load user details for footer
            loadUserDetails();
            
            const path = window.location.pathname;
            
            if (path === '/admin/dashboard' || path === '/admin') {
                loadAdminStats();
            } else if (path === '/admin/students') {
                loadStudentsData();
            } else if (path === '/admin/landlords') {
                loadLandlordsData();
            } else if (path === '/admin/verifications') {
                loadVerificationsData();
            } else if (path === '/admin/disbursements') {
                loadDisbursementsData();
            } else if (path === '/admin/payments') {
                loadPaymentsData();
            } else if (path === '/admin/bookings') {
                loadBookingsData();
            } else if (path === '/admin/hostels') {
                loadHostelsData();
            } else if (path === '/admin/logs') {
                loadLogsData();
            }
        });

        // Re-load data when browser back/forward buttons are used
        window.addEventListener('popstate', function() {
            const path = window.location.pathname;
            
            if (path === '/admin/dashboard' || path === '/admin') {
                loadAdminStats();
            } else if (document.getElementById('data-container')) {
                // For pages with data-container, reload the appropriate data
                if (path.includes('/students')) {
                    loadStudentsData();
                } else if (path.includes('/landlords')) {
                    loadLandlordsData();
                } else if (path.includes('/verifications')) {
                    loadVerificationsData();
                } else if (path.includes('/disbursements')) {
                    loadDisbursementsData();
                } else if (path.includes('/payments')) {
                    loadPaymentsData();
                } else if (path.includes('/bookings')) {
                    loadBookingsData();
                } else if (path.includes('/hostels')) {
                    loadHostelsData();
                } else if (path.includes('/logs')) {
                    loadLogsData();
                }
            }
        });

        
        // Global AJAX error handling
        $(document).ajaxError(function(event, jqXHR) {
            if (jqXHR.status === 401) {
                // Unauthorized - redirect to login
                window.location.href = '/login';
            } else if (jqXHR.status === 403) {
                // Forbidden - show error
                PalevelDialog.error('You do not have permission to perform this action');
            } else if (jqXHR.status === 0) {
                // Network error or timeout
                PalevelDialog.error('Unable to connect to the server. Please check your connection.');
            } else if (jqXHR.status >= 500) {
                // Server error
                PalevelDialog.error('Server error occurred. Please try again later.');
            }
        });

        // Handle network errors for fetch API
        window.addEventListener('unhandledrejection', function(event) {
            if (event.reason && event.reason.message) {
                if (event.reason.message.includes('fetch')) {
                    PalevelDialog.error('Network error. Please check your connection and try again.');
                }
            }
        });

        // Add loading states to links
        document.addEventListener('DOMContentLoaded', function() {
            const links = document.querySelectorAll('a[href]');
            links.forEach(link => {
                link.addEventListener('click', function(e) {
                    const href = this.getAttribute('href');
                    if (href && href !== '#' && !href.startsWith('javascript:') && !href.startsWith('mailto:') && !href.startsWith('tel:')) {
                        // Add loading state
                        this.style.opacity = '0.7';
                        this.style.pointerEvents = 'none';
                        
                        // Reset after a timeout in case navigation fails
                        setTimeout(() => {
                            this.style.opacity = '';
                            this.style.pointerEvents = '';
                        }, 5000);
                    }
                });
            });
        });
    </script>
    
    <!-- Placeholder functions for page-specific scripts -->
    <script>
        // Placeholder functions that will be overridden by page-specific scripts
        function loadDisbursementsData() {
            // This function will be defined in the disbursements page
            console.log('loadDisbursementsData placeholder - should be overridden by page script');
        }
    </script>
    
    @include('partials.palevel-dialog')
    @stack('scripts')
</body>
</html>
