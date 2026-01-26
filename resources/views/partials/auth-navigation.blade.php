<!-- Navigation Bar for Auth Pages -->
<nav x-data="{ open: false }" class="sticky top-0 z-50 bg-white/10 backdrop-blur-md border-b border-white/20">
    <div class="max-w-7xl mx-auto px-6 py-4">
        <div class="flex justify-between items-center">
            <!-- Logo -->
            <div class="flex items-center space-x-3">
                <a href="{{ route('landing') }}" class="flex items-center space-x-3 group">
                    <div class="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-lg transform group-hover:scale-105 transition-all duration-300 overflow-hidden">
                        <img src="{{ asset('images/PaLevel Logo-White.png') }}" alt="PaLevel" class="w-full h-full object-contain p-1">
                    </div>
                    <span class="text-white font-bold text-xl anta-font">PaLevel</span>
                </a>
            </div>

            <!-- Navigation Links -->
            <div class="hidden md:flex items-center space-x-6">
                @php
                    $isLanding = request()->routeIs('landing');
                    $isRegister = request()->routeIs('register.choice');
                    $isLogin = request()->routeIs('login');
                @endphp
                <a href="{{ route('landing') }}" 
                   class="{{ $isLanding ? 'text-white' : 'text-white/90 hover:text-white' }} font-medium transition-colors duration-200 relative group">
                    Home
                    <span class="absolute bottom-0 left-0 {{ $isLanding ? 'w-full' : 'w-0 group-hover:w-full' }} h-0.5 bg-white transition-all duration-200"></span>
                </a>
                @if($isLanding)
                    <a href="#features" 
                       class="text-white/90 hover:text-white font-medium transition-colors duration-200 relative group">
                        Features
                        <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-white transition-all duration-200 group-hover:w-full"></span>
                    </a>
                    <a href="#about" 
                       class="text-white/90 hover:text-white font-medium transition-colors duration-200 relative group">
                        About
                        <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-white transition-all duration-200 group-hover:w-full"></span>
                    </a>
                    <a href="#contact" 
                       class="text-white/90 hover:text-white font-medium transition-colors duration-200 relative group">
                        Contact
                        <span class="absolute bottom-0 left-0 w-0 h-0.5 bg-white transition-all duration-200 group-hover:w-full"></span>
                    </a>
                @endif
            </div>

            <!-- CTA Buttons -->
            <div class="hidden md:flex items-center space-x-4">
                <a href="{{ route('login') }}" 
                   class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                    Sign In
                </a>
                <a href="{{ route('register.choice') }}" 
                   class="bg-white text-teal-700 px-5 py-2 rounded-full font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg">
                    Get Started
                </a>
                <a href="{{ route('download.app') }}" 
                   class="bg-gray-800 text-teal-100 px-5 py-2 rounded-full font-semibold hover:bg-white hover:text-teal-700 transform hover:scale-105 transition-all duration-300 shadow-lg">
                    Download App
                </a>
            </div>

            <!-- Mobile Menu Button -->
            <div class="md:hidden">
                <button @click="open = !open" class="text-white/90 hover:text-white transition-colors">
                    <i class="fas fa-bars text-xl"></i>
                </button>
            </div>
        </div>

        <!-- Mobile Navigation -->
        <div x-show="open" @click.away="open = false" 
             x-transition:enter="transition ease-out duration-200"
             x-transition:enter-start="opacity-0 transform -translate-y-2"
             x-transition:enter-end="opacity-100 transform translate-y-0"
             x-transition:leave="transition ease-in duration-150"
             x-transition:leave-start="opacity-100 transform translate-y-0"
             x-transition:leave-end="opacity-0 transform -translate-y-2"
             class="md:hidden mt-4 pt-4 border-t border-white/20">
            <div class="flex flex-col space-y-4">
                <a href="{{ route('landing') }}" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                    <i class="fas fa-home mr-2"></i>Home
                </a>
                @if(request()->routeIs('landing'))
                    <a href="#features" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                        Features
                    </a>
                    <a href="#about" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                        About
                    </a>
                    <a href="#contact" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                        Contact
                    </a>
                @endif
                <a href="{{ route('register.choice') }}" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                    <i class="fas fa-user-plus mr-2"></i>Sign Up
                </a>
                <a href="{{ route('login') }}" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                    <i class="fas fa-sign-in-alt mr-2"></i>Sign In
                </a>
                <a href="{{ route('download.app') }}" class="text-white/90 hover:text-white font-medium transition-colors duration-200">
                    Download App
                </a>
            </div>
        </div>
    </div>
</nav>
