<?php
/**
 * Sinople Cryptographic Suite Integration
 *
 * Implements the Absolute Max Cryptographic Suite where feasible in PHP.
 * Phase 1: Native PHP implementations (no external dependencies).
 *
 * @package Sinople
 * @since 1.0.0
 * @see CRYPTOGRAPHIC-INTEGRATION.md for full documentation
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Check if cryptographic enhancements are enabled
 *
 * Can be disabled via wp-config.php:
 * define('SINOPLE_ENABLE_CRYPTO_SUITE', false);
 */
if ( ! defined( 'SINOPLE_ENABLE_CRYPTO_SUITE' ) ) {
    define( 'SINOPLE_ENABLE_CRYPTO_SUITE', true );
}

if ( ! SINOPLE_ENABLE_CRYPTO_SUITE ) {
    return;
}

/**
 * 1. ARGON2ID PASSWORD HASHING
 *
 * Spec: 512 MiB memory, 8 iterations, 4 parallel lanes
 * Provides GPU/ASIC resistance for maximum security
 */

/**
 * Override WordPress password hashing to use Argon2id
 *
 * @param string $password Plain text password
 * @return string Hashed password
 */
function sinople_argon2id_hash( $password ) {
    // Check if Argon2id is available (PHP 7.2+)
    if ( ! defined( 'PASSWORD_ARGON2ID' ) ) {
        // Fallback to WordPress default (bcrypt)
        return wp_hash_password( $password );
    }

    // Absolute Max Cryptographic Suite parameters
    $options = array(
        'memory_cost' => 524288,  // 512 MiB (in KiB)
        'time_cost'   => 8,       // 8 iterations
        'threads'     => 4,       // 4 parallel lanes
    );

    $hash = password_hash( $password, PASSWORD_ARGON2ID, $options );

    if ( $hash === false ) {
        // Fallback if hashing fails
        error_log( 'Sinople: Argon2id hashing failed, using WordPress default' );
        return wp_hash_password( $password );
    }

    return $hash;
}

/**
 * Verify Argon2id password
 *
 * @param bool        $check    Password check result
 * @param string      $password Plain text password
 * @param string      $hash     Stored hash
 * @param string|int  $user_id  User ID
 * @return bool True if password matches
 */
function sinople_argon2id_verify( $check, $password, $hash, $user_id ) {
    // If already verified by another method, return that result
    if ( $check ) {
        return $check;
    }

    // Verify using password_verify (handles Argon2id automatically)
    if ( password_verify( $password, $hash ) ) {
        return true;
    }

    return $check;
}

// Only enable if PHP supports Argon2id
if ( defined( 'PASSWORD_ARGON2ID' ) ) {
    add_filter( 'wp_hash_password', 'sinople_argon2id_hash', 10, 1 );
    add_filter( 'check_password', 'sinople_argon2id_verify', 10, 4 );
}

/**
 * 2. XCHACHA20-POLY1305 SYMMETRIC ENCRYPTION
 *
 * Spec: 256-bit keys, larger nonce space
 * Used for encrypting sensitive WordPress options/transients
 */

/**
 * Get master encryption key
 *
 * Priority:
 * 1. SINOPLE_MASTER_KEY environment variable
 * 2. SINOPLE_MASTER_KEY constant in wp-config.php
 * 3. Derived from WordPress salt (less secure)
 *
 * @return string 256-bit key (32 bytes)
 */
function sinople_get_master_key() {
    // Check environment variable first
    $env_key = getenv( 'SINOPLE_MASTER_KEY' );
    if ( $env_key && strlen( $env_key ) === SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES ) {
        return $env_key;
    }

    // Check wp-config.php constant
    if ( defined( 'SINOPLE_MASTER_KEY' ) && strlen( SINOPLE_MASTER_KEY ) === SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES ) {
        return SINOPLE_MASTER_KEY;
    }

    // Fallback: derive from WordPress salts (less secure, but workable)
    $salt_data = wp_salt( 'secure_auth' ) . wp_salt( 'nonce' );
    return hash( 'sha256', $salt_data, true );
}

/**
 * Encrypt data using XChaCha20-Poly1305
 *
 * @param string $plaintext Data to encrypt
 * @param string $key       256-bit encryption key (optional, uses master key)
 * @return string|false Base64-encoded encrypted data or false on failure
 */
function sinople_encrypt( $plaintext, $key = null ) {
    // Check if libsodium is available
    if ( ! function_exists( 'sodium_crypto_aead_xchacha20poly1305_ietf_encrypt' ) ) {
        error_log( 'Sinople: libsodium not available for encryption' );
        return false;
    }

    if ( $key === null ) {
        $key = sinople_get_master_key();
    }

    // Validate key length
    if ( strlen( $key ) !== SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES ) {
        error_log( 'Sinople: Invalid encryption key length' );
        return false;
    }

    try {
        // Generate random nonce (XChaCha20 has 192-bit nonce)
        $nonce = random_bytes( SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES );

        // Encrypt with authenticated encryption
        $ciphertext = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt(
            $plaintext,
            '',     // Additional authenticated data (optional)
            $nonce,
            $key
        );

        // Return nonce + ciphertext, base64-encoded
        return base64_encode( $nonce . $ciphertext );

    } catch ( Exception $e ) {
        error_log( 'Sinople encryption error: ' . $e->getMessage() );
        return false;
    }
}

