@extends('layouts.app')

@section('title', 'Hostels')

@section('content')
<div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="mb-8 flex items-center justify-between">
        <div>
            <h1 class="text-3xl font-bold text-gray-900">Hostels</h1>
            <p class="mt-2 text-gray-600">Browse available accommodations</p>
        </div>
        @if($currentUser['user_type'] === 'landlord')
            <a href="{{ route('landlord.hostels.create') }}" 
               class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">
                <i class="fas fa-plus mr-2"></i>Add Hostel
            </a>
        @endif
    </div>

    @if(isset($error))
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            {{ $error }}
        </div>
    @endif

    <!-- Search and Filters -->
    <div class="bg-white shadow rounded-lg mb-8">
        <div class="px-6 py-4">
            <form class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Search</label>
                    <input type="text" placeholder="Search hostels..." 
                           class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                </div>
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
                <div class="flex items-end">
                    <button type="submit" class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <i class="fas fa-search mr-2"></i>Search
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Hostels Grid -->
    @if(isset($hostels) && count($hostels) > 0)
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            @foreach($hostels as $hostel)
                <div class="bg-white shadow rounded-lg overflow-hidden hover:shadow-lg transition-shadow duration-200">
                    <!-- Hostel Image -->
                    @if(isset($hostel['cover_image_url']))
                        <img src="{{ \App\Helpers\MediaHelper::getMediaUrl($hostel['cover_image_url']) }}" alt="{{ $hostel['name'] }}" 
                             class="w-full h-48 object-cover">
                    @else
                        <div class="w-full h-48 bg-gray-200 flex items-center justify-center">
                            <i class="fas fa-building text-gray-400 text-3xl"></i>
                        </div>
                    @endif
                    
                    <div class="p-4">
                        <!-- Hostel Header -->
                        <div class="flex items-center justify-between mb-2">
                            <h3 class="text-lg font-medium text-gray-900 truncate">{{ $hostel['name'] }}</h3>
                            <div class="flex items-center space-x-2">
                                @if($hostel['is_active'])
                                    <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">Active</span>
                                @else
                                    <span class="px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800">Inactive</span>
                                @endif
                            </div>
                        </div>
                        
                        <!-- Location Info -->
                        <div class="flex items-center text-sm text-gray-500 mb-2">
                            <i class="fas fa-map-marker-alt mr-1"></i>{{ $hostel['address'] }}
                        </div>
                        
                        <div class="flex items-center text-sm text-gray-500 mb-3">
                            <i class="fas fa-university mr-1"></i>{{ $hostel['university'] }}
                            <span class="mx-2">•</span>
                            <i class="fas fa-map-pin mr-1"></i>{{ $hostel['district'] }}
                        </div>
                        
                        <!-- Price and Rooms -->
                        <div class="flex items-center justify-between mb-3">
                            <div>
                                <span class="text-lg font-bold text-blue-600">
                                    MWK {{ number_format($hostel['price_per_month'] ?? 0, 0) }}
                                </span>
                                <span class="text-xs text-gray-500">/month</span>
                            </div>
                            <span class="text-sm text-gray-500">
                                {{ $hostel['total_rooms'] ?? 0 }} rooms
                            </span>
                        </div>
                        
                        <!-- Hostel Type -->
                        <div class="flex items-center text-sm text-gray-600 mb-3">
                            <i class="fas fa-home mr-1"></i>{{ ucfirst($hostel['type']) }}
                        </div>
                        
                        <!-- Amenities (if available) -->
                        @if(isset($hostel['amenities']) && is_array($hostel['amenities']))
                            <div class="flex flex-wrap gap-1 mb-3">
                                @foreach(array_slice($hostel['amenities'], 0, 3) as $amenity)
                                    <span class="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded">{{ $amenity }}</span>
                                @endforeach
                                @if(count($hostel['amenities']) > 3)
                                    <span class="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded">+{{ count($hostel['amenities']) - 3 }}</span>
                                @endif
                            </div>
                        @endif
                        
                        <!-- Actions -->
                        <div class="flex space-x-2">
                            <a href="{{ route('hostels.show', $hostel['hostel_id']) }}" 
                               class="flex-1 bg-blue-600 text-white text-center px-3 py-2 rounded-md hover:bg-blue-700 text-sm font-medium">
                                View Details
                            </a>
                            <a href="{{ route('hostels.rooms', $hostel['hostel_id']) }}" 
                               class="px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-sm">
                                <i class="fas fa-door-open"></i>
                            </a>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    @else
        <div class="text-center py-12">
            <i class="fas fa-building text-gray-400 text-4xl mb-4"></i>
            <p class="text-gray-500 text-lg">No hostels found</p>
            <p class="text-gray-400 text-sm mt-2">Try adjusting your search criteria</p>
            @if($currentUser['user_type'] === 'landlord')
                <a href="{{ route('landlord.hostels.create') }}" class="mt-4 text-blue-600 hover:text-blue-500">
                    Add your first hostel
                </a>
            @endif
        </div>
    @endif
</div>
@endsection
