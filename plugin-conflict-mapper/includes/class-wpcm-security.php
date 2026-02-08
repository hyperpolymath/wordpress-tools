<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Security Class
 *
 * Centralized security utilities integrating php-aegis with WordPress.
 * Provides validation, sanitization, and security verification.
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.1.0
 * @see https://github.com/hyperpolymath/php-aegis
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

use PhpAegis\Validator;
use PhpAegis\Sanitizer;

/**
 * WPCM_Security class
 *
 * Security layer integrating php-aegis with WordPress-specific functions.
 * Requires PHP 8.2+.
 */
class WPCM_Security {

    /**
     * php-aegis Validator instance
     */
    private static ?Validator $validator = null;

    /**
     * php-aegis Sanitizer instance
     */
    private static ?Sanitizer $sanitizer = null;

    /**
     * Get Validator instance (lazy initialization)
     */
    private static function validator(): Validator {
        return self::$validator ??= new Validator();
    }

    /**
     * Get Sanitizer instance (lazy initialization)
     */
    private static function sanitizer(): Sanitizer {
        return self::$sanitizer ??= new Sanitizer();
    }

    /**
     * Validate email address using php-aegis
     *
     * @param string $email Email to validate.
     * @return bool True if valid email.
     */
    public static function validate_email(string $email): bool {
        return self::validator()->email($email);
    }

    /**
     * Validate URL using php-aegis
     *
     * @param string $url URL to validate.
     * @return bool True if valid URL.
     */
    public static function validate_url(string $url): bool {
        return self::validator()->url($url);
    }

    /**
     * Validate integer within range
     *
     * @param mixed    $value Value to validate.
     * @param int|null $min   Minimum value (optional).
     * @param int|null $max   Maximum value (optional).
     * @return bool True if valid integer within range.
     */
    public static function validate_int(mixed $value, ?int $min = null, ?int $max = null): bool {
        $options = [];

        if ($min !== null) {
            $options['min_range'] = $min;
        }

        if ($max !== null) {
            $options['max_range'] = $max;
        }

        $filter_options = empty($options) ? null : ['options' => $options];

        return filter_var($value, FILTER_VALIDATE_INT, $filter_options) !== false;
    }

