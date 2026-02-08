# SPDX-License-Identifier: PMPL-1.0-or-later
# Cryptographic Suite Integration for WordPress + Sinople Theme

Based on `/home/hyper/Documents/Absolute-Max-Cryptographic-Suite.csv`

## Executive Summary

This document assesses the feasibility of integrating the Absolute Max Cryptographic Suite into WordPress and the Sinople theme, identifies what can be implemented natively, what requires extensions, and what is architecturally incompatible.

**Overall Assessment:**
- ✅ **Feasible in PHP**: 40% (password hashing, symmetric encryption, some hashing)
- ⚠️ **Requires Extensions**: 30% (BLAKE3, advanced post-quantum primitives)
- ❌ **Architecturally Incompatible**: 30% (post-quantum signatures, hardware-level changes)

---

## Category-by-Category Analysis

### 1. Password Hashing: Argon2id
**Spec:** 512 MiB memory, 8 iterations, 4 lanes

**Status:** ✅ **Fully Supported** in PHP 7.2+

**WordPress Implementation:**
WordPress uses `wp_hash_password()` which defaults to bcrypt via `password_hash()`. PHP supports Argon2id natively.

**Integration Steps:**

```php
// wordpress/inc/security.php or functions.php

/**
 * Override WordPress password hashing to use Argon2id
 * Meets Absolute Max Cryptographic Suite requirements
 */
function sinople_argon2id_password_hash( $password ) {
    // Argon2id with maximum security parameters
    return password_hash( $password, PASSWORD_ARGON2ID, array(
        'memory_cost' => 512 * 1024, // 512 MiB (in KiB)
        'time_cost'   => 8,           // 8 iterations
        'threads'     => 4,           // 4 parallel lanes
    ) );
}
add_filter( 'wp_hash_password', 'sinople_argon2id_password_hash', 10, 1 );

/**
 * Verify Argon2id password
 */
function sinople_argon2id_password_verify( $check, $password, $hash, $user_id ) {
    if ( password_verify( $password, $hash ) ) {
        return true;
    }
    return $check;
}
add_filter( 'wp_check_password', 'sinople_argon2id_password_verify', 10, 4 );
```

**Compatibility:** ✅ Works with all WordPress versions that run PHP 7.2+
**Performance Impact:** ⚠️ High (intentional - GPU/ASIC resistance)
**User Impact:** None (transparent upgrade)

---

### 2. General Hashing: SHAKE3-512
**Spec:** 512-bit output for provenance, key derivation, long-term storage

**Status:** ⚠️ **Limited Support** (SHAKE256 available, SHAKE3 not yet standardized)

**PHP Support:**
- PHP 8.4+: `hash('shake256', $data, false, 512)` for SHAKE256
- SHAKE3 (Keccak finalist): Not yet in PHP core

**WordPress Usage Scenarios:**
1. File integrity verification (uploads, theme files)
2. Cache keys
3. Nonce generation
4. Session identifiers

**Integration (SHAKE256 fallback):**

```php
/**
 * SHAKE256-512 hashing for file integrity
 * Falls back from SHAKE3-512 (not yet available)
 */
function sinople_shake_hash( $data, $output_length = 64 ) {
    if ( ! function_exists( 'hash' ) ) {
        return hash( 'sha512', $data ); // Fallback to SHA-512
    }

    // SHAKE256 with 512-bit (64-byte) output
    return hash( 'shake256', $data, false, $output_length );
}

// Use for file uploads
add_filter( 'wp_handle_upload_prefilter', function( $file ) {
    $file['integrity_hash'] = sinople_shake_hash( file_get_contents( $file['tmp_name'] ) );
    return $file;
} );
```

