<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Complete Profile - Student</title>
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
<body class="gradient-bg min-h-screen flex items-center justify-center p-4">
    <!-- Background Logo Effect -->
    <div class="absolute inset-0 flex items-center justify-center opacity-5 pointer-events-none">
        <div class="w-96 h-96 bg-white rounded-full"></div>
    </div>

    <div class="w-full max-w-2xl glass-effect rounded-2xl p-8 shadow-2xl slide-up relative z-10">
        <div class="mb-8 flex items-center justify-between">
            <div>
                <h2 class="text-white text-3xl anta-font font-bold">Complete Your Profile</h2>
                <div class="text-white/80 mt-1">Student Account Setup</div>
            </div>
            <div class="glass-effect w-14 h-14 rounded-full flex items-center justify-center shadow-lg">
                <i class="fas fa-graduation-cap text-white text-2xl"></i>
            </div>
        </div>

        <!-- User Info from Google -->
        @if(!empty($oauthUserData))
        <div class="mb-6 p-4 bg-white/10 rounded-lg border border-white/20">
            <div class="flex items-center space-x-4">
                @if(!empty($oauthUserData['photo_url']))
                <img src="{{ $oauthUserData['photo_url'] }}" alt="Profile" class="w-16 h-16 rounded-full border-2 border-white/50">
                @else
                <div class="w-16 h-16 rounded-full bg-white/20 flex items-center justify-center">
                    <i class="fas fa-user text-white text-2xl"></i>
                </div>
                @endif
                <div class="text-white">
                    <div class="font-semibold text-lg">{{ $oauthUserData['display_name'] ?? 'User' }}</div>
                    <div class="text-white/80">{{ $oauthUserData['email'] }}</div>
                </div>
            </div>
        </div>
        @endif

        <form id="profileForm" class="space-y-6">
            @csrf
            
            <!-- Demographics Section -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                    <label for="gender" class="block text-sm font-medium text-white mb-2">Gender</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-venus-mars text-white/60"></i>
                        </div>
                        <select name="gender" id="gender" 
                                class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all appearance-none">
                            <option value="" class="text-gray-800">Select Gender</option>
                            <option value="Male" class="text-gray-800">Male</option>
                            <option value="Female" class="text-gray-800">Female</option>
                            <option value="Prefer not to say" class="text-gray-800">Prefer not to say</option>
                        </select>
                        <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                            <i class="fas fa-chevron-down text-white/60"></i>
                        </div>
                    </div>
                </div>
                <div>
                    <label for="date_of_birth" class="block text-sm font-medium text-white mb-2">Date of Birth</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-calendar-alt text-white/60"></i>
                        </div>
                        <input name="date_of_birth" id="date_of_birth" type="date" 
                               class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all" />
                    </div>
                </div>
            </div>

            <!-- Student Specific Fields -->
            <div class="space-y-6">
                <div>
                    <label for="university" class="block text-sm font-medium text-white mb-2">University *</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-university text-white/60"></i>
                        </div>
                        <select id="university" name="university" required
                                class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all appearance-none">
                        </select>
                        <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                            <i class="fas fa-chevron-down text-white/60"></i>
                        </div>
                    </div>
                </div>
                <div>
                    <label for="year_of_study" class="block text-sm font-medium text-white mb-2">Year of Study *</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-graduation-cap text-white/60"></i>
                        </div>
                        <select id="year_of_study" name="year_of_study" required
                                class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all appearance-none">
                            <option value="" class="text-gray-800">Select Year</option>
                            <option value="1st Year" class="text-gray-800">1st Year</option>
                            <option value="2nd Year" class="text-gray-800">2nd Year</option>
                            <option value="3rd Year" class="text-gray-800">3rd Year</option>
                            <option value="4th Year" class="text-gray-800">4th Year</option>
                            <option value="Postgraduate" class="text-gray-800">Postgraduate</option>
                        </select>
                        <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                            <i class="fas fa-chevron-down text-white/60"></i>
                        </div>
                    </div>
                </div>
                
                <!-- Phone Number (required for OAuth) -->
                <div>
                    <label for="phone_number" class="block text-sm font-medium text-white mb-2">Phone Number *</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-phone text-white/60"></i>
                        </div>
                        <input name="phone_number" id="phone_number" type="tel" required
                               class="pl-10 w-full px-4 py-3 bg-white/20 border border-white/30 rounded-lg text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                               placeholder="Enter your phone number" />
                    </div>
                </div>
            </div>

            <div class="flex items-center justify-between pt-4">
                <a href="{{ route('signup.flow') }}" class="text-white/80 hover:text-white transition-colors flex items-center">
                    <i class="fas fa-arrow-left mr-2"></i> Back
                </a>
                <button type="button" id="completeBtn" 
                        class="bg-white text-teal-700 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg flex items-center">
                    Complete Setup <i class="fas fa-check-circle ml-2"></i>
                </button>
            </div>
        </form>
    </div>

    <script>
        const completeBtn = document.getElementById('completeBtn');

        async function loadUniversities(){
            try{
                const res = await fetch("{{ route('signup.universities') }}");
                const list = await res.json();
                const sel = document.getElementById('university');
                sel.innerHTML = '<option value="" class="text-gray-800">Select University</option>' + list.map(u=>`<option class="text-gray-800">${u}</option>`).join('');
            }catch(e){ console.warn('Failed to load universities'); }
        }

        loadUniversities();

        completeBtn.addEventListener('click', async ()=>{
            const university = document.getElementById('university').value;
            const yearOfStudy = document.getElementById('year_of_study').value;
            const phoneNumber = document.getElementById('phone_number').value;
            
            if(!university){
                PalevelDialog.error('Please select your university');
                return;
            }
            
            if(!yearOfStudy){
                PalevelDialog.error('Please select your year of study');
                return;
            }
            
            if(!phoneNumber || phoneNumber.trim().length < 9){
                PalevelDialog.error('Please enter a valid phone number');
                return;
            }

            try{
                completeBtn.disabled = true; 
                const originalText = completeBtn.innerHTML;
                completeBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Completing setup...';

                const data = {
                    gender: document.getElementById('gender').value,
                    date_of_birth: document.getElementById('date_of_birth').value,
                    university: university,
                    year_of_study: yearOfStudy,
                    phone_number: phoneNumber
                };

                const res = await fetch("{{ route('signup.oauth.complete.student') }}", {
                    method: 'POST', 
                    headers: { 
                        'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value, 
                        'Content-Type':'application/json' 
                    },
                    body: JSON.stringify(data)
                });
                
                const json = await res.json();
                if(res.ok && json.success){ 
                    window.location = json.redirect || "{{ route('tenant.dashboard') }}"; 
                }
                else if(json.errors){ 
                    PalevelDialog.error(Object.values(json.errors)[0][0]); 
                }
                else { 
                    PalevelDialog.error(json.error || 'Failed to complete setup'); 
                }
            }catch(e){ 
                PalevelDialog.error('Network error'); 
            }
            
            completeBtn.disabled = false; 
            if(completeBtn.innerHTML.includes('Completing')) completeBtn.innerHTML = 'Complete Setup <i class="fas fa-check-circle ml-2"></i>';
        });
    </script>

    @include('partials.palevel-dialog')
</body>
</html>
