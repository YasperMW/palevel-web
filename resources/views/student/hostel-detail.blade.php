@extends('layouts.app')

@section('title', $hostel['name'] ?? 'Hostel Details')

@php
function generateStars($rating) {
    $stars = '';
    for ($i = 1; $i <= 5; $i++) {
        if ($i <= floor($rating)) {
            $stars .= '<svg class="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>';
        } elseif ($i - 0.5 <= $rating) {
            $stars .= '<svg class="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>';
        } else {
            $stars .= '<svg class="w-4 h-4 text-gray-300" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>';
        }
    }
    return $stars;
}

function formatDate($dateString) {
    $date = new \DateTime($dateString);
    $now = new \DateTime();
    $diff = $date->diff($now);
    
    if ($diff->days == 1) return '1 day ago';
    if ($diff->days < 7) return $diff->days . ' days ago';
    if ($diff->days < 30) return floor($diff->days / 7) . ' week' . (floor($diff->days / 7) > 1 ? 's' : '') . ' ago';
    if ($diff->days < 365) return floor($diff->days / 30) . ' month' . (floor($diff->days / 30) > 1 ? 's' : '') . ' ago';
    return floor($diff->days / 365) . ' year' . (floor($diff->days / 365) > 1 ? 's' : '') . ' ago';
}
@endphp

