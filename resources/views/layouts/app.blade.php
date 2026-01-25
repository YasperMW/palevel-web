<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Palevel Dashboard') - Palevel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/palevel-dialog.css') }}">
    @stack('styles')
    <script>
        const API_BASE_URL = '{{ config("services.api.base_url", "http://192.168.43.12:8888") }}';
        const AUTH_TOKEN = '{{ Session::get("palevel_token") }}';
        const CURRENT_USER = @json(Session::get('palevel_user'));
    </script>
</head>
<body class="bg-gray-50">
    <div id="app">
        @if(Session::has('palevel_user'))
            @include('partials.navigation')
        @endif
        
        <main class="@if(Session::has('palevel_user')) pt-16 @endif">
            @if(session('error'))
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4" role="alert">
                    <span class="block sm:inline">{{ session('error') }}</span>
                    <button type="button" class="absolute top-0 bottom-0 right-0 px-4 py-3" onclick="this.parentElement.remove()">
                        <span class="text-red-500">&times;</span>
                    </button>
                </div>
            @endif
            
            @if(session('success'))
                <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4" role="alert">
                    <span class="block sm:inline">{{ session('success') }}</span>
                    <button type="button" class="absolute top-0 bottom-0 right-0 px-4 py-3" onclick="this.parentElement.remove()">
                        <span class="text-green-500">&times;</span>
                    </button>
                </div>
            @endif

            @yield('content')
        </main>
    </div>

    @include('partials.palevel-dialog')

    <script src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
    <script src="{{ asset('js/palevel-dialog.js') }}" defer></script>
    @stack('scripts')
</body>
</html>
