<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign Up - PaLevel</title>
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
        <main class="flex-1 flex items-center justify-center px-6 py-12">
            <div class="max-w-4xl w-full">
                <!-- Background Logo Effect -->
                <div class="absolute inset-0 flex items-center justify-center opacity-5">
                    <div class="w-96 h-96 bg-white rounded-full"></div>
                </div>

                <!-- Sign Up Content -->
                <div class="relative z-10 text-center slide-up">
                    <!-- Logo Section -->
                    <div class="mb-8">
                        <div class="glass-effect w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4 shadow-2xl float-animation overflow-hidden">
                            <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-full h-full object-contain p-2">
                        </div>
                        <h1 class="text-3xl font-bold text-white anta-font mb-2">PaLevel</h1>
                    </div>
                    
                    <!-- Intro Text -->
                    <div class="mb-12">
                        <h2 class="text-2xl md:text-3xl text-white anta-font font-medium mb-8">
                            Let's get you signed up<br>for your next level up!
                        </h2>
                        
                        <!-- Sign Up Title -->
                        <div class="inline-block">
                            <h1 class="text-5xl md:text-7xl font-bold text-white anta-font" style="color: #07746B;">
                                Sign up
                            </h1>
                        </div>
                    </div>

                    <!-- Role Selection Question -->
                    <div class="mb-12">
                        <h3 class="text-3xl md:text-4xl text-white anta-font font-bold">
                            Would you like to<br>sign up as a
                        </h3>
                    </div>

                    <!-- Role Selection Buttons -->
                    <div class="flex items-center justify-center space-x-4 md:space-x-8">
                        <!-- Student Button -->
                        <a href="{{ route('register.student') }}" 
                           class="group transform hover:scale-105 transition-all duration-300">
                            <div class="bg-teal-700 text-white px-8 py-4 rounded-full font-semibold anta-font text-lg md:text-xl hover:bg-teal-800 transition-colors shadow-lg">
                                Student
                            </div>
                        </a>

                        <!-- Question Mark -->
                        <div class="text-6xl md:text-8xl font-bold anta-font" style="color: #07746B;">
                            ?
                        </div>

                        <!-- Landlord Button -->
                        <a href="{{ route('register.landlord') }}" 
                           class="group transform hover:scale-105 transition-all duration-300">
                            <div class="bg-teal-700 text-white px-8 py-4 rounded-full font-semibold anta-font text-lg md:text-xl hover:bg-teal-800 transition-colors shadow-lg">
                                Landlord
                            </div>
                        </a>
                    </div>

                    <!-- Login Link -->
                    <div class="mt-16">
                        <p class="text-white/80">
                            Already have an account? 
                            <a href="{{ route('login') }}" class="text-white font-semibold hover:text-white/80 transition-colors">
                                Sign in
                            </a>
                        </p>
                    </div>
                </div>
            </div>
        </main>
    </div>
</body>
</html>