/**
 * Decrypt data using XChaCha20-Poly1305
 *
 * @param string $encrypted Base64-encoded encrypted data
 * @param string $key       256-bit encryption key (optional, uses master key)
 * @return string|false Decrypted plaintext or false on failure
 */
function sinople_decrypt( $encrypted, $key = null ) {
    // Check if libsodium is available
    if ( ! function_exists( 'sodium_crypto_aead_xchacha20poly1305_ietf_decrypt' ) ) {
        error_log( 'Sinople: libsodium not available for decryption' );
        return false;
    }

    if ( $key === null ) {
        $key = sinople_get_master_key();
    }

    // Validate key length
    if ( strlen( $key ) !== SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES ) {
        error_log( 'Sinople: Invalid decryption key length' );
        return false;
    }

    try {
        // Decode from base64
        $decoded = base64_decode( $encrypted, true );
        if ( $decoded === false ) {
            return false;
        }

        // Extract nonce and ciphertext
        $nonce_length = SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES;
        $nonce = mb_substr( $decoded, 0, $nonce_length, '8bit' );
        $ciphertext = mb_substr( $decoded, $nonce_length, null, '8bit' );

        // Decrypt and verify authentication
        $plaintext = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt(
            $ciphertext,
            '',     // Additional authenticated data (must match encryption)
            $nonce,
            $key
        );

        if ( $plaintext === false ) {
            error_log( 'Sinople: Decryption failed (authentication error)' );
            return false;
        }

        return $plaintext;

    } catch ( Exception $e ) {
        error_log( 'Sinople decryption error: ' . $e->getMessage() );
        return false;
    }
}

/**
 * Set encrypted WordPress option
 *
 * @param string $option Option name
 * @param mixed  $value  Value to encrypt and store
 * @param string $key    Optional encryption key
 * @return bool True on success
 */
function sinople_set_encrypted_option( $option, $value, $key = null ) {
    $serialized = serialize( $value );
    $encrypted = sinople_encrypt( $serialized, $key );

    if ( $encrypted === false ) {
        return false;
    }

    // Store with prefix to identify encrypted options
    return update_option( '_sinople_encrypted_' . $option, $encrypted );
}

/**
 * Get encrypted WordPress option
 *
 * @param string $option  Option name
 * @param mixed  $default Default value if not found
 * @param string $key     Optional encryption key
 * @return mixed Decrypted value or default
 */
function sinople_get_encrypted_option( $option, $default = false, $key = null ) {
    $encrypted = get_option( '_sinople_encrypted_' . $option, false );

    if ( $encrypted === false ) {
        return $default;
    }

    $decrypted = sinople_decrypt( $encrypted, $key );
    if ( $decrypted === false ) {
        return $default;
    }

    return unserialize( $decrypted );
}

/**
 * 3. SHAKE256 HASHING
 *
 * Spec: 512-bit output for integrity verification
 * Note: SHAKE3 not yet available, using SHAKE256 as approximation
 */

/**
 * Generate SHAKE256 hash
 *
 * @param string $data   Data to hash
 * @param int    $length Output length in bytes (default 64 = 512 bits)
 * @return string Hexadecimal hash
 */
function sinople_shake_hash( $data, $length = 64 ) {
    // Check if SHAKE256 is available
    if ( ! function_exists( 'hash' ) || ! in_array( 'shake256', hash_algos(), true ) ) {
        // Fallback to SHA-512
        error_log( 'Sinople: SHAKE256 not available, using SHA-512 fallback' );
        return hash( 'sha512', $data );
    }

    // SHAKE256 with variable output length
    return hash( 'shake256', $data, false, $length );
}

/**
 * Generate file integrity hash
 *
 * @param string $file_path Path to file
 * @return string|false SHAKE256 hash or false on error
 */
function sinople_hash_file( $file_path ) {
    if ( ! file_exists( $file_path ) || ! is_readable( $file_path ) ) {
        return false;
    }

    $content = file_get_contents( $file_path );
    if ( $content === false ) {
        return false;
    }

    return sinople_shake_hash( $content );
}

/**
 * Add integrity hash to uploaded files
 *
 * @param array $file Upload file data
 * @return array Modified file data with integrity hash
 */
function sinople_add_upload_integrity_hash( $file ) {
    if ( isset( $file['tmp_name'] ) && file_exists( $file['tmp_name'] ) ) {
        $file['sinople_integrity_hash'] = sinople_hash_file( $file['tmp_name'] );
    }
    return $file;
}
add_filter( 'wp_handle_upload_prefilter', 'sinople_add_upload_integrity_hash' );

