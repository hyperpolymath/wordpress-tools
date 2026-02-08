<?php
/**
 * Sinople Cryptographic Suite - Usage Examples
 *
 * This file demonstrates how to use the cryptographic functions.
 * DO NOT include this file in production - it's for reference only.
 *
 * @package Sinople
 * @since 1.0.0
 */

// This file should NOT be included in functions.php
// It's documentation only

/**
 * EXAMPLE 1: Argon2id Password Hashing
 *
 * Automatically applied to all WordPress password operations.
 * No code changes needed - just activate the theme.
 */

// User registration/password change
// WordPress will automatically use Argon2id (512 MiB, 8 iter, 4 lanes)
$user_id = wp_create_user( 'username', 'password', 'email@example.com' );

// Login verification also automatic
$user = wp_authenticate( 'username', 'password' );

/**
 * EXAMPLE 2: XChaCha20-Poly1305 Encryption
 *
 * Use for encrypting sensitive options, transients, or metadata.
 */

// Store encrypted API key
sinople_set_encrypted_option( 'openai_api_key', 'sk-...' );

// Retrieve encrypted API key
$api_key = sinople_get_encrypted_option( 'openai_api_key' );

// Encrypt arbitrary data
$plaintext = 'Sensitive data';
$encrypted = sinople_encrypt( $plaintext );

// Decrypt
$decrypted = sinople_decrypt( $encrypted );

// Use custom encryption key (instead of master key)
$custom_key = random_bytes( SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES );
$encrypted = sinople_encrypt( $plaintext, $custom_key );
$decrypted = sinople_decrypt( $encrypted, $custom_key );

/**
 * EXAMPLE 3: SHAKE256 Hashing
 *
 * Use for file integrity, cache keys, or content hashing.
 */

// Hash uploaded file (automatic via filter)
// The integrity hash is added to the upload array automatically

// Manual file hashing
$file_path = '/path/to/file.txt';
$hash = sinople_hash_file( $file_path );

// Hash arbitrary data
$data = 'Some content';
$hash = sinople_shake_hash( $data );

// Generate longer hash (1024 bits)
$long_hash = sinople_shake_hash( $data, 128 );

// Store content hash in post meta
function save_post_integrity_hash( $post_id ) {
    $content = get_post_field( 'post_content', $post_id );
    $hash = sinople_shake_hash( $content );
    update_post_meta( $post_id, '_content_integrity_hash', $hash );
}
add_action( 'save_post', 'save_post_integrity_hash' );

/**
 * EXAMPLE 4: Ed25519 Signatures
 *
 * Use for REST API authentication, Webmention verification, or data integrity.
 */

// Generate keypair (do once, store securely)
$keypair = sinople_generate_keypair();
$public_key = $keypair['public'];
$secret_key = $keypair['secret'];

// Store keys (encrypted)
sinople_set_encrypted_option( 'ed25519_public_key', $public_key );
sinople_set_encrypted_option( 'ed25519_secret_key', $secret_key );

// Sign API request
$request_data = wp_json_encode( array( 'action' => 'webmention', 'source' => 'https://example.com' ) );
$signature = sinople_sign( $request_data, $secret_key );

// Send signature in header
$response = wp_remote_post( 'https://api.example.com/endpoint', array(
    'headers' => array(
        'X-Signature' => base64_encode( $signature ),
    ),
    'body' => $request_data,
) );

// Verify signature (recipient side)
$received_data = file_get_contents( 'php://input' );
$received_signature = base64_decode( $_SERVER['HTTP_X_SIGNATURE'] ?? '' );
$public_key = sinople_get_encrypted_option( 'ed25519_public_key' );

if ( sinople_verify_signature( $received_data, $received_signature, $public_key ) ) {
    // Signature valid, process request
} else {
    // Signature invalid, reject request
    wp_send_json_error( 'Invalid signature', 401 );
}

/**
 * EXAMPLE 5: HKDF Key Derivation
 *
 * Derive application-specific keys from a master key.
 */

// Get master key (from environment or wp-config.php)
$master_key = sinople_get_master_key();

// Derive multiple keys for different purposes
$keys = sinople_generate_derived_keys( $master_key );

// Use derived keys
$db_encryption_key = $keys['database'];
$session_key = $keys['session'];
$api_key = $keys['api'];

// Derive single key
$cache_key = sinople_derive_key( $master_key, 'cache-encryption', 32 );

// Derive key with custom salt
$user_specific_key = sinople_derive_key(
    $master_key,
    'user-' . $user_id,
    32,
    wp_salt( 'auth' )
);