@section('content')
<div class="min-h-screen bg-gray-50">
    <!-- Hero Section with Images -->
    <div class="relative h-96 bg-gradient-to-br from-teal-600 to-teal-800">
        @php
            $coverImage = null;
            if (isset($hostel['media']) && is_array($hostel['media']) && count($hostel['media']) > 0) {
                foreach ($hostel['media'] as $media) {
                    // Check for is_cover flag (loose check for true/1)
                    $isCover = isset($media['is_cover']) && filter_var($media['is_cover'], FILTER_VALIDATE_BOOLEAN);
                    
                    if ($isCover) {
                        $coverImage = \App\Helpers\MediaHelper::getMediaUrl($media['url']);
                        break;
                    }
                }
                
                // Fallback: If no image is marked as cover (e.g. single image), use the first one
                if (!$coverImage) {
                    $coverImage = \App\Helpers\MediaHelper::getMediaUrl($hostel['media'][0]['url']);
                }
            }
        @endphp
        
        @if($coverImage)
            <img src="{{ $coverImage }}" alt="{{ $hostel['name'] }}" 
                 class="w-full h-full object-cover">
            <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
        @else
            <div class="w-full h-full flex items-center justify-center">
                <svg class="w-24 h-24 text-white/30" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                </svg>
            </div>
        @endif
        
        <!-- Back Button -->
        <div class="absolute top-4 left-4">
            <a href="{{ url()->previous() }}" 
               class="inline-flex items-center px-4 py-2 bg-white/20 backdrop-blur-sm text-white rounded-lg hover:bg-white/30 transition-colors duration-200">
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
                </svg>
                Back
            </a>
        </div>
        
        <!-- Share Button -->
        <div class="absolute top-4 right-4">
            <button onclick="shareHostel()" 
                    class="inline-flex items-center px-4 py-2 bg-white/20 backdrop-blur-sm text-white rounded-lg hover:bg-white/30 transition-colors duration-200">
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.026a3 3 0 10-4.732 2.684m4.732-2.684a3 3 0 00-4.732-2.684M3 12a3 3 0 104.732 2.684M3 12a3 3 0 014.732-2.684"></path>
                </svg>
                Share
            </button>
        </div>
        
        <!-- Hostel Title Overlay -->
        @if($coverImage)
        <div class="absolute bottom-0 left-0 right-0 p-8">
            <div class="max-w-4xl mx-auto">
                <h1 class="text-4xl font-bold text-white mb-2">{{ $hostel['name'] ?? 'Hostel' }}</h1>
                <div class="flex items-center text-white/90">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                    {{ $hostel['address'] ?? '' }}
                </div>
            </div>
        </div>
        @endif
    </div>

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Main Content (2/3 width) -->
            <div class="lg:col-span-2 space-y-8">
                <!-- Price and Basic Info -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <div class="flex items-center justify-between mb-6">
                        <div>
                            <div class="flex items-baseline">
                                <span class="text-3xl font-bold text-teal-600">MWK {{ number_format($hostel['price_per_month'] ?? 0, 0) }}</span>
                                <span class="text-gray-500 ml-2">/month</span>
                            </div>
                            <p class="text-sm text-gray-600 mt-1">{{ $hostel['type'] ?? 'Hostel' }}</p>
                        </div>
                        @if($hostel['is_active'] ?? false)
                            <span class="px-4 py-2 bg-green-100 text-green-800 text-sm font-semibold rounded-full">Available</span>
                        @else
                            <span class="px-4 py-2 bg-red-100 text-red-800 text-sm font-semibold rounded-full">Not Available</span>
                        @endif
                    </div>
                    
                    <!-- Quick Stats -->
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div class="text-center p-3 bg-gray-50 rounded-lg">
                            <div class="text-2xl font-bold text-gray-900">{{ $totalRooms }}</div>
                            <div class="text-xs text-gray-600">Total Rooms</div>
                        </div>
                        <div class="text-center p-3 bg-gray-50 rounded-lg">
                            <div class="text-2xl font-bold text-teal-600">{{ $availableRooms }}</div>
                            <div class="text-xs text-gray-600">Available</div>
                        </div>
                        <div class="text-center p-3 bg-gray-50 rounded-lg">
                            <div class="text-2xl font-bold text-yellow-600">{{ number_format($averageRating, 1) }}</div>
                            <div class="text-xs text-gray-600">Rating</div>
                        </div>
                        <div class="text-center p-3 bg-gray-50 rounded-lg">
                            <div class="text-2xl font-bold text-blue-600">{{ $totalReviews }}</div>
                            <div class="text-xs text-gray-600">Reviews</div>
                        </div>
                    </div>
                </div>

                <!-- Description -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h2 class="text-xl font-semibold text-gray-900 mb-4">Description</h2>
                    <p class="text-gray-700 leading-relaxed">{{ $hostel['description'] ?? 'No description available.' }}</p>
                </div>

                <!-- Amenities -->
                @if(isset($hostel['amenities']) && (is_array($hostel['amenities']) || is_object($hostel['amenities'])))
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h2 class="text-xl font-semibold text-gray-900 mb-4">Amenities</h2>
                    <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                        @foreach($hostel['amenities'] as $key => $value)
                            @if($value)
                            <div class="flex items-center p-3 bg-teal-50 rounded-lg border border-teal-200">
                                <svg class="w-5 h-5 text-teal-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                                </svg>
                                <span class="text-sm font-medium text-teal-900">{{ is_string($key) ? $key : $value }}</span>
                            </div>
                            @endif
                        @endforeach
                    </div>
                </div>
                @endif

                <!-- Available Rooms -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h2 class="text-xl font-semibold text-gray-900 mb-4">Available Rooms</h2>
                    <div id="rooms-container">
                        @if(count($rooms) > 0)
                            <div class="space-y-6">
                                @foreach($rooms as $room)
                                <div class="bg-white rounded-xl border border-gray-200 shadow-md hover:shadow-lg transition-all duration-300 overflow-hidden">
                                    <!-- Room Image Section -->
                                    <div class="relative h-48 bg-gradient-to-br from-teal-50 to-teal-100">
                                        @php
                                            $roomImage = null;
                                            if (isset($room['media']) && is_array($room['media'])) {
                                                foreach ($room['media'] as $media) {
                                                    if (isset($media['type']) && $media['type'] == 'image') {
                                                        $roomImage = $media['url'];
                                                        break;
                                                    }
                                                }
                                            }
                                            if (!$roomImage && isset($room['image_url'])) {
                                                $roomImage = $room['image_url'];
                                            }
                                        @endphp
                                        
                                        @if($roomImage)
                                            <img src="{{ \App\Helpers\MediaHelper::getMediaUrl($roomImage) }}" alt="Room {{ $room['room_number'] ?? '' }}" 
                                                 class="w-full h-full object-cover">
                                        @else
                                            <div class="w-full h-full flex items-center justify-center">
                                                <svg class="w-16 h-16 text-teal-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                                                </svg>
                                            </div>
                                        @endif
                                        
                                        <!-- Room Type Badge -->
                                        <div class="absolute top-3 right-3">
                                            <span class="px-3 py-1 bg-white/90 backdrop-blur-sm text-teal-700 text-xs font-semibold rounded-full border border-teal-200">
                                                {{ $room['room_type'] ?? 'Standard' }}
                                            </span>
                                        </div>
                                    </div>

                                    <!-- Video Section -->
                                    @php
                                        $hasVideo = false;
                                        $videoUrl = null;
                                        if (isset($room['media']) && is_array($room['media'])) {
                                            foreach ($room['media'] as $media) {
                                                if (isset($media['type']) && $media['type'] == 'video') {
                                                    $hasVideo = true;
                                                    $videoUrl = \App\Helpers\MediaHelper::getMediaUrl($media['url']);
                                                    break;
                                                }
                                            }
                                        }
                                    @endphp
                                    
                                    @if($hasVideo && $videoUrl)
                                    <div class="px-6 pt-4">
                                        <div class="relative bg-black rounded-lg overflow-hidden" style="padding-bottom: 56.25%;">
                                            <video 
                                                class="absolute top-0 left-0 w-full h-full object-cover"
                                                controls
                                                preload="metadata"
                                                poster="{{ \App\Helpers\MediaHelper::getMediaUrl($roomImage) ?? 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=400' }}">
                                                <source src="{{ $videoUrl }}" type="video/mp4">
                                                <source src="{{ $videoUrl }}" type="video/webm">
                                                Your browser does not support the video tag.
                                            </video>
                                            <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
                                                <div class="bg-white/20 backdrop-blur-sm rounded-full p-3">
                                                    <svg class="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 24 24">
                                                        <path d="M8 5v14l11-7z"/>
                                                    </svg>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    @endif

                                    <!-- Room Details -->
                                    <div class="p-6">
                                        <div class="flex items-start justify-between mb-4">
                                            <div>
                                                <h3 class="text-xl font-bold text-gray-900 mb-2">Room {{ $room['room_number'] ?? '' }}</h3>
                                                <div class="space-y-1">
                                                    <p class="text-sm text-gray-600">
                                                Capacity: {{ $room['capacity'] ?? 1 }} person{{ ($room['capacity'] ?? 1) != 1 ? 's' : '' }}
                                                    </p>
                                                    @if(isset($room['booking_fee']) && $room['booking_fee'] > 0)
                                                    <p class="text-sm text-gray-600">Booking Fee: MWK {{ number_format($room['booking_fee'], 2) }}</p>
                                                    @endif
                                                </div>
                                            </div>
                                            <div class="text-right">
                                                <div class="text-2xl font-bold text-teal-600">MWK {{ number_format($room['price_per_month'] ?? 0) }}</div>
                                                <div class="text-sm text-gray-500">/month</div>
                                            </div>
                                        </div>

                                        <!-- Availability Status -->
                                        <div class="mb-4">
                                            @if(($room['occupants'] ?? 0) < ($room['capacity'] ?? 1))
                                                <div class="inline-flex items-center px-3 py-1 bg-green-50 border border-green-200 rounded-full">
                                                    <svg class="w-4 h-4 text-green-600 mr-2" fill="currentColor" viewBox="0 0 20 20">
                                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                                                    </svg>
                                                    <span class="text-sm font-medium text-green-800">Available</span>
                                                </div>
                                            @else
                                                <div class="inline-flex items-center px-3 py-1 bg-red-50 border border-red-200 rounded-full">
                                                    <svg class="w-4 h-4 text-red-600 mr-2" fill="currentColor" viewBox="0 0 20 20">
                                                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
                                                    </svg>
                                                    <span class="text-sm font-medium text-red-800">Occupied</span>
                                                </div>
                                            @endif
                                        </div>

                                        <!-- Action Buttons -->
                                        <div class="flex space-x-3">
                                            <button onclick="openBookingModal({{ json_encode($room) }}, {{ json_encode($hostel) }})" 
                                                    @if(($room['occupants'] ?? 0) >= ($room['capacity'] ?? 1)) disabled @endif
                                                    class="w-full bg-teal-600 text-white px-4 py-3 rounded-lg hover:bg-teal-700 font-medium transition-colors duration-200 disabled:bg-gray-300 disabled:cursor-not-allowed">
                                                Book This Room
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                @endforeach
                            </div>
                        @else
                            <div class="text-center py-12 text-gray-500">
                                <svg class="w-16 h-16 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
                                </svg>
                                <p class="text-lg font-medium">No rooms available at the moment</p>
                                <p class="text-sm mt-2">Check back later or contact the landlord for more information</p>
                            </div>
                        @endif
                    </div>
                </div>

                <!-- Reviews Section -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6" 
                     x-data="{
                         showReviews: true,
                         filter: 'Newest',
                         reviews: {{ json_encode($reviews) }},
                         get sortedReviews() {
                             return this.reviews.sort((a, b) => {
                                 let dateA = new Date(a.created_at);
                                 let dateB = new Date(b.created_at);
                                 let ratingA = a.rating || 0;
                                 let ratingB = b.rating || 0;
                                 
                                 switch(this.filter) {
                                     case 'Oldest': return dateA - dateB;
                                     case 'Highest rating': return ratingB - ratingA;
                                     case 'Lowest rating': return ratingA - ratingB;
                                     case 'Newest': 
                                     default: return dateB - dateA;
                                 }
                             });
                         },
                         formatDate(dateString) {
                             const date = new Date(dateString);
                             const now = new Date();
                             const diffTime = Math.abs(now - date);
                             const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                             
                             if (diffDays === 1) return '1 day ago';
                             if (diffDays < 7) return diffDays + ' days ago';
                             if (diffDays < 30) return Math.floor(diffDays / 7) + ' week' + (Math.floor(diffDays / 7) > 1 ? 's' : '') + ' ago';
                             if (diffDays < 365) return Math.floor(diffDays / 30) + ' month' + (Math.floor(diffDays / 30) > 1 ? 's' : '') + ' ago';
                             return Math.floor(diffDays / 365) + ' year' + (Math.floor(diffDays / 365) > 1 ? 's' : '') + ' ago';
                         }
                     }">
                    <div class="flex items-center justify-between mb-6 cursor-pointer" @click="showReviews = !showReviews">
                        <div class="flex items-center">
                            <h2 class="text-xl font-semibold text-gray-900">Reviews & Ratings</h2>
                            <svg class="w-5 h-5 text-gray-500 ml-2 transform transition-transform duration-200" 
                                 :class="{'rotate-180': showReviews}"
                                 fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                            </svg>
                        </div>
                        @if(auth()->check())
                        <button @click.stop="showReviewForm()" 
                                class="text-teal-600 hover:text-teal-700 text-sm font-medium">
                            Write a Review
                        </button>
                        @endif
                    </div>
                    
                    <div x-show="showReviews" x-transition>
                        @if(count($reviews) > 0)
                            <div class="bg-gray-50 rounded-lg p-4 mb-6">
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center">
                                        <div class="text-3xl font-bold text-gray-900">{{ number_format($averageRating, 1) }}</div>
                                        <div class="ml-3">
                                            <div class="flex items-center">
                                                @for($i = 1; $i <= 5; $i++)
                                                    @if($i <= floor($averageRating))
                                                        <svg class="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                                                    @else
                                                        <svg class="w-4 h-4 text-gray-300" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                                                    @endif
                                                @endfor
                                            </div>
                                            <p class="text-sm text-gray-600">{{ $totalReviews }} review{{ $totalReviews != 1 ? 's' : '' }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Filter Chips -->
                            <div class="flex flex-wrap gap-2 mb-6">
                                <template x-for="f in ['Newest', 'Oldest', 'Highest rating', 'Lowest rating']">
                                    <button @click="filter = f"
                                            class="px-3 py-1 rounded-full text-sm font-medium transition-colors duration-200 border"
                                            :class="filter === f ? 'bg-teal-600 text-white border-teal-600' : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'">
                                        <span x-text="f"></span>
                                    </button>
                                </template>
                            </div>
                            
                            <div class="space-y-4">
                                <template x-for="review in sortedReviews" :key="review.review_id || review.created_at">
                                <div class="border border-gray-200 rounded-lg p-4">
                                    <div class="flex items-start justify-between">
                                        <div class="flex items-start">
                                            <div class="w-10 h-10 bg-teal-100 rounded-full flex items-center justify-center">
                                                <span class="text-teal-600 font-semibold" x-text="(review.student_name || 'S')[0]">
                                                </span>
                                            </div>
                                            <div class="ml-3">
                                                <div class="flex items-center">
                                                    <h4 class="font-semibold text-gray-900" x-text="review.student_name || 'Student'"></h4>
                                                    <div class="flex items-center ml-2">
                                                        <span class="text-amber-600 font-bold text-sm mr-1" x-text="review.rating"></span>
                                                        <svg class="w-4 h-4 text-amber-600" fill="currentColor" viewBox="0 0 20 20">
                                                            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path>
                                                        </svg>
                                                    </div>
                                                </div>
                                                <p class="text-sm text-gray-600 mt-1" x-text="formatDate(review.created_at)">
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                    <p class="mt-3 text-gray-700" x-text="review.comment" x-show="review.comment"></p>
                                </div>
                                </template>
                            </div>
                        @else
                            <div class="text-center py-8 text-gray-500">
                                <svg class="w-12 h-12 mx-auto mb-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"></path>
                                </svg>
                                <p>No reviews yet. Be the first to review this hostel!</p>
                            </div>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Sidebar (1/3 width) -->
            <div class="space-y-6">
                <!-- Location -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Location</h3>
                    <div class="space-y-3">
                        <div class="flex items-start">
                            <svg class="w-5 h-5 text-gray-400 mt-0.5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                            </svg>
                            <div>
                                <p class="text-sm font-medium text-gray-900">Address</p>
                                <p class="text-sm text-gray-600">{{ $hostel['address'] ?? 'N/A' }}</p>
                            </div>
                        </div>
                        <div class="flex items-start">
                            <svg class="w-5 h-5 text-gray-400 mt-0.5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                            </svg>
                            <div>
                                <p class="text-sm font-medium text-gray-900">District</p>
                                <p class="text-sm text-gray-600">{{ $hostel['district'] ?? 'N/A' }}</p>
                            </div>
                        </div>
                        <div class="flex items-start">
                            <svg class="w-5 h-5 text-gray-400 mt-0.5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                            </svg>
                            <div>
                                <p class="text-sm font-medium text-gray-900">University</p>
                                <p class="text-sm text-gray-600">{{ $hostel['university'] ?? 'N/A' }}</p>
                            </div>
                        </div>
                    </div>
                    
                    @if(isset($hostel['latitude']) && isset($hostel['longitude']))
                    <button onclick="showMap()" 
                            class="w-full mt-4 bg-teal-600 text-white px-4 py-2 rounded-lg hover:bg-teal-700 text-sm font-medium transition-colors duration-200">
                        View on Map
                    </button>
                    @endif
                </div>

                <!-- Landlord Information -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Landlord Information</h3>
                    <div id="landlord-container">
                        <div class="text-center py-4">
                            <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-teal-600 mb-2"></div>
                            <p class="text-gray-500 text-sm">Loading landlord info...</p>
                        </div>
                    </div>
                </div>

                <!-- Booking Actions -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Ready to Book?</h3>
                    <button onclick="bookNow()" 
                            class="w-full bg-teal-600 text-white px-4 py-3 rounded-lg hover:bg-teal-700 font-medium transition-colors duration-200">
                        Book This Hostel
                    </button>
                    <button onclick="scheduleTour()" 
                            class="w-full mt-3 border border-gray-300 text-gray-700 px-4 py-3 rounded-lg hover:bg-gray-50 font-medium transition-colors duration-200">
                        Schedule a Tour
                    </button>
                    <button onclick="addToFavorites()" 
                            class="w-full mt-3 text-teal-600 hover:text-teal-700 font-medium">
                        <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path>
                        </svg>
                        Add to Favorites
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Booking Confirmation Dialog -->
<div id="bookingConfirmationDialog" class="fixed inset-0 bg-black bg-opacity-50 hidden items-center justify-center z-50">
    <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div class="p-6">
            <!-- Header -->
            <div class="flex items-center justify-between mb-6">
                <h3 class="text-xl font-bold text-gray-900">Confirm Booking</h3>
                <button onclick="closeConfirmationDialog()" class="text-gray-400 hover:text-gray-600 transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>

            <!-- Booking Details -->
            <div class="space-y-4 mb-6">
                <div class="bg-gray-50 rounded-lg p-4">
                    <h4 class="font-semibold text-gray-900 mb-3">Booking Details</h4>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between">
                            <span class="text-gray-600">Hostel:</span>
                            <span class="font-medium text-gray-900" id="confirmHostelName">-</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-600">Room:</span>
                            <span class="font-medium text-gray-900" id="confirmRoomDetails">-</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-600">Duration:</span>
                            <span class="font-medium text-gray-900" id="confirmDuration">-</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-600">Start Date:</span>
                            <span class="font-medium text-gray-900" id="confirmStartDate">-</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-600">Payment Type:</span>
                            <span class="font-medium text-gray-900" id="confirmPaymentType">-</span>
                        </div>
                    </div>
                </div>

                <!-- Payment Summary -->
                <div class="bg-teal-50 rounded-lg p-4 border border-teal-200">
                    <h4 class="font-semibold text-teal-900 mb-3">Payment Summary</h4>
                    <div class="space-y-2 text-sm">
                        <div class="flex justify-between">
                            <span class="text-teal-700" id="confirmBaseAmountLabel">Booking Fee:</span>
                            <span class="font-medium text-teal-900" id="confirmBaseAmount">-</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-teal-700">Platform Fee:</span>
                            <span class="font-medium text-teal-900" id="confirmPlatformFee">-</span>
                        </div>
                        <div class="border-t border-teal-300 pt-2 mt-2">
                            <div class="flex justify-between">
                                <span class="font-semibold text-teal-900">Total Amount:</span>
                                <span class="font-bold text-teal-900 text-lg" id="confirmTotalAmount">-</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex space-x-3">
                <button onclick="backToBookingDialog()" 
                        class="flex-1 px-4 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium transition-colors duration-200">
                    Back to Edit
                </button>
                <button onclick="confirmFinalBooking()" 
                        class="flex-1 px-4 py-3 bg-gradient-to-r from-teal-600 to-teal-700 text-white rounded-lg hover:from-teal-700 hover:to-teal-800 font-medium transition-all duration-200">
                    Confirm Booking
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Booking Modal -->
<div id="bookingModal" class="fixed inset-0 z-50 hidden overflow-y-auto">
    <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        <!-- Background overlay -->
        <div class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" onclick="closeBookingModal()"></div>

        <!-- Modal panel -->
        <div class="inline-block w-full max-w-2xl p-6 my-8 text-left align-middle transition-all transform bg-white shadow-xl rounded-2xl">
            <!-- Modal header -->
            <div class="flex items-center justify-between mb-6">
                <h3 class="text-2xl font-bold text-gray-900">Book This Room</h3>
                <button onclick="closeBookingModal()" class="text-gray-400 hover:text-gray-600 transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>
            </div>

            <!-- Room Details Section -->
            <div id="modalRoomDetails" class="mb-6 p-4 bg-gray-50 rounded-lg">
                <!-- Room details will be populated here -->
            </div>

            <!-- Booking Form -->
            <form id="bookingForm" class="space-y-6">
                <!-- Start Date -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Start Date</label>
                    <div class="relative">
                        <input type="date" 
                               id="startDate" 
                               name="startDate"
                               required
                               class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent transition-colors duration-200"
                               oninput="validateStartDate()"
                               onchange="calculateTotal()">
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                            <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                            </svg>
                        </div>
                    </div>
                    <div id="startDateError" class="hidden mt-2 text-sm text-red-600 flex items-center">
                        <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
                        </svg>
                        <span id="startDateErrorText"></span>
                    </div>
                    <div id="startDateSuccess" class="hidden mt-2 text-sm text-green-600 flex items-center">
                        <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                        </svg>
                        <span>Date is valid</span>
                    </div>
                </div>

                <!-- Duration -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Duration (months)</label>
                    <div class="relative">
                        <input type="number" 
                               id="duration" 
                               name="duration"
                               min="1" 
                               max="12" 
                               value="1"
                               required
                               class="w-full px-4 py-3 pr-16 border border-gray-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-transparent transition-colors duration-200"
                               oninput="validateDuration()"
                               onchange="calculateTotal()">
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                            <span class="text-gray-500 text-sm">months</span>
                        </div>
                    </div>
                    <div id="durationError" class="hidden mt-2 text-sm text-red-600 flex items-center">
                        <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
                        </svg>
                        <span id="durationErrorText"></span>
                    </div>
                    <div id="durationSuccess" class="hidden mt-2 text-sm text-green-600 flex items-center">
                        <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                        </svg>
                        <span>Duration is valid</span>
                    </div>
                </div>

                <!-- Payment Options -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-3">Payment Option</label>
                    <div class="space-y-3">
                        <label class="flex items-center p-4 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50 transition-colors">
                            <input type="radio" name="paymentOption" value="booking_fee" checked class="mr-3 text-teal-600 focus:ring-teal-500">
                            <div class="flex-1">
                                <span class="font-medium">Pay Booking Fee Only</span>
                                <span class="text-sm text-gray-500 block">Secure your room with booking fee</span>
                            </div>
                            <span class="font-bold text-teal-600" id="bookingFeeAmount">MWK 0</span>
                        </label>
                        <label class="flex items-center p-4 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50 transition-colors">
                            <input type="radio" name="paymentOption" value="full_amount" class="mr-3 text-teal-600 focus:ring-teal-500" onchange="calculateTotal()">
                            <div class="flex-1">
                                <span class="font-medium">Pay Full Amount</span>
                                <span class="text-sm text-gray-500 block">Pay for entire duration upfront</span>
                            </div>
                            <span class="font-bold text-teal-600" id="fullAmountDisplay">MWK 0</span>
                        </label>
                    </div>
                </div>

                <!-- Cost Breakdown -->
                <div id="costBreakdown" class="hidden p-4 bg-teal-50 border border-teal-200 rounded-lg">
                    <h4 class="font-semibold text-gray-900 mb-3">Cost Breakdown</h4>
                    <div id="costDetails" class="space-y-2">
                        <!-- Cost details will be populated here -->
                    </div>
                </div>

                <!-- Error Message -->
                <div id="bookingError" class="hidden p-4 bg-red-50 border border-red-200 rounded-lg">
                    <div class="flex items-center">
                        <svg class="w-5 h-5 text-red-600 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path>
                        </svg>
                        <span class="text-red-700" id="errorMessage"></span>
                    </div>
                </div>

                <!-- Action Buttons -->
                <div class="flex space-x-4 pt-4">
                    <button type="button" 
                            onclick="closeBookingModal()"
                            class="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium transition-colors duration-200">
                        Cancel
                    </button>
                    <button type="submit" 
                            id="submitBookingBtn"
                            class="flex-1 bg-teal-600 text-white px-6 py-3 rounded-lg hover:bg-teal-700 font-medium transition-colors duration-200 disabled:bg-gray-300 disabled:cursor-not-allowed">
                        Proceed to Payment
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function shareHostel() {
    if (navigator.share) {
        navigator.share({
            title: '{{ $hostel['name'] ?? 'Hostel' }}',
            text: 'Check out this amazing hostel!',
            url: window.location.href
        });
    } else {
        // Fallback - copy to clipboard
        navigator.clipboard.writeText(window.location.href);
        PalevelDialog.info('Link copied to clipboard!');
    }
}

function showMap() {
    // Open in Google Maps
    const lat = {{ $hostel['latitude'] ?? 0 }};
    const lng = {{ $hostel['longitude'] ?? 0 }};
    window.open(`https://www.google.com/maps?q=${lat},${lng}`, '_blank');
}

// Booking Modal Functions
let currentRoom = null;
let currentHostel = null;
const PLATFORM_FEE = 2500; // PalLevel platform fee

function openBookingModal(room, hostel) {
    console.log('openBookingModal called with:', { room, hostel });
    
    // Validate room and hostel data
    if (!room || !hostel) {
        console.error('Booking modal error: Missing room or hostel data', { room, hostel });
        showError('Invalid room or hostel information. Please refresh the page and try again.');
        return;
    }
    
    // Check if room has required identifiers
    const roomId = room['room_id'] || room['id'];
    const hostelId = hostel['hostel_id'] || hostel['id'];
    
    console.log('Extracted IDs:', { roomId, hostelId });
    console.log('Available room fields:', Object.keys(room));
    console.log('Available hostel fields:', Object.keys(hostel));
    
    if (!roomId) {
        console.error('Booking modal error: Room missing ID', room);
        showError('Invalid room information. Please refresh the page and try again.');
        return;
    }
    
    if (!hostelId) {
        console.error('Booking modal error: Hostel missing ID', hostel);
        showError('Invalid hostel information. Please refresh the page and try again.');
        return;
    }
    
    console.log('Opening booking modal with:', { roomId, hostelId, room, hostel });
    
    currentRoom = room;
    currentHostel = hostel;
    
    // Populate room details
    const roomDetails = document.getElementById('modalRoomDetails');
    roomDetails.innerHTML = `
        <div class="flex items-start justify-between">
            <div>
                <h4 class="text-lg font-bold text-gray-900">${hostel['name'] ?? 'Hostel'} - Room ${room['room_number'] ?? ''}</h4>
                <div class="mt-2 space-y-1">
                    <p class="text-sm text-gray-600"><strong>Type:</strong> ${room['room_type'] ?? room['type'] ?? 'Standard'}</p>
                    <p class="text-sm text-gray-600"><strong>Capacity:</strong> ${room['capacity'] ?? 1} person${(room['capacity'] ?? 1) != 1 ? 's' : ''}</p>
                    <p class="text-sm text-gray-600"><strong>Price:</strong> MWK ${number_format(room['price_per_month'] ?? 0)}/month</p>
                    ${room['booking_fee'] && room['booking_fee'] > 0 ? `<p class="text-sm text-gray-600"><strong>Booking Fee:</strong> MWK ${number_format(room['booking_fee'])}</p>` : ''}
                    <p class="text-sm text-gray-600"><strong>Status:</strong> 
                        <span class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-full ${(room['occupants'] ?? 0) < (room['capacity'] ?? 1) ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
                            ${(room['occupants'] ?? 0) < (room['capacity'] ?? 1) ? 'Available' : 'Occupied'}
                        </span>
                    </p>
                </div>
            </div>
            <div class="text-right">
                <div class="text-2xl font-bold text-teal-600">MWK ${number_format(room['price_per_month'] ?? 0)}</div>
                <div class="text-sm text-gray-500">per month</div>
            </div>
        </div>
    `;
    
    // Update payment option amounts
    const bookingFee = parseFloat(room['booking_fee'] ?? 0);
    const roomPrice = parseFloat(room['price_per_month'] ?? 0);
    
    document.getElementById('bookingFeeAmount').textContent = `MWK ${number_format(bookingFee)}`;
    document.getElementById('fullAmountDisplay').textContent = `MWK ${number_format(roomPrice)}`;
    
    // Reset form
    document.getElementById('bookingForm').reset();
    document.getElementById('duration').value = '1';
    
    // Set minimum date to today
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('startDate').min = today;
    document.getElementById('startDate').value = today;
    
    // Hide error message
    document.getElementById('bookingError').classList.add('hidden');
    
    // Initialize validation state
    const submitBtn = document.getElementById('submitBookingBtn');
    submitBtn.disabled = true;
    submitBtn.classList.add('disabled:bg-gray-300', 'disabled:cursor-not-allowed');
    
    // Clear any previous validation states
    document.getElementById('startDate').classList.remove('border-red-500', 'border-green-500');
    document.getElementById('duration').classList.remove('border-red-500', 'border-green-500');
    document.getElementById('startDateError').classList.add('hidden');
    document.getElementById('startDateSuccess').classList.add('hidden');
    document.getElementById('durationError').classList.add('hidden');
    document.getElementById('durationSuccess').classList.add('hidden');
    
    // Show modal
    document.getElementById('bookingModal').classList.remove('hidden');
    document.body.style.overflow = 'hidden';
    
    // Calculate initial total and run initial validation
    calculateTotal();
    validateStartDate();
    validateDuration();
}

function closeBookingModal() {
    document.getElementById('bookingModal').classList.add('hidden');
    document.body.style.overflow = 'auto';
    currentRoom = null;
    currentHostel = null;
}

function calculateTotal() {
    const duration = parseInt(document.getElementById('duration').value) || 0;
    const paymentOption = document.querySelector('input[name="paymentOption"]:checked').value;
    const roomPrice = parseFloat(currentRoom?.['price_per_month'] ?? 0);
    const bookingFee = parseFloat(currentRoom?.['booking_fee'] ?? 0);
    
    if (duration > 0) {
        const costBreakdown = document.getElementById('costBreakdown');
        const costDetails = document.getElementById('costDetails');
        
        let totalAmount = 0;
        let breakdownHTML = '';
        
        if (paymentOption === 'full_amount') {
            const roomTotal = roomPrice * duration;
            totalAmount = roomTotal + PLATFORM_FEE;
            
            breakdownHTML = `
                <div class="flex justify-between text-sm">
                    <span>Room (${duration} ${duration > 1 ? 'months' : 'month'})</span>
                    <span class="font-medium">MWK ${number_format(roomTotal)}</span>
                </div>
            `;
        } else {
            totalAmount = bookingFee + PLATFORM_FEE;
            
            breakdownHTML = `
                <div class="flex justify-between text-sm">
                    <span>Booking Fee</span>
                    <span class="font-medium">MWK ${number_format(bookingFee)}</span>
                </div>
            `;
        }
        
        breakdownHTML += `
            <div class="flex justify-between text-sm">
                <span>PalLevel Platform Fee</span>
                <span class="font-medium">MWK ${number_format(PLATFORM_FEE)}</span>
            </div>
            <div class="border-t pt-2 mt-2">
                <div class="flex justify-between font-bold text-base">
                    <span>Total Amount</span>
                    <span class="text-teal-600">MWK ${number_format(totalAmount)}</span>
                </div>
            </div>
        `;
        
        costDetails.innerHTML = breakdownHTML;
        costBreakdown.classList.remove('hidden');
    } else {
        document.getElementById('costBreakdown').classList.add('hidden');
    }
    
    // Update full amount display
    const fullAmount = roomPrice * duration;
    document.getElementById('fullAmountDisplay').textContent = `MWK ${number_format(fullAmount)}`;
}

function number_format(num) {
    return new Intl.NumberFormat('en-MW', { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(num);
}

// Real-time validation functions
function validateStartDate() {
    const startDateInput = document.getElementById('startDate');
    const startDateError = document.getElementById('startDateError');
    const startDateSuccess = document.getElementById('startDateSuccess');
    const startDateErrorText = document.getElementById('startDateErrorText');
    
    const selectedDate = new Date(startDateInput.value);
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Set to start of day for fair comparison
    
    // Reset validation states
    startDateInput.classList.remove('border-red-500', 'border-green-500');
    startDateError.classList.add('hidden');
    startDateSuccess.classList.add('hidden');
    
    if (!startDateInput.value) {
        startDateErrorText.textContent = 'Start date is required';
        startDateError.classList.remove('hidden');
        startDateInput.classList.add('border-red-500');
        updateSubmitButtonState(false, false);
        return false;
    }
    
    if (selectedDate <= today) {
        startDateErrorText.textContent = 'Start date must be in the future';
        startDateError.classList.remove('hidden');
        startDateInput.classList.add('border-red-500');
        updateSubmitButtonState(false, null);
        return false;
    }
    
    // Check if date is too far in the future (more than 2 months)
    const maxDate = new Date();
    maxDate.setMonth(maxDate.getMonth() + 2);
    if (selectedDate > maxDate) {
        startDateErrorText.textContent = 'Start date cannot be more than 2 months in advance';
        startDateError.classList.remove('hidden');
        startDateInput.classList.add('border-red-500');
        updateSubmitButtonState(false, null);
        return false;
    }
    
    // Valid date
    startDateSuccess.classList.remove('hidden');
    startDateInput.classList.add('border-green-500');
    updateSubmitButtonState(true, null);
    return true;
}

function validateDuration() {
    const durationInput = document.getElementById('duration');
    const durationError = document.getElementById('durationError');
    const durationSuccess = document.getElementById('durationSuccess');
    const durationErrorText = document.getElementById('durationErrorText');
    
    const duration = parseInt(durationInput.value);
    
    // Reset validation states
    durationInput.classList.remove('border-red-500', 'border-green-500');
    durationError.classList.add('hidden');
    durationSuccess.classList.add('hidden');
    
    if (!durationInput.value || isNaN(duration)) {
        durationErrorText.textContent = 'Duration is required';
        durationError.classList.remove('hidden');
        durationInput.classList.add('border-red-500');
        updateSubmitButtonState(null, false);
        return false;
    }
    
    if (duration < 1) {
        durationErrorText.textContent = 'Duration must be at least 1 month';
        durationError.classList.remove('hidden');
        durationInput.classList.add('border-red-500');
        updateSubmitButtonState(null, false);
        return false;
    }
    
    if (duration > 12) {
        durationErrorText.textContent = 'Duration cannot exceed 12 months';
        durationError.classList.remove('hidden');
        durationInput.classList.add('border-red-500');
        updateSubmitButtonState(null, false);
        return false;
    }
    
    // Valid duration
    durationSuccess.classList.remove('hidden');
    durationInput.classList.add('border-green-500');
    updateSubmitButtonState(null, true);
    return true;
}

function updateSubmitButtonState(startDateValid = null, durationValid = null) {
    const submitBtn = document.getElementById('submitBookingBtn');
    const startDateInput = document.getElementById('startDate');
    const durationInput = document.getElementById('duration');
    
    // Use provided values or compute them
    if (startDateValid === null) {
        const maxDate = new Date();
        maxDate.setMonth(maxDate.getMonth() + 2);
        startDateValid = startDateInput.value && 
                          new Date(startDateInput.value) > new Date(new Date().setHours(0, 0, 0, 0)) &&
                          new Date(startDateInput.value) <= maxDate;
    }
    
    if (durationValid === null) {
        durationValid = durationInput.value && 
                        !isNaN(parseInt(durationInput.value)) && 
                        parseInt(durationInput.value) >= 1 && 
                        parseInt(durationInput.value) <= 12;
    }
    
    if (startDateValid && durationValid) {
        submitBtn.disabled = false;
        submitBtn.classList.remove('disabled:bg-gray-300', 'disabled:cursor-not-allowed');
    } else {
        submitBtn.disabled = true;
        submitBtn.classList.add('disabled:bg-gray-300', 'disabled:cursor-not-allowed');
    }
}

function showError(message) {
    const bookingError = document.getElementById('bookingError');
    const errorMessage = document.getElementById('errorMessage');
    errorMessage.textContent = message;
    bookingError.classList.remove('hidden');
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        bookingError.classList.add('hidden');
    }, 5000);
}

// Handle form submission
document.addEventListener('DOMContentLoaded', function() {
    const bookingForm = document.getElementById('bookingForm');
    if (bookingForm) {
        bookingForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Run validation first
            const startDateValid = validateStartDate();
            const durationValid = validateDuration();
            
            if (!startDateValid || !durationValid) {
                showError('Please fix the validation errors before proceeding');
                return;
            }
            
            const startDate = document.getElementById('startDate').value;
            const duration = parseInt(document.getElementById('duration').value) || 0;
            const paymentOption = document.querySelector('input[name="paymentOption"]:checked').value;
            
            // Hide error message
            document.getElementById('bookingError').classList.add('hidden');
            
            // Calculate total
            const roomPrice = parseFloat(currentRoom?.['price_per_month'] ?? 0);
            const bookingFee = parseFloat(currentRoom?.['booking_fee'] ?? 0);
            let totalAmount = 0;
            let baseAmount = 0;
            
            if (paymentOption === 'full_amount') {
                baseAmount = roomPrice * duration;
                totalAmount = baseAmount + PLATFORM_FEE;
            } else {
                baseAmount = bookingFee;
                totalAmount = bookingFee + PLATFORM_FEE;
            }
            
            // Prepare booking data
            const bookingData = {
                roomId: currentRoom?.['room_id'] || currentRoom?.['id'],
                hostelId: currentHostel?.['hostel_id'] || currentHostel?.['id'],
                startDate: startDate,
                duration: duration,
                amount: totalAmount,
                baseAmount: baseAmount,
                isFullPayment: paymentOption === 'full_amount',
                bookingFee: bookingFee,
                roomDetails: currentRoom,
                hostelDetails: currentHostel
            };
            
            // Start validation flow
            validateBookingFlow(bookingData);
        });
    }
    
    // Handle payment option changes
    const paymentOptions = document.querySelectorAll('input[name="paymentOption"]');
    paymentOptions.forEach(option => {
        option.addEventListener('change', calculateTotal);
    });
});