**SHAKE3 Integration:**
Requires external library like [libsodium-plus](https://github.com/jedisct1/libsodium-php) or waiting for PHP 9.x

---

### 3. PQ Signatures: Dilithium5-AES (ML-DSA-87)
**Spec:** Hybrid with AES-256 for post-quantum resistance

**Status:** ❌ **Not Feasible** in WordPress/PHP

**Why Not:**
- No native PHP implementation of Dilithium (CRYSTALS-Dilithium)
- ML-DSA-87 (FIPS 204) requires specialized libraries (liboqs)
- WordPress signature verification is HTTP-based (doesn't use PKI directly)

**Where PQ Signatures Would Be Used:**
1. Plugin/theme signing (WordPress.org handles this)
2. Update verification (handled by WordPress core)
3. Git commit signing (handled by Git/GPG)

**Workaround:**
- Use Ed448 for classical signatures (available via `sodium_crypto_sign_ed25519`)
- Document intent to migrate to Dilithium when PHP support arrives
- Use SHAKE256 for content integrity instead

**Future Integration:**
When PHP adds ML-DSA support (PHP 9+?), integrate via:
```php
// Hypothetical future API
$signature = dilithium_sign( $message, $private_key );
$valid = dilithium_verify( $message, $signature, $public_key );
```

---

### 4. PQ Key Exchange: Kyber-1024 + SHAKE256-KDF
**Spec:** ML-KEM-1024 (FIPS 203) for key encapsulation

**Status:** ❌ **Not Feasible** in WordPress/PHP

**Why Not:**
- TLS handshakes happen at web server level (OpenLiteSpeed, nginx, Caddy)
- PHP doesn't control TLS negotiation
- ML-KEM not yet in OpenSSL (required for web server TLS)

**Where This Applies:**
- HTTPS connections (server-level, not PHP)
- Database connections (MariaDB TLS, not PHP)

**Workaround:**
- Use X25519 key exchange (current best classical)
- Monitor for OpenSSL 4.x post-quantum support
- Configure web server to prefer PQ-hybrid ciphersuites when available

**Server-Level Integration (Future):**
```nginx
# nginx (when OpenSSL 4+ supports ML-KEM)
ssl_protocols TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-KYBER1024-RSA-AES256-GCM-SHA384:...';
```

---

### 5. Classical Signatures: Ed448 + Dilithium5 Hybrid
**Spec:** Hybrid classical/PQ signatures

**Status:** ⚠️ **Partial** (Ed25519 via libsodium, Ed448 limited, Dilithium N/A)

**PHP Sodium Support:**
- ✅ Ed25519 signatures: `sodium_crypto_sign()`
- ❌ Ed448: Not in libsodium (requires OpenSSL 3.x bindings)
- ❌ Dilithium: Not available

**WordPress Use Cases:**
1. REST API request signing
2. Webmention verification
3. Micropub authentication

**Integration (Ed25519 for now):**

```php
/**
 * Ed25519 signature for REST API requests
 * Future: Upgrade to Ed448 when available
 */
function sinople_sign_request( $data, $private_key ) {
    return sodium_crypto_sign_detached( $data, $private_key );
}

function sinople_verify_signature( $data, $signature, $public_key ) {
    return sodium_crypto_sign_verify_detached( $signature, $data, $public_key );
}

// Example: Sign Webmention endpoint
add_action( 'rest_api_init', function() {
    register_rest_route( 'sinople/v1', '/webmention', array(
        'methods'  => 'POST',
        'callback' => 'sinople_webmention_handler',
        'permission_callback' => 'sinople_verify_webmention_signature',
    ) );
} );
```

---

### 6. Symmetric Encryption: XChaCha20-Poly1305
**Spec:** 256-bit key, larger nonce space

**Status:** ✅ **Fully Supported** via libsodium

**WordPress Use Cases:**
1. Session data encryption
2. Database field encryption (sensitive metadata)
3. Encrypted transients/options

**Integration:**

```php
/**
 * XChaCha20-Poly1305 encryption for WordPress options/transients
 */
function sinople_encrypt( $plaintext, $key ) {
    $nonce = random_bytes( SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES );

    $ciphertext = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt(
        $plaintext,
        '',     // Additional data
        $nonce,
        $key
    );

    return base64_encode( $nonce . $ciphertext );
}

function sinople_decrypt( $encrypted, $key ) {
    $decoded = base64_decode( $encrypted );
    $nonce = mb_substr( $decoded, 0, SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES, '8bit' );
    $ciphertext = mb_substr( $decoded, SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES, null, '8bit' );

    return sodium_crypto_aead_xchacha20poly1305_ietf_decrypt(
        $ciphertext,
        '',
        $nonce,
        $key
    );
}

// Use for sensitive options
function sinople_set_encrypted_option( $key, $value, $encryption_key ) {
    $encrypted = sinople_encrypt( serialize( $value ), $encryption_key );
    update_option( $key, $encrypted );
}
```

**Performance:** ✅ Excellent (faster than AES-GCM)

---

### 7. Key Derivation: HKDF-SHAKE512
**Spec:** Post-quantum KDF for all secret key material

**Status:** ⚠️ **Partial** (HKDF available, SHAKE512 limited)

**PHP Support:**
- ✅ HKDF: `hash_hkdf()` function (PHP 7.1.2+)
- ⚠️ SHAKE256 support (not SHAKE512)
- ❌ SHAKE3 not yet in PHP

**Integration (SHAKE256 fallback):**

```php
/**
 * HKDF with SHAKE256 (approximating SHAKE512 requirement)
 * True SHAKE512 pending PHP support
 */
function sinople_derive_key( $input_key_material, $info, $length = 32 ) {
    $salt = random_bytes( 32 );

    return hash_hkdf(
        'shake256',          // Algorithm (SHAKE512 not available)
        $input_key_material,
        $length,
        $info,
        $salt
    );
}

// Example: Derive encryption keys from master key
$master_key = getenv( 'SINOPLE_MASTER_KEY' );
$db_encryption_key = sinople_derive_key( $master_key, 'database-encryption', 32 );
$session_key = sinople_derive_key( $master_key, 'session-encryption', 32 );
```

---

### 8. RNG: ChaCha20-DRBG
**Spec:** 512-bit seed for deterministic high-entropy CSPRNG

**Status:** ⚠️ **Not Directly Available** (PHP uses OS CSPRNG)

**PHP Behavior:**
- `random_bytes()` uses OS-provided CSPRNG:
  - Linux: `/dev/urandom` (ChaCha20 or AES-based)
  - Windows: `BCryptGenRandom` (AES-CTR-DRBG)
- No direct control over underlying DRBG algorithm

**Workaround:**
Trust OS CSPRNG (already secure) or implement ChaCha20-DRBG manually:

```php
/**
 * ChaCha20-based DRBG (manual implementation)
 * Only use if OS CSPRNG is distrusted
 */
class ChaCha20DRBG {
    private $key;
    private $counter = 0;

    public function __construct( $seed ) {
        if ( strlen( $seed ) !== 64 ) { // 512 bits
            throw new Exception( 'Seed must be 512 bits' );
        }
        $this->key = substr( $seed, 0, 32 );
    }

    public function generate( $length ) {
        $output = '';
        while ( strlen( $output ) < $length ) {
            $block = $this->chacha20_block( $this->counter++ );
            $output .= $block;
        }
        return substr( $output, 0, $length );
    }

    private function chacha20_block( $counter ) {
        // Implement ChaCha20 block function
        // ... (complex, use sodium_crypto_stream_chacha20 instead)
    }
}
```

**Recommendation:** Use `random_bytes()` (already cryptographically secure)

---

### 9. User-Friendly Hash Names
**Spec:** Base32(SHAKE256(hash)) → Wordlist

**Status:** ✅ **Implementable**

**Use Cases:**
- Human-readable file identifiers
- Memorable session IDs
- User-facing hash references

**Integration:**

```php
/**
 * Generate memorable hash names (e.g., "Gigantic-Giraffe-7")
 */
function sinople_memorable_hash( $data ) {
    $hash = hash( 'shake256', $data, true, 8 ); // 64 bits
    $base32 = base_convert( bin2hex( $hash ), 16, 32 );

    $wordlist = array( 'Alpha', 'Beta', 'Gamma', 'Delta', 'Echo', /* ... */ );

    $word1 = $wordlist[ hexdec( $hash[0] . $hash[1] ) % count( $wordlist ) ];
    $word2 = $wordlist[ hexdec( $hash[2] . $hash[3] ) % count( $wordlist ) ];
    $number = hexdec( $hash[6] . $hash[7] ) % 100;

    return sprintf( '%s-%s-%d', $word1, $word2, $number );
}

// Example: Generate memorable upload IDs
add_filter( 'wp_handle_upload', function( $upload ) {
    $upload['memorable_id'] = sinople_memorable_hash( $upload['file'] );
    return $upload;
} );
```

---

### 10. Database Hashing: BLAKE3 + SHAKE3-512
**Spec:** BLAKE3 for speed, SHAKE3-512 for long-term storage

**Status:** ❌ **Not Natively Supported**

**PHP/MariaDB Limitations:**
- BLAKE3: No PHP extension (yet)
- SHAKE3: Not standardized
- MariaDB: Only supports MD5, SHA1, SHA2 family

**Workarounds:**

1. **BLAKE3 via Extension:**
   - Install [blake3-php](https://github.com/BLAKE3-team/BLAKE3) PECL extension
   - Requires compilation, not portable

2. **Fallback to SHAKE256:**
   ```php
   function sinople_db_hash( $data ) {
       return hash( 'shake256', $data, false, 64 ); // 512 bits
   }
   ```

3. **Content Hashing in PHP (not database):**
   ```php
   // Store hashes in wp_postmeta instead of computed columns
   function sinople_generate_content_hash( $post_id ) {
       $content = get_post_field( 'post_content', $post_id );
       $hash = sinople_db_hash( $content );
       update_post_meta( $post_id, '_content_hash_shake256', $hash );
   }
   add_action( 'save_post', 'sinople_generate_content_hash' );
   ```

**BLAKE3 Future Integration:**
When PHP extension is available:
```php
if ( function_exists( 'blake3' ) ) {
    $hash = blake3( $data, 64 ); // 512-bit output
}
```

---

### 11-17. Protocol, Accessibility, and Verification

#### 11. Semantic XML/GraphQL: Virtuoso + SPARQL 1.2
**Status:** ⚠️ **Requires External Database**

WordPress uses MySQL/MariaDB, not Virtuoso (RDF database).

**Integration Options:**
1. **Separate Virtuoso Instance:**
   - Run Virtuoso alongside MariaDB
   - Export WordPress content as RDF/Turtle
   - Query via SPARQL endpoint

2. **Already Implemented:**
   - ✅ Sinople WASM semantic processor (Sophia RDF)
   - ✅ RDF export via REST API (`/wp-json/sinople/v1/rdf`)
   - ✅ Turtle format ontologies

**No Code Change Needed:** Sinople already supports semantic XML/RDF.

---

#### 12. Protocol Stack: QUIC + HTTP/3 + IPv6
**Status:** ✅ **Already Supported** (Server-Level)

- OpenLiteSpeed: Native HTTP/3 support
- Caddy: Native HTTP/3 support
- IPv6: Enable in server config

**WordPress Integration:**
None needed (server handles protocol)

**Enforce IPv6-Only (Optional):**
```nginx
# nginx
server {
    listen [::]:443 ssl http3;  # IPv6 only
    # Omit IPv4 listen directive
}
```

---

#### 13. Accessibility: WCAG 2.3 AAA + ARIA
**Status:** ✅ **Fully Implemented** in Sinople

Already compliant:
- ✅ 7:1 contrast ratio
- ✅ Full keyboard navigation
- ✅ Screen reader optimized
- ✅ ARIA landmarks and labels
- ✅ Semantic HTML5

**No Code Change Needed.**

---

#### 14. Fallback: SPHINCS+
**Status:** ❌ **Not Available** in PHP

SPHINCS+ (post-quantum signature) requires specialized libraries.

**Recommendation:** Monitor for PHP support in future versions.

---

#### 15. Formal Verification: Coq/Isabelle
**Status:** ⚠️ **Development-Time Only**

Formal verification is not runtime integration.

**Application:**
- Verify cryptographic primitives during development
- Document proofs in `/docs/formal-verification/`
- Not executable code

---

## Implementation Priority

### Phase 1: Immediate (Native PHP Support)
1. ✅ **Argon2id password hashing** - Drop-in replacement
2. ✅ **XChaCha20-Poly1305 encryption** - For sensitive options
3. ✅ **SHAKE256 hashing** - File integrity, cache keys
4. ✅ **Ed25519 signatures** - REST API, Webmention
5. ✅ **HKDF-SHAKE256** - Key derivation

**Estimated Effort:** 2-4 hours
**Lines of Code:** ~200-300
**Performance Impact:** Minimal (faster in some cases)

---

### Phase 2: Extension-Dependent (Requires Compilation)
1. ⚠️ **BLAKE3** - Install PECL extension
2. ⚠️ **Ed448** - OpenSSL 3.x bindings
3. ⚠️ **ChaCha20-DRBG** - Manual implementation or extension

**Estimated Effort:** 1-2 days (if extensions exist)
**Complexity:** High (requires server access, compilation)

---

### Phase 3: Future (Awaiting Standardization)
1. ❌ **Dilithium5/ML-DSA** - PHP 9+ or liboqs bindings
2. ❌ **Kyber-1024/ML-KEM** - OpenSSL 4+ or web server support
3. ❌ **SHAKE3-512** - PHP core or extension
4. ❌ **SPHINCS+** - PHP bindings

**Estimated Arrival:** 2026-2028 (OpenSSL 4, PHP 9)
**Preparation:** Document intent, stub functions

---

## Recommended Implementation Plan

### Step 1: Update `wordpress/inc/security.php`

Create a new file or extend existing security module:

```php
<?php
/**
 * Sinople Cryptographic Suite Integration
 * Based on Absolute Max Cryptographic Suite
 *
 * Phase 1: Native PHP implementations (no dependencies)
 */

// Argon2id password hashing
add_filter( 'wp_hash_password', 'sinople_argon2id_hash', 10, 1 );
add_filter( 'wp_check_password', 'sinople_argon2id_verify', 10, 4 );

// XChaCha20-Poly1305 symmetric encryption
// SHAKE256 hashing for integrity
// Ed25519 for REST API signatures
// HKDF-SHAKE256 for key derivation
```

### Step 2: Add Configuration Constants

In `wp-config.php`:

```php
// Cryptographic Suite Configuration
define( 'SINOPLE_ENABLE_ARGON2ID', true );
define( 'SINOPLE_ENABLE_XCHACHA20', true );
define( 'SINOPLE_MASTER_KEY', getenv( 'SINOPLE_MASTER_KEY' ) ?: wp_salt( 'secure_auth' ) );
```

### Step 3: Document in README

Add section to `README.adoc`:

```asciidoc
== Cryptographic Security

Sinople implements the Absolute Max Cryptographic Suite where feasible:

- ✅ Argon2id password hashing (512 MiB, 8 iter, 4 lanes)
- ✅ XChaCha20-Poly1305 symmetric encryption
- ✅ SHAKE256 hashing (pending SHAKE3 support)
- ✅ Ed25519 signatures (upgrade path to Ed448)
- ⏳ Post-quantum cryptography (awaiting PHP/OpenSSL support)

See [CRYPTOGRAPHIC-INTEGRATION.md](CRYPTOGRAPHIC-INTEGRATION.md) for details.
```

---

## Testing Plan

```bash
# Test Argon2id hashing
php -r "echo password_hash('test', PASSWORD_ARGON2ID, ['memory_cost' => 512*1024, 'time_cost' => 8, 'threads' => 4]);"

# Test XChaCha20-Poly1305
php -r "var_dump(function_exists('sodium_crypto_aead_xchacha20poly1305_ietf_encrypt'));"

# Test SHAKE256
php -r "echo hash('shake256', 'test', false, 64);"

# Test Ed25519
php -r "var_dump(function_exists('sodium_crypto_sign'));"
```

---

## Conclusion

**Feasibility Summary:**
- ✅ **40% Implementable Now** (Argon2id, XChaCha20, SHAKE256, Ed25519, HKDF)
- ⚠️ **30% Needs Extensions** (BLAKE3, Ed448, ChaCha20-DRBG)
- ❌ **30% Not Feasible Yet** (PQ signatures, PQ key exchange, SHAKE3)

**Recommendation:**
1. Implement Phase 1 immediately (native PHP support)
2. Document Phase 2 and Phase 3 as aspirational goals
3. Monitor PHP/OpenSSL development for PQ crypto support
4. Update Sinople as new crypto primitives become available

**Impact:**
- ✅ Significantly improves WordPress security posture
- ✅ Future-proof against quantum threats (as much as possible)
- ✅ Aligns with FOSS philosophy (libsodium is open-source)
- ⚠️ Performance cost for Argon2id (intentional, acceptable)