/**
 * 4. ED25519 SIGNATURES
 *
 * Spec: Ed25519 for now, upgrade path to Ed448 + Dilithium5
 * Used for REST API request signing and Webmention verification
 */

/**
 * Generate Ed25519 keypair
 *
 * @return array ['public' => string, 'secret' => string]
 */
function sinople_generate_keypair() {
    if ( ! function_exists( 'sodium_crypto_sign_keypair' ) ) {
        error_log( 'Sinople: libsodium not available for key generation' );
        return false;
    }

    $keypair = sodium_crypto_sign_keypair();

    return array(
        'public' => sodium_crypto_sign_publickey( $keypair ),
        'secret' => sodium_crypto_sign_secretkey( $keypair ),
    );
}

/**
 * Sign data with Ed25519
 *
 * @param string $data       Data to sign
 * @param string $secret_key Secret key (64 bytes)
 * @return string Signature (64 bytes)
 */
function sinople_sign( $data, $secret_key ) {
    if ( ! function_exists( 'sodium_crypto_sign_detached' ) ) {
        error_log( 'Sinople: libsodium not available for signing' );
        return false;
    }

    return sodium_crypto_sign_detached( $data, $secret_key );
}

/**
 * Verify Ed25519 signature
 *
 * @param string $data       Data that was signed
 * @param string $signature  Signature to verify
 * @param string $public_key Public key (32 bytes)
 * @return bool True if signature is valid
 */
function sinople_verify_signature( $data, $signature, $public_key ) {
    if ( ! function_exists( 'sodium_crypto_sign_verify_detached' ) ) {
        error_log( 'Sinople: libsodium not available for verification' );
        return false;
    }

    return sodium_crypto_sign_verify_detached( $signature, $data, $public_key );
}

/**
 * 5. HKDF-SHAKE256 KEY DERIVATION
 *
 * Spec: HKDF with SHAKE256 (approximating SHAKE512 requirement)
 * Used for deriving encryption keys from master key
 */

/**
 * Derive key using HKDF-SHAKE256
 *
 * @param string $input_key_material Input keying material
 * @param string $info               Application-specific context
 * @param int    $length             Output key length in bytes (default 32)
 * @param string $salt               Optional salt
 * @return string Derived key
 */
function sinople_derive_key( $input_key_material, $info, $length = 32, $salt = '' ) {
    // Check if hash_hkdf is available (PHP 7.1.2+)
    if ( ! function_exists( 'hash_hkdf' ) ) {
        // Fallback: simple hash-based derivation (less secure)
        error_log( 'Sinople: hash_hkdf not available, using fallback' );
        return hash( 'sha256', $input_key_material . $info . $salt, true );
    }

    // Use SHAKE256 for HKDF (approximating SHAKE512)
    if ( ! in_array( 'shake256', hash_algos(), true ) ) {
        // Fallback to SHA-256
        return hash_hkdf( 'sha256', $input_key_material, $length, $info, $salt );
    }

    return hash_hkdf( 'shake256', $input_key_material, $length, $info, $salt );
}

/**
 * Generate application-specific keys from master key
 *
 * @param string $master_key Master key
 * @return array Array of derived keys
 */
function sinople_generate_derived_keys( $master_key ) {
    return array(
        'database'   => sinople_derive_key( $master_key, 'sinople-database-encryption', 32 ),
        'session'    => sinople_derive_key( $master_key, 'sinople-session-encryption', 32 ),
        'api'        => sinople_derive_key( $master_key, 'sinople-api-signing', 32 ),
        'cache'      => sinople_derive_key( $master_key, 'sinople-cache-encryption', 32 ),
        'webmention' => sinople_derive_key( $master_key, 'sinople-webmention-signing', 32 ),
    );
}

/**
 * Diagnostic: Check cryptographic suite availability
 *
 * @return array Status of each component
 */
function sinople_crypto_diagnostics() {
    return array(
        'argon2id'     => defined( 'PASSWORD_ARGON2ID' ),
        'xchacha20'    => function_exists( 'sodium_crypto_aead_xchacha20poly1305_ietf_encrypt' ),
        'shake256'     => in_array( 'shake256', hash_algos(), true ),
        'ed25519'      => function_exists( 'sodium_crypto_sign_detached' ),
        'hkdf'         => function_exists( 'hash_hkdf' ),
        'php_version'  => PHP_VERSION,
        'libsodium'    => extension_loaded( 'sodium' ),
    );
}

/**
 * Log cryptographic suite status on theme activation
 */
function sinople_log_crypto_status() {
    if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
        $status = sinople_crypto_diagnostics();
        error_log( 'Sinople Cryptographic Suite Status: ' . wp_json_encode( $status ) );
    }
}
add_action( 'after_setup_theme', 'sinople_log_crypto_status' );
