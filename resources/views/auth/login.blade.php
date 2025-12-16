<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In - PaLevel</title>
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

        <!-- Login Container -->
        <div class="relative z-10 w-full max-w-md">
            <!-- Logo Section -->
            <div class="text-center mb-8 slide-up">
                <div class="glass-effect w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4 shadow-2xl float-animation overflow-hidden">
                    <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-full h-full object-contain p-2">
                </div>
                <h1 class="text-3xl font-bold text-white anta-font mb-2">PaLevel</h1>
                <p class="text-white/80">Welcome back</p>
            </div>

            <!-- Login Form -->
            <div class="glass-effect rounded-2xl p-8 shadow-2xl slide-up">
                <h2 class="text-2xl font-bold text-white text-center mb-6">Sign In</h2>
                
                <form action="{{ route('login') }}" method="POST" class="space-y-6">
                    @csrf
                    
                    <div>
                        <label for="email" class="block text-sm font-medium text-white mb-2">Email address</label>
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
                        <label for="password" class="block text-sm font-medium text-white mb-2">Password</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-lock text-white/60"></i>
                            </div>
                            <input id="password" name="password" type="password" autocomplete="current-password" required
                                   class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                   placeholder="Enter your password">
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

                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <input id="remember-me" name="remember-me" type="checkbox" 
                                   class="h-4 w-4 bg-white/20 border-white/30 rounded focus:ring-white/50 focus:ring-2 text-teal-600">
                            <label for="remember-me" class="ml-2 block text-sm text-white/80">
                                Remember me
                            </label>
                        </div>

                        <div class="text-sm">
                            <a href="#" class="text-white/80 hover:text-white transition-colors">
                                Forgot your password?
                            </a>
                        </div>
                    </div>

                    <button type="submit" id="loginButton"
                            class="w-full bg-white text-teal-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg flex items-center justify-center">
                        <span id="loginButtonText">
                            <i class="fas fa-sign-in-alt mr-2"></i>
                            Sign In
                        </span>
                        <span id="loginButtonSpinner" class="hidden">
                            <i class="fas fa-spinner fa-spin mr-2"></i>
                            Signing In...
                        </span>
                    </button>
                </form>

                <!-- Back to Home -->
                <div class="text-center mt-6">
                    <a href="{{ route('landing') }}" class="text-white/60 hover:text-white/80 transition-colors inline-flex items-center">
                        <i class="fas fa-arrow-left mr-2"></i>
                        Back to Home
                    </a>
                </div>
            </div>
        </div>
    </main>
    </div>

    <script>
        // Add focus effects to inputs
        document.querySelectorAll('input').forEach(input => {
            input.addEventListener('focus', function() {
                this.parentElement.classList.add('scale-105');
            });
            
            input.addEventListener('blur', function() {
                this.parentElement.classList.remove('scale-105');
            });
        });

        // Handle login form submission with loading state
        document.addEventListener('DOMContentLoaded', function() {
            const loginForm = document.querySelector('form');
            const loginButton = document.getElementById('loginButton');
            const loginButtonText = document.getElementById('loginButtonText');
            const loginButtonSpinner = document.getElementById('loginButtonSpinner');

            if (loginForm) {
                loginForm.addEventListener('submit', function(e) {
                    // Show loading state
                    loginButton.disabled = true;
                    loginButton.classList.add('opacity-75', 'cursor-not-allowed');
                    loginButtonText.classList.add('hidden');
                    loginButtonSpinner.classList.remove('hidden');
                    
                    // Re-enable button after 10 seconds as fallback
                    setTimeout(function() {
                        loginButton.disabled = false;
                        loginButton.classList.remove('opacity-75', 'cursor-not-allowed');
                        loginButtonText.classList.remove('hidden');
                        loginButtonSpinner.classList.add('hidden');
                    }, 10000);
                });
            }
        });
    </script>
</body>
</html>
