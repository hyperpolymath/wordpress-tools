#!/usr/bin/env bash
# Add SPDX headers to all PHP files for RSR Gold compliance
# SPDX-License-Identifier: PMPL-1.0-or-later OR Palimpsest-0.8

set -euo pipefail

# SPDX header template
read -r -d '' SPDX_HEADER << 'EOF' || true
/**
 * SPDX-License-Identifier: PMPL-1.0-or-later OR Palimpsest-0.8
 *
 * @package WP_Plugin_Conflict_Mapper
 * @license AGPL-3.0-or-later OR Palimpsest-0.8
 */
EOF

# Counter for files processed
count=0
skipped=0

echo "Adding SPDX headers to PHP files..."
echo ""

# Find all PHP files excluding vendor and node_modules
while IFS= read -r -d '' file; do
    # Check if file already has SPDX header
    if grep -q "SPDX-License-Identifier" "$file"; then
        echo "⏭️  Skipping (already has SPDX): $file"
        ((skipped++))
        continue
    fi

    # Check if file starts with <?php
    if head -n 1 "$file" | grep -q "<?php"; then
        # Create temporary file
        tmp_file=$(mktemp)

        # Add SPDX header after <?php tag
        echo "<?php" > "$tmp_file"
        echo "$SPDX_HEADER" >> "$tmp_file"
        tail -n +2 "$file" >> "$tmp_file"

        # Replace original file
        mv "$tmp_file" "$file"

        echo "✅ Added SPDX header: $file"
        ((count++))
    else
        echo "⚠️  Skipping (no <?php tag): $file"
        ((skipped++))
    fi
done < <(find . -name "*.php" \
    -not -path "*/vendor/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/build/*" \
    -type f \
    -print0)

echo ""
echo "================================================"
echo "SPDX Header Addition Complete"
echo "================================================"
echo "Files processed: $count"
echo "Files skipped: $skipped"
echo "Total: $((count + skipped))"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test code: just check"
echo "3. Commit: git commit -am 'Add SPDX headers for RSR Gold compliance'"
