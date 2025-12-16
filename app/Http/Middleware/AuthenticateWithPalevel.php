<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class AuthenticateWithPalevel
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $token = Session::get('palevel_token');
        $user = Session::get('palevel_user');

        if (!$token || !$user) {
            return redirect()->route('login')->with('error', 'Please login to continue.');
        }

        // Check role-based access if roles are specified
        if (!empty($roles) && !in_array($user['user_type'], $roles)) {
            return redirect()->route('dashboard')->with('error', 'Unauthorized access.');
        }

        // Share user data with all views
        view()->share('currentUser', $user);
        view()->share('userToken', $token);

        return $next($request);
    }
}
