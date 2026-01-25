<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In - PaLevel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/palevel-dialog.css') }}">
    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
    <script src="{{ asset('js/palevel-dialog.js') }}" defer></script>
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
                                   class="pl-10 pr-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                                   placeholder="Enter your password">
                            <button type="button" id="togglePassword" 
                                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-white/60 hover:text-white transition-colors">
                                <i id="eyeIcon" class="fas fa-eye"></i>
                            </button>
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
                        <div class="bg-red-500/20 border border-red-400/50 text-white px-4 py-3 rounded-lg" id="sessionError">
                            <div class="flex items-center">
                                <i class="fas fa-exclamation-triangle mr-2"></i>
                                <p class="text-sm">{{ session('error') }}</p>
                            </div>
                        </div>
                    @endif

                    <!-- Google Sign-In Error Container (hidden by default) -->
                    <div id="googleError" class="bg-red-500/20 border border-red-400/50 text-white px-4 py-3 rounded-lg hidden">
                        <div class="flex items-center">
                            <i class="fas fa-exclamation-triangle mr-2"></i>
                            <p class="text-sm" id="googleErrorMessage"></p>
                        </div>
                    </div>

                    <div class="flex items-center justify-between">
                        <div class="text-sm">
                            <a href="{{ route('password.request') }}" class="text-white/80 hover:text-white transition-colors">
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

                <div class="mt-6 text-center">
                    <p class="text-white/80">
                        Don't have an account? 
                        <a href="{{ route('register.choice') }}" class="text-white font-semibold hover:underline">Sign up</a>
                    </p>
                </div>

                <!-- Google Sign In -->
                <div class="mt-6">
                    <div class="relative">
                        <div class="absolute inset-0 flex items-center">
                            <div class="w-full border-t border-white/20"></div>
                        </div>
                        <div class="relative flex justify-center text-sm">
                            <span class="px-2 bg-transparent text-white/80">Or continue with</span>
                        </div>
                    </div>

                    <div class="mt-6">
                        <button type="button" id="googleSignInButton" onclick="signInWithGoogle()" 
                                class="w-full flex items-center justify-center px-4 py-3 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 transition-all shadow-lg font-semibold relative">
                            <span id="googleButtonContent" class="flex items-center">
                                <img src="https://www.svgrepo.com/show/475656/google-color.svg" class="h-5 w-5 mr-2" alt="Google">
                                Sign in with Google
                            </span>
                            <span id="googleButtonSpinner" class="hidden flex items-center">
                                <i class="fas fa-spinner fa-spin mr-2"></i>
                                Signing in with Google...
                            </span>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </main>
    </div>

    <script src="https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.22.0/firebase-auth-compat.js"></script>
    <script>
        // Firebase configuration - check if values are set
        const firebaseConfig = {
            apiKey: "{{ config('services.firebase.api_key') ?: 'demo-api-key' }}",
            authDomain: "{{ config('services.firebase.auth_domain') ?: 'demo-project.firebaseapp.com' }}",
            projectId: "{{ config('services.firebase.project_id') ?: 'demo-project' }}",
            storageBucket: "{{ config('services.firebase.storage_bucket') ?: 'demo-project.appspot.com' }}",
            messagingSenderId: "{{ config('services.firebase.messaging_sender_id') ?: '123456789' }}",
            appId: "{{ config('services.firebase.app_id') ?: '1:123456789:web:abcdef123456' }}"
        };

        // Initialize Firebase
        if (!firebase.apps.length) {
            // Check if using demo values
            if ("{{ config('services.firebase.api_key') }}" === "") {
                console.warn('Firebase is not configured. Please add FIREBASE_* variables to your .env file');
                // Disable Google Sign-In button if not configured
                const googleButton = document.querySelector('button[onclick="signInWithGoogle()"]');
                if (googleButton) {
                    googleButton.disabled = true;
                    googleButton.textContent = 'Google Sign-In Not Configured';
                    googleButton.classList.add('opacity-50', 'cursor-not-allowed');
                }
            }
            firebase.initializeApp(firebaseConfig);
        }

        // Function to map backend error messages to user-friendly messages
        function getGoogleErrorMessage(errorMessage) {
            // Map specific backend errors to user-friendly messages
            const errorMappings = {
                'This email is already registered with a regular account. Please use your password to login instead of OAuth.':
                    'Email already in use. Sign in with your password instead',
                'Invalid Firebase ID token':
                    'Invalid authentication. Please try signing in again',
                'Expired Firebase ID token':
                    'Session expired. Please try signing in again',
                'Revoked Firebase ID token':
                    'Authentication revoked. Please try signing in again',
                'Firebase token does not contain an email address':
                    'Invalid account. Please try again or use a different account',
                'Token verification failed':
                    'Authentication failed. Please try again',
                'Firebase authentication failed:':
                    'Authentication failed. Please try again'
            };

            // Check for exact matches first
            if (errorMappings[errorMessage]) {
                return errorMappings[errorMessage];
            }

            // Check for partial matches
            for (const [backendError, userMessage] of Object.entries(errorMappings)) {
                if (errorMessage.includes(backendError) || backendError.includes(errorMessage)) {
                    return userMessage;
                }
            }

            // Default fallback for any Firebase-related errors
            if (errorMessage.toLowerCase().includes('firebase') || 
                errorMessage.toLowerCase().includes('token') ||
                errorMessage.toLowerCase().includes('authentication')) {
                return 'Google sign-in failed. Please try again';
            }

            // Return original message if no mapping found
            return errorMessage;
        }

        function signInWithGoogle() {
            const button = document.getElementById('googleSignInButton');
            const buttonContent = document.getElementById('googleButtonContent');
            const buttonSpinner = document.getElementById('googleButtonSpinner');
            
            // Show loading state immediately
            button.disabled = true;
            button.classList.add('opacity-75', 'cursor-not-allowed');
            buttonContent.classList.add('hidden');
            buttonSpinner.classList.remove('hidden');
            
            const provider = new firebase.auth.GoogleAuthProvider();
            
            firebase.auth().signInWithPopup(provider)
                .then((result) => {
                    // Get user details
                    const user = result.user;
                    return user.getIdToken().then(idToken => {
                        return {
                            idToken: idToken,
                            email: user.email,
                            displayName: user.displayName,
                            photoURL: user.photoURL
                        };
                    });
                })
                .then((authData) => {
                    return fetch('{{ route("auth.google.callback") }}', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': '{{ csrf_token() }}'
                        },
                        body: JSON.stringify({ 
                            id_token: authData.idToken,
                            email: authData.email,
                            display_name: authData.displayName,
                            photo_url: authData.photoURL
                        })
                    });
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        if (data.needs_role_selection) {
                            // Show role selection modal
                            showRoleSelectionModal();
                        } else {
                            // Success animation before redirect
                            button.classList.remove('opacity-75', 'cursor-not-allowed');
                            button.classList.add('bg-green-500', 'text-white');
                            buttonContent.classList.remove('hidden');
                            buttonContent.innerHTML = '<i class="fas fa-check mr-2"></i>Success!';
                            buttonSpinner.classList.add('hidden');
                            
                            setTimeout(() => {
                                window.location.href = data.redirect;
                            }, 1000);
                        }
                    } else {
                        // Error state - show error in the error container
                        button.classList.remove('opacity-75', 'cursor-not-allowed');
                        button.classList.add('bg-red-500', 'text-white');
                        buttonContent.classList.remove('hidden');
                        buttonContent.innerHTML = '<i class="fas fa-exclamation-triangle mr-2"></i>Failed';
                        buttonSpinner.classList.add('hidden');
                        
                        // Show error message in the error container
                        const googleError = document.getElementById('googleError');
                        const googleErrorMessage = document.getElementById('googleErrorMessage');
                        if (googleError && googleErrorMessage) {
                            const userFriendlyMessage = getGoogleErrorMessage(data.error || 'Unknown error occurred');
                            googleErrorMessage.textContent = userFriendlyMessage;
                            googleError.classList.remove('hidden');
                        }
                        
                        // Reset button after 3 seconds
                        setTimeout(() => {
                            button.classList.remove('bg-red-500', 'text-white');
                            button.disabled = false;
                            buttonContent.classList.remove('hidden');
                            buttonContent.innerHTML = '<img src="https://www.svgrepo.com/show/475656/google-color.svg" class="h-5 w-5 mr-2" alt="Google">Sign in with Google';
                            buttonSpinner.classList.add('hidden');
                            
                            // Hide error after 5 seconds
                            setTimeout(() => {
                                if (googleError) {
                                    googleError.classList.add('hidden');
                                }
                            }, 5000);
                        }, 3000);
                    }
                })
                .catch((error) => {
                    console.error('Error:', error);
                    
                    // Error state - show error in the error container
                    button.classList.remove('opacity-75', 'cursor-not-allowed');
                    button.classList.add('bg-red-500', 'text-white');
                    buttonContent.classList.remove('hidden');
                    buttonContent.innerHTML = '<i class="fas fa-exclamation-triangle mr-2"></i>Error';
                    buttonSpinner.classList.add('hidden');
                    
                    // Show error message in the error container
                    const googleError = document.getElementById('googleError');
                    const googleErrorMessage = document.getElementById('googleErrorMessage');
                    if (googleError && googleErrorMessage) {
                        // Try to extract error message from the error object
                        let errorMessage = 'Google Sign-In failed. Please try again.';
                        if (error.message) {
                            errorMessage = getGoogleErrorMessage(error.message);
                        } else if (typeof error === 'string') {
                            errorMessage = getGoogleErrorMessage(error);
                        }
                        googleErrorMessage.textContent = errorMessage;
                        googleError.classList.remove('hidden');
                    }
                    
                    // Reset button after 3 seconds
                    setTimeout(() => {
                        button.classList.remove('bg-red-500', 'text-white');
                        button.disabled = false;
                        buttonContent.classList.remove('hidden');
                        buttonContent.innerHTML = '<img src="https://www.svgrepo.com/show/475656/google-color.svg" class="h-5 w-5 mr-2" alt="Google">Sign in with Google';
                        buttonSpinner.classList.add('hidden');
                        
                        // Hide error after 5 seconds
                        setTimeout(() => {
                            if (googleError) {
                                googleError.classList.add('hidden');
                            }
                        }, 5000);
                    }, 3000);
                });
        }

        function showRoleSelectionModal() {
            // Create modal overlay
            const modalOverlay = document.createElement('div');
            modalOverlay.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
            modalOverlay.id = 'roleSelectionModal';
            
            // Create modal content
            const modalContent = document.createElement('div');
            modalContent.className = 'bg-white rounded-lg p-8 max-w-md w-full mx-4';
            modalContent.innerHTML = `
                <h3 class="text-xl font-bold text-gray-800 mb-4">Select Your Role</h3>
                <p class="text-gray-600 mb-6">Please select your role to continue with registration:</p>
                <div class="space-y-3">
                    <button onclick="selectRole('tenant')" class="w-full bg-teal-600 hover:bg-teal-700 text-white font-medium py-3 px-4 rounded-lg transition-colors">
                        <i class="fas fa-graduation-cap mr-2"></i>
                        Student
                    </button>
                    <button onclick="selectRole('landlord')" class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-4 rounded-lg transition-colors">
                        <i class="fas fa-home mr-2"></i>
                        Landlord
                    </button>
                    <button onclick="closeRoleSelectionModal()" class="w-full bg-gray-300 hover:bg-gray-400 text-gray-700 font-medium py-3 px-4 rounded-lg transition-colors">
                        Cancel
                    </button>
                </div>
            `;
            
            modalOverlay.appendChild(modalContent);
            document.body.appendChild(modalOverlay);
            
            // Close modal when clicking overlay
            modalOverlay.addEventListener('click', function(e) {
                if (e.target === modalOverlay) {
                    closeRoleSelectionModal();
                }
            });
        }

        function selectRole(role) {
            closeRoleSelectionModal();
            // Redirect to OAuth completion pages instead of regular personal info
            if (role === 'tenant') {
                window.location.href = '{{ route("signup.oauth.student") }}';
            } else if (role === 'landlord') {
                window.location.href = '{{ route("signup.oauth.landlord") }}';
            }
        }

        function closeRoleSelectionModal() {
            const modal = document.getElementById('roleSelectionModal');
            if (modal) {
                modal.remove();
            }
        }
    </script>

    <script>
        // Handle login form submission with loading state
        document.addEventListener('DOMContentLoaded', function() {
            const loginForm = document.querySelector('form');
            const loginButton = document.getElementById('loginButton');
            const loginButtonText = document.getElementById('loginButtonText');
            const loginButtonSpinner = document.getElementById('loginButtonSpinner');

            // Password visibility toggle
            const togglePassword = document.getElementById('togglePassword');
            const passwordInput = document.getElementById('password');
            const eyeIcon = document.getElementById('eyeIcon');

            if (togglePassword && passwordInput && eyeIcon) {
                togglePassword.addEventListener('click', function() {
                    const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                    passwordInput.setAttribute('type', type);
                    
                    // Toggle eye icon
                    if (type === 'password') {
                        eyeIcon.classList.remove('fa-eye-slash');
                        eyeIcon.classList.add('fa-eye');
                    } else {
                        eyeIcon.classList.remove('fa-eye');
                        eyeIcon.classList.add('fa-eye-slash');
                    }
                });
            }

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

    @include('partials.palevel-dialog')
</body>
</html>