// Validation flow matching Flutter app
async function validateBookingFlow(bookingData) {
    try {
        // Step 1: Check for existing active bookings
        const hasActiveBooking = await checkExistingBookings();
        if (hasActiveBooking) {
            const shouldContinue = await showActiveBookingDialog(hasActiveBooking);
            if (!shouldContinue) return;
        }
        
        // Step 2: Check gender mismatch
        const genderMismatch = await checkGenderMismatch(bookingData.roomDetails);
        if (genderMismatch.isMismatch) {
            const shouldProceed = await showGenderMismatchDialog(genderMismatch);
            if (!shouldProceed) return;
        }
        
        // Step 3: Show final confirmation dialog
        const shouldConfirm = await showBookingConfirmationDialog(bookingData);
        if (!shouldConfirm) return;
        
        // Step 4: Proceed with booking
        proceedWithBooking(bookingData);
        
    } catch (error) {
        console.error('Validation flow error:', error);
        showError('An error occurred during validation. Please try again.');
    }
}

// Check for existing active bookings
async function checkExistingBookings() {
    try {
        const response = await fetch(`${API_BASE_URL}/bookings/my-bookings/`, {
            headers: {
                'Authorization': `Bearer ${AUTH_TOKEN}`,
                'Accept': 'application/json'
            }
        });
        
        if (response.ok) {
            const bookings = await response.json();
            const now = new Date();
            
            for (const booking of bookings) {
                const status = (booking.status || booking.booking_status || '').toLowerCase();
                if (!status.includes('confirm')) continue;
                
                const checkOutDate = new Date(booking.check_out_date || booking.checkOut || booking.check_out);
                if (!checkOutDate.getTime() || now <= checkOutDate) {
                    return {
                        hostelName: booking.room?.hostel?.name || booking.hostel_name || '',
                        roomNumber: booking.room?.room_number || booking.room_number || '',
                        checkOutDate: checkOutDate.toISOString().split('T')[0]
                    };
                }
            }
        }
    } catch (error) {
        console.log('Could not check existing bookings:', error);
        // Allow booking to continue if we can't check
    }
    
    return null;
}

