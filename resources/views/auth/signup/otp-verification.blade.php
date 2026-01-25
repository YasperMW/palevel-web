<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Account - PaLevel</title>
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

    <div class="w-full max-w-xl glass-effect rounded-2xl p-8 shadow-2xl slide-up relative z-10">
        <div class="mb-8 flex items-center justify-between">
            <div>
                <h2 class="text-white text-3xl anta-font font-bold">Verify your email</h2>
                <div class="text-white/80 mt-1">Step 2 of 3</div>
            </div>
            <div class="glass-effect w-14 h-14 rounded-full flex items-center justify-center shadow-lg">
                <i class="fas fa-envelope-open-text text-white text-2xl"></i>
            </div>
        </div>

        <p class="text-white/80 mb-6 text-lg">We've sent a 6-digit code to <strong class="text-white font-semibold">{{ $email }}</strong></p>

        <form id="otpForm" class="space-y-6">
            @csrf
            <div>
                <label for="otp" class="text-white/80 mb-2 block text-sm font-medium">Enter Verification Code</label>
                <input name="otp" id="otp" maxlength="6" 
                       class="w-full px-4 py-4 bg-white/20 border border-white/30 rounded-xl text-white text-2xl tracking-[0.5em] text-center font-bold placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent transition-all"
                       placeholder="000000" />
                <p id="error_otp" class="text-red-300 text-sm mt-2 hidden flex items-center justify-center"><i class="fas fa-exclamation-circle mr-1"></i> <span></span></p>
            </div>

            <div class="flex items-center justify-between pt-4">
                <a href="{{ route('signup.personal', ['userType' => Session::get('signup_user_type','tenant')]) }}" class="text-white/80 hover:text-white transition-colors flex items-center">
                    <i class="fas fa-arrow-left mr-2"></i> Back
                </a>
                <div class="flex items-center gap-4">
                    <button type="button" id="resendBtn" class="text-white/80 hover:text-white text-sm underline transition-colors">Resend Code</button>
                    <button type="button" id="verifyBtn" 
                            class="bg-white text-teal-700 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transform hover:scale-105 transition-all duration-300 shadow-lg flex items-center">
                        Verify <i class="fas fa-check ml-2"></i>
                    </button>
                </div>
            </div>
        </form>
    </div>

    <script>
        const verifyBtn = document.getElementById('verifyBtn');
        const resendBtn = document.getElementById('resendBtn');
        const form = document.getElementById('otpForm');

        function showError(msg){ 
            const el = document.getElementById('error_otp'); 
            el.querySelector('span').textContent=msg; 
            el.classList.remove('hidden'); 
            // Shake animation
            const input = document.getElementById('otp');
            input.classList.add('animate-pulse');
            setTimeout(() => input.classList.remove('animate-pulse'), 500);
        }
        function clearError(){ 
            const el = document.getElementById('error_otp'); 
            el.querySelector('span').textContent=''; 
            el.classList.add('hidden'); 
        }

        verifyBtn.addEventListener('click', async ()=>{
            clearError();
            const otp = document.getElementById('otp').value.trim();
            if(!otp) { showError('OTP is required'); return; }
            if(!/^[0-9]{6}$/.test(otp)){ showError('OTP must be a 6-digit code'); return; }
            try{
                verifyBtn.disabled=true; 
                const originalText = verifyBtn.innerHTML;
                verifyBtn.innerHTML='<i class="fas fa-spinner fa-spin mr-2"></i> Verifying...';
                
                const res = await fetch("{{ route('signup.verify.post') }}", {
                    method: 'POST', headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value, 'Content-Type':'application/json' },
                    body: JSON.stringify({ otp })
                });
                const json = await res.json();
                if(res.ok && json.success){ window.location = json.redirect || "{{ route('dashboard') }}"; }
                else if(json.errors) { showError(Object.values(json.errors)[0][0]); }
                else { showError(json.error || 'Invalid code'); }
            }catch(e){ showError('Network error'); }
            verifyBtn.disabled=false; 
            if(verifyBtn.innerHTML.includes('Verifying')) verifyBtn.innerHTML = 'Verify <i class="fas fa-check ml-2"></i>';
        });

        resendBtn.addEventListener('click', async ()=>{
            resendBtn.disabled=true; 
            const originalText = resendBtn.textContent;
            resendBtn.textContent='Resending...';
            try{
                const res = await fetch("{{ route('signup.resend_otp') }}", { method: 'POST', headers: { 'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value } });
                const json = await res.json();
                if (json && json.error) {
                    PalevelDialog.error(json.error);
                } else {
                    PalevelDialog.info((json && json.message) ? json.message : 'OTP resent');
                }
            }catch(e){ PalevelDialog.error('Network error'); }
            resendBtn.disabled=false; resendBtn.textContent='Resend Code';
        });
    </script>

    @include('partials.palevel-dialog')
</body>
</html>