/**
 * EXAMPLE 6: Secure Webmention Handler
 *
 * Complete example using multiple cryptographic primitives.
 */
function sinople_secure_webmention_handler( WP_REST_Request $request ) {
    // 1. Verify signature
    $signature = $request->get_header( 'X-Signature' );
    $public_key = sinople_get_encrypted_option( 'webmention_public_key' );

    if ( ! $signature || ! sinople_verify_signature(
        $request->get_body(),
        base64_decode( $signature ),
        $public_key
    ) ) {
        return new WP_Error( 'invalid_signature', 'Invalid signature', array( 'status' => 401 ) );
    }

    // 2. Get encrypted credentials
    $api_credentials = sinople_get_encrypted_option( 'webmention_credentials' );

    // 3. Hash source URL for deduplication
    $source_hash = sinople_shake_hash( $request->get_param( 'source' ) );

    // Check if already processed
    if ( get_transient( 'webmention_' . $source_hash ) ) {
        return new WP_Error( 'duplicate', 'Already processed', array( 'status' => 409 ) );
    }

    // 4. Process webmention...
    // Store result with encrypted metadata if needed

    // 5. Set transient (dedupe for 24 hours)
    set_transient( 'webmention_' . $source_hash, true, DAY_IN_SECONDS );

    return rest_ensure_response( array( 'status' => 'accepted' ) );
}

/**
 * EXAMPLE 7: Diagnostics
 *
 * Check if all cryptographic features are available.
 */
$status = sinople_crypto_diagnostics();

if ( $status['argon2id'] ) {
    echo "✅ Argon2id password hashing: Available\n";
} else {
    echo "❌ Argon2id: Requires PHP 7.2+\n";
}

if ( $status['xchacha20'] ) {
    echo "✅ XChaCha20-Poly1305 encryption: Available\n";
} else {
    echo "❌ XChaCha20: Requires libsodium extension\n";
}

if ( $status['shake256'] ) {
    echo "✅ SHAKE256 hashing: Available\n";
} else {
    echo "❌ SHAKE256: Not available in this PHP version\n";
}

/**
 * EXAMPLE 8: Configuration in wp-config.php
 */

/*
// Add to wp-config.php:

// Enable/disable cryptographic suite
define( 'SINOPLE_ENABLE_CRYPTO_SUITE', true );

// Set master encryption key (GENERATE THIS SECURELY!)
// openssl rand -base64 32
define( 'SINOPLE_MASTER_KEY', 'YOUR_32_BYTE_BASE64_KEY_HERE' );

// Or use environment variable:
// export SINOPLE_MASTER_KEY="your-key-here"

// Disable Argon2id if it causes performance issues
// (not recommended - falls back to bcrypt)
// define( 'SINOPLE_ENABLE_ARGON2ID', false );
*/

/**
 * EXAMPLE 9: Performance Considerations
 */

// Argon2id is intentionally slow (GPU resistance)
// Test hashing time:
$start = microtime( true );
$hash = wp_hash_password( 'test_password' );
$duration = microtime( true ) - $start;
echo "Password hashing took: " . round( $duration * 1000 ) . "ms\n";
// Expected: 500-2000ms depending on server

// XChaCha20 is very fast
$start = microtime( true );
$encrypted = sinople_encrypt( str_repeat( 'x', 1024 * 1024 ) ); // 1 MB
$duration = microtime( true ) - $start;
echo "1MB encryption took: " . round( $duration * 1000 ) . "ms\n";
// Expected: < 10ms

/**
 * EXAMPLE 10: Security Best Practices
 */

// 1. ALWAYS use encrypted options for sensitive data
sinople_set_encrypted_option( 'payment_gateway_key', $key );

// 2. NEVER log decrypted data
// BAD:
// error_log( 'API Key: ' . $decrypted_key );

// GOOD:
error_log( 'API Key configured: ' . ( $decrypted_key ? 'Yes' : 'No' ) );

// 3. Verify signatures before processing external data
if ( ! sinople_verify_signature( $data, $sig, $public_key ) ) {
    return; // Reject
}

// 4. Use derived keys instead of reusing master key
$specific_key = sinople_derive_key( $master_key, 'specific-purpose' );
$encrypted = sinople_encrypt( $data, $specific_key );

// 5. Hash before comparing sensitive strings (timing-safe)
$expected_hash = sinople_shake_hash( $expected_token );
$provided_hash = sinople_shake_hash( $provided_token );
if ( hash_equals( $expected_hash, $provided_hash ) ) {
    // Valid
}
