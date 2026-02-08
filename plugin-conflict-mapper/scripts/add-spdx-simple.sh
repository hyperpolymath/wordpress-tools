#!/usr/bin/env bash
# Add SPDX headers to all PHP files for RSR Gold compliance

cd /home/user/wp-plugin-conflict-mapper

count=0
skipped=0

echo "Adding SPDX headers to PHP files..."

# Find all PHP files excluding vendor and node_modules
find . -name "*.php" \
    -not -path "*/vendor/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/build/*" \
    -type f | while read file; do

    # Check if file already has SPDX header
    if grep -q "SPDX-License-Identifier" "$file" 2>/dev/null; then
        echo "⏭️  Skip: $file (already has SPDX)"
        continue
    fi

    # Check if file starts with <?php
    if head -n 1 "$file" 2>/dev/null | grep -q "<?php"; then
        # Create backup
        cp "$file" "$file.bak"

        # Add SPDX header after <?php tag
        (
            echo "<?php"
            echo "/**"
            echo " * SPDX-License-Identifier: AGPL-3.0-or-later OR Palimpsest-0.8"
            echo " *"
            echo " * @package WP_Plugin_Conflict_Mapper"
            echo " * @license AGPL-3.0-or-later OR Palimpsest-0.8"
            echo " */"
            tail -n +2 "$file.bak"
        ) > "$file"

        # Remove backup
        rm "$file.bak"

        echo "✅ Added: $file"
    else
        echo "⚠️  Skip: $file (no <?php tag)"
    fi
done

echo ""
echo "✅ SPDX headers added to all eligible PHP files"