// Check gender mismatch
async function checkGenderMismatch(room) {
    try {
        let userGender = null;
        
        if (typeof CURRENT_USER !== 'undefined' && CURRENT_USER && CURRENT_USER.gender) {
            userGender = CURRENT_USER.gender.toLowerCase();
        }
        
        if (!userGender) return { isMismatch: false };
        
        // Parse room gender
        const roomType = (room.room_type || room.type || '').toLowerCase().trim();
        const isFemaleRoom = roomType.endsWith('-female');
        const isMaleRoom = roomType.endsWith('-male');
        const isMixedRoom = !isFemaleRoom && !isMaleRoom;
        
        // Determine mismatch
        let isMismatch = false;
        if (userGender === 'male' && isFemaleRoom) {
            isMismatch = true;
        } else if (userGender === 'female' && isMaleRoom) {
            isMismatch = true;
        }
        
        return {
            isMismatch,
            userGender,
            roomGender: isFemaleRoom ? 'female' : (isMaleRoom ? 'male' : 'mixed'),
            roomType
        };
        
    } catch (error) {
        console.log('Could not check gender:', error);
        return { isMismatch: false };
    }
}

// Show active booking dialog
function showActiveBookingDialog(activeBooking) {
    return new Promise((resolve) => {
        const message = activeBooking.hostelName ? 
            `You already have an active confirmed booking at ${activeBooking.hostelName}${activeBooking.roomNumber ? ` (Room ${activeBooking.roomNumber})` : ''} until ${activeBooking.checkOutDate}. Do you want to continue and make another booking?` :
            `You already have an active confirmed booking until ${activeBooking.checkOutDate}. Do you want to continue and make another booking?`;

        PalevelDialog.confirm(message, 'Confirm').then((ok) => resolve(!!ok));
    });
}

