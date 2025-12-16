<nav class="bg-white shadow-lg fixed top-0 left-0 right-0 z-50">
    <div class="max-w-7xl mx-auto px-4">
        <div class="flex justify-between h-16">
            <div class="flex items-center">
                <a href="{{ route('dashboard') }}" class="flex items-center space-x-2">
                    <img src="{{ asset('images/PaLevel Logo-Teal.png') }}" alt="PaLevel" class="h-8 w-auto">
                    <span class="font-bold text-xl text-gray-800">PaLevel</span>
                </a>
            </div>

            <div class="flex items-center space-x-4">
                <!-- User Type Badge -->
                <span class="px-3 py-1 text-xs font-semibold rounded-full 
                    @if($currentUser['user_type'] === 'admin') bg-purple-100 text-purple-800
                    @elseif($currentUser['user_type'] === 'landlord') bg-green-100 text-green-800
                    @else bg-blue-100 text-blue-800
                    @endif">
                    {{ ucfirst($currentUser['user_type']) }}
                </span>

                <!-- Navigation Links -->
                <div class="hidden md:flex items-center space-x-4">
                    @if($currentUser['user_type'] === 'admin')
                        <a href="{{ route('admin.dashboard') }}" class="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium">Dashboard</a>
                        <a href="{{ route('hostels.index') }}" class="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium">Hostels</a>
                    @elseif($currentUser['user_type'] === 'landlord')
                        <a href="{{ route('landlord.dashboard') }}" class="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium">Dashboard</a>
                        <a href="{{ route('hostels.index') }}" class="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium">My Hostels</a>
                        <a href="{{ route('landlord.hostels.create') }}" class="bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-blue-700">Add Hostel</a>
                    @else
                        <a href="{{ route('tenant.dashboard') }}" class="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium">Dashboard</a>
                        <a href="{{ route('hostels.index') }}" class="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium">Browse Hostels</a>
                    @endif
                </div>

                <!-- User Menu -->
                <div x-data="{ open: false }" class="relative">
                    <button @click="open = !open" class="flex items-center space-x-2 text-gray-700 hover:text-blue-600 focus:outline-none">
                        <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold">
                            {{ strtoupper(substr($currentUser['first_name'], 0, 1)) }}
                        </div>
                        <span class="hidden md:block text-sm font-medium">{{ $currentUser['first_name'] }} {{ $currentUser['last_name'] }}</span>
                        <i class="fas fa-chevron-down text-xs"></i>
                    </button>

                    <div x-show="open" @click.away="open = false" 
                         x-transition:enter="transition ease-out duration-200"
                         x-transition:enter-start="opacity-0 transform scale-95"
                         x-transition:enter-end="opacity-100 transform scale-100"
                         x-transition:leave="transition ease-in duration-75"
                         x-transition:leave-start="opacity-100 transform scale-100"
                         x-transition:leave-end="opacity-0 transform scale-95"
                         class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                        <a href="{{ route('profile') }}" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                            <i class="fas fa-user mr-2"></i>Profile
                        </a>
                        <form action="{{ route('logout') }}" method="POST" class="block">
                            @csrf
                            <button type="submit" class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                <i class="fas fa-sign-out-alt mr-2"></i>Logout
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Mobile menu button -->
                <div class="md:hidden">
                    <button x-data="{ open: false }" @click="open = !open" class="text-gray-700 hover:text-blue-600 focus:outline-none">
                        <i class="fas fa-bars text-xl"></i>
                    </button>
                </div>
            </div>
        </div>

        <!-- Mobile Navigation -->
        <div x-data="{ open: false }" x-show="open" @click.away="open = false" 
             x-transition:enter="transition ease-out duration-200"
             x-transition:enter-start="opacity-0 transform scale-95"
             x-transition:enter-end="opacity-100 transform scale-100"
             x-transition:leave="transition ease-in duration-75"
             x-transition:leave-start="opacity-100 transform scale-100"
             x-transition:leave-end="opacity-0 transform scale-95"
             class="md:hidden bg-white border-t border-gray-200">
            <div class="px-2 pt-2 pb-3 space-y-1">
                @if($currentUser['user_type'] === 'admin')
                    <a href="{{ route('admin.dashboard') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50">Dashboard</a>
                    <a href="{{ route('hostels.index') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50">Hostels</a>
                @elseif($currentUser['user_type'] === 'landlord')
                    <a href="{{ route('landlord.dashboard') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50">Dashboard</a>
                    <a href="{{ route('hostels.index') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50">My Hostels</a>
                    <a href="{{ route('landlord.hostels.create') }}" class="block px-3 py-2 rounded-md text-base font-medium text-white bg-blue-600 hover:bg-blue-700">Add Hostel</a>
                @else
                    <a href="{{ route('tenant.dashboard') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50">Dashboard</a>
                    <a href="{{ route('hostels.index') }}" class="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:text-blue-600 hover:bg-gray-50">Browse Hostels</a>
                @endif
            </div>
        </div>
    </div>
</nav>