    /**
     * Validate boolean value
     *
     * @param mixed $value Value to validate.
     * @return bool True if valid boolean representation.
     */
    public static function validate_bool(mixed $value): bool {
        return filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) !== null;
    }

    /**
     * Validate IP address
     *
     * @param string   $ip   IP address to validate.
     * @param int|null $type FILTER_FLAG_IPV4 or FILTER_FLAG_IPV6 (optional).
     * @return bool True if valid IP address.
     */
    public static function validate_ip(string $ip, ?int $type = null): bool {
        return filter_var($ip, FILTER_VALIDATE_IP, $type) !== false;
    }

    /**
     * Validate slug format
     *
     * Checks if string contains only lowercase alphanumeric and hyphens.
     *
     * @param string $slug Slug to validate.
     * @return bool True if valid slug format.
     */
    public static function validate_slug(string $slug): bool {
        return (bool) preg_match('/^[a-z0-9]+(?:-[a-z0-9]+)*$/', $slug);
    }

    /**
     * Sanitize HTML for safe output using php-aegis
     *
     * Prevents XSS by encoding special characters.
     *
     * @param string $input Input to sanitize.
     * @return string Sanitized output safe for HTML.
     */
    public static function sanitize_html(string $input): string {
        return self::sanitizer()->html($input);
    }

    /**
     * Strip all HTML and PHP tags using php-aegis
     *
     * @param string $input Input to strip.
     * @return string Content without tags.
     */
    public static function strip_tags(string $input): string {
        return self::sanitizer()->stripTags($input);
    }

    /**
     * Sanitize text field (WordPress wrapper)
     *
     * @param string $input Input to sanitize.
     * @return string Sanitized text.
     */
    public static function sanitize_text(string $input): string {
        return sanitize_text_field($input);
    }

    /**
     * Sanitize key (WordPress wrapper)
     *
     * @param string $input Input to sanitize.
     * @return string Sanitized key.
     */
    public static function sanitize_key(string $input): string {
        return sanitize_key($input);
    }

    /**
     * Sanitize textarea field (WordPress wrapper)
     *
     * @param string $input Input to sanitize.
     * @return string Sanitized textarea content.
     */
    public static function sanitize_textarea(string $input): string {
        return sanitize_textarea_field($input);
    }

    /**
     * Sanitize file name (WordPress wrapper)
     *
     * @param string $input Input to sanitize.
     * @return string Sanitized file name.
     */
    public static function sanitize_filename(string $input): string {
        return sanitize_file_name($input);
    }

    /**
     * Sanitize and validate integer
     *
     * Returns absolute integer value, always positive.
     *
     * @param mixed $input Input to sanitize.
     * @return int Absolute integer value.
     */
    public static function sanitize_int(mixed $input): int {
        return absint($input);
    }

    /**
     * Sanitize integer allowing negative values
     *
     * @param mixed $input Input to sanitize.
     * @return int Integer value.
     */
    public static function sanitize_int_signed(mixed $input): int {
        return (int) $input;
    }

    /**
     * Verify WordPress nonce
     *
     * @param string $nonce  Nonce to verify.
     * @param string $action Action name.
     * @return bool True if valid nonce.
     */
    public static function verify_nonce(string $nonce, string $action): bool {
        return wp_verify_nonce($nonce, $action) !== false;
    }

    /**
     * Check AJAX referer (nonce)
     *
     * @param string $action    Action name.
     * @param string $query_arg Query argument containing nonce.
     * @param bool   $die       Whether to die on failure.
     * @return bool|int False on failure, 1 or 2 on success.
     */
    public static function check_ajax_nonce(
        string $action,
        string $query_arg = '_wpnonce',
        bool $die = false
    ): bool|int {
        return check_ajax_referer($action, $query_arg, $die);
    }

    /**
     * Check user capability
     *
     * @param string $capability Capability to check.
     * @return bool True if user has capability.
     */
    public static function check_capability(string $capability = 'manage_options'): bool {
        return current_user_can($capability);
    }

    /**
     * Verify AJAX request security
     *
     * Combines nonce verification and capability check.
     *
     * @param string $nonce_action Nonce action name.
     * @param string $nonce_key    POST key containing nonce.
     * @param string $capability   Required capability.
     * @return bool True if request is valid.
     */
    public static function verify_ajax_request(
        string $nonce_action,
        string $nonce_key = 'nonce',
        string $capability = 'manage_options'
    ): bool {
        if (!self::check_ajax_nonce($nonce_action, $nonce_key, false)) {
            return false;
        }

        return self::check_capability($capability);
    }

    /**
     * Send unauthorized JSON response and die
     *
     * @param string $message Error message.
     * @return never
     */
    public static function send_unauthorized(string $message = ''): never {
        if (empty($message)) {
            $message = __('Security check failed', 'wp-plugin-conflict-mapper');
        }

        wp_send_json_error(['message' => $message], 403);
    }

    /**
     * Send forbidden JSON response and die
     *
     * @param string $message Error message.
     * @return never
     */
    public static function send_forbidden(string $message = ''): never {
        if (empty($message)) {
            $message = __('Insufficient permissions', 'wp-plugin-conflict-mapper');
        }

        wp_send_json_error(['message' => $message], 403);
    }

    /**
     * Get and sanitize POST parameter
     *
     * @param string $key     Parameter key.
     * @param string $type    Sanitization type: text, int, email, url, key, textarea.
     * @param mixed  $default Default value if not set.
     * @return mixed Sanitized value.
     */
    public static function get_post_param(string $key, string $type = 'text', mixed $default = ''): mixed {
        // phpcs:ignore WordPress.Security.NonceVerification.Missing -- Nonce should be verified separately
        if (!isset($_POST[$key])) {
            return $default;
        }

        // phpcs:ignore WordPress.Security.NonceVerification.Missing -- Nonce should be verified separately
        $value = $_POST[$key];

        return self::sanitize_by_type($value, $type);
    }

    /**
     * Get and sanitize GET parameter
     *
     * @param string $key     Parameter key.
     * @param string $type    Sanitization type: text, int, email, url, key, textarea.
     * @param mixed  $default Default value if not set.
     * @return mixed Sanitized value.
     */
    public static function get_get_param(string $key, string $type = 'text', mixed $default = ''): mixed {
        // phpcs:ignore WordPress.Security.NonceVerification.Recommended -- Nonce should be verified separately
        if (!isset($_GET[$key])) {
            return $default;
        }

        // phpcs:ignore WordPress.Security.NonceVerification.Recommended -- Nonce should be verified separately
        $value = $_GET[$key];

        return self::sanitize_by_type($value, $type);
    }

    /**
     * Sanitize value by type
     *
     * @param mixed  $value Value to sanitize.
     * @param string $type  Sanitization type.
     * @return mixed Sanitized value.
     */
    private static function sanitize_by_type(mixed $value, string $type): mixed {
        return match ($type) {
            'int' => self::sanitize_int($value),
            'int_signed' => self::sanitize_int_signed($value),
            'email' => sanitize_email($value),
            'url' => esc_url_raw($value),
            'key' => self::sanitize_key($value),
            'textarea' => self::sanitize_textarea($value),
            'filename' => self::sanitize_filename($value),
            'html' => wp_kses_post($value),
            default => self::sanitize_text($value),
        };
    }

    /**
     * Escape output for HTML context (WordPress wrapper)
     *
     * @param string $output Output to escape.
     * @return string Escaped output.
     */
    public static function esc_html(string $output): string {
        return esc_html($output);
    }

    /**
     * Escape output for HTML attribute context (WordPress wrapper)
     *
     * @param string $output Output to escape.
     * @return string Escaped output.
     */
    public static function esc_attr(string $output): string {
        return esc_attr($output);
    }

    /**
     * Escape output for URL context (WordPress wrapper)
     *
     * @param string $output Output to escape.
     * @return string Escaped output.
     */
    public static function esc_url(string $output): string {
        return esc_url($output);
    }

    /**
     * Escape output for JavaScript context (WordPress wrapper)
     *
     * @param string $output Output to escape.
     * @return string Escaped output.
     */
    public static function esc_js(string $output): string {
        return esc_js($output);
    }

    /**
     * Check for potentially dangerous patterns in content
     *
     * @param string $content Content to check.
     * @return array<array{type: string, message: string}> Array of detected issues.
     */
    public static function detect_dangerous_patterns(string $content): array {
        $issues = [];

        $dangerous_patterns = [
            'eval'             => '/\beval\s*\(/i',
            'base64_decode'    => '/\bbase64_decode\s*\(/i',
            'shell_exec'       => '/\bshell_exec\s*\(/i',
            'exec'             => '/\bexec\s*\(/i',
            'system'           => '/\bsystem\s*\(/i',
            'passthru'         => '/\bpassthru\s*\(/i',
            'popen'            => '/\bpopen\s*\(/i',
            'proc_open'        => '/\bproc_open\s*\(/i',
            'unserialize'      => '/\bunserialize\s*\(/i',
            'create_function'  => '/\bcreate_function\s*\(/i',
            'preg_replace_e'   => '/preg_replace\s*\(\s*[\'"][^\'"]*\/[a-zA-Z]*e/i',
            'extract'          => '/\bextract\s*\(\s*\$_(GET|POST|REQUEST)/i',
            'sql_injection'    => '/\$wpdb->(query|get_results)\s*\(\s*["\'].*?\$[a-zA-Z_]/',
        ];

        foreach ($dangerous_patterns as $name => $pattern) {
            if (preg_match($pattern, $content)) {
                $issues[] = [
                    'type'    => $name,
                    'message' => sprintf('Potentially dangerous pattern detected: %s', $name),
                ];
            }
        }

        return $issues;
    }
}