// Show gender mismatch dialog
function showGenderMismatchDialog(genderInfo) {
    return new Promise((resolve) => {
        const message = `This room is reserved for ${genderInfo.roomGender} residents.\n\nYour profile is set to "${genderInfo.userGender}".\n\nDo you want to proceed anyway?`;

        PalevelDialog.confirm(message, 'Confirm').then((ok) => resolve(!!ok));
    });
}

// Show booking confirmation dialog
function showBookingConfirmationDialog(bookingData) {
    return new Promise((resolve) => {
        // Store current booking data for final confirmation
        window.currentBookingData = bookingData;
        
        // Populate confirmation dialog
        const paymentType = bookingData.isFullPayment ? 'Full Payment' : 'Booking Fee Only';
        const durationText = bookingData.duration > 1 ? `${bookingData.duration} months` : `${bookingData.duration} month`;
        
        document.getElementById('confirmHostelName').textContent = bookingData.hostelDetails.name || bookingData.hostelDetails.title || 'N/A';
        document.getElementById('confirmRoomDetails').textContent = `${bookingData.roomDetails.room_number || 'N/A'} (${bookingData.roomDetails.room_type || bookingData.roomDetails.type || 'N/A'})`;
        document.getElementById('confirmDuration').textContent = durationText;
        document.getElementById('confirmStartDate').textContent = bookingData.startDate;
        document.getElementById('confirmPaymentType').textContent = paymentType;
        
        document.getElementById('confirmBaseAmountLabel').textContent = bookingData.isFullPayment ? 'Room Rent:' : 'Booking Fee:';
        document.getElementById('confirmBaseAmount').textContent = `MWK ${number_format(bookingData.baseAmount)}`;
        document.getElementById('confirmPlatformFee').textContent = `MWK ${number_format(PLATFORM_FEE)}`;
        document.getElementById('confirmTotalAmount').textContent = `MWK ${number_format(bookingData.amount)}`;
        
        // Hide booking modal and show confirmation dialog
        document.getElementById('bookingModal').classList.add('hidden');
        document.getElementById('bookingConfirmationDialog').classList.remove('hidden');
        document.getElementById('bookingConfirmationDialog').classList.add('flex');
        
        // Store resolve function for button clicks
        window.confirmationResolve = resolve;
    });
}

