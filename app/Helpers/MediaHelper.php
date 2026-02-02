<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Config;

class MediaHelper
{
    /**
     * Resolve the full URL for a media item.
     *
     * @param string|null $path
     * @return string|null
     */
    public static function getMediaUrl(?string $path)
    {
        if (empty($path)) {
            \Illuminate\Support\Facades\Log::warning('MediaHelper: Path is empty');
            return null;
        }

        \Illuminate\Support\Facades\Log::info('MediaHelper: Processing path', ['path' => $path]);

        // If it's already a full URL, return it
        if (filter_var($path, FILTER_VALIDATE_URL)) {
            return $path;
        }

        // Get the API base URL
        $baseUrl = Config::get('palevel.api_url');
        
        // Fallback to services.api.base_url if palevel.api_url is not set or invalid
        if (empty($baseUrl) || $baseUrl === '??') {
            $baseUrl = Config::get('services.api.base_url');
        }
        
        if (empty($baseUrl)) {
            return $path;
        }

        // Ensure base URL doesn't have trailing slash
        $baseUrl = rtrim($baseUrl, '/');
        
        // Clean the path and normalize slashes
        $cleanPath = ltrim(str_replace('\\', '/', $path), '/');
        
        // If the path doesn't start with 'uploads/' and the base URL doesn't end with '/uploads',
        // prepend 'uploads/' to match the backend static mount.
        if (!str_starts_with($cleanPath, 'uploads/') && !str_ends_with($baseUrl, '/uploads')) {
            $cleanPath = 'uploads/' . $cleanPath;
        }
        
        // Ensure path starts with slash for the final concatenation
        $tokenizedPath = '/' . $cleanPath;

        $url = $baseUrl . $tokenizedPath;
        \Illuminate\Support\Facades\Log::info('MediaHelper: Generated URL', ['url' => $url]);
        return $url;
    }
}
