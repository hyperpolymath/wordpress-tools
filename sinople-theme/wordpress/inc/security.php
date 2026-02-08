<?php
/**
 * Security Integration for Sinople Theme
 *
 * Integrates php-aegis with WordPress security patterns and
 * provides additional hardening utilities.
 *
 * @package Sinople
 * @since 1.0.0
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Sinople Security Class
 *
 * Wraps php-aegis Sanitizer/Validator with WordPress-specific patterns
 * and adds RDF/Turtle-specific sanitization.
 */
class Sinople_Security {

    /**
     * Singleton instance
     *
     * @var Sinople_Security|null
     */
    private static ?Sinople_Security $instance = null;

    /**
     * php-aegis Sanitizer instance (if available)
     *
     * @var object|null
     */
    private ?object $aegis_sanitizer = null;

    /**
     * php-aegis Validator instance (if available)
     *
     * @var object|null
     */
    private ?object $aegis_validator = null;

    /**
     * Get singleton instance
     *
     * @return Sinople_Security
     */
    public static function instance(): Sinople_Security {
        if ( null === self::$instance ) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Private constructor
     */
    private function __construct() {
        $this->init_aegis();
    }

    /**
     * Initialize php-aegis if available
     */
    private function init_aegis(): void {
        // Check if Composer autoload is available
        $autoload_path = get_template_directory() . '/vendor/autoload.php';
        if ( file_exists( $autoload_path ) ) {
            require_once $autoload_path;

            if ( class_exists( 'PhpAegis\\Sanitizer' ) ) {
                $this->aegis_sanitizer = new \PhpAegis\Sanitizer();
            }
            if ( class_exists( 'PhpAegis\\Validator' ) ) {
                $this->aegis_validator = new \PhpAegis\Validator();
            }
        }
    }

    /**
     * Check if php-aegis is available
     *
     * @return bool
     */
    public function is_aegis_available(): bool {
        return null !== $this->aegis_sanitizer;
    }

    /**
     * Sanitize HTML for XSS prevention
     *
     * Uses php-aegis if available, falls back to WordPress function.
     *
     * @param string $input Input string to sanitize.
     * @return string Sanitized string.
     */
    public function sanitize_html( string $input ): string {
        if ( $this->aegis_sanitizer ) {
            return $this->aegis_sanitizer->html( $input );
        }
        return esc_html( $input );
    }

    /**
     * Validate email address
     *
     * Uses php-aegis if available, falls back to WordPress/PHP.
     *
     * @param string $email Email to validate.
     * @return bool True if valid.
     */
    public function validate_email( string $email ): bool {
        if ( $this->aegis_validator ) {
            return $this->aegis_validator->email( $email );
        }
        return is_email( $email ) !== false;
    }

    /**
     * Validate URL
     *
     * Uses php-aegis if available, falls back to PHP filter.
     *
     * @param string $url URL to validate.
     * @return bool True if valid.
     */
    public function validate_url( string $url ): bool {
        if ( $this->aegis_validator ) {
            return $this->aegis_validator->url( $url );
        }
        return filter_var( $url, FILTER_VALIDATE_URL ) !== false;
    }

    /**
     * Escape string for RDF Turtle format
     *
     * Properly escapes special characters per Turtle specification:
     * https://www.w3.org/TR/turtle/#sec-escapes
     *
     * @param string $input String to escape.
     * @return string Turtle-escaped string.
     */
    public function escape_turtle_string( string $input ): string {
        // Turtle string escape sequences (N-Triples compatible)
        $replacements = array(
            '\\' => '\\\\',  // Backslash (must be first)
            '"'  => '\\"',   // Double quote
            "'"  => "\\'",   // Single quote
            "\n" => '\\n',   // Newline
            "\r" => '\\r',   // Carriage return
            "\t" => '\\t',   // Tab
        );

        $escaped = str_replace(
            array_keys( $replacements ),
            array_values( $replacements ),
            $input
        );

        // Remove any control characters that could break parsing
        $escaped = preg_replace( '/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $escaped );

        return $escaped;
    }

    /**
     * Escape string for RDF Turtle IRI
     *
     * @param string $iri IRI to escape.
     * @return string Escaped IRI.
     */
    public function escape_turtle_iri( string $iri ): string {
        // IRIs in Turtle cannot contain: < > " { } | ^ ` \
        // and spaces/controls must be percent-encoded
        $iri = str_replace(
            array( '<', '>', '"', '{', '}', '|', '^', '`', '\\', ' ' ),
            array( '%3C', '%3E', '%22', '%7B', '%7D', '%7C', '%5E', '%60', '%5C', '%20' ),
            $iri
        );
        return $iri;
    }

    /**
     * Validate Turtle literal for RDF safety
     *
     * @param string $value Value to check.
     * @return bool True if safe for Turtle output.
     */
    public function is_safe_turtle_literal( string $value ): bool {
        // Check for injection attempts
        $dangerous_patterns = array(
            '/@prefix\s/i',      // Prefix injection
            '/@base\s/i',        // Base injection
            '/\.\s*$/m',         // Statement terminator injection
            '/;\s*$/m',          // Predicate separator injection
            '/>\s*</m',          // IRI injection
        );

        foreach ( $dangerous_patterns as $pattern ) {
            if ( preg_match( $pattern, $value ) ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Sanitize Micropub content
     *
     * Applies appropriate sanitization based on content type.
     *
     * @param mixed  $content Raw content from Micropub.
     * @param string $type    Content type (html, text, etc).
     * @return string Sanitized content.
     */
    public function sanitize_micropub_content( $content, string $type = 'text' ): string {
        if ( ! is_string( $content ) ) {
            if ( is_array( $content ) && isset( $content[0] ) ) {
                $content = $content[0];
            } else {
                return '';
            }
        }

        switch ( $type ) {
            case 'html':
                // Allow safe HTML subset
                return wp_kses_post( $content );

            case 'text':
            default:
                // Plain text - escape everything
                return sanitize_textarea_field( $content );
        }
    }

    /**
     * Verify IndieAuth token
     *
     * @param string $token    Bearer token.
     * @param string $endpoint Token endpoint URL.
     * @return array|WP_Error Token info on success, error on failure.
     */
    public function verify_indieauth_token( string $token, string $endpoint = 'https://tokens.indieauth.com/token' ): array|\WP_Error {
        // Remove 'Bearer ' prefix if present
        $token = preg_replace( '/^Bearer\s+/i', '', $token );

        if ( empty( $token ) ) {
            return new \WP_Error( 'missing_token', 'No token provided', array( 'status' => 401 ) );
        }

        // Verify token with endpoint
        $response = wp_remote_get( $endpoint, array(
            'headers' => array(
                'Authorization' => 'Bearer ' . $token,
                'Accept'        => 'application/json',
            ),
            'timeout' => 10,
        ) );

        if ( is_wp_error( $response ) ) {
            return $response;
        }

        $code = wp_remote_retrieve_response_code( $response );
        $body = wp_remote_retrieve_body( $response );

        if ( 200 !== $code ) {
            return new \WP_Error(
                'invalid_token',
                'Token verification failed',
                array( 'status' => 401 )
            );
        }

        $data = json_decode( $body, true );

        if ( ! isset( $data['me'] ) ) {
            return new \WP_Error(
                'invalid_response',
                'Token endpoint returned invalid response',
                array( 'status' => 401 )
            );
        }

        // Verify 'me' matches site URL
        $site_url = home_url( '/' );
        if ( rtrim( $data['me'], '/' ) !== rtrim( $site_url, '/' ) ) {
            return new \WP_Error(
                'unauthorized',
                'Token not valid for this site',
                array( 'status' => 403 )
            );
        }

        return $data;
    }

    /**
     * Add security headers
     *
     * Should be called early in the request lifecycle.
     */
    public function add_security_headers(): void {
        if ( headers_sent() ) {
            return;
        }

        // Content Security Policy (relaxed for WordPress admin compatibility)
        if ( ! is_admin() ) {
            header( "Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; frame-ancestors 'self'" );
        }

        // Prevent MIME type sniffing
        header( 'X-Content-Type-Options: nosniff' );

        // Enable XSS filter
        header( 'X-XSS-Protection: 1; mode=block' );

        // Prevent clickjacking
        header( 'X-Frame-Options: SAMEORIGIN' );

        // Referrer policy
        header( 'Referrer-Policy: strict-origin-when-cross-origin' );

        // Permissions policy
        header( "Permissions-Policy: geolocation=(), microphone=(), camera=()" );
    }
}

/**
 * Get security instance
 *
 * @return Sinople_Security
 */
function sinople_security(): Sinople_Security {
    return Sinople_Security::instance();
}

/**
 * Add security headers on init
 */
function sinople_init_security(): void {
    if ( ! is_admin() ) {
        sinople_security()->add_security_headers();
    }
}
add_action( 'send_headers', 'sinople_init_security' );