// Close confirmation dialog
function closeConfirmationDialog() {
    document.getElementById('bookingConfirmationDialog').classList.add('hidden');
    document.getElementById('bookingConfirmationDialog').classList.remove('flex');
    window.confirmationResolve = null;
    window.currentBookingData = null;
}

// Back to booking dialog
function backToBookingDialog() {
    closeConfirmationDialog();
    document.getElementById('bookingModal').classList.remove('hidden');
    window.confirmationResolve(false);
}

// Confirm final booking
async function confirmFinalBooking() {
    if (window.confirmationResolve) {
        window.confirmationResolve(true);
    }
    closeConfirmationDialog();
    await proceedWithBooking(window.currentBookingData);
}

// Proceed with booking - Complete PayChangu integration
async function proceedWithBooking(bookingData) {
    try {
        // Show loading state
        showLoadingState('Initiating booking...');
        
        // Step 1: Create booking
        const bookingResponse = await createBooking(bookingData);
        
        if (!bookingResponse.success) {
            throw new Error(bookingResponse.message || 'Failed to create booking');
        }
        
        console.log('Booking response received:', bookingResponse);
        console.log('Booking data structure:', bookingResponse.data);
        console.log('Available keys in data:', Object.keys(bookingResponse.data || {}));
        console.log('Full data object:', JSON.stringify(bookingResponse.data, null, 2));
        
        // Extract booking ID from response - backend API returns data directly
        let bookingId = null;
        if (bookingResponse.data) {
            // Backend API returns booking data directly (not nested)
            bookingId = bookingResponse.data.booking_id || 
                        bookingResponse.data.id || 
                        bookingResponse.data.bookingId ||
                        bookingResponse.data.booking;
            console.log('Tried booking_id:', bookingResponse.data.booking_id);
            console.log('Tried id:', bookingResponse.data.id);
            console.log('Tried bookingId:', bookingResponse.data.bookingId);
            console.log('Tried booking:', bookingResponse.data.booking);
        }
        
        console.log('Extracted booking ID:', bookingId);
        
        if (!bookingId) {
            console.error('Could not extract booking ID from response:', bookingResponse);
            throw new Error('Booking was created but could not extract booking ID. Please contact support.');
        }
        
        // Step 2: Use user data from session (no API call to avoid JWT expiration)
        let userData = null;
        
        if (typeof CURRENT_USER !== 'undefined' && CURRENT_USER) {
            userData = {
                email: CURRENT_USER.email,
                phone_number: CURRENT_USER.phone_number || '',
                first_name: CURRENT_USER.first_name || '',
                last_name: CURRENT_USER.last_name || ''
            };
        }
        
        if (!userData || !userData.email) {
            throw new Error('User email is required for payment. Please ensure your profile is complete.');
        }
        
        // Step 3: Initiate PayChangu payment
        showLoadingState('Connecting to payment gateway...');
        
        const paymentResponse = await initiatePayChanguPayment(bookingId, bookingData.amount, userData);
        
        if (!paymentResponse.success) {
            throw new Error(paymentResponse.message || 'Failed to initiate payment');
        }
        
        const paymentUrl = paymentResponse.data.payment_url;
        const paymentId = paymentResponse.data.tx_ref;
        
        if (!paymentUrl) {
            throw new Error('Payment gateway did not return payment URL');
        }
        
        // Step 4: Redirect to dedicated payment page
        showLoadingState('Redirecting to payment page...');
        
        // Store booking info for payment page
        sessionStorage.setItem('pendingBooking', JSON.stringify({
            bookingId: bookingId,
            paymentId: paymentId,
            amount: bookingData.amount,
            paymentUrl: paymentUrl,
            timestamp: Date.now()
        }));
        
        // Redirect to payment page
        window.location.href = `/student/payment/${bookingId}?paymentUrl=${encodeURIComponent(paymentUrl)}&paymentId=${encodeURIComponent(paymentId)}`;
        
    } catch (error) {
        console.error('Booking error:', error);
        showError(`Booking failed: ${error.message}`);
        hideLoadingState();
    }
}

