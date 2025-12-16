<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Landlord Sign Up - PaLevel</title>
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
<body class="gradient-bg min-h-screen">
    <div id="app" class="min-h-screen flex flex-col">
        <!-- Navigation Bar -->
        @include('partials.auth-navigation')

        <!-- Main Content -->
        <main class="flex-1 flex items-center justify-center px-4 py-12">
        <!-- Background Logo Effect -->
        <div class="absolute inset-0 flex items-center justify-center opacity-5">
            <div class="w-96 h-96 bg-white rounded-full"></div>
        </div>

        <!-- Registration Container -->
        <div class="relative z-10 w-full max-w-2xl">
            <!-- Logo Section -->
            <div class="text-center mb-8 slide-up">
                <div class="glass-effect w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 shadow-2xl overflow-hidden">
                    <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-full h-full object-contain p-2">
                </div>
                <h1 class="text-3xl font-bold text-white anta-font mb-2">Landlord Sign Up</h1>
                <p class="text-white/80">List your hostels and connect with students</p>
            </div>

            <!-- Registration Form -->
            <div class="glass-effect rounded-2xl p-8 shadow-2xl slide-up">
                <form action="{{ route('register') }}" method="POST" class="space-y-6" enctype="multipart/form-data">
                    @csrf
                    <input type="hidden" name="user_type" value="landlord">
                    
                    <!-- Personal Information -->
                    <div class="space-y-4">
                        <h3 class="text-lg font-semibold text-white mb-4">Personal Information</h3>
                        
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label for="first_name" class="block text-sm font-medium text-white mb-2">First Name</label>
                                <input id="first_name" name="first_name" type="text" required
                                       class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="First name" value="{{ old('first_name') }}">
                            </div>
                            <div>
                                <label for="last_name" class="block text-sm font-medium text-white mb-2">Last Name</label>
                                <input id="last_name" name="last_name" type="text" required
                                       class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="Last name" value="{{ old('last_name') }}">
                            </div>
                        </div>

                        <div>
                            <label for="email" class="block text-sm font-medium text-white mb-2">Email Address</label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <i class="fas fa-envelope text-white/60"></i>
                                </div>
                                <input id="email" name="email" type="email" autocomplete="email" required
                                       class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="Enter your email" value="{{ old('email') }}">
                            </div>
                        </div>

                        <div>
                            <label for="phone_number" class="block text-sm font-medium text-white mb-2">Phone Number</label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <i class="fas fa-phone text-white/60"></i>
                                </div>
                                <input id="phone_number" name="phone_number" type="tel" required
                                       class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="Enter your phone number" value="{{ old('phone_number') }}">
                            </div>
                        </div>

                        <div>
                            <label for="id_document" class="block text-sm font-medium text-white mb-2">ID Document</label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <i class="fas fa-id-card text-white/60"></i>
                                </div>
                                <input id="id_document" name="id_document" type="file" accept="image/*"
                                       class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-white/20 file:text-white hover:file:bg-white/30 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                            </div>
                            <p class="text-xs text-white/60 mt-1">Upload a clear photo of your ID document</p>
                        </div>
                    </div>

                    <!-- Password Information -->
                    <div class="space-y-4">
                        <h3 class="text-lg font-semibold text-white mb-4">Password</h3>
                        
                        <div>
                            <label for="password" class="block text-sm font-medium text-white mb-2">Password</label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <i class="fas fa-lock text-white/60"></i>
                                </div>
                                <input id="password" name="password" type="password" required
                                       class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="Create a strong password">
                            </div>
                            <p class="text-xs text-white/60 mt-1">Use at least 8 characters with letters, numbers, and symbols</p>
                        </div>

                        <div>
                            <label for="password_confirmation" class="block text-sm font-medium text-white mb-2">Confirm Password</label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <i class="fas fa-lock text-white/60"></i>
                                </div>
                                <input id="password_confirmation" name="password_confirmation" type="password" required
                                       class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="Confirm your password">
                            </div>
                        </div>
                    </div>

                    @if ($errors->any())
                        <div class="bg-red-500/20 border border-red-400/50 text-white px-4 py-3 rounded-lg">
                            <div class="flex items-center">
                                <i class="fas fa-exclamation-triangle mr-2"></i>
                                <div>
                                    @foreach ($errors->all() as $error)
                                        <p class="text-sm">{{ $error }}</p>
                                    @endforeach
                                </div>
                            </div>
                        </div>
                    @endif

                    @if(session('error'))
                        <div class="bg-red-500/20 border border-red-400/50 text-white px-4 py-3 rounded-lg">
                            <div class="flex items-center">
                                <i class="fas fa-exclamation-triangle mr-2"></i>
                                <p class="text-sm">{{ session('error') }}</p>
                            </div>
                        </div>
                    @endif

                    <div class="flex items-center">
                        <input id="terms" name="terms" type="checkbox" required
                               class="h-4 w-4 bg-white/20 border-white/30 rounded focus:ring-white/50 focus:ring-2 text-teal-600">
                        <label for="terms" class="ml-2 block text-sm text-white/80">
                            I agree to the <a href="#" class="text-white hover:text-white/90">Terms of Service</a> 
                            and <a href="#" class="text-white hover:text-white/90">Privacy Policy</a>
                        </label>
                    </div>

                    <button type="submit" 
                            class="w-full bg-white text-teal-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg">
                        <i class="fas fa-building mr-2"></i>
                        Create Landlord Account
                    </button>
                </form>

                <!-- Back Links -->
                <div class="mt-6 text-center space-y-2">
                    <p class="text-white/80">
                        Already have an account? 
                        <a href="{{ route('login') }}" class="text-white font-semibold hover:text-white/80 transition-colors">
                            Sign in
                        </a>
                    </p>
                    <p class="text-white/60">
                        <a href="{{ route('register.choice') }}" class="hover:text-white/80 transition-colors">
                            <i class="fas fa-arrow-left mr-1"></i>
                            Back to account type selection
                        </a>
                    </p>
                </div>
            </div>
        </div>
    </div>
</main>
</div>
</body>
</html>
