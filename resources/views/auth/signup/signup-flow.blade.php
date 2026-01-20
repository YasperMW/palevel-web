<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Choose Your Role - PaLevel Signup</title>
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

        .role-card {
            transition: all 0.3s ease;
        }

        .role-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
        }
    </style>
</head>
<body class="gradient-bg min-h-screen flex items-center justify-center p-4">
    <!-- Background Logo Effect -->
    <div class="absolute inset-0 flex items-center justify-center opacity-5 pointer-events-none">
        <div class="w-96 h-96 bg-white rounded-full"></div>
    </div>

    <div class="w-full max-w-4xl glass-effect rounded-2xl p-8 shadow-2xl slide-up relative z-10">
        <div class="text-center mb-8">
            <div class="glass-effect w-20 h-20 rounded-full flex items-center justify-center shadow-lg mx-auto mb-4">
                <img src="{{ asset('images/PaLevel Logo-White.png') }}" class="w-12" alt="logo">
            </div>
            <h1 class="text-white text-4xl anta-font font-bold mb-2">Join PaLevel</h1>
            <p class="text-white/80 text-lg">Choose your role to get started</p>
        </div>

        <div class="grid md:grid-cols-2 gap-8">
            <!-- Student Card -->
            <div class="role-card glass-effect rounded-xl p-6 cursor-pointer hover:bg-white/20" onclick="window.location.href='{{ route('signup.personal', ['userType' => 'tenant']) }}'">
                <div class="text-center">
                    <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                        <i class="fas fa-graduation-cap text-white text-2xl"></i>
                    </div>
                    <h3 class="text-white text-xl font-semibold mb-3">Student</h3>
                    <p class="text-white/70 text-sm mb-4">
                        Find and book hostels near your university. Connect with landlords and secure your accommodation.
                    </p>
                    <ul class="text-white/60 text-sm space-y-2 text-left">
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Browse verified hostels</li>
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Compare prices & amenities</li>
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Secure online booking</li>
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Student discounts available</li>
                    </ul>
                    <button class="mt-6 w-full bg-white text-teal-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-all duration-300">
                        Sign up as Student
                    </button>
                </div>
            </div>

            <!-- Landlord Card -->
            <div class="role-card glass-effect rounded-xl p-6 cursor-pointer hover:bg-white/20" onclick="window.location.href='{{ route('signup.personal', ['userType' => 'landlord']) }}'">
                <div class="text-center">
                    <div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                        <i class="fas fa-home text-white text-2xl"></i>
                    </div>
                    <h3 class="text-white text-xl font-semibold mb-3">Landlord</h3>
                    <p class="text-white/70 text-sm mb-4">
                        List your hostels and reach thousands of students looking for accommodation.
                    </p>
                    <ul class="text-white/60 text-sm space-y-2 text-left">
                        <li><i class="fas fa-check text-green-400 mr-2"></i>List multiple properties</li>
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Manage bookings online</li>
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Receive payments securely</li>
                        <li><i class="fas fa-check text-green-400 mr-2"></i>Access tenant analytics</li>
                    </ul>
                    <button class="mt-6 w-full bg-white text-teal-700 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-all duration-300">
                        Sign up as Landlord
                    </button>
                </div>
            </div>
        </div>

        <div class="mt-8 text-center">
            <p class="text-white/70 text-sm mb-4">
                Already have an account? 
                <a href="{{ route('login') }}" class="text-white hover:underline font-semibold">
                    Sign in here
                </a>
            </p>
            
            <!-- Google Sign Up -->
            <div class="max-w-md mx-auto">
                <div class="relative">
                    <div class="absolute inset-0 flex items-center">
                        <div class="w-full border-t border-white/30"></div>
                    </div>
                    <div class="relative flex justify-center text-sm">
                        <span class="px-4 bg-transparent text-white/70">Or sign up with</span>
                    </div>
                </div>

                <div class="mt-6">
                    <button type="button" id="googleSignUpButton" onclick="signUpWithGoogle()" 
                            class="w-full flex items-center justify-center px-4 py-3 bg-white text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 transition-all shadow-lg font-semibold relative">
                        <span id="googleButtonContent" class="flex items-center">
                            <img src="https://www.svgrepo.com/show/475656/google-color.svg" class="h-5 w-5 mr-2" alt="Google">
                            Sign up with Google
                        </span>
                        <span id="googleButtonSpinner" class="hidden flex items-center">
                            <i class="fas fa-spinner fa-spin mr-2"></i>
                            Signing up with Google...
                        </span>
                    </button>
                </div>
            </div>
        </div>
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
                // Disable Google Sign-Up button if not configured
                const googleButton = document.querySelector('button[onclick="signUpWithGoogle()"]');
                if (googleButton) {
                    googleButton.disabled = true;
                    googleButton.textContent = 'Google Sign-Up Not Configured';
                    googleButton.classList.add('opacity-50', 'cursor-not-allowed');
                }
            }
            firebase.initializeApp(firebaseConfig);
        }

        function signUpWithGoogle() {
            const button = document.getElementById('googleSignUpButton');
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
                            user: {
                                email: user.email,
                                name: user.displayName,
                                firstName: user.displayName ? user.displayName.split(' ')[0] : '',
                                lastName: user.displayName ? user.displayName.split(' ').slice(1).join(' ') : '',
                                avatar: user.photoURL,
                                emailVerified: user.emailVerified
                            }
                        };
                    });
                })
                .then((authData) => {
                    return fetch('{{ route("auth.google.callback") }}', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '{{ csrf_token() }}'
                        },
                        body: JSON.stringify({
                            id_token: authData.idToken,
                            user: authData.user,
                            is_signup: true // Flag to indicate this is from signup flow
                        })
                    });
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Store session data
                        if (data.token) {
                            localStorage.setItem('palevel_token', data.token);
                        }
                        if (data.user) {
                            localStorage.setItem('palevel_user', JSON.stringify(data.user));
                        }
                        
                        // Redirect to role selection or dashboard based on user status
                        if (data.needs_profile_setup) {
                            window.location.href = data.redirect_url || '{{ route("signup.profile") }}';
                        } else {
                            window.location.href = data.redirect_url || '{{ route("dashboard") }}';
                        }
                    } else {
                        throw new Error(data.message || 'Google sign-up failed');
                    }
                })
                .catch((error) => {
                    console.error('Google sign-up error:', error);
                    
                    // Reset button state
                    button.disabled = false;
                    button.classList.remove('opacity-75', 'cursor-not-allowed');
                    buttonContent.classList.remove('hidden');
                    buttonSpinner.classList.add('hidden');
                    
                    // Show error message
                    if (error.message.includes('popup-closed-by-user')) {
                        // User closed the popup - don't show error
                        return;
                    }
                    
                    buttonContent.innerHTML = '<i class="fas fa-exclamation-triangle mr-2"></i>Error';
                    buttonSpinner.classList.add('hidden');
                    
                    alert('Google Sign-Up failed. Please check console for details.');
                    
                    // Reset button after 3 seconds
                    setTimeout(() => {
                        buttonContent.innerHTML = '<img src="https://www.svgrepo.com/show/475656/google-color.svg" class="h-5 w-5 mr-2" alt="Google">Sign up with Google';
                    }, 3000);
                });
        }
    </script>
</body>
</html>
