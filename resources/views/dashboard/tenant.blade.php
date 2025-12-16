@extends('layouts.app')

@section('title', 'Tenant Dashboard')

@section('content')
<div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
    <!-- Branded Header -->
    <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl shadow-lg p-6 mb-8">
        <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <div class="bg-white/10 backdrop-blur-sm rounded-lg p-3">
                    <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="h-12 w-auto">
                </div>
                <div>
                    <h1 class="text-3xl font-bold text-white">Tenant Dashboard</h1>
                    <p class="text-blue-100">Find your perfect accommodation</p>
                </div>
            </div>
            <div class="hidden md:flex items-center space-x-2">
                <div class="bg-white/20 backdrop-blur-sm rounded-lg px-4 py-2">
                    <span class="text-white font-medium">Student Portal</span>
                </div>
            </div>
        </div>
    </div>

    @if(isset($error))
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {{ $error }}
        </div>
    @endif

    <!-- Search Section -->
    <div class="bg-white shadow rounded-lg mb-8">
        <div class="px-6 py-4">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Search Hostels</h3>
            <form class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">University</label>
                    <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                        <option>All Universities</option>
                        <option>UNIMA</option>
                        <option>MUST</option>
                        <option>LUANAR</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">District</label>
                    <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                        <option>All Districts</option>
                        <option>Blantyre</option>
                        <option>Lilongwe</option>
                        <option>Zomba</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Price Range</label>
                    <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                        <option>Any Price</option>
                        <option>Under MWK 50,000</option>
                        <option>MWK 50,000 - 100,000</option>
                        <option>Over MWK 100,000</option>
                    </select>
                </div>
                <div class="flex items-end">
                    <button type="submit" class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <i class="fas fa-search mr-2"></i>Search
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- My Bookings -->
    @if(isset($bookings) && count($bookings) > 0)
        <div class="bg-white shadow rounded-lg mb-8">
            <div class="px-6 py-4">
                <h3 class="text-lg font-medium text-gray-900 mb-4">My Bookings</h3>
                <div class="space-y-4">
                    @foreach($bookings as $booking)
                        <div class="border border-gray-200 rounded-lg p-4">
                            <div class="flex items-center justify-between">
                                <div>
                                    <h4 class="text-md font-medium text-gray-900">{{ $booking['hostel_name'] ?? 'Hostel' }}</h4>
                                    <p class="text-sm text-gray-500">{{ $booking['room_number'] ?? 'Room' }}</p>
                                    <div class="flex items-center mt-2 space-x-4">
                                        <span class="text-sm text-gray-600">
                                            <i class="fas fa-calendar mr-1"></i>
                                            {{ \Carbon\Carbon::parse($booking['start_date'])->format('M d, Y') }} - 
                                            {{ \Carbon\Carbon::parse($booking['end_date'])->format('M d, Y') }}
                                        </span>
                                        <span class="text-sm font-medium text-gray-900">
                                            MWK {{ number_format($booking['total_amount'], 2) }}
                                        </span>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <span class="px-3 py-1 text-xs font-semibold rounded-full 
                                        @if($booking['status'] === 'confirmed') bg-green-100 text-green-800
                                        @elseif($booking['status'] === 'pending') bg-yellow-100 text-yellow-800
                                        @else bg-red-100 text-red-800
                                        @endif">
                                        {{ ucfirst($booking['status']) }}
                                    </span>
                                    <div class="mt-2 space-x-2">
                                        <button class="text-blue-600 hover:text-blue-800 text-sm">
                                            <i class="fas fa-eye mr-1"></i>View
                                        </button>
                                        @if($booking['status'] === 'pending')
                                            <button class="text-red-600 hover:text-red-800 text-sm">
                                                <i class="fas fa-times mr-1"></i>Cancel
                                            </button>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    @endif

    <!-- Available Hostels -->
    <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-medium text-gray-900">Available Hostels</h3>
                <span class="text-sm text-gray-500">{{ count($hostels ?? []) }} hostels found</span>
            </div>
            
            @if(isset($hostels) && count($hostels) > 0)
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    @foreach($hostels as $hostel)
                        <div class="border border-gray-200 rounded-lg overflow-hidden hover:shadow-lg transition-shadow duration-200">
                            @if(isset($hostel['cover_image_url']))
                                <img src="{{ $hostel['cover_image_url'] }}" alt="{{ $hostel['name'] }}" 
                                     class="w-full h-48 object-cover">
                            @else
                                <div class="w-full h-48 bg-gray-200 flex items-center justify-center">
                                    <i class="fas fa-building text-gray-400 text-3xl"></i>
                                </div>
                            @endif
                            
                            <div class="p-4">
                                <div class="flex items-center justify-between mb-2">
                                    <h4 class="text-lg font-medium text-gray-900 truncate">{{ $hostel['name'] }}</h4>
                                    @if($hostel['is_active'])
                                        <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">Available</span>
                                    @endif
                                </div>
                                
                                <p class="text-sm text-gray-600 mb-2">{{ $hostel['address'] }}</p>
                                
                                <div class="flex items-center text-sm text-gray-500 mb-3">
                                    <i class="fas fa-map-marker-alt mr-1"></i>{{ $hostel['district'] }}
                                    <span class="mx-2">•</span>
                                    <i class="fas fa-university mr-1"></i>{{ $hostel['university'] }}
                                </div>
                                
                                <div class="flex items-center justify-between mb-3">
                                    <span class="text-lg font-bold text-blue-600">
                                        MWK {{ number_format($hostel['price_per_month'] ?? 0, 0) }}
                                        <span class="text-xs font-normal text-gray-500">/month</span>
                                    </span>
                                    <span class="text-sm text-gray-500">
                                        {{ $hostel['total_rooms'] ?? 0 }} rooms
                                    </span>
                                </div>
                                
                                <div class="flex items-center text-sm text-gray-600 mb-3">
                                    <i class="fas fa-home mr-1"></i>{{ ucfirst($hostel['type']) }}
                                </div>
                                
                                <div class="flex space-x-2">
                                    <a href="{{ route('hostels.show', $hostel['hostel_id']) }}" 
                                       class="flex-1 bg-blue-600 text-white text-center px-3 py-2 rounded-md hover:bg-blue-700 text-sm font-medium">
                                        View Details
                                    </a>
                                    <button class="px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-sm">
                                        <i class="fas fa-heart text-red-500"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            @else
                <div class="text-center py-12">
                    <i class="fas fa-search text-gray-400 text-4xl mb-4"></i>
                    <p class="text-gray-500 text-lg">No hostels found</p>
                    <p class="text-gray-400 text-sm mt-2">Try adjusting your search criteria</p>
                </div>
            @endif
        </div>
    </div>

    <!-- Notifications -->
    @if(isset($notifications) && count($notifications) > 0)
        <div class="bg-white shadow rounded-lg mt-8">
            <div class="px-6 py-4">
                <h3 class="text-lg font-medium text-gray-900 mb-4">Recent Notifications</h3>
                <div class="space-y-3">
                    @foreach(array_slice($notifications, 0, 5) as $notification)
                        <div class="flex items-start p-3 bg-gray-50 rounded-lg @if(!$notification['is_read']) border-l-4 border-blue-500 @endif">
                            <div class="flex-shrink-0">
                                <i class="fas fa-bell text-blue-500 mt-1"></i>
                            </div>
                            <div class="ml-3 flex-1">
                                <p class="text-sm text-gray-900">{{ $notification['title'] ?? 'Notification' }}</p>
                                <p class="text-xs text-gray-500 mt-1">{{ \Carbon\Carbon::parse($notification['created_at'])->diffForHumans() }}</p>
                            </div>
                            @if(!$notification['is_read'])
                                <span class="w-2 h-2 bg-blue-500 rounded-full"></span>
                            @endif
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    @endif
</div>
@endsection
