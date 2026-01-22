@extends('layouts.app')

@section('title', 'Student Dashboard')

@section('content')
<div class="min-h-screen bg-gray-50">
    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        @if(isset($error))
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-6">
                {{ $error }}
            </div>
        @endif

        <!-- Search Section -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 mb-8">
            <div class="p-6">
                <h2 class="text-xl font-semibold text-gray-900 mb-6">Search Hostels</h2>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">University</label>
                        <select id="university-filter" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500">
                            <option value="All Universities">All Universities</option>
                            <option value="UNIMA">UNIMA</option>
                            <option value="MUST">MUST</option>
                            <option value="LUANAR">LUANAR</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">District</label>
                        <select id="district-filter" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500">
                            <option value="All Districts">All Districts</option>
                            <option value="Blantyre">Blantyre</option>
                            <option value="Lilongwe">Lilongwe</option>
                            <option value="Zomba">Zomba</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Price Range</label>
                        <select id="price-filter" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500">
                            <option value="Any Price">Any Price</option>
                            <option value="Under MWK 50,000">Under MWK 50,000</option>
                            <option value="MWK 50,000 - 100,000">MWK 50,000 - 100,000</option>
                            <option value="Over MWK 100,000">Over MWK 100,000</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Stats -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-teal-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">Available Hostels</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ $availableHostels ?? 0 }}</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-blue-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">My Bookings</p>
                        <p class="text-2xl font-semibold text-gray-900">{{ count($bookings ?? []) }}</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div class="flex items-center">
                    <div class="bg-purple-100 rounded-lg p-3">
                        <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                    </div>
                    <div class="ml-4">
                        <p class="text-sm font-medium text-gray-600">Total Spent</p>
                        <p class="text-2xl font-semibold text-gray-900">MWK {{ number_format($totalSpent ?? 0, 0) }}</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- My Bookings Section -->
        @php
            // Filter only confirmed bookings and limit to 3 most recent
            $confirmedBookings = collect($bookings ?? [])
                ->filter(fn($booking) => ($booking['status'] ?? '') === 'confirmed')
                ->take(3);
        @endphp
        
        @if($confirmedBookings->count() > 0)
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 mb-8">
                <div class="p-6">
                    <div class="flex items-center justify-between mb-6">
                        <h2 class="text-xl font-semibold text-gray-900">My Bookings</h2>
                        <a href="{{ route('student.bookings') }}" class="text-teal-600 hover:text-teal-700 text-sm font-medium">View All →</a>
                    </div>
                    <div class="space-y-4">
                        @foreach($confirmedBookings as $booking)
                            <div class="border border-gray-200 rounded-xl p-4 hover:shadow-md transition-shadow duration-200">
                                <div class="flex items-center justify-between">
                                    <div class="flex-1">
                                        <h4 class="text-lg font-medium text-gray-900">{{ $booking['hostel_name'] ?? 'Hostel' }}</h4>
                                        <p class="text-sm text-gray-600 mb-2">{{ $booking['room_number'] ?? 'Room' }}</p>
                                        <div class="flex items-center space-x-4 text-sm">
                                            <span class="text-gray-600">
                                                <svg class="w-4 h-4 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                                                </svg>
                                                {{ \Carbon\Carbon::parse($booking['start_date'] ?? $booking['check_in_date'] ?? $booking['checkInDate'] ?? 'now')->format('M d, Y') }} - 
                                                {{ \Carbon\Carbon::parse($booking['end_date'] ?? $booking['check_out_date'] ?? $booking['checkOutDate'] ?? 'now')->format('M d, Y') }}
                                            </span>
                                            <span class="font-semibold text-gray-900">
                                                MWK {{ number_format($booking['total_amount'] ?? 0, 0) }}
                                            </span>
                                        </div>
                                    </div>
                                    <div class="text-right">
                                        <span class="px-3 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                                            Confirmed
                                        </span>
                                        <div class="mt-2">
                                            <a href="{{ route('student.bookings') }}" class="text-teal-600 hover:text-teal-800 text-sm font-medium">
                                                View Details
                                            </a>
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
        <div class="bg-white rounded-xl shadow-sm border border-gray-200">
            <div class="p-6">
                <div class="flex items-center justify-between mb-6">
                    <div id="results-message">
                        <h2 class="text-xl font-semibold text-gray-900">Available Hostels</h2>
                    </div>
                </div>
                
                <div id="hostels-container">
                    @if(isset($hostels) && count($hostels) > 0)
                        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                            @foreach(array_slice($hostels, 0, 6) as $hostel)
                            <div class="border border-gray-200 rounded-xl overflow-hidden hover:shadow-lg transition-shadow duration-200">
                                <div class="relative">
                                    @php
                                        $coverImage = null;
                                        if (isset($hostel['media']) && is_array($hostel['media'])) {
                                            foreach ($hostel['media'] as $media) {
                                                if (isset($media['is_cover']) && $media['is_cover']) {
                                                    $coverImage = \App\Helpers\MediaHelper::getMediaUrl($media['url']);
                                                    break;
                                                }
                                            }
                                            if (!$coverImage && count($hostel['media']) > 0) {
                                                $coverImage = \App\Helpers\MediaHelper::getMediaUrl($hostel['media'][0]['url']);
                                            }
                                        }
                                    @endphp
                                    @if($coverImage)
                                        <img src="{{ $coverImage }}" alt="{{ $hostel['name'] }}" 
                                             class="w-full h-48 object-cover">
                                    @else
                                        <div class="w-full h-48 bg-gray-200 flex items-center justify-center">
                                            <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                                            </svg>
                                        </div>
                                    @endif
                                    <div class="absolute top-4 right-4">
                                        <span class="px-3 py-1 bg-teal-600 text-white text-xs font-bold rounded-full shadow-sm">
                                            {{ $hostel['type'] ?? 'Hostel' }}
                                        </span>
                                    </div>
                                </div>
                                
                                <div class="p-4">
                                    <div class="flex items-center justify-between mb-2">
                                        <h3 class="text-lg font-semibold text-gray-900 truncate">{{ $hostel['name'] }}</h3>
                                        @if($hostel['is_active'])
                                            <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">Available</span>
                                        @endif
                                    </div>
                                    
                                    <p class="text-sm text-gray-600 mb-3">{{ $hostel['address'] }}</p>
                                    
                                    <div class="flex items-center text-sm text-gray-500 mb-3">
                                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                        </svg>
                                        {{ $hostel['district'] }}
                                        <span class="mx-2">•</span>
                                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                                        </svg>
                                        {{ $hostel['university'] }}
                                    </div>
                                    
                                    <div class="flex items-center justify-between mb-4">
                                        <span class="text-lg font-bold text-teal-600">
                                            MWK {{ number_format($hostel['price_per_month'] ?? 0, 0) }}
                                            <span class="text-xs font-normal text-gray-500">/month</span>
                                        </span>
                                        <span class="text-sm text-gray-500">
                                            {{ $hostel['total_rooms'] ?? 0 }} rooms
                                        </span>
                                    </div>
                                    
                                    <div class="flex space-x-2">
                                        <a href="{{ route('hostels.show', $hostel['hostel_id']) }}" 
                                           class="flex-1 bg-teal-600 text-white text-center px-4 py-2 rounded-lg hover:bg-teal-700 text-sm font-medium transition-colors duration-200">
                                            View Details
                                        </a>
                                        <button class="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm transition-colors duration-200">
                                            <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path>
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        @endforeach
                        </div>
                    @else
                        <div class="text-center py-12">
                            <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                            </svg>
                            <p class="text-gray-500 text-lg">No hostels found</p>
                            <p class="text-gray-400 text-sm mt-2">Try adjusting your search criteria</p>
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </main>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const allHostels = @json($hostels ?? []);
    const universityFilter = document.getElementById('university-filter');
    const districtFilter = document.getElementById('district-filter');
    const priceFilter = document.getElementById('price-filter');
    const hostelsContainer = document.getElementById('hostels-container');
    const resultsMessage = document.getElementById('results-message');
    
    function filterHostels() {
        const university = universityFilter.value;
        const district = districtFilter.value;
        const priceRange = priceFilter.value;
        
        console.log('Filtering with:', { university, district, priceRange });
        console.log('Total hostels:', allHostels.length);
        
        let filteredHostels = allHostels.filter(hostel => {
            // Filter by university
            if (university !== 'All Universities') {
                const hostelUniversity = (hostel.university || '').toLowerCase().trim();
                const selectedUniversity = university.toLowerCase().trim();
                
                // More flexible matching - check if the selected university is contained in the hostel university string
                const isMatch = hostelUniversity === selectedUniversity || 
                               hostelUniversity.includes(selectedUniversity) || 
                               selectedUniversity.includes(hostelUniversity);
                
                console.log('University comparison:', {
                    selected: selectedUniversity,
                    hostel: hostelUniversity,
                    hostelRaw: hostel.university,
                    match: isMatch
                });
                
                if (!isMatch) {
                    return false;
                }
            }
            
            // Filter by district
            if (district !== 'All Districts') {
                const hostelDistrict = (hostel.district || '').toLowerCase().trim();
                const selectedDistrict = district.toLowerCase().trim();
                if (hostelDistrict !== selectedDistrict) {
                    return false;
                }
            }
            
            // Filter by price range
            if (priceRange !== 'Any Price') {
                const price = parseFloat(hostel.price_per_month || 0);
                switch(priceRange) {
                    case 'Under MWK 50,000':
                        if (price >= 50000) return false;
                        break;
                    case 'MWK 50,000 - 100,000':
                        if (price < 50000 || price > 100000) return false;
                        break;
                    case 'Over MWK 100,000':
                        if (price <= 100000) return false;
                        break;
                }
            }
            
            return true;
        });
        
        console.log('Filtered hostels count:', filteredHostels.length);
        displayHostels(filteredHostels);
        updateResultsMessage(filteredHostels, university, district, priceRange);
    }
    
    function displayHostels(hostels) {
        if (!hostelsContainer) return;
        
        if (hostels.length === 0) {
            hostelsContainer.innerHTML = `
                <div class="text-center py-12">
                    <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                    </svg>
                    <p class="text-gray-500 text-lg">No hostels found</p>
                    <p class="text-gray-400 text-sm mt-2">Try adjusting your search criteria</p>
                </div>
            `;
            return;
        }
        
        const hostelsHtml = hostels.slice(0, 6).map(hostel => {
            // Debug: log hostel data structure
            console.log('Hostel data:', hostel);
            console.log('Hostel keys:', Object.keys(hostel));
            
            // Try different possible ID fields
            const hostelId = hostel.hostel_id || hostel.id || hostel.hostelId;
            console.log('Using hostel ID:', hostelId);
            
            const coverImage = getCoverImage(hostel);
            const availabilityBadge = hostel.is_active ? 
                '<span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">Available</span>' : '';
            
            return `
                <div class="border border-gray-200 rounded-xl overflow-hidden hover:shadow-lg transition-shadow duration-200">
                    <div class="relative">
                        ${coverImage}
                        <div class="absolute top-4 right-4">
                            <span class="px-3 py-1 bg-teal-600 text-white text-xs font-bold rounded-full shadow-sm">
                                ${hostel.type || 'Hostel'}
                            </span>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="flex items-center justify-between mb-2">
                            <h3 class="text-lg font-semibold text-gray-900 truncate">${hostel.name}</h3>
                            ${availabilityBadge}
                        </div>
                        <p class="text-sm text-gray-600 mb-3">${hostel.address}</p>
                        <div class="flex items-center text-sm text-gray-500 mb-3">
                            <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            </svg>
                            ${hostel.district}
                            <span class="mx-2">•</span>
                            <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                            </svg>
                            ${hostel.university}
                        </div>
                        <div class="flex items-center justify-between mb-4">
                            <span class="text-lg font-bold text-teal-600">
                                MWK ${Number(hostel.price_per_month || 0).toLocaleString()}
                                <span class="text-xs font-normal text-gray-500">/month</span>
                            </span>
                            <span class="text-sm text-gray-500">
                                ${hostel.total_rooms || 0} rooms
                            </span>
                        </div>
                        <div class="flex space-x-2">
                            <a href="{{ route('hostels.show', ['id' => '__HOSTEL_ID__']) }}" 
                               class="flex-1 bg-teal-600 text-white text-center px-4 py-2 rounded-lg hover:bg-teal-700 text-sm font-medium transition-colors duration-200 hostel-detail-link"
                               data-hostel-id="${hostelId}">
                                View Details
                            </a>
                            <button class="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm transition-colors duration-200">
                                <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path>
                                </svg>
                            </button>
                        </div>
                    </div>
                </div>
            `;
        }).join('');
        
        hostelsContainer.innerHTML = `<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">${hostelsHtml}</div>`;
        
        // Update hostel detail links with correct IDs
        document.querySelectorAll('.hostel-detail-link').forEach(link => {
            const hostelId = link.getAttribute('data-hostel-id');
            console.log('Updating link for hostel ID:', hostelId);
            console.log('Original href:', link.href);
            link.href = link.href.replace('__HOSTEL_ID__', hostelId);
            console.log('Updated href:', link.href);
        });
    }
    
    function getCoverImage(hostel) {
        if (hostel.media && Array.isArray(hostel.media)) {
            const coverImage = hostel.media.find(media => media.is_cover) || hostel.media[0];
            if (coverImage && coverImage.url) {
                let imageUrl = coverImage.url;
                if (!imageUrl.startsWith('http')) {
                    // Ensure base URL doesn't have trailing slash and path starts with slash
                    const baseUrl = apiBaseUrl.replace(/\/$/, '');
                    const path = imageUrl.startsWith('/') ? imageUrl : '/' + imageUrl;
                    imageUrl = baseUrl + path;
                }
                return `<img src="${imageUrl}" alt="${hostel.name}" class="w-full h-48 object-cover">`;
            }
        }
        return `
            <div class="w-full h-48 bg-gray-200 flex items-center justify-center">
                <svg class="w-12 h-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                </svg>
            </div>
        `;
    }
    
    function updateResultsMessage(hostels, university, district, priceRange) {
        if (!resultsMessage) return;
        
        const hasFilters = university !== 'All Universities' || district !== 'All Districts' || priceRange !== 'Any Price';
        
        if (hasFilters) {
            resultsMessage.innerHTML = `
                <p class="text-sm text-gray-600 mt-1">
                    Found ${hostels.length} hostel${hostels.length !== 1 ? 's' : ''} matching your filters
                </p>
            `;
            resultsMessage.style.display = 'block';
        } else {
            resultsMessage.style.display = 'none';
        }
    }
    
    // Add event listeners
    if (universityFilter) {
        universityFilter.addEventListener('change', filterHostels);
        console.log('University filter listener added');
    } else {
        console.error('University filter element not found');
    }
    
    if (districtFilter) {
        districtFilter.addEventListener('change', filterHostels);
        console.log('District filter listener added');
    } else {
        console.error('District filter element not found');
    }
    
    if (priceFilter) {
        priceFilter.addEventListener('change', filterHostels);
        console.log('Price filter listener added');
    } else {
        console.error('Price filter element not found');
    }
    
    // Initialize display
    console.log('Initial hostel data:', allHostels);
    if (allHostels.length > 0) {
        console.log('Sample hostel:', allHostels[0]);
        console.log('Available universities:', [...new Set(allHostels.map(h => h.university).filter(Boolean))]);
    }
    filterHostels();
});
</script>
@endsection