// Create booking API call
async function createBooking(bookingData) {
    // Validate required booking data
    console.log('createBooking called with data:', bookingData);
    
    if (!bookingData || !bookingData.roomId) {
        console.error('Booking error: Missing roomId', bookingData);
        console.error('Current room data:', window.currentRoom);
        return { 
            success: false, 
            message: 'Room information is missing. Please try selecting the room again.' 
        };
    }
    
    if (!bookingData.startDate) {
        console.error('Booking error: Missing startDate', bookingData);
        return { 
            success: false, 
            message: 'Start date is missing. Please try again.' 
        };
    }
    
    if (!bookingData.duration || bookingData.duration <= 0) {
        console.error('Booking error: Invalid duration', bookingData);
        return { 
            success: false, 
            message: 'Invalid booking duration. Please try again.' 
        };
    }
    
    console.log('Creating booking with data:', bookingData);
    
    const response = await fetch(`${API_BASE_URL}/bookings/`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': `Bearer ${AUTH_TOKEN}`
        },
        body: JSON.stringify({
            room_id: bookingData.roomId,
            check_in_date: bookingData.startDate,
            duration_months: bookingData.duration,
            amount: bookingData.amount,
            payment_type: bookingData.isFullPayment ? 'full' : 'booking_fee',
            payment_method: 'paychangu',
            status: 'pending'
        })
    });
    
    // Check if response is JSON
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
        const text = await response.text();
        console.error('Non-JSON response:', text);
        return { 
            success: false, 
            message: 'Server returned non-JSON response. Please check if all API endpoints are properly configured.' 
        };
    }
    
    try {
        const data = await response.json();
        
        if (response.ok && response.status === 201) {
            return { success: true, data: data };
        } else {
            return { success: false, message: data.message || 'Failed to create booking' };
        }
    } catch (error) {
        console.error('JSON parsing error:', error);
        return { 
            success: false, 
            message: 'Invalid JSON response from server. Please check API configuration.' 
        };
    }
}

// Initiate PayChangu payment
async function initiatePayChanguPayment(bookingId, amount, userData) {
    console.log('Initiating payment with:', { bookingId, amount, userData });
    
    const paymentData = {
        booking_id: bookingId,
        amount: amount,
        email: userData.email,
        phone_number: userData.phone_number || '',
        first_name: userData.first_name || '',
        last_name: userData.last_name || '',
        currency: 'MWK'
    };
    
    console.log('Payment request data:', paymentData);
    
    const response = await fetch(`${API_BASE_URL}/payments/paychangu/initiate`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': `Bearer ${AUTH_TOKEN}`
        },
        body: JSON.stringify(paymentData)
    });
    
    console.log('Payment response status:', response.status);
    console.log('Payment response headers:', response.headers);
    
    // Check if response is JSON
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
        const text = await response.text();
        console.error('Non-JSON response:', text);
        return { 
            success: false, 
            message: `Payment gateway returned non-JSON response (${response.status}): ${text.substring(0, 200)}...` 
        };
    }
    
    try {
        const data = await response.json();
        console.log('Payment response data:', data);
        
        if (response.ok) {
            return { success: true, data: data };
        } else {
            return { success: false, message: data.message || `Payment initiation failed (${response.status})` };
        }
    } catch (error) {
        console.error('JSON parsing error:', error);
        return { 
            success: false, 
            message: 'Invalid JSON response from payment gateway. Please check API configuration.' 
        };
    }
}

// Show loading state
function showLoadingState(message) {
    // Create loading overlay if it doesn't exist
    let loadingOverlay = document.getElementById('paymentLoadingOverlay');
    if (!loadingOverlay) {
        loadingOverlay = document.createElement('div');
        loadingOverlay.id = 'paymentLoadingOverlay';
        loadingOverlay.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
        loadingOverlay.innerHTML = `
            <div class="bg-white rounded-lg p-6 max-w-sm mx-4 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600 mx-auto mb-4"></div>
                <p class="text-gray-700 font-medium" id="loadingMessage">${message}</p>
            </div>
        `;
        document.body.appendChild(loadingOverlay);
    } else {
        document.getElementById('loadingMessage').textContent = message;
    }
}

// Hide loading state
function hideLoadingState() {
    const loadingOverlay = document.getElementById('paymentLoadingOverlay');
    if (loadingOverlay) {
        loadingOverlay.remove();
    }
}

// Show payment instructions
function showPaymentInstructions(bookingId, paymentUrl, paymentId) {
    hideLoadingState();
    
    // Create payment instructions modal
    const instructionsModal = document.createElement('div');
    instructionsModal.id = 'paymentInstructionsModal';
    instructionsModal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
    instructionsModal.innerHTML = `
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 p-6">
            <div class="text-center mb-6">
                <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                </div>
                <h3 class="text-xl font-bold text-gray-900 mb-2">Payment Initiated</h3>
                <p class="text-gray-600">Your booking has been created and payment window has opened.</p>
            </div>
            
            <div class="space-y-4 mb-6">
                <div class="bg-gray-50 rounded-lg p-4">
                    <h4 class="font-semibold text-gray-900 mb-2">Booking Details</h4>
                    <div class="text-sm space-y-1">
                        <p><strong>Booking ID:</strong> #${bookingId}</p>
                        <p><strong>Amount:</strong> MWK ${number_format(window.currentBookingData?.amount || 0)}</p>
                    </div>
                </div>
                
                <div class="bg-blue-50 rounded-lg p-4">
                    <h4 class="font-semibold text-blue-900 mb-2">Next Steps</h4>
                    <ol class="text-sm text-blue-800 space-y-2 list-decimal list-inside">
                        <li>Complete payment in the opened window</li>
                        <li>After successful payment, you'll be redirected automatically</li>
                        <li>If not redirected, come back and click "Verify Payment"</li>
                    </ol>
                </div>
            </div>
            
            <div class="flex space-x-3">
                <button onclick="window.open('${paymentUrl}', '_blank')" 
                        class="flex-1 bg-teal-600 text-white px-4 py-3 rounded-lg hover:bg-teal-700 font-medium transition-colors">
                    Reopen Payment
                </button>
                <button onclick="verifyPaymentAndRedirect('${paymentId || bookingId}')" 
                        class="flex-1 border border-gray-300 text-gray-700 px-4 py-3 rounded-lg hover:bg-gray-50 font-medium transition-colors">
                    Verify Payment
                </button>
            </div>
            
            <div class="mt-4 text-center">
                <button onclick="closePaymentInstructions()" class="text-sm text-gray-500 hover:text-gray-700">
                    Close and Continue Later
                </button>
            </div>
        </div>
    `;
    
    document.body.appendChild(instructionsModal);
}

// Close payment instructions
function closePaymentInstructions() {
    const modal = document.getElementById('paymentInstructionsModal');
    if (modal) {
        modal.remove();
    }
}

// Verify payment and redirect to bookings
async function verifyPaymentAndRedirect(paymentId) {
    try {
        showLoadingState('Verifying payment...');
        
        // If paymentId is not provided or looks like a booking ID (numeric), try to get from session
        if (!paymentId || /^\d+$/.test(paymentId)) {
            try {
                const pending = JSON.parse(sessionStorage.getItem('pendingBooking'));
                if (pending && pending.paymentId) {
                    paymentId = pending.paymentId;
                }
            } catch (e) {}
        }

        const response = await fetch(`/api/payments/verify?reference=${paymentId}`, {
            headers: {
                'Accept': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
            }
        });
        
        const result = await response.json();
        
        if (result.success && result.data.status === 'paid') {
            // Payment successful - redirect to bookings
            hideLoadingState();
            closePaymentInstructions();
            
            // Clear pending booking
            sessionStorage.removeItem('pendingBooking');
            
            // Show success message
            PalevelDialog.info('Payment successful! Redirecting to your bookings...');
            
            // Redirect to bookings page
            window.location.href = '/student/bookings';
        } else {
            // Payment not yet processed
            hideLoadingState();
            PalevelDialog.error('Payment not yet verified. Please complete the payment and try again.');
        }
    } catch (error) {
        hideLoadingState();
        PalevelDialog.error('Error verifying payment: ' + error.message);
    }
}

// Check for pending payment on page load
document.addEventListener('DOMContentLoaded', function() {
    const pendingBooking = sessionStorage.getItem('pendingBooking');
    if (pendingBooking) {
        const booking = JSON.parse(pendingBooking);
        
        // If more than 30 minutes have passed, clear it
        if (Date.now() - booking.timestamp > 30 * 60 * 1000) {
            sessionStorage.removeItem('pendingBooking');
            return;
        }
        
        // Show payment verification prompt
        PalevelDialog.confirm(
            'You have a pending payment from a previous booking.\n\n' +
            `Booking ID: #${booking.bookingId}\n` +
            'Would you like to verify this payment now?',
            'Confirm'
        ).then((shouldVerify) => {
            if (shouldVerify) {
                verifyPaymentAndRedirect(booking.paymentId || booking.bookingId);
            } else {
                sessionStorage.removeItem('pendingBooking');
            }
        });
    }
});

