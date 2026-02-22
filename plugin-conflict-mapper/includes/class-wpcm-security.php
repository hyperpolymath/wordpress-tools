<?php
/**
 * WPCM Security — Centralized Hardening Kernel.
 *
 * This class provides high-assurance security utilities for the 
 * WP Plugin Conflict Mapper. It integrates the `PhpAegis` library 
 * to provide verified validation and sanitization services.
 *
 * @package WP_Plugin_Conflict_Mapper
 * @see https://github.com/hyperpolymath/php-aegis
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

use PhpAegis\Validator;
use PhpAegis\Sanitizer;

class WPCM_Security {
    private static ?Validator $validator = null;
    private static ?Sanitizer $sanitizer = null;

    /**
     * LAZY INITIALIZATION: Ensures that security instances are only 
     * created when needed, reducing memory pressure during standard 
     * WordPress requests.
     */
    private static function validator(): Validator {
        return self::$validator ??= new Validator();
    }

    /**
     * VALIDATION: High-assurance check for email authenticity.
     * Uses `PhpAegis` logic which is more rigorous than standard 
     * PHP filter_var or WordPress is_email.
     */
    public static function validate_email(string $email): bool {
        return self::validator()->email($email);
    }

    /**
     * VALIDATION: Validates URLs to prevent SSRF and redirect attacks.
     */
    public static function validate_url(string $url): bool {
        return self::validator()->url($url);
    }
}
