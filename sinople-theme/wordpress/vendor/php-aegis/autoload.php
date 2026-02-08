<?php
/**
 * SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024-2025 Hyperpolymath
 *
 * PSR-4 compatible autoloader for PhpAegis in WordPress context.
 *
 * @package PhpAegis
 */

declare(strict_types=1);

spl_autoload_register(function (string $class): void {
    $prefix = 'PhpAegis\\';
    $base_dir = __DIR__ . '/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});
