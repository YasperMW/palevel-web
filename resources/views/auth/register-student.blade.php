<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Sign Up - PaLevel</title>
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
                <h1 class="text-3xl font-bold text-white anta-font mb-2">Student Sign Up</h1>
                <p class="text-white/80">Join thousands of students finding their perfect home</p>
            </div>

            <!-- Registration Form -->
            <div class="glass-effect rounded-2xl p-8 shadow-2xl slide-up">
                <form action="{{ route('register') }}" method="POST" class="space-y-6">
                    @csrf
                    <input type="hidden" name="user_type" value="tenant">
                    
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
                                <input id="phone_number" name="phone_number" type="tel"
                                       class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                       placeholder="Enter your phone number" value="{{ old('phone_number') }}">
                            </div>
                        </div>
                    </div>

                    <!-- Academic Information -->
                    <div class="space-y-4">
                        <h3 class="text-lg font-semibold text-white mb-4">Academic Information</h3>
                        
                        <div>
                            <label for="university" class="block text-sm font-medium text-white mb-2">University</label>
                            <select id="university" name="university" required
                                    class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                                <option value="">Select your university</option>
                                <option value="University of Malawi (UNIMA)">University of Malawi (UNIMA)</option>
                                <option value="Malawi University of Science and Technology (MUST)">Malawi University of Science and Technology (MUST)</option>
                                <option value="Lilongwe University of Agriculture and Natural Resources (LUANAR)">Lilongwe University of Agriculture and Natural Resources (LUANAR)</option>
                                <option value="Mzuzu University (MZUNI)">Mzuzu University (MZUNI)</option>
                                <option value="Malawi University of Business and Applied Sciences (MUBAS)">Malawi University of Business and Applied Sciences (MUBAS)</option>
                                <option value="Kamuzu University of Health Sciences (KUHeS)">Kamuzu University of Health Sciences (KUHeS)</option>
                                <option value="Malawi College of Accountancy (MCA)">Malawi College of Accountancy (MCA)</option>
                                <option value="Malawi School of Government (MSG)">Malawi School of Government (MSG)</option>
                                <option value="Domasi College of Education (DCE)">Domasi College of Education (DCE)</option>
                                <option value="Nalikule College of Education (NCE)">Nalikule College of Education (NCE)</option>
                                <option value="Malawi College of Health Sciences (MCHS)">Malawi College of Health Sciences (MCHS)</option>
                                <option value="Catholic University of Malawi (CUNIMA)">Catholic University of Malawi (CUNIMA)</option>
                                <option value="DMI St John the Baptist University (DMI)">DMI St John the Baptist University (DMI)</option>
                                <option value="Nkhoma University (NKHUNI)">Nkhoma University (NKHUNI)</option>
                                <option value="Malawi Assemblies of God University (MAGU)">Malawi Assemblies of God University (MAGU)</option>
                                <option value="Daeyang University (DU)">Daeyang University (DU)</option>
                                <option value="Malawi Adventist University (MAU)">Malawi Adventist University (MAU)</option>
                                <option value="Pentecostal Life University (PLU)">Pentecostal Life University (PLU)</option>
                                <option value="African Bible College (ABC)">African Bible College (ABC)</option>
                                <option value="University of Livingstonia (UNILIA)">University of Livingstonia (UNILIA)</option>
                                <option value="Exploits University (EU)">Exploits University (EU)</option>
                                <option value="University of Lilongwe (UNILIL)">University of Lilongwe (UNILIL)</option>
                                <option value="Millennium University (MU)">Millennium University (MU)</option>
                                <option value="Lake Malawi Anglican University (LAMAU)">Lake Malawi Anglican University (LAMAU)</option>
                                <option value="Unicaf University Malawi (UNICAF)">Unicaf University Malawi (UNICAF)</option>
                                <option value="Blantyre International University (BIU)">Blantyre International University (BIU)</option>
                                <option value="ShareWORLD Open University (SWOU)">ShareWORLD Open University (SWOU)</option>
                                <option value="Skyway University (SU)">Skyway University (SU)</option>
                                <option value="University of Blantyre Synod (UBS)">University of Blantyre Synod (UBS)</option>
                                <option value="Jubilee University (JU)">Jubilee University (JU)</option>
                                <option value="Marble Hill University (MHU)">Marble Hill University (MHU)</option>
                                <option value="Zomba Theological College (ZTC)">Zomba Theological College (ZTC)</option>
                                <option value="Emmanuel University (EMUNI)">Emmanuel University (EMUNI)</option>
                                <option value="International Open University (IOU)">International Open University (IOU)</option>
                                <option value="International College of Business and Management (ICBM)">International College of Business and Management (ICBM)</option>
                                <option value="St John of God College of Health Sciences (SJOG)">St John of God College of Health Sciences (SJOG)</option>
                                <option value="Malawi Institute of Journalism (MIJ)">Malawi Institute of Journalism (MIJ)</option>
                            </select>
                        </div>

                        <div>
                            <label for="year_of_study" class="block text-sm font-medium text-white mb-2">Year of Study</label>
                            <select id="year_of_study" name="year_of_study" required
                                    class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                                <option value="">Select your year</option>
                                <option value="1st Year">1st Year</option>
                                <option value="2nd Year">2nd Year</option>
                                <option value="3rd Year">3rd Year</option>
                                <option value="4th Year">4th Year</option>
                                <option value="Postgraduate">Postgraduate</option>
                            </select>
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
                                       placeholder="Create a password">
                            </div>
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

                    <button type="submit" id="registerButton"
                            class="w-full bg-white text-teal-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg flex items-center justify-center">
                        <span id="registerButtonText">
                            <i class="fas fa-user-plus mr-2"></i>
                            Create Student Account
                        </span>
                        <span id="registerButtonSpinner" class="hidden">
                            <i class="fas fa-spinner fa-spin mr-2"></i>
                            Creating Account...
                        </span>
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
        </main>
    </div>
</body>

<script>
    // Handle registration form submission with loading state
    document.addEventListener('DOMContentLoaded', function() {
        const registerForm = document.querySelector('form');
        const registerButton = document.getElementById('registerButton');
        const registerButtonText = document.getElementById('registerButtonText');
        const registerButtonSpinner = document.getElementById('registerButtonSpinner');

        if (registerForm) {
            registerForm.addEventListener('submit', function(e) {
                // Show loading state
                registerButton.disabled = true;
                registerButton.classList.add('opacity-75', 'cursor-not-allowed');
                registerButtonText.classList.add('hidden');
                registerButtonSpinner.classList.remove('hidden');
                
                // Re-enable button after 15 seconds as fallback (longer for registration)
                setTimeout(function() {
                    registerButton.disabled = false;
                    registerButton.classList.remove('opacity-75', 'cursor-not-allowed');
                    registerButtonText.classList.remove('hidden');
                    registerButtonSpinner.classList.add('hidden');
                }, 15000);
            });
        }
    });
</script>
</html>
