@extends('layouts.app')

@section('title', 'Landlord Dashboard')

@section('content')
<div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
    <!-- Branded Header -->
    <div class="bg-gradient-to-r from-green-600 to-green-700 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="h-12 w-auto">
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">Landlord Dashboard</h1>
                    <p class="text-green-100">Manage your hostels and track performance</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span class="text-white font-medium">Property Manager</span>
                </div>
            </div>
        </div>
    </div>

    @if(isset($error))
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {{ $error }}
        </div>
    @endif

    <!-- Stats Overview -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-green-100 rounded-md p-3">
                        <i class="fas fa-building text-green-600 text-xl"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Total Hostels</dt>
                            <dd class="text-lg font-semibold text-gray-900">{{ count($hostels ?? []) }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-blue-100 rounded-md p-3">
                        <i class="fas fa-door-open text-blue-600 text-xl"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Total Rooms</dt>
                            <dd class="text-lg font-semibold text-gray-900">{{ $stats['total_rooms'] ?? 0 }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-yellow-100 rounded-md p-3">
                        <i class="fas fa-calendar-check text-yellow-600 text-xl"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Active Bookings</dt>
                            <dd class="text-lg font-semibold text-gray-900">{{ $stats['active_bookings'] ?? 0 }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0 bg-purple-100 rounded-md p-3">
                        <i class="fas fa-money-bill-wave text-purple-600 text-xl"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Monthly Revenue</dt>
                            <dd class="text-lg font-semibold text-gray-900">MWK {{ number_format($stats['monthly_revenue'] ?? 0, 2) }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="bg-white shadow rounded-lg mb-8">
        <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Quick Actions</h3>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <a href="{{ route('landlord.hostels.create') }}" 
                   class="inline-flex items-center px-4 py-3 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    <i class="fas fa-plus mr-2"></i>
                    Add New Hostel
                </a>
                <a href="{{ route('hostels.index') }}" 
                   class="inline-flex items-center px-4 py-3 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    <i class="fas fa-list mr-2"></i>
                    View All Hostels
                </a>
                <button class="inline-flex items-center px-4 py-3 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    <i class="fas fa-chart-bar mr-2"></i>
                    View Reports
                </button>
            </div>
        </div>
    </div>

    <!-- Recent Hostels & Bookings -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Recent Hostels -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg leading-6 font-medium text-gray-900">Your Hostels</h3>
                    <a href="{{ route('hostels.index') }}" class="text-sm text-blue-600 hover:text-blue-500">View all</a>
                </div>
                
                @if(isset($hostels) && count($hostels) > 0)
                    <div class="space-y-4">
                        @foreach(array_slice($hostels, 0, 5) as $hostel)
                            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                <div class="flex-1">
                                    <h4 class="text-sm font-medium text-gray-900">{{ $hostel['name'] }}</h4>
                                    <p class="text-sm text-gray-500">{{ $hostel['address'] }}</p>
                                    <div class="flex items-center mt-1 space-x-4">
                                        <span class="text-xs text-gray-500">
                                            <i class="fas fa-door-open mr-1"></i>{{ $hostel['total_rooms'] ?? 0 }} rooms
                                        </span>
                                        <span class="text-xs text-gray-500">
                                            <i class="fas fa-map-marker-alt mr-1"></i>{{ $hostel['district'] }}
                                        </span>
                                    </div>
                                </div>
                                <div class="flex items-center space-x-2">
                                    @if($hostel['is_active'])
                                        <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">Active</span>
                                    @else
                                        <span class="px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800">Inactive</span>
                                    @endif
                                    <a href="{{ route('hostels.show', $hostel['hostel_id']) }}" 
                                       class="text-blue-600 hover:text-blue-800">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                </div>
                            </div>
                        @endforeach
                    </div>
                @else
                    <div class="text-center py-8">
                        <i class="fas fa-building text-gray-400 text-4xl mb-4"></i>
                        <p class="text-gray-500">No hostels yet</p>
                        <a href="{{ route('landlord.hostels.create') }}" class="mt-4 text-blue-600 hover:text-blue-500">
                            Add your first hostel
                        </a>
                    </div>
                @endif
            </div>
        </div>

        <!-- Recent Bookings -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg leading-6 font-medium text-gray-900">Recent Bookings</h3>
                    <a href="#" class="text-sm text-blue-600 hover:text-blue-500">View all</a>
                </div>
                
                @if(isset($bookings) && count($bookings) > 0)
                    <div class="space-y-4">
                        @foreach(array_slice($bookings, 0, 5) as $booking)
                            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                <div class="flex-1">
                                    <h4 class="text-sm font-medium text-gray-900">
                                        {{ $booking['student_name'] ?? 'Student' }}
                                    </h4>
                                    <p class="text-sm text-gray-500">{{ $booking['room_number'] ?? 'Room' }}</p>
                                    <div class="flex items-center mt-1 space-x-4">
                                        <span class="text-xs text-gray-500">
                                            {{ \Carbon\Carbon::parse($booking['start_date'])->format('M d') }} - 
                                            {{ \Carbon\Carbon::parse($booking['end_date'])->format('M d') }}
                                        </span>
                                        <span class="text-xs font-medium">
                                            MWK {{ number_format($booking['total_amount'], 2) }}
                                        </span>
                                    </div>
                                </div>
                                <div class="flex items-center space-x-2">
                                    <span class="px-2 py-1 text-xs font-semibold rounded-full 
                                        @if($booking['status'] === 'confirmed') bg-green-100 text-green-800
                                        @elseif($booking['status'] === 'pending') bg-yellow-100 text-yellow-800
                                        @else bg-red-100 text-red-800
                                        @endif">
                                        {{ ucfirst($booking['status']) }}
                                    </span>
                                </div>
                            </div>
                        @endforeach
                    </div>
                @else
                    <div class="text-center py-8">
                        <i class="fas fa-calendar text-gray-400 text-4xl mb-4"></i>
                        <p class="text-gray-500">No recent bookings</p>
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>
@endsection
