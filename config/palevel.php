<?php

return [
    'api_url' => env('PALEVEL_API_URL', '??'),
    'api_timeout' => env('PALEVEL_API_TIMEOUT', 10),
    'jwt_secret' => env('PALEVEL_JWT_SECRET', 'palevel-default-secret'),
    'supported_user_types' => ['tenant', 'landlord', 'admin'],
    'default_currency' => 'MWK',
    'file_upload' => [
        'max_size' => 10240, // 10MB in KB
        'allowed_types' => ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
    ],
];
