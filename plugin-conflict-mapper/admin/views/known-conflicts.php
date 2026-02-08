<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Known Conflicts Visualization View
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.3.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

// Variables passed from controller: $scan_results, $db_stats, $recommendations
?>

<div class="wrap wpcm-known-conflicts">
    <h1>
        <span class="dashicons dashicons-warning" style="font-size: 30px; width: 30px; height: 30px; margin-right: 10px; color: #d63638;"></span>
        <?php esc_html_e('Known Plugin Conflicts', 'wp-plugin-conflict-mapper'); ?>
    </h1>

    <p class="wpcm-subtitle">
        <?php esc_html_e('Quick scan against our curated database of known plugin conflicts.', 'wp-plugin-conflict-mapper'); ?>
    </p>

    <!-- Summary Cards -->
    <div class="wpcm-conflict-summary">
        <div class="wpcm-summary-card wpcm-summary-total">
            <div class="wpcm-summary-icon">
                <span class="dashicons dashicons-search"></span>
            </div>
            <div class="wpcm-summary-data">
                <span class="wpcm-summary-number"><?php echo esc_html($scan_results['plugins_checked']); ?></span>
                <span class="wpcm-summary-label"><?php esc_html_e('Plugins Checked', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>

        <div class="wpcm-summary-card wpcm-summary-found <?php echo $scan_results['total_conflicts'] > 0 ? 'has-conflicts' : ''; ?>">
            <div class="wpcm-summary-icon">
                <span class="dashicons dashicons-<?php echo $scan_results['total_conflicts'] > 0 ? 'dismiss' : 'yes-alt'; ?>"></span>
            </div>
            <div class="wpcm-summary-data">
                <span class="wpcm-summary-number"><?php echo esc_html($scan_results['total_conflicts']); ?></span>
                <span class="wpcm-summary-label"><?php esc_html_e('Conflicts Found', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>

        <div class="wpcm-summary-card wpcm-summary-critical <?php echo $scan_results['critical_conflicts'] > 0 ? 'has-issues' : ''; ?>">
            <div class="wpcm-summary-icon">
                <span class="dashicons dashicons-megaphone"></span>
            </div>
            <div class="wpcm-summary-data">
                <span class="wpcm-summary-number"><?php echo esc_html($scan_results['critical_conflicts']); ?></span>
                <span class="wpcm-summary-label"><?php esc_html_e('Critical', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>

        <div class="wpcm-summary-card wpcm-summary-high <?php echo $scan_results['high_conflicts'] > 0 ? 'has-issues' : ''; ?>">
            <div class="wpcm-summary-icon">
                <span class="dashicons dashicons-flag"></span>
            </div>
            <div class="wpcm-summary-data">
                <span class="wpcm-summary-number"><?php echo esc_html($scan_results['high_conflicts']); ?></span>
                <span class="wpcm-summary-label"><?php esc_html_e('High', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>

        <div class="wpcm-summary-card wpcm-summary-medium">
            <div class="wpcm-summary-icon">
                <span class="dashicons dashicons-info"></span>
            </div>
            <div class="wpcm-summary-data">
                <span class="wpcm-summary-number"><?php echo esc_html($scan_results['medium_conflicts']); ?></span>
                <span class="wpcm-summary-label"><?php esc_html_e('Medium', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>

        <div class="wpcm-summary-card wpcm-summary-low">
            <div class="wpcm-summary-icon">
                <span class="dashicons dashicons-marker"></span>
            </div>
            <div class="wpcm-summary-data">
                <span class="wpcm-summary-number"><?php echo esc_html($scan_results['low_conflicts']); ?></span>
                <span class="wpcm-summary-label"><?php esc_html_e('Low', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>
    </div>

    <!-- Conflict Type Distribution Chart -->
    <div class="wpcm-charts-row">
        <div class="wpcm-chart-container">
            <h2><?php esc_html_e('Severity Distribution', 'wp-plugin-conflict-mapper'); ?></h2>
            <div class="wpcm-severity-chart" id="wpcm-severity-chart">
                <?php
                $total = max(1, $scan_results['total_conflicts']);
                $severities = array(
                    'critical' => array('count' => $scan_results['critical_conflicts'], 'color' => '#d63638', 'label' => __('Critical', 'wp-plugin-conflict-mapper')),
                    'high' => array('count' => $scan_results['high_conflicts'], 'color' => '#e65100', 'label' => __('High', 'wp-plugin-conflict-mapper')),
                    'medium' => array('count' => $scan_results['medium_conflicts'], 'color' => '#dba617', 'label' => __('Medium', 'wp-plugin-conflict-mapper')),
                    'low' => array('count' => $scan_results['low_conflicts'], 'color' => '#72aee6', 'label' => __('Low', 'wp-plugin-conflict-mapper')),
                );
                ?>
                <?php if ($scan_results['total_conflicts'] > 0): ?>
                    <div class="wpcm-bar-chart">
                        <?php foreach ($severities as $key => $sev): ?>
                            <?php if ($sev['count'] > 0): ?>
                                <div class="wpcm-bar-item">
                                    <div class="wpcm-bar-label"><?php echo esc_html($sev['label']); ?></div>
                                    <div class="wpcm-bar-track">
                                        <div class="wpcm-bar-fill" style="width: <?php echo esc_attr(($sev['count'] / $total) * 100); ?>%; background-color: <?php echo esc_attr($sev['color']); ?>;">
                                            <span class="wpcm-bar-value"><?php echo esc_html($sev['count']); ?></span>
                                        </div>
                                    </div>
                                </div>
                            <?php endif; ?>
                        <?php endforeach; ?>
                    </div>
                <?php else: ?>
                    <div class="wpcm-no-conflicts">
                        <span class="dashicons dashicons-yes-alt"></span>
                        <p><?php esc_html_e('No known conflicts detected!', 'wp-plugin-conflict-mapper'); ?></p>
                    </div>
                <?php endif; ?>
            </div>
        </div>

        <div class="wpcm-chart-container">
            <h2><?php esc_html_e('Conflict Types', 'wp-plugin-conflict-mapper'); ?></h2>
            <div class="wpcm-type-chart" id="wpcm-type-chart">
                <?php
                $types = array(
                    'overlap' => array('count' => $scan_results['conflicts_by_type']['overlap'], 'icon' => 'admin-page', 'color' => '#9b59b6', 'label' => __('Overlap', 'wp-plugin-conflict-mapper')),
                    'conflict' => array('count' => $scan_results['conflicts_by_type']['conflict'], 'icon' => 'dismiss', 'color' => '#e74c3c', 'label' => __('Conflict', 'wp-plugin-conflict-mapper')),
                    'incompatible' => array('count' => $scan_results['conflicts_by_type']['incompatible'], 'icon' => 'no', 'color' => '#34495e', 'label' => __('Incompatible', 'wp-plugin-conflict-mapper')),
                    'performance' => array('count' => $scan_results['conflicts_by_type']['performance'], 'icon' => 'performance', 'color' => '#f39c12', 'label' => __('Performance', 'wp-plugin-conflict-mapper')),
                );
                ?>
                <div class="wpcm-type-grid">
                    <?php foreach ($types as $key => $type): ?>
                        <div class="wpcm-type-item <?php echo $type['count'] > 0 ? 'has-issues' : ''; ?>">
                            <span class="dashicons dashicons-<?php echo esc_attr($type['icon']); ?>" style="color: <?php echo esc_attr($type['color']); ?>;"></span>
                            <span class="wpcm-type-count"><?php echo esc_html($type['count']); ?></span>
                            <span class="wpcm-type-label"><?php echo esc_html($type['label']); ?></span>
                        </div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>

    <!-- Detected Conflicts List -->
    <?php if (!empty($scan_results['conflicts'])): ?>
        <div class="wpcm-conflicts-list">
            <h2>
                <span class="dashicons dashicons-list-view"></span>
                <?php esc_html_e('Detected Conflicts', 'wp-plugin-conflict-mapper'); ?>
            </h2>

            <div class="wpcm-filter-bar">
                <label for="wpcm-severity-filter"><?php esc_html_e('Filter by severity:', 'wp-plugin-conflict-mapper'); ?></label>
                <select id="wpcm-severity-filter" class="wpcm-filter-select">
                    <option value="all"><?php esc_html_e('All', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="critical"><?php esc_html_e('Critical', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="high"><?php esc_html_e('High', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="medium"><?php esc_html_e('Medium', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="low"><?php esc_html_e('Low', 'wp-plugin-conflict-mapper'); ?></option>
                </select>
            </div>

            <div class="wpcm-conflicts-grid" id="wpcm-conflicts-grid">
                <?php foreach ($scan_results['conflicts'] as $detected): ?>
                    <?php
                    $conflict = $detected['conflict'];
                    $severity = $conflict['severity'];
                    $severity_colors = array(
                        'critical' => '#d63638',
                        'high' => '#e65100',
                        'medium' => '#dba617',
                        'low' => '#72aee6',
                    );
                    $severity_icons = array(
                        'critical' => 'megaphone',
                        'high' => 'flag',
                        'medium' => 'info',
                        'low' => 'marker',
                    );
                    ?>
                    <div class="wpcm-conflict-card" data-severity="<?php echo esc_attr($severity); ?>">
                        <div class="wpcm-conflict-header" style="border-left-color: <?php echo esc_attr($severity_colors[$severity]); ?>;">
                            <span class="wpcm-severity-badge wpcm-severity-<?php echo esc_attr($severity); ?>">
                                <span class="dashicons dashicons-<?php echo esc_attr($severity_icons[$severity]); ?>"></span>
                                <?php echo esc_html(ucfirst($severity)); ?>
                            </span>
                            <span class="wpcm-conflict-type wpcm-type-<?php echo esc_attr($conflict['type']); ?>">
                                <?php echo esc_html(ucfirst($conflict['type'])); ?>
                            </span>
                        </div>

                        <div class="wpcm-conflict-plugins">
                            <div class="wpcm-plugin-pair">
                                <span class="wpcm-plugin-name">
                                    <span class="dashicons dashicons-admin-plugins"></span>
                                    <?php echo esc_html($detected['plugin_a_info']['name'] ?? $conflict['plugin_a']); ?>
                                </span>
                                <span class="wpcm-conflict-icon">
                                    <span class="dashicons dashicons-randomize"></span>
                                </span>
                                <span class="wpcm-plugin-name">
                                    <span class="dashicons dashicons-admin-plugins"></span>
                                    <?php echo esc_html($detected['plugin_b_info']['name'] ?? $conflict['plugin_b']); ?>
                                </span>
                            </div>
                        </div>

                        <div class="wpcm-conflict-description">
                            <p><?php echo esc_html($conflict['description']); ?></p>
                        </div>

                        <div class="wpcm-conflict-resolution">
                            <strong>
                                <span class="dashicons dashicons-lightbulb"></span>
                                <?php esc_html_e('Resolution:', 'wp-plugin-conflict-mapper'); ?>
                            </strong>
                            <p><?php echo esc_html($conflict['resolution']); ?></p>
                        </div>

                        <?php if (!empty($conflict['verified'])): ?>
                            <div class="wpcm-verified-badge">
                                <span class="dashicons dashicons-yes"></span>
                                <?php esc_html_e('Verified', 'wp-plugin-conflict-mapper'); ?>
                            </div>
                        <?php endif; ?>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    <?php endif; ?>

    <!-- Database Stats -->
    <div class="wpcm-db-stats">
        <h2>
            <span class="dashicons dashicons-database"></span>
            <?php esc_html_e('Known Conflicts Database', 'wp-plugin-conflict-mapper'); ?>
        </h2>

        <div class="wpcm-db-stats-grid">
            <div class="wpcm-db-stat">
                <span class="wpcm-db-stat-value"><?php echo esc_html($db_stats['total_entries']); ?></span>
                <span class="wpcm-db-stat-label"><?php esc_html_e('Total Entries', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
            <div class="wpcm-db-stat">
                <span class="wpcm-db-stat-value"><?php echo esc_html($db_stats['unique_plugins']); ?></span>
                <span class="wpcm-db-stat-label"><?php esc_html_e('Unique Plugins', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
            <div class="wpcm-db-stat">
                <span class="wpcm-db-stat-value"><?php echo esc_html($db_stats['verified_count']); ?></span>
                <span class="wpcm-db-stat-label"><?php esc_html_e('Verified Conflicts', 'wp-plugin-conflict-mapper'); ?></span>
            </div>
        </div>

        <div class="wpcm-db-breakdown">
            <h3><?php esc_html_e('Database Breakdown', 'wp-plugin-conflict-mapper'); ?></h3>
            <div class="wpcm-breakdown-grid">
                <div class="wpcm-breakdown-section">
                    <h4><?php esc_html_e('By Severity', 'wp-plugin-conflict-mapper'); ?></h4>
                    <ul>
                        <li><span class="wpcm-dot" style="background: #d63638;"></span> <?php esc_html_e('Critical:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_severity']['critical']); ?></li>
                        <li><span class="wpcm-dot" style="background: #e65100;"></span> <?php esc_html_e('High:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_severity']['high']); ?></li>
                        <li><span class="wpcm-dot" style="background: #dba617;"></span> <?php esc_html_e('Medium:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_severity']['medium']); ?></li>
                        <li><span class="wpcm-dot" style="background: #72aee6;"></span> <?php esc_html_e('Low:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_severity']['low']); ?></li>
                    </ul>
                </div>
                <div class="wpcm-breakdown-section">
                    <h4><?php esc_html_e('By Type', 'wp-plugin-conflict-mapper'); ?></h4>
                    <ul>
                        <li><span class="wpcm-dot" style="background: #9b59b6;"></span> <?php esc_html_e('Overlap:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_type']['overlap']); ?></li>
                        <li><span class="wpcm-dot" style="background: #e74c3c;"></span> <?php esc_html_e('Conflict:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_type']['conflict']); ?></li>
                        <li><span class="wpcm-dot" style="background: #34495e;"></span> <?php esc_html_e('Incompatible:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_type']['incompatible']); ?></li>
                        <li><span class="wpcm-dot" style="background: #f39c12;"></span> <?php esc_html_e('Performance:', 'wp-plugin-conflict-mapper'); ?> <?php echo esc_html($db_stats['by_type']['performance']); ?></li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <!-- Export Options -->
    <div class="wpcm-export-section">
        <h2>
            <span class="dashicons dashicons-download"></span>
            <?php esc_html_e('Export Results', 'wp-plugin-conflict-mapper'); ?>
        </h2>
        <p><?php esc_html_e('Download your scan results for documentation or further analysis.', 'wp-plugin-conflict-mapper'); ?></p>
        <button type="button" id="wpcm-export-json" class="button button-secondary">
            <span class="dashicons dashicons-media-code"></span>
            <?php esc_html_e('Export as JSON', 'wp-plugin-conflict-mapper'); ?>
        </button>
    </div>

    <!-- Hidden JSON data for export -->
    <script type="application/json" id="wpcm-scan-data">
        <?php echo wp_json_encode($scan_results); ?>
    </script>
</div>
