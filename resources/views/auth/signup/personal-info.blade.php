<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Personal Info - PaLevel Signup</title>
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

        /* Custom dropdown styling for white placeholder and black text */
        select {
            color: black !important;
        }

        select option {
            color: black !important;
        }

        select option:first-child {
            color: white !important;
        }

        select:invalid {
            color: white !important;
        }

        /* Date input styling */
        input[type="date"] {
            color: black !important;
        }

        input[type="date"]::-webkit-datetime-edit-text {
            color: white !important;
        }

        input[type="date"]::-webkit-datetime-edit-month-field {
            color: white !important;
        }

        input[type="date"]::-webkit-datetime-edit-day-field {
            color: white !important;
        }

        input[type="date"]::-webkit-datetime-edit-year-field {
            color: white !important;
        }

        input[type="date"]:not(:valid) {
            color: white !important;
        }
    </style>
</head>
<body class="gradient-bg min-h-screen flex items-center justify-center p-4">
    <!-- Background Logo Effect -->
    <div class="absolute inset-0 flex items-center justify-center opacity-5 pointer-events-none">
        <div class="w-96 h-96 bg-white rounded-full"></div>
    </div>

    <div class="w-full max-w-2xl glass-effect rounded-2xl p-8 shadow-2xl slide-up relative z-10">
        <div class="flex items-center justify-between mb-8">
            <div>
                <h2 class="text-white text-3xl anta-font font-bold">Create Account</h2>
                <p class="text-white/80 mt-1">Complete your registration</p>
            </div>
            <div class="glass-effect w-16 h-16 rounded-full flex items-center justify-center shadow-lg">
                <img src="{{ asset('images/PaLevel Logo-White.png') }}" class="w-10" alt="logo">
            </div>
        </div>

        <form id="personalForm" class="space-y-6">
            @csrf
            <input type="hidden" name="user_type" value="{{ $userType }}">

            <!-- Basic Information -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                    <label for="first_name" class="block text-sm font-medium text-white mb-2">First Name</label>
                    <input name="first_name" id="first_name" required 
                           class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                           placeholder="First name" />
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_first_name"></p>
                </div>
                <div>
                    <label for="last_name" class="block text-sm font-medium text-white mb-2">Last Name</label>
                    <input name="last_name" id="last_name" required 
                           class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                           placeholder="Last name" />
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_last_name"></p>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                    <label for="email" class="block text-sm font-medium text-white mb-2">Email Address</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-envelope text-white/60"></i>
                        </div>
                        <input name="email" id="email" type="email" required 
                               class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                               placeholder="Enter your email" />
                    </div>
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_email"></p>
                </div>
                <div>
                    <label for="phone_number" class="block text-sm font-medium text-white mb-2">Phone Number</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-phone text-white/60"></i>
                        </div>
                        <input name="phone_number" id="phone_number" required 
                               class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                               placeholder="Enter your phone number" />
                    </div>
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_phone_number"></p>
                </div>
            </div>

            <!-- Additional Profile Fields -->
            @if($userType === 'tenant')
                <div>
                    <label for="university" class="block text-sm font-medium text-white mb-2">University</label>
                    <select name="university" id="university" required
                            class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                        <option value="" class="text-white">Select your university</option>
                        <option value="University of Malawi (UNIMA)">University of Malawi (UNIMA)</option>
                        <option value="Malawi University of Science and Technology (MUST)">Malawi University of Science and Technology (MUST)</option>
                        <option value="Lilongwe University of Agriculture and Natural Resources (LUANAR)">Lilongwe University of Agriculture and Natural Resources (LUANAR)</option>
                        <option value="Mzuzu University (MZUNI)">Mzuzu University (MZUNI)</option>
                        <option value="Malawi University of Business and Applied Sciences (MUBAS)">Malawi University of Business and Applied Sciences (MUBAS)</option>
                        <option value="Kamuzu University of Health Sciences (KUHeS)">Kamuzu University of Health Sciences (KUHeS)</option>
                        <option value="Malawi College of Accountancy (MCA)">Malawi College of Accountancy (MCA)</option>
                        <option value="Other">Other</option>
                    </select>
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_university"></p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label for="year_of_study" class="block text-sm font-medium text-white mb-2">Year of Study</label>
                        <select name="year_of_study" id="year_of_study" required
                                class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                            <option value="" class="text-white">Select your year</option>
                            <option value="1st Year">1st Year</option>
                            <option value="2nd Year">2nd Year</option>
                            <option value="3rd Year">3rd Year</option>
                            <option value="4th Year">4th Year</option>
                            <option value="Postgraduate">Postgraduate</option>
                        </select>
                        <p class="text-red-300 text-sm mt-1 hidden" id="error_year_of_study"></p>
                    </div>
                    <div>
                        <label for="gender" class="block text-sm font-medium text-white mb-2">Gender</label>
                        <select name="gender" id="gender" required
                                class="w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                            <option value="" class="text-white">Select gender</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                            <option value="Prefer not to say">Prefer not to say</option>
                        </select>
                        <p class="text-red-300 text-sm mt-1 hidden" id="error_gender"></p>
                    </div>
                </div>
            @endif

            @if($userType === 'landlord')
                <div>
                    <label for="national_id_image" class="block text-sm font-medium text-white mb-2">National ID Document</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-id-card text-white/60"></i>
                        </div>
                        <input name="national_id_image" id="national_id_image" type="file" required
                               class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-white/20 file:text-black hover:file:bg-white/30 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                               accept=".jpg,.jpeg,.png,.pdf">
                    </div>
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_national_id_image"></p>
                </div>
            @endif

            <!-- Date of Birth - Only for Tenants -->
            @if($userType === 'tenant')
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label for="date_of_birth" class="block text-sm font-medium text-white mb-2">Date of Birth</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-calendar text-white/60"></i>
                            </div>
                            <input name="date_of_birth" id="date_of_birth" type="date" required
                                   class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all">
                        </div>
                        <p class="text-red-300 text-sm mt-1 hidden" id="error_date_of_birth"></p>
                    </div>
                </div>
            @endif

            <!-- Password Fields - Moved to End -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                    <label for="password" class="block text-sm font-medium text-white mb-2">Password</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-lock text-white/60"></i>
                        </div>
                        <input name="password" id="password" type="password" required 
                               class="pl-10 pr-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                               placeholder="Create a password">
                        <button type="button" id="togglePassword" 
                                class="absolute inset-y-0 right-0 pr-3 flex items-center text-white/60 hover:text-white transition-colors">
                            <i id="eyeIcon" class="fas fa-eye"></i>
                        </button>
                    </div>
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_password"></p>
                </div>
                <div>
                    <label for="password_confirmation" class="block text-sm font-medium text-white mb-2">Confirm Password</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-lock text-white/60"></i>
                        </div>
                        <input name="password_confirmation" id="password_confirmation" type="password" required 
                               class="pl-10 pr-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-black placeholder-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                               placeholder="Confirm your password">
                        <button type="button" id="toggleConfirmPassword" 
                                class="absolute inset-y-0 right-0 pr-3 flex items-center text-white/60 hover:text-white transition-colors">
                            <i id="confirmEyeIcon" class="fas fa-eye"></i>
                        </button>
                    </div>
                    <p class="text-red-300 text-sm mt-1 hidden" id="error_password_confirmation"></p>
                    <p id="passwordMatch" class="text-sm mt-1 hidden"></p>
                </div>
            </div>
            
            <!-- Password Strength Indicator - Full Width -->
            <div class="md:col-span-2">
                <div class="mt-2">
                    <div class="flex justify-between items-center mb-1">
                        <span class="text-xs text-white/70">Password Strength</span>
                        <span id="strengthText" class="text-xs font-medium">-</span>
                    </div>
                    <div class="w-full bg-white/20 rounded-full h-2 overflow-hidden">
                        <div id="strengthBar" class="h-full transition-all duration-300 rounded-full" style="width: 0%"></div>
                    </div>
                    <div id="passwordRequirements" class="mt-2 space-y-1 text-xs text-white/60">
                        <div id="req-length" class="flex items-center">
                            <i id="check-length" class="fas fa-circle text-gray-400 mr-2 w-3"></i>
                            <span>At least 8 characters</span>
                        </div>
                        <div id="req-lowercase" class="flex items-center">
                            <i id="check-lowercase" class="fas fa-circle text-gray-400 mr-2 w-3"></i>
                            <span>One lowercase letter (a-z)</span>
                        </div>
                        <div id="req-uppercase" class="flex items-center">
                            <i id="check-uppercase" class="fas fa-circle text-gray-400 mr-2 w-3"></i>
                            <span>One uppercase letter (A-Z)</span>
                        </div>
                        <div id="req-number" class="flex items-center">
                            <i id="check-number" class="fas fa-circle text-gray-400 mr-2 w-3"></i>
                            <span>One number (0-9)</span>
                        </div>
                        <div id="req-special" class="flex items-center">
                            <i id="check-special" class="fas fa-circle text-gray-400 mr-2 w-3"></i>
                            <span>One special character (!@#$%^&*.)</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="flex items-center justify-between pt-4">
                <a href="{{ route('signup.flow') }}" class="text-white/80 hover:text-white transition-colors flex items-center">
                    <i class="fas fa-arrow-left mr-2"></i> Back
                </a>
                <button type="button" id="nextBtn" 
                        class="bg-white text-teal-700 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg flex items-center">
                    Continue <i class="fas fa-arrow-right ml-2"></i>
                </button>
            </div>
        </form>
    </div>

    <script>
        const form = document.getElementById('personalForm');
        const nextBtn = document.getElementById('nextBtn');

        // Password visibility toggles
        const togglePassword = document.getElementById('togglePassword');
        const passwordInput = document.getElementById('password');
        const eyeIcon = document.getElementById('eyeIcon');

        const toggleConfirmPassword = document.getElementById('toggleConfirmPassword');
        const confirmPasswordInput = document.getElementById('password_confirmation');
        const confirmEyeIcon = document.getElementById('confirmEyeIcon');

        const passwordMatch = document.getElementById('passwordMatch');

        // Smart placeholder and input color management
        function updateInputState(input, placeholder, isFocused) {
            if (isFocused) {
                input.classList.remove('placeholder-white');
                input.classList.add('placeholder-black');
                input.setAttribute('placeholder', '');
            } else {
                input.classList.remove('placeholder-black');
                input.classList.add('placeholder-white');
                input.setAttribute('placeholder', placeholder);
            }
        }

        // Password visibility toggle
        if (togglePassword && passwordInput && eyeIcon) {
            togglePassword.addEventListener('click', function() {
                const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                passwordInput.setAttribute('type', type);
                
                if (type === 'password') {
                    eyeIcon.classList.remove('fa-eye-slash');
                    eyeIcon.classList.add('fa-eye');
                } else {
                    eyeIcon.classList.remove('fa-eye');
                    eyeIcon.classList.add('fa-eye-slash');
                }
            });
        }

        // Confirm password visibility toggle
        if (toggleConfirmPassword && confirmPasswordInput && confirmEyeIcon) {
            toggleConfirmPassword.addEventListener('click', function() {
                const type = confirmPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                confirmPasswordInput.setAttribute('type', type);
                
                if (type === 'password') {
                    confirmEyeIcon.classList.remove('fa-eye-slash');
                    confirmEyeIcon.classList.add('fa-eye');
                } else {
                    confirmEyeIcon.classList.remove('fa-eye');
                    confirmEyeIcon.classList.add('fa-eye-slash');
                }
            });
        }

        // Focus/blur event listeners for smart placeholder behavior
        if (passwordInput) {
            passwordInput.addEventListener('focus', () => updateInputState(passwordInput, 'Create a password', true));
            passwordInput.addEventListener('blur', () => updateInputState(passwordInput, 'Create a password', false));
        }

        if (confirmPasswordInput) {
            confirmPasswordInput.addEventListener('focus', () => updateInputState(confirmPasswordInput, 'Confirm your password', true));
            confirmPasswordInput.addEventListener('blur', () => updateInputState(confirmPasswordInput, 'Confirm your password', false));
        }

        // Real-time password match feedback
        function checkPasswordMatch() {
            const password = passwordInput.value;
            const confirmPassword = confirmPasswordInput.value;
            
            if (confirmPassword.length > 0) {
                if (password === confirmPassword) {
                    passwordMatch.textContent = '✓ Passwords match';
                    passwordMatch.classList.remove('text-red-300', 'text-yellow-300');
                    passwordMatch.classList.add('text-green-300');
                    passwordMatch.classList.remove('hidden');
                } else {
                    passwordMatch.textContent = '✗ Passwords do not match';
                    passwordMatch.classList.remove('text-green-300', 'text-yellow-300');
                    passwordMatch.classList.add('text-red-300');
                    passwordMatch.classList.remove('hidden');
                }
            } else {
                passwordMatch.classList.add('hidden');
            }
        }

        // Password strength checker
        function checkPasswordStrength() {
            const password = passwordInput.value;
            if (!password) {
                updateStrengthBar(0, 'Empty');
                return;
            }

            let strength = 0;
            const requirements = {
                length: password.length >= 8,
                lowercase: /[a-z]/.test(password),
                uppercase: /[A-Z]/.test(password),
                number: /[0-9]/.test(password),
                special: /[!@#$%^&*.]/.test(password)
            };

            // Update requirement indicators
            updateRequirement('check-length', requirements.length);
            updateRequirement('check-lowercase', requirements.lowercase);
            updateRequirement('check-uppercase', requirements.uppercase);
            updateRequirement('check-number', requirements.number);
            updateRequirement('check-special', requirements.special);

            // Calculate strength
            Object.values(requirements).forEach(met => {
                if (met) strength++;
            });

            // Update strength bar and text
            if (strength === 0) {
                updateStrengthBar(0, 'Very Weak');
            } else if (strength <= 2) {
                updateStrengthBar(25, 'Weak');
            } else if (strength <= 3) {
                updateStrengthBar(50, 'Fair');
            } else if (strength === 4) {
                updateStrengthBar(75, 'Good');
            } else if (strength === 5) {
                updateStrengthBar(100, 'Strong');
            }
        }

        function updateRequirement(checkId, passed) {
            const element = document.getElementById(checkId);
            if (passed) {
                element.classList.remove('fa-circle', 'text-gray-400');
                element.classList.add('fa-check-circle', 'text-green-400');
            } else {
                element.classList.remove('fa-check-circle', 'text-green-400');
                element.classList.add('fa-circle', 'text-gray-400');
            }
        }

        function updateStrengthBar(percentage, text) {
            const strengthBar = document.getElementById('strengthBar');
            const strengthText = document.getElementById('strengthText');
            
            strengthBar.style.width = percentage + '%';
            strengthText.textContent = text;
            
            // Update bar color based on strength
            strengthBar.classList.remove('bg-red-500', 'bg-orange-500', 'bg-yellow-500', 'bg-green-500');
            
            if (percentage <= 25) {
                strengthBar.classList.add('bg-red-500');
            } else if (percentage <= 50) {
                strengthBar.classList.add('bg-orange-500');
            } else if (percentage <= 75) {
                strengthBar.classList.add('bg-yellow-500');
            } else {
                strengthBar.classList.add('bg-green-500');
            }
        }

        // Real-time validation for all fields
        function setupRealTimeValidation() {
            const fields = [
                { id: 'first_name', validator: () => validateName(document.getElementById('first_name').value, 'First name') },
                { id: 'last_name', validator: () => validateName(document.getElementById('last_name').value, 'Last name') },
                { id: 'email', validator: () => validateEmail(document.getElementById('email').value) },
                { id: 'phone_number', validator: () => validatePhone(document.getElementById('phone_number').value) },
                { id: 'gender', validator: () => validateRequired(document.getElementById('gender').value, 'Gender') },
                { id: 'date_of_birth', validator: () => validateRequired(document.getElementById('date_of_birth').value, 'Date of birth') }
            ];

            fields.forEach(field => {
                const element = document.getElementById(field.id);
                if (element) {
                    element.addEventListener('input', () => {
                        const result = field.validator();
                        const errorElement = document.getElementById('error_' + field.id);
                        if (errorElement) {
                            if (!result.ok) {
                                errorElement.textContent = result.msg;
                                errorElement.classList.remove('hidden');
                            } else {
                                errorElement.textContent = '';
                                errorElement.classList.add('hidden');
                            }
                        }
                    });

                    element.addEventListener('blur', () => {
                        const result = field.validator();
                        const errorElement = document.getElementById('error_' + field.id);
                        if (errorElement) {
                            if (!result.ok && element.value.trim()) {
                                errorElement.textContent = result.msg;
                                errorElement.classList.remove('hidden');
                            } else {
                                errorElement.textContent = '';
                                errorElement.classList.add('hidden');
                            }
                        }
                    });
                }
            });

            // Role-specific fields
            const userType = document.querySelector('input[name="user_type"]')?.value;
            
            if (userType === 'tenant') {
                ['university', 'year_of_study'].forEach(fieldId => {
                    const element = document.getElementById(fieldId);
                    if (element) {
                        element.addEventListener('change', () => {
                            const result = validateRequired(element.value, fieldId === 'university' ? 'University' : 'Year of study');
                            const errorElement = document.getElementById('error_' + fieldId);
                            if (errorElement) {
                                if (!result.ok) {
                                    errorElement.textContent = result.msg;
                                    errorElement.classList.remove('hidden');
                                } else {
                                    errorElement.textContent = '';
                                    errorElement.classList.add('hidden');
                                }
                            }
                        });
                    }
                });
            }

            if (userType === 'landlord') {
                const idFileInput = document.getElementById('national_id_image');
                if (idFileInput) {
                    idFileInput.addEventListener('change', () => {
                        const file = idFileInput.files[0];
                        const errorElement = document.getElementById('error_national_id_image');
                        if (errorElement) {
                            if (!file) {
                                errorElement.textContent = 'National ID document is required';
                                errorElement.classList.remove('hidden');
                            } else {
                                errorElement.textContent = '';
                                errorElement.classList.add('hidden');
                            }
                        }
                    });
                }
            }
        }

        // Initialize real-time validation
        setupRealTimeValidation();

        // Add event listeners for real-time feedback
        if (passwordInput && confirmPasswordInput) {
            passwordInput.addEventListener('input', () => {
                checkPasswordMatch();
                checkPasswordStrength();
            });
            confirmPasswordInput.addEventListener('input', checkPasswordMatch);
        }

        function showErrors(errors) {
            ['first_name','last_name','email','phone_number','password','password_confirmation','university','year_of_study','gender','date_of_birth','national_id_image'].forEach(k=>{
                const el = document.getElementById('error_'+k);
                if(el) {
                    if(errors[k]){
                        el.textContent = errors[k][0]; el.classList.remove('hidden');
                    } else { el.textContent=''; el.classList.add('hidden'); }
                }
            });
            
            // Handle general errors (not field-specific)
            if(errors.general && errors.general.length > 0) {
                alert(errors.general[0]);
            }
        }

        function validateEmail(email) {
            if(!email || !email.trim()) return { ok: false, msg: 'Email is required' };
            const re = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
            if(!re.test(email.trim())) return { ok: false, msg: 'Invalid email format' };
            return { ok: true };
        }

        function validateName(name, field) {
            if(!name || !name.trim()) return { ok: false, msg: field + ' is required' };
            if(name.trim().length < 2) return { ok: false, msg: field + ' must be at least 2 characters' };
            return { ok: true };
        }

        function validatePhone(phone) {
            if(!phone || !phone.trim()) return { ok: false, msg: 'Phone number is required' };
            const cleaned = phone.replace(/[^0-9+]/g, '');
            if(cleaned.length < 9) return { ok: false, msg: 'Phone number must be at least 9 digits' };
            return { ok: true };
        }

        function validatePassword(password) {
            if(!password || !password.trim()) return { ok: false, msg: 'Password is required' };
            if(password.length < 8) return { ok: false, msg: 'Password must be at least 8 characters' };
            if(!/[a-z]/.test(password)) return { ok: false, msg: 'Password must contain at least one lowercase letter' };
            if(!/[A-Z]/.test(password)) return { ok: false, msg: 'Password must contain at least one uppercase letter' };
            if(!/[0-9]/.test(password)) return { ok: false, msg: 'Password must contain at least one number' };
            if(!/[!@#$%^&*.]/.test(password)) return { ok: false, msg: 'Password must contain at least one special character' };
            return { ok: true };
        }

        function validatePasswordConfirmation(password, confirmPassword) {
            if(!confirmPassword || !confirmPassword.trim()) return { ok: false, msg: 'Password confirmation is required' };
            if(password !== confirmPassword) return { ok: false, msg: 'Passwords do not match' };
            return { ok: true };
        }

        function validateRequired(field, value, fieldName) {
            if(!value || !value.trim()) return { ok: false, msg: fieldName + ' is required' };
            return { ok: true };
        }

        nextBtn.addEventListener('click', async ()=>{
            // Client-side real-time validation matching backend messages
            showErrors({});
            const first = document.getElementById('first_name').value;
            const last = document.getElementById('last_name').value;
            const email = document.getElementById('email').value;
            const phone = document.getElementById('phone_number').value;
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('password_confirmation').value;
            const userType = document.querySelector('input[name="user_type"]').value;

            const vFirst = validateName(first, 'First name');
            const vLast = validateName(last, 'Last name');
            const vEmail = validateEmail(email);
            const vPhone = validatePhone(phone);
            const vPassword = validatePassword(password);
            const vPasswordConfirm = validatePasswordConfirmation(password, confirmPassword);

            const clientErrors = {};
            if(!vFirst.ok) clientErrors.first_name = [vFirst.msg];
            if(!vLast.ok) clientErrors.last_name = [vLast.msg];
            if(!vEmail.ok) clientErrors.email = [vEmail.msg];
            if(!vPhone.ok) clientErrors.phone_number = [vPhone.msg];
            if(!vPassword.ok) clientErrors.password = [vPassword.msg];
            if(!vPasswordConfirm.ok) clientErrors.password_confirmation = [vPasswordConfirm.msg];

            // Additional field validations
            const genderElement = document.getElementById('gender');
            const dobElement = document.getElementById('date_of_birth');
            
            if(genderElement) {
                const gender = genderElement.value;
                const vGender = validateRequired(gender, 'Gender');
                if(!vGender.ok) clientErrors.gender = [vGender.msg];
            }
            
            if(dobElement) {
                const dob = dobElement.value;
                const vDob = validateRequired(dob, 'Date of birth');
                if(!vDob.ok) clientErrors.date_of_birth = [vDob.msg];
            }

            // Role-specific validations
            if(userType === 'tenant') {
                const university = document.getElementById('university').value;
                const year = document.getElementById('year_of_study').value;
                const vUniversity = validateRequired(university, 'University');
                const vYear = validateRequired(year, 'Year of study');
                if(!vUniversity.ok) clientErrors.university = [vUniversity.msg];
                if(!vYear.ok) clientErrors.year_of_study = [vYear.msg];
            }

            if(userType === 'landlord') {
                const idFile = document.getElementById('national_id_image').files[0];
                if(!idFile) clientErrors.national_id_image = ['National ID document is required'];
            }

            if(Object.keys(clientErrors).length > 0){ showErrors(clientErrors); return; }

            const data = new FormData(form);
            const hasFileUpload = userType === 'landlord' && document.getElementById('national_id_image').files[0];
            
            try {
                // Show loading state immediately
                nextBtn.disabled = true; 
                const originalText = nextBtn.innerHTML;
                nextBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Creating Account...';
                nextBtn.classList.add('opacity-75', 'cursor-not-allowed');
                
                let res;
                if (hasFileUpload) {
                    // Use multipart request for file uploads (landlords with ID)
                    res = await fetch("{{ config('palevel.api_url') }}/create_user_with_id/", {
                        method: 'POST',
                        body: data
                    });
                } else {
                    // Use JSON request for regular signup (tenants)
                    res = await fetch("{{ config('palevel.api_url') }}/create_user/", {
                        method: 'POST',
                        headers: { 
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify(Object.fromEntries(data))
                    });
                }
                const json = await res.json();
                if(res.ok){
                    // Account created successfully, redirect to OTP verification
                    // Store signup data in session via Laravel route first
                    const sessionData = {
                        first_name: document.getElementById('first_name').value,
                        last_name: document.getElementById('last_name').value,
                        email: document.getElementById('email').value,
                        phone_number: document.getElementById('phone_number').value,
                        user_type: userType
                    };
                    
                    // Store data in Laravel session for OTP flow
                    await fetch("{{ route('signup.personal.store') }}", {
                        method: 'POST',
                        headers: { 
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value
                        },
                        body: JSON.stringify(sessionData)
                    });
                    
                    window.location = "{{ route('signup.verify') }}";
                } else if(json.errors || json.detail){
                    // Handle API error format
                    const errors = json.errors || { general: [json.detail || 'Registration failed'] };
                    showErrors(errors);
                    // Reset button state on error
                    nextBtn.disabled = false; 
                    nextBtn.innerHTML = originalText;
                    nextBtn.classList.remove('opacity-75', 'cursor-not-allowed');
                } else {
                    alert(json.error || json.detail || 'Failed to create account');
                    // Reset button state on error
                    nextBtn.disabled = false; 
                    nextBtn.innerHTML = originalText;
                    nextBtn.classList.remove('opacity-75', 'cursor-not-allowed');
                }
            } catch(err){ 
                // Reset button state on network error
                nextBtn.disabled = false; 
                nextBtn.innerHTML = originalText;
                nextBtn.classList.remove('opacity-75', 'cursor-not-allowed');
                alert('Network error'); 
            }
        });
    </script>
</body>
</html>