// Show error message
function showError(message) {
    const bookingError = document.getElementById('bookingError');
    const errorMessage = document.getElementById('errorMessage');
    
    errorMessage.textContent = message;
    bookingError.classList.remove('hidden');
}

function bookNow() {
    // Redirect to general booking page
    window.location.href = `/booking/hostel/{{ $hostel['hostel_id'] ?? $hostel['id'] }}`;
}

function scheduleTour() {
    // Open tour scheduling modal or redirect
    PalevelDialog.info('Tour scheduling feature coming soon!');
}

function addToFavorites() {
    // Add to favorites functionality
    PalevelDialog.info('Added to favorites!');
}

function contactLandlord() {
    // Open contact form or redirect
    PalevelDialog.info('Contact feature coming soon!');
}

function showReviewForm() {
    // Open review form modal
    PalevelDialog.info('Review form coming soon!');
}

// Lazy loading functionality - disabled since data is now loaded server-side
document.addEventListener('DOMContentLoaded', function() {
    // Data is now loaded by Laravel controller, no need for AJAX calls
    console.log('Hostel detail page loaded with server-side data');
    
    // Only load landlord info if needed (simplified version)
    loadLandlord('{{ $hostel['hostel_id'] ?? $hostel['id'] }}');
});

// Keep these functions for potential future use but don't call them on page load
async function loadRooms(hostelId, backendUrl) {
    console.log('loadRooms called but disabled - data loaded server-side');
    return;
}

async function loadReviews(hostelId, backendUrl) {
    console.log('loadReviews called but disabled - data loaded server-side');
    return;
}

async function loadLandlord(hostelId) {
    const landlordContainer = document.getElementById('landlord-container');
    
    try {
        // For now, display basic landlord info from the hostel data
        // Flutter app gets landlord info differently, so we'll show a simplified version
        const landlordHtml = `
            <div class="text-center py-4 text-gray-500">
                <svg class="w-12 h-12 mx-auto mb-3 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                </svg>
                <p>Landlord information available upon booking</p>
            </div>
        `;
        
        landlordContainer.innerHTML = landlordHtml;
    } catch (error) {
        console.error('Error loading landlord:', error);
        landlordContainer.innerHTML = `
            <div class="text-center py-4 text-red-500">
                <p>Failed to load landlord information. Please try again.</p>
            </div>
        `;
    }
}

function displayRooms(rooms) {
    const roomsContainer = document.getElementById('rooms-container');
    const availableRooms = rooms.filter(room => room.is_available);
    
    const roomsHtml = availableRooms.map(room => `
        <div class="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow duration-200">
            <div class="flex items-center justify-between">
                <div>
                    <h3 class="font-semibold text-gray-900">Room ${room.room_number || ''}</h3>
                    <p class="text-sm text-gray-600">${room.type || 'Single'} • Capacity: ${room.capacity || 1} person${(room.capacity || 1) != 1 ? 's' : ''}</p>
                </div>
                <div class="text-right">
                    <div class="text-lg font-bold text-teal-600">MWK ${Number(room.price_per_month || 0).toLocaleString()}</div>
                    <div class="text-sm text-gray-500">/month</div>
                </div>
            </div>
            <div class="mt-3 flex space-x-2">
                <button onclick="bookRoom('${room.room_id || room.id || ''}')" 
                        class="flex-1 bg-teal-600 text-white px-4 py-2 rounded-lg hover:bg-teal-700 text-sm font-medium transition-colors duration-200">
                    Book This Room
                </button>
                <button class="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm transition-colors duration-200">
                    View Details
                </button>
            </div>
        </div>
    `).join('');
    
    roomsContainer.innerHTML = `<div class="space-y-4">${roomsHtml}</div>`;
}

function displayReviews(reviews, averageRating, totalReviews) {
    const reviewsContainer = document.getElementById('reviews-container');
    
    const reviewsHtml = `
        <div class="bg-gray-50 rounded-lg p-4 mb-6">
            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <div class="text-3xl font-bold text-gray-900">${Number(averageRating || 0).toFixed(1)}</div>
                    <div class="ml-3">
                        <div class="flex items-center">
                            ${generateStars(averageRating || 0)}
                        </div>
                        <p class="text-sm text-gray-600">${totalReviews || 0} review${(totalReviews || 0) != 1 ? 's' : ''}</p>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="space-y-4">
            ${reviews.map(review => `
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex items-start justify-between">
                        <div class="flex items-start">
                            <div class="w-10 h-10 bg-teal-100 rounded-full flex items-center justify-center">
                                <span class="text-teal-600 font-semibold">
                                    ${(review.student_name || 'S').charAt(0).toUpperCase()}
                                </span>
                            </div>
                            <div class="ml-3">
                                <div class="flex items-center">
                                    <h4 class="font-semibold text-gray-900">${review.student_name || 'Student'}</h4>
                                    <div class="flex items-center ml-2">
                                        ${generateStars(review.rating || 0)}
                                    </div>
                                </div>
                                <p class="text-sm text-gray-600 mt-1">
                                    ${formatDate(review.created_at)}
                                </p>
                            </div>
                        </div>
                    </div>
                    ${review.comment ? `<p class="mt-3 text-gray-700">${review.comment}</p>` : ''}
                </div>
            `).join('')}
        </div>
    `;
    
    reviewsContainer.innerHTML = reviewsHtml;
}

function displayLandlord(landlord) {
    const landlordContainer = document.getElementById('landlord-container');
    
    const landlordHtml = `
        <div class="flex items-center mb-4">
            <div class="w-12 h-12 bg-teal-100 rounded-full flex items-center justify-center">
                <span class="text-teal-600 font-semibold text-lg">
                    ${(landlord.first_name || 'L').charAt(0).toUpperCase()}
                </span>
            </div>
            <div class="ml-3">
                <h4 class="font-semibold text-gray-900">${landlord.first_name || ''} ${landlord.last_name || ''}</h4>
                <p class="text-sm text-gray-600">Property Owner</p>
            </div>
        </div>
        <div class="space-y-2">
            ${landlord.phone_number ? `
            <div class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
                </svg>
                ${landlord.phone_number}
            </div>
            ` : ''}
            ${landlord.email ? `
            <div class="flex items-center text-sm text-gray-600">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
                ${landlord.email}
            </div>
            ` : ''}
        </div>
        <button onclick="contactLandlord()" 
                class="w-full mt-4 border border-teal-600 text-teal-600 px-4 py-2 rounded-lg hover:bg-teal-50 text-sm font-medium transition-colors duration-200">
            Contact Landlord
        </button>
    `;
    
    landlordContainer.innerHTML = landlordHtml;
}

function updateAvailableRooms(rooms) {
    const availableRooms = rooms.filter(room => room.is_available).length;
    const availableRoomsElement = document.getElementById('available-rooms');
    if (availableRoomsElement) {
        availableRoomsElement.innerHTML = availableRooms;
    }
}

function updateRatingStats(averageRating, totalReviews) {
    const ratingElement = document.getElementById('average-rating');
    const reviewsElement = document.getElementById('total-reviews');
    
    if (ratingElement) {
        ratingElement.innerHTML = Number(averageRating || 0).toFixed(1);
    }
    if (reviewsElement) {
        reviewsElement.innerHTML = totalReviews || 0;
    }
}

function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now - date);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 1) return '1 day ago';
    if (diffDays < 7) return `${diffDays} days ago`;
    if (diffDays < 30) return `${Math.floor(diffDays / 7)} week${Math.floor(diffDays / 7) > 1 ? 's' : ''} ago`;
    if (diffDays < 365) return `${Math.floor(diffDays / 30)} month${Math.floor(diffDays / 30) > 1 ? 's' : ''} ago`;
    return `${Math.floor(diffDays / 365)} year${Math.floor(diffDays / 365) > 1 ? 's' : ''} ago`;
}

function generateStars(rating) {
    let stars = '';
    for (let i = 1; i <= 5; i++) {
        if (i <= Math.floor(rating)) {
            stars += '<svg class="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>';
        } else if (i - 0.5 <= rating) {
            stars += '<svg class="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>';
        } else {
            stars += '<svg class="w-4 h-4 text-gray-300" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>';
        }
    }
    return stars;
}
</script>
@endsection
