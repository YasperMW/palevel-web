@php
    $currentUser = Session::get('palevel_user');
    $userDetails = Session::get('palevel_user_details', $currentUser); // Fallback to basic user data
    $userType = $userDetails['user_type'] ?? $currentUser['user_type'] ?? 'user';

    // Helper function for active classes (Closure distinct from global scope issues)
    $navClass = function($active) {
        return $active 
            ? 'inline-flex items-center px-4 py-2 rounded-full text-sm font-semibold text-teal-700 bg-teal-50 border border-teal-100 shadow-sm transition-all duration-200'
            : 'inline-flex items-center px-4 py-2 rounded-full text-sm font-medium text-gray-500 hover:text-teal-600 hover:bg-gray-50 transition-all duration-200 hover:shadow-sm';
    };
    
    $mobileNavClass = function($active) {
        return $active
            ? 'block px-3 py-2 rounded-md text-base font-medium text-teal-700 bg-teal-50 border-l-4 border-teal-600'
            : 'block px-3 py-2 rounded-md text-base font-medium text-gray-600 hover:text-teal-600 hover:bg-teal-50 hover:border-l-4 hover:border-teal-300';
    };
@endphp

<!-- Modern Unified Navigation -->
<nav x-data="{ mobileMenuOpen: false, userDropdownOpen: false }" class="fixed top-0 left-0 right-0 z-50 bg-white/90 backdrop-filter backdrop-blur-md border-b border-gray-100 shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            
            <!-- Logo Area -->
            <div class="flex items-center">
                <a href="{{ route('landing') }}" class="flex-shrink-0 flex items-center gap-3 group">
                    <div class="w-10 h-10 bg-gradient-to-br from-teal-500 to-teal-600 rounded-xl flex items-center justify-center text-white shadow-lg group-hover:shadow-teal-500/30 transition-all duration-300">
                        <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="h-6 w-auto" onerror="this.style.display='none'; this.nextElementSibling.style.display='block'">
                        <span class="text-lg font-bold hidden">P</span>
                    </div>
                    <span class="font-bold text-xl tracking-tight text-gray-900 group-hover:text-teal-600 transition-colors duration-300">
                        PaLevel
                        <span class="text-xs font-medium text-teal-500 bg-teal-50 px-2 py-0.5 rounded-full ml-1 border border-teal-100">
                            {{ ucfirst($userType) }}
                        </span>
                    </span>
                </a>
            </div>

            <!-- Desktop Navigation Links -->
            <div class="hidden md:flex md:items-center md:space-x-1">
                @if($userType === 'admin')
                    <a href="{{ route('admin.dashboard') }}" class="{{ $navClass(request()->routeIs('admin.dashboard')) }}">Dashboard</a>
                    <a href="{{ route('admin.students') }}" class="{{ $navClass(request()->routeIs('admin.students')) }}">Students</a>
                    <a href="{{ route('admin.landlords') }}" class="{{ $navClass(request()->routeIs('admin.landlords')) }}">Landlords</a>
                    <a href="{{ route('admin.hostels') }}" class="{{ $navClass(request()->routeIs('admin.hostels')) }}">Hostels</a>
                
                @elseif($userType === 'landlord')
                    <a href="{{ route('landlord.dashboard') }}" class="{{ $navClass(request()->routeIs('landlord.dashboard')) }}">Dashboard</a>
                    <a href="{{ route('hostels.index') }}" class="{{ $navClass(request()->routeIs('hostels.index')) }}">My Hostels</a>
                    <a href="{{ route('landlord.bookings') }}" class="{{ $navClass(request()->routeIs('landlord.bookings')) }}">Bookings</a>
                    <a href="{{ route('landlord.payments') }}" class="{{ $navClass(request()->routeIs('landlord.payments')) }}">Payments</a>
                    <!-- Create Action -->
                    <a href="{{ route('landlord.hostels.create') }}" class="ml-4 px-4 py-2 rounded-full bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 hover:shadow-lg hover:shadow-teal-500/30 transition-all duration-300 flex items-center gap-2 transform hover:-translate-y-0.5">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                        Add Hostel
                    </a>

                @else
                    <!-- Student/Tenant -->
                    <a href="{{ route('student.home') }}" class="{{ $navClass(request()->routeIs('student.home')) }}">Home</a>
                    <a href="{{ route('student.bookings') }}" class="{{ $navClass(request()->routeIs('student.bookings')) }}">My Bookings</a>
                @endif
            </div>

            <!-- Right Actions (Notifications & User) -->
            <div class="hidden md:flex items-center space-x-3">
                <!-- Notifications -->
                <button class="p-2 rounded-full text-gray-400 hover:text-teal-600 hover:bg-teal-50 transition-all duration-200 relative group">
                    <span class="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white"></span>
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                </button>

                <!-- Profile Dropdown -->
                <div class="relative" @click.away="userDropdownOpen = false">
                    <button @click="userDropdownOpen = !userDropdownOpen" class="flex items-center gap-3 pl-2 pr-1 py-1 rounded-full hover:bg-gray-50 border border-transparent hover:border-gray-200 transition-all duration-200">
                        <span class="text-sm font-medium text-gray-700 hidden lg:block">
                            {{ $userDetails['first_name'] ?? 'User' }}
                        </span>
                        <div class="h-8 w-8 rounded-full bg-gradient-to-r from-teal-500 to-teal-400 p-0.5 shadow-sm">
                            <div class="h-full w-full rounded-full bg-white flex items-center justify-center text-teal-600 font-bold text-xs uppercase overflow-hidden">
                                {{ substr($userDetails['first_name'] ?? 'U', 0, 1) }}
                            </div>
                        </div>
                        <svg class="w-4 h-4 text-gray-400 transition-transform duration-200" :class="{'rotate-180': userDropdownOpen}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
                    </button>

                    <!-- Dropdown Menu -->
                    <div x-show="userDropdownOpen" 
                         x-transition:enter="transition ease-out duration-200"
                         x-transition:enter-start="opacity-0 translateY-2"
                         x-transition:enter-end="opacity-100 translateY-0"
                         x-transition:leave="transition ease-in duration-150"
                         x-transition:leave-start="opacity-100 translateY-0"
                         x-transition:leave-end="opacity-0 translateY-2"
                         class="absolute right-0 mt-2 w-64 bg-white rounded-2xl shadow-xl border border-gray-100 py-2 ring-1 ring-black ring-opacity-5 origin-top-right overflow-hidden"
                         style="display: none;">
                        
                        <div class="px-6 py-4 border-b border-gray-50 bg-gray-50/50">
                            <p class="text-sm text-gray-500">Signed in as</p>
                            <p class="text-sm font-bold text-gray-900 truncate">{{ $userDetails['email'] ?? 'user@example.com' }}</p>
                            <p class="text-xs text-teal-600 font-medium mt-1">{{ ucfirst($userType) }} Account</p>
                        </div>

                        <div class="py-2">
                            <a href="{{ route('profile') }}" class="flex items-center px-6 py-3 text-sm text-gray-700 hover:bg-teal-50 hover:text-teal-700 transition-colors">
                                <svg class="w-5 h-5 mr-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                                Profile Settings
                            </a>
                            <a href="#" class="flex items-center px-6 py-3 text-sm text-gray-700 hover:bg-teal-50 hover:text-teal-700 transition-colors">
                                <svg class="w-5 h-5 mr-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/></svg>
                                Preferences
                            </a>
                        </div>

                        <div class="border-t border-gray-100 py-2">
                             <form action="{{ route('logout') }}" method="POST">
                                @csrf
                                <button type="submit" class="flex w-full items-center px-6 py-3 text-sm text-red-600 hover:bg-red-50 hover:text-red-700 transition-colors">
                                    <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                                    Sign out
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Mobile Menu Button -->
            <div class="flex items-center md:hidden">
                <button @click="mobileMenuOpen = !mobileMenuOpen" class="inline-flex items-center justify-center p-2 rounded-md text-gray-500 hover:text-teal-600 hover:bg-teal-50 focus:outline-none transition-colors">
                    <svg class="h-6 w-6" :class="{'hidden': mobileMenuOpen, 'block': !mobileMenuOpen}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
                    <svg class="h-6 w-6" :class="{'block': mobileMenuOpen, 'hidden': !mobileMenuOpen}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
        </div>
    </div>

    <!-- Mobile Menu -->
    <div x-show="mobileMenuOpen" 
         x-transition:enter="transition ease-out duration-200"
         x-transition:enter-start="opacity-0 -translate-y-2"
         x-transition:enter-end="opacity-100 translate-y-0"
         x-transition:leave="transition ease-in duration-150"
         x-transition:leave-start="opacity-100 translate-y-0"
         x-transition:leave-end="opacity-0 -translate-y-2"
         class="md:hidden bg-white border-b border-gray-200 overflow-hidden shadow-lg"
         style="display: none;">
        
        <div class="px-2 pt-2 pb-3 space-y-1">
             @if($userType === 'admin')
                <a href="{{ route('admin.dashboard') }}" class="{{ $mobileNavClass(request()->routeIs('admin.dashboard')) }}">Dashboard</a>
                <a href="{{ route('admin.students') }}" class="{{ $mobileNavClass(request()->routeIs('admin.students')) }}">Students</a>
                <a href="{{ route('admin.landlords') }}" class="{{ $mobileNavClass(request()->routeIs('admin.landlords')) }}">Landlords</a>
            
            @elseif($userType === 'landlord')
                <a href="{{ route('landlord.dashboard') }}" class="{{ $mobileNavClass(request()->routeIs('landlord.dashboard')) }}">Dashboard</a>
                <a href="{{ route('hostels.index') }}" class="{{ $mobileNavClass(request()->routeIs('hostels.index')) }}">My Hostels</a>
                <a href="{{ route('landlord.bookings') }}" class="{{ $mobileNavClass(request()->routeIs('landlord.bookings')) }}">Bookings</a>
                <a href="{{ route('landlord.hostels.create') }}" class="block px-3 py-2 rounded-md text-base font-bold text-teal-700 bg-teal-50 border-l-4 border-teal-600">Add Hostel</a>

            @else
                <a href="{{ route('student.home') }}" class="{{ $mobileNavClass(request()->routeIs('student.home')) }}">Home</a>
                <a href="{{ route('student.bookings') }}" class="{{ $mobileNavClass(request()->routeIs('student.bookings')) }}">My Bookings</a>
            @endif
        </div>

        <div class="pt-4 pb-4 border-t border-gray-100 bg-gray-50/50">
            <div class="flex items-center px-4">
                <div class="flex-shrink-0">
                    <div class="h-10 w-10 rounded-full bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-lg">
                        {{ substr($userDetails['first_name'] ?? 'U', 0, 1) }}
                    </div>
                </div>
                <div class="ml-3">
                    <div class="text-base font-medium text-gray-800">{{ $userDetails['first_name'] ?? 'User' }} {{ $userDetails['last_name'] ?? '' }}</div>
                    <div class="text-sm font-medium text-gray-500">{{ $userDetails['email'] ?? '' }}</div>
                </div>
            </div>
            <div class="mt-3 px-2 space-y-1">
                <a href="{{ route('profile') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-600 hover:text-teal-600 hover:bg-teal-50">Your Profile</a>
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="w-full text-left block px-3 py-2 rounded-md text-base font-medium text-red-600 hover:bg-red-50">Sign out</button>
                </form>
            </div>
        </div>
    </div>
</nav>
