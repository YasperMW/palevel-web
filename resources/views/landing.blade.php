<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PaLevel - Find Your Perfect Home</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Anta&display=swap');
        
        .anta-font {
            font-family: 'Anta', sans-serif;
        }
        
        .gradient-bg {
            background: linear-gradient(135deg, #07746B 0%, #0DDAC9 100%);
        }
        
        .glass-effect {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.3);
        }
        
        .logo-container {
            animation: fadeInScale 1.5s ease-out;
        }
        
        @keyframes fadeInScale {
            0% {
                opacity: 0;
                transform: scale(0.8);
            }
            100% {
                opacity: 1;
                transform: scale(1);
            }
        }
        
        .pulse-animation {
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0%, 100% {
                opacity: 1;
            }
            50% {
                opacity: 0.7;
            }
        }
        
        .float-animation {
            animation: float 3s ease-in-out infinite;
        }
        
        @keyframes float {
            0%, 100% {
                transform: translateY(0px);
            }
            50% {
                transform: translateY(-10px);
            }
        }
        
        .slide-up {
            animation: slideUp 0.8s ease-out;
        }
        
        @keyframes slideUp {
            0% {
                opacity: 0;
                transform: translateY(30px);
            }
            100% {
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
</head>
<body class="gradient-bg min-h-screen overflow-x-hidden">
    <div id="app" class="min-h-screen flex flex-col">
        <!-- Navigation Bar -->
        <nav class="relative z-50 bg-white/10 backdrop-blur-md border-b border-white/20">
            <div class="max-w-7xl mx-auto px-6 py-4">
                <div class="flex justify-between items-center">
                    <!-- Logo -->
                    <div class="flex items-center space-x-3">
                        <div class="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-lg overflow-hidden">
                            <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-full h-full object-contain p-1">
                        </div>
                        <span class="text-white font-bold text-xl anta-font">PaLevel</span>
                    </div>

                    <!-- Desktop Navigation -->
                    <div class="hidden md:flex items-center space-x-8">
                        <a href="#features" class="text-white/90 hover:text-white font-medium transition-colors duration-200 relative group">
                            Features
                            <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-white transition-all duration-200 group-hover:w-full"></span>
                        </a>
                        <a href="#about" class="text-white/90 hover:text-white font-medium transition-colors duration-200 relative group">
                            About
                            <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-white transition-all duration-200 group-hover:w-full"></span>
                        </a>
                        <a href="#contact" class="text-white/90 hover:text-white font-medium transition-colors duration-200 relative group">
                            Contact
                            <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-white transition-all duration-200 group-hover:w-full"></span>
                        </a>
                    </div>

                    <!-- CTA Buttons -->
                    <div class="hidden md:flex items-center space-x-4">
                        <a href="{{ route('login') }}" 
                           class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                            Sign In
                        </a>
                        <a href="{{ route('register.choice') }}" 
                           class="bg-white text-teal-700 px-6 py-2 rounded-full font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg">
                            Get Started
                        </a>
                    </div>

                    <!-- Mobile Menu Button -->
                    <div class="md:hidden">
                        <button x-data="{ open: false }" @click="open = !open" class="text-white/90 hover:text-white transition-colors">
                            <i class="fas fa-bars text-xl"></i>
                        </button>
                    </div>
                </div>

                <!-- Mobile Navigation -->
                <div x-data="{ open: false }" x-show="open" @click.away="open = false" 
                     x-transition:enter="transition ease-out duration-200"
                     x-transition:enter-start="opacity-0 transform -translate-y-2"
                     x-transition:enter-end="opacity-100 transform translate-y-0"
                     x-transition:leave="transition ease-in duration-150"
                     x-transition:leave-start="opacity-100 transform translate-y-0"
                     x-transition:leave-end="opacity-0 transform -translate-y-2"
                     class="md:hidden mt-4 pt-4 border-t border-white/20">
                    <div class="flex flex-col space-y-4">
                        <a href="#features" class="text-white/90 hover:text-white font-medium transition-colors duration-200">Features</a>
                        <a href="#about" class="text-white/90 hover:text-white font-medium transition-colors duration-200">About</a>
                        <a href="#contact" class="text-white/90 hover:text-white font-medium transition-colors duration-200">Contact</a>
                        <div class="flex flex-col space-y-3 pt-4 border-t border-white/20">
                            <a href="{{ route('login') }}" 
                               class="text-white/90 hover:text-white font-medium transition-colors duration-200 text-center">
                                Sign In
                            </a>
                            <a href="{{ route('register.choice') }}" 
                               class="bg-white text-teal-700 px-6 py-2 rounded-full font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg text-center">
                                Get Started
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </nav>

        <!-- Hero Section -->
        <main class="flex-1 flex items-center justify-center px-6 py-12">
            <div class="max-w-6xl mx-auto text-center">
                <!-- Logo Container -->
                <div class="logo-container mb-12">
                    <div class="glass-effect w-32 h-32 md:w-40 md:h-40 rounded-full flex items-center justify-center mx-auto shadow-2xl float-animation p-4">
                        <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-full h-full object-contain">
                    </div>
                </div>

                <!-- App Name and Tagline -->
                <div class="slide-up mb-16">
                    <h1 class="text-5xl md:text-7xl font-bold text-white anta-font mb-4 tracking-wider" style="text-shadow: 0 4px 10px rgba(0,0,0,0.2);">
                        PaLevel
                    </h1>
                    <p class="text-xl md:text-2xl text-white/90 font-medium mb-8">
                        Find Your Perfect Home
                    </p>
                    
                    <!-- CTA Buttons -->
                    <div class="flex flex-col sm:flex-row gap-4 justify-center mb-12">
                        <a href="{{ route('login') }}" 
                           class="bg-white text-teal-700 px-8 py-4 rounded-full font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg">
                            <i class="fas fa-sign-in-alt mr-2"></i>
                            Sign In
                        </a>
                        <a href="{{ route('register.choice') }}" 
                           class="border-2 border-white text-white px-8 py-4 rounded-full font-semibold hover:bg-white hover:text-teal-700 transform hover:scale-105 transition-all duration-300">
                            <i class="fas fa-user-plus mr-2"></i>
                            Get Started
                        </a>
                    </div>
                </div>

                <!-- Features Section -->
                <div id="features" class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
                    <div class="glass-effect rounded-2xl p-6 transform hover:scale-105 transition-all duration-300">
                        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-search text-white text-2xl"></i>
                        </div>
                        <h3 class="text-xl font-semibold text-white mb-2">Easy Search</h3>
                        <p class="text-white/80">Find hostels near your university with advanced filters</p>
                    </div>
                    
                    <div class="glass-effect rounded-2xl p-6 transform hover:scale-105 transition-all duration-300">
                        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-shield-alt text-white text-2xl"></i>
                        </div>
                        <h3 class="text-xl font-semibold text-white mb-2">Secure Booking</h3>
                        <p class="text-white/80">Safe and secure payment processing for your peace of mind</p>
                    </div>
                    
                    <div class="glass-effect rounded-2xl p-6 transform hover:scale-105 transition-all duration-300">
                        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-comments text-white text-2xl"></i>
                        </div>
                        <h3 class="text-xl font-semibold text-white mb-2">Direct Communication</h3>
                        <p class="text-white/80">Chat directly with landlords for any questions</p>
                    </div>
                </div>

                <!-- Featured Hostels Section -->
                <div id="hostels" class="mb-16">
                    <div class="text-center mb-12">
                        <h2 class="text-3xl md:text-4xl font-bold text-white anta-font mb-4">Featured Hostels</h2>
                        <p class="text-xl text-white/90 max-w-2xl mx-auto">
                            Discover some of the best student accommodations available right now
                        </p>
                    </div>

                    @if(isset($hostels) && count($hostels) > 0)
                        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                            @foreach(array_slice($hostels, 0, 6) as $hostel)
                                <div class="glass-effect rounded-2xl overflow-hidden transform hover:scale-105 transition-all duration-300">
                                    <!-- Image -->
                                    <div class="relative h-48 w-full">
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
                                        @else
                                            <div class="w-full h-full bg-white/20 flex items-center justify-center">
                                                <i class="fas fa-home text-white text-4xl"></i>
                                            </div>
                                        @endif
                                        <div class="absolute top-4 right-4">
                                            <span class="px-3 py-1 bg-teal-600 text-white text-xs font-bold rounded-full">
                                                {{ $hostel['type'] ?? 'Hostel' }}
                                            </span>
                                        </div>
                                    </div>
                                    
                                    <!-- Content -->
                                    <div class="p-6">
                                        <h3 class="text-xl font-bold text-white mb-2 truncate">{{ $hostel['name'] }}</h3>
                                        <p class="text-white/80 text-sm mb-4 flex items-center">
                                            <i class="fas fa-map-marker-alt mr-2"></i>
                                            <span class="truncate">{{ $hostel['address'] }}, {{ $hostel['district'] }}</span>
                                        </p>
                                        
                                        <div class="flex items-center justify-between mb-4 text-white/90 text-sm">
                                            <span><i class="fas fa-bed mr-1"></i> {{ $hostel['total_rooms'] ?? 0 }} Rooms</span>
                                            <span class="truncate max-w-[50%]"><i class="fas fa-university mr-1"></i> {{ $hostel['university'] }}</span>
                                        </div>
                                        
                                        <div class="border-t border-white/20 pt-4 flex items-center justify-between">
                                            <div>
                                                <span class="text-xl font-bold text-white">
                                                    MK{{ number_format($hostel['price_per_month'] ?? 0) }}
                                                </span>
                                                <span class="text-white/70 text-sm">/mo</span>
                                            </div>
                                            <a href="{{ route('login') }}" class="bg-white text-teal-700 px-4 py-2 rounded-lg font-semibold hover:bg-gray-100 transition-colors text-sm">
                                                View Details
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                        
                        <div class="text-center mt-12">
                            <a href="{{ route('register.choice') }}" class="inline-block border-2 border-white text-white px-8 py-3 rounded-full font-semibold hover:bg-white hover:text-teal-700 transition-all duration-300">
                                View All Hostels
                            </a>
                        </div>
                    @else
                        <div class="glass-effect rounded-2xl p-8 text-center max-w-2xl mx-auto">
                            <i class="fas fa-building text-white text-4xl mb-4"></i>
                            <p class="text-white text-lg">No hostels currently available to display.</p>
                            <p class="text-white/80 mt-2">Check back soon or sign up to get notified when new hostels are added.</p>
                        </div>
                    @endif
                </div>
            </div>
        </main>

        <!-- About Section -->
        <section id="about" class="py-20 px-6">
            <div class="max-w-6xl mx-auto">
                <div class="text-center mb-16">
                    <h2 class="text-4xl md:text-5xl font-bold text-white anta-font mb-4">About PaLevel</h2>
                    <p class="text-xl text-white/90 max-w-3xl mx-auto">
                        Empowering students to find their perfect home away from home
                    </p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
                    <!-- About Content -->
                    <div class="space-y-6">
                        <div class="glass-effect rounded-2xl p-8">
                            <h3 class="text-2xl font-bold text-white mb-4">Our Mission</h3>
                            <p class="text-white/80 leading-relaxed mb-6">
                                PaLevel is dedicated to simplifying the hostel search process for students across Malawi. 
                                We connect students with safe, affordable, and convenient accommodation options near their universities.
                            </p>
                            <p class="text-white/80 leading-relaxed">
                                Our platform bridges the gap between students seeking quality housing and landlords offering 
                                excellent properties, creating a seamless experience for both parties.
                            </p>
                        </div>

                        <div class="glass-effect rounded-2xl p-8">
                            <h3 class="text-2xl font-bold text-white mb-4">Why Choose Us?</h3>
                            <ul class="space-y-3 text-white/80">
                                <li class="flex items-start">
                                    <i class="fas fa-check-circle text-white mr-3 mt-1"></i>
                                    <span>Verified listings with detailed information and photos</span>
                                </li>
                                <li class="flex items-start">
                                    <i class="fas fa-check-circle text-white mr-3 mt-1"></i>
                                    <span>Direct communication with landlords</span>
                                </li>
                                <li class="flex items-start">
                                    <i class="fas fa-check-circle text-white mr-3 mt-1"></i>
                                    <span>Secure booking and payment processing</span>
                                </li>
                                <li class="flex items-start">
                                    <i class="fas fa-check-circle text-white mr-3 mt-1"></i>
                                    <span>Real reviews from fellow students</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                    <!-- Stats & Visual -->
                    <div class="space-y-8">
                        <!-- Stats Cards -->
                        <div class="grid grid-cols-2 gap-4">
                            <div class="glass-effect rounded-xl p-6 text-center">
                                <div class="text-3xl font-bold text-white mb-2">500+</div>
                                <div class="text-white/80 text-sm">Verified Hostels</div>
                            </div>
                            <div class="glass-effect rounded-xl p-6 text-center">
                                <div class="text-3xl font-bold text-white mb-2">10,000+</div>
                                <div class="text-white/80 text-sm">Happy Students</div>
                            </div>
                            <div class="glass-effect rounded-xl p-6 text-center">
                                <div class="text-3xl font-bold text-white mb-2">15+</div>
                                <div class="text-white/80 text-sm">Universities</div>
                            </div>
                            <div class="glass-effect rounded-xl p-6 text-center">
                                <div class="text-3xl font-bold text-white mb-2">98%</div>
                                <div class="text-white/80 text-sm">Satisfaction Rate</div>
                            </div>
                        </div>

                        <!-- Visual Element -->
                        <div class="glass-effect rounded-2xl p-8 text-center">
                            <div class="w-24 h-24 mx-auto mb-4 bg-white/20 rounded-full flex items-center justify-center">
                                <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-16 h-16 object-contain">
                            </div>
                            <h4 class="text-xl font-bold text-white mb-2">Trusted by Students</h4>
                            <p class="text-white/80">Join thousands of students who found their perfect home through PaLevel</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Contact Section -->
        <section id="contact" class="py-20 px-6">
            <div class="max-w-6xl mx-auto">
                <div class="text-center mb-16">
                    <h2 class="text-4xl md:text-5xl font-bold text-white anta-font mb-4">Get in Touch</h2>
                    <p class="text-xl text-white/90 max-w-3xl mx-auto">
                        Have questions? We're here to help you find your perfect accommodation
                    </p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                    <!-- Contact Info Cards -->
                    <div class="glass-effect rounded-2xl p-8 text-center">
                        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-phone text-white text-2xl"></i>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-2">Call Us</h3>
                        <p class="text-white/80 mb-4">+265 88 327 1664</p>
                        <p class="text-white/60 text-sm">Mon-Fri: 8AM-6PM</p>
                    </div>

                    <div class="glass-effect rounded-2xl p-8 text-center">
                        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-envelope text-white text-2xl"></i>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-2">Email Us</h3>
                        <p class="text-white/80 mb-4">kernelsooft1@gmail.com</p>
                        <p class="text-white/60 text-sm">We respond within 24 hours</p>
                    </div>

                    <div class="glass-effect rounded-2xl p-8 text-center">
                        <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-map-marker-alt text-white text-2xl"></i>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-2">Visit Us</h3>
                        <p class="text-white/80 mb-4">Area 47, Lilongwe</p>
                        <p class="text-white/60 text-sm">Malawi</p>
                    </div>
                </div>

                <!-- Social Media Links -->
                <div class="text-center mt-12">
                    <h3 class="text-xl font-bold text-white mb-6">Follow Us</h3>
                    <div class="flex justify-center space-x-4">
                        <a href="#" class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
                            <i class="fab fa-facebook-f text-white"></i>
                        </a>
                        <a href="#" class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
                            <i class="fab fa-twitter text-white"></i>
                        </a>
                        <a href="#" class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
                            <i class="fab fa-instagram text-white"></i>
                        </a>
                        <a href="#" class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
                            <i class="fab fa-whatsapp text-white"></i>
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- Enhanced Footer -->
        <footer class="bg-teal-900/50 backdrop-blur-md border-t border-white/20 py-12 px-6">
            <div class="max-w-6xl mx-auto">
                <div class="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
                    <!-- Company Info -->
                    <div class="col-span-1 md:col-span-2">
                        <div class="flex items-center space-x-3 mb-4">
                            <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="h-10 w-auto">
                            <span class="text-white font-bold text-xl anta-font">PaLevel</span>
                        </div>
                        <p class="text-white/80 mb-4">
                            Your trusted platform for finding the perfect student accommodation in Malawi. 
                            We connect students with verified hostels near their universities.
                        </p>
                        <div class="flex space-x-4">
                            <a href="#" class="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center hover:bg-white/20 transition-colors">
                                <i class="fab fa-facebook-f text-white text-sm"></i>
                            </a>
                            <a href="#" class="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center hover:bg-white/20 transition-colors">
                                <i class="fab fa-twitter text-white text-sm"></i>
                            </a>
                            <a href="#" class="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center hover:bg-white/20 transition-colors">
                                <i class="fab fa-instagram text-white text-sm"></i>
                            </a>
                            <a href="#" class="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center hover:bg-white/20 transition-colors">
                                <i class="fab fa-whatsapp text-white text-sm"></i>
                            </a>
                        </div>
                    </div>

                    <!-- Quick Links -->
                    <div>
                        <h4 class="text-white font-bold mb-4">Quick Links</h4>
                        <ul class="space-y-2">
                            <li><a href="{{ route('landing') }}" class="text-white/80 hover:text-white transition-colors">Home</a></li>
                            <li><a href="#features" class="text-white/80 hover:text-white transition-colors">Features</a></li>
                            <li><a href="#about" class="text-white/80 hover:text-white transition-colors">About</a></li>
                            <li><a href="#contact" class="text-white/80 hover:text-white transition-colors">Contact</a></li>
                            <li><a href="{{ route('login') }}" class="text-white/80 hover:text-white transition-colors">Sign In</a></li>
                            <li><a href="{{ route('register.choice') }}" class="text-white/80 hover:text-white transition-colors">Sign Up</a></li>
                        </ul>
                    </div>

                    <!-- Contact Info -->
                    <div>
                        <h4 class="text-white font-bold mb-4">Contact Info</h4>
                        <ul class="space-y-2 text-white/80">
                            <li class="flex items-center">
                                <i class="fas fa-phone mr-2"></i>
                                +265 88 327 1664
                            </li>
                            <li class="flex items-center">
                                <i class="fas fa-envelope mr-2"></i>
                                kernelsooft1@gmail.com
                            </li>
                            <li class="flex items-center">
                                <i class="fas fa-map-marker-alt mr-2"></i>
                                Area 47, Lilongwe, Malawi
                            </li>
                            <li class="flex items-center">
                                <i class="fas fa-clock mr-2"></i>
                                Mon-Fri: 8AM-6PM
                            </li>
                        </ul>
                    </div>
                </div>

                <!-- Bottom Footer -->
                <div class="border-t border-white/20 pt-8">
                    <div class="flex flex-col md:flex-row justify-between items-center">
                        <div class="text-white/60 text-sm mb-4 md:mb-0">
                            © 2025 PaLevel. All rights reserved.
                        </div>
                        <div class="flex items-center space-x-4">
                            <a href="#" class="text-white/60 hover:text-white text-sm">Privacy Policy</a>
                            <a href="#" class="text-white/60 hover:text-white text-sm">Terms of Service</a>
                            <div class="flex items-center space-x-2">
                                <span class="text-white/60 text-sm">Powered by</span>
                                <img src="{{ asset('images/KernelSoft-Logo-V1.png') }}" alt="Kernelsoft" class="w-6 h-6 object-contain">
                                <span class="text-white/80 text-sm font-medium">Kernelsoft</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </footer>
    </div>

    <script>
        // Smooth scrolling for navigation links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });

        // Add parallax effect on scroll
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            const parallax = document.querySelector('.logo-container');
            if (parallax) {
                parallax.style.transform = `translateY(${scrolled * 0.5}px)`;
            }
        });
    </script>
</body>
</html>
