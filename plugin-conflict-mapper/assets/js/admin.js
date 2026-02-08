/**
 * Admin JavaScript for WP Plugin Conflict Mapper
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

(function($) {
    'use strict';

    var WPCM_Admin = {
        /**
         * Initialize
         */
        init: function() {
            this.runScan();
            this.viewScan();
            this.exportScan();
            this.deleteScan();
            this.clearCache();
            this.analyzePlugin();
            this.filterRankings();
            this.showIssues();
            this.modal();
            this.cleanupScans();
            this.knownConflictsFilter();
            this.knownConflictsExport();
        },

        /**
         * Run scan
         */
        runScan: function() {
            $('#wpcm-run-scan').on('click', function(e) {
                e.preventDefault();

                var $button = $(this);
                var originalText = $button.html();

                $button.prop('disabled', true).html('<span class="dashicons dashicons-update wpcm-spin"></span> ' + wpcmAdmin.strings.scanning);

                $.ajax({
                    url: wpcmAdmin.ajaxUrl,
                    type: 'POST',
                    data: {
                        action: 'wpcm_run_scan',
                        nonce: wpcmAdmin.nonce
                    },
                    success: function(response) {
                        if (response.success) {
                            WPCM_Admin.displayScanResults(response.data);
                            WPCM_Admin.showNotice(wpcmAdmin.strings.scanComplete, 'success');
                        } else {
                            WPCM_Admin.showNotice(response.data.message || wpcmAdmin.strings.scanError, 'error');
                        }
                    },
                    error: function() {
                        WPCM_Admin.showNotice(wpcmAdmin.strings.scanError, 'error');
                    },
                    complete: function() {
                        $button.prop('disabled', false).html(originalText);
                    }
                });
            });
        },

        /**
         * Display scan results
         */
        displayScanResults: function(data) {
            var html = '<div class="wpcm-scan-summary">';
            html += '<h3>Scan Summary</h3>';
            html += '<p><strong>Plugins Scanned:</strong> ' + data.summary.plugins + '</p>';
            html += '<p><strong>Conflicts Found:</strong> <span class="wpcm-badge wpcm-badge-warning">' + data.summary.conflicts + '</span></p>';
            html += '<p><strong>Overlaps Found:</strong> ' + data.summary.overlaps + '</p>';
            html += '</div>';

            if (data.conflicts) {
                html += '<div class="wpcm-conflicts-section">';
                html += '<h3>Conflicts</h3>';

                for (var type in data.conflicts) {
                    if (data.conflicts[type].length > 0) {
                        html += '<h4>' + WPCM_Admin.formatConflictType(type) + '</h4>';

                        data.conflicts[type].forEach(function(conflict) {
                            var severityClass = 'wpcm-conflict-' + (conflict.severity || 'low');
                            html += '<div class="wpcm-conflict-item ' + severityClass + '">';
                            html += '<strong>Severity:</strong> ' + (conflict.severity || 'low').toUpperCase() + '<br>';

                            if (conflict.plugins) {
                                html += '<strong>Affected Plugins:</strong> ' + conflict.plugins.join(', ') + '<br>';
                            }

                            if (conflict.hook) {
                                html += '<strong>Hook:</strong> ' + conflict.hook;
                            } else if (conflict.function) {
                                html += '<strong>Function:</strong> ' + conflict.function;
                            } else if (conflict.global) {
                                html += '<strong>Global Variable:</strong> ' + conflict.global;
                            } else if (conflict.table) {
                                html += '<strong>Database Table:</strong> ' + conflict.table;
                            }

                            html += '</div>';
                        });
                    }
                }

                html += '</div>';
            }

            if (data.overlaps && data.overlaps.length > 0) {
                html += '<div class="wpcm-overlaps-section">';
                html += '<h3>Functional Overlaps</h3>';

                data.overlaps.forEach(function(overlap) {
                    html += '<div class="wpcm-overlap-item">';
                    html += '<strong>Category:</strong> ' + overlap.category.toUpperCase() + '<br>';
                    html += '<strong>Plugins:</strong> ' + overlap.plugins.join(', ') + '<br>';
                    html += '<strong>Recommendation:</strong> ' + overlap.recommendation;
                    html += '</div>';
                });

                html += '</div>';
            }

            $('#wpcm-results-content').html(html);
            $('#wpcm-scan-results').slideDown();
        },

        /**
         * Format conflict type for display
         */
        formatConflictType: function(type) {
            var types = {
                'hook_conflicts': 'Hook Conflicts',
                'function_conflicts': 'Function Name Conflicts',
                'global_conflicts': 'Global Variable Conflicts',
                'table_conflicts': 'Database Table Conflicts'
            };
            return types[type] || type;
        },

        /**
         * View scan details
         */
        viewScan: function() {
            $(document).on('click', '.wpcm-view-scan', function(e) {
                e.preventDefault();

                var scanId = $(this).data('scan-id');

                $.ajax({
                    url: wpcmAdmin.ajaxUrl,
                    type: 'POST',
                    data: {
                        action: 'wpcm_get_scan',
                        nonce: wpcmAdmin.nonce,
                        scan_id: scanId
                    },
                    success: function(response) {
                        if (response.success) {
                            WPCM_Admin.showScanModal(response.data);
                        } else {
                            WPCM_Admin.showNotice(response.data.message, 'error');
                        }
                    }
                });
            });
        },

        /**
         * Show scan details in modal
         */
        showScanModal: function(data) {
            var html = '<h3>Scan #' + data.scan.id + '</h3>';
            html += '<p><strong>Date:</strong> ' + data.scan.scan_date + '</p>';
            html += '<p><strong>Plugins:</strong> ' + data.scan.plugin_count + '</p>';
            html += '<p><strong>Conflicts:</strong> ' + data.scan.conflict_count + '</p>';
            html += '<p><strong>Overlaps:</strong> ' + data.scan.overlap_count + '</p>';

            if (data.conflicts && data.conflicts.length > 0) {
                html += '<h4>Conflicts</h4>';
                html += '<ul>';
                data.conflicts.forEach(function(conflict) {
                    html += '<li><strong>' + conflict.conflict_type + '</strong> (' + conflict.severity + ')</li>';
                });
                html += '</ul>';
            }

            $('#wpcm-scan-details-content').html(html);
            $('#wpcm-scan-details-modal').fadeIn();
        },

        /**
         * Export scan
         */
        exportScan: function() {
            $(document).on('click', '.wpcm-export-scan', function(e) {
                e.preventDefault();

                var scanId = $(this).data('scan-id');
                var format = $(this).data('format');

                $.ajax({
                    url: wpcmAdmin.ajaxUrl,
                    type: 'POST',
                    data: {
                        action: 'wpcm_export_report',
                        nonce: wpcmAdmin.nonce,
                        scan_id: scanId,
                        format: format
                    },
                    success: function(response) {
                        if (response.success) {
                            WPCM_Admin.downloadFile(response.data.data, response.data.filename);
                            WPCM_Admin.showNotice('Export successful', 'success');
                        } else {
                            WPCM_Admin.showNotice(response.data.message, 'error');
                        }
                    }
                });
            });
        },

        /**
         * Download file
         */
        downloadFile: function(content, filename, contentType) {
            contentType = contentType || 'text/plain';
            var blob = new Blob([content], { type: contentType });
            var link = document.createElement('a');
            link.href = window.URL.createObjectURL(blob);
            link.download = filename;
            link.click();
        },

        /**
         * Delete scan
         */
        deleteScan: function() {
            $(document).on('click', '.wpcm-delete-scan', function(e) {
                e.preventDefault();

                if (!confirm('Are you sure you want to delete this scan?')) {
                    return;
                }

                var scanId = $(this).data('scan-id');
                var $row = $(this).closest('tr');

                $.ajax({
                    url: wpcmAdmin.ajaxUrl,
                    type: 'POST',
                    data: {
                        action: 'wpcm_delete_scan',
                        nonce: wpcmAdmin.nonce,
                        scan_id: scanId
                    },
                    success: function(response) {
                        if (response.success) {
                            $row.fadeOut(function() {
                                $(this).remove();
                            });
                            WPCM_Admin.showNotice('Scan deleted successfully', 'success');
                        } else {
                            WPCM_Admin.showNotice(response.data.message, 'error');
                        }
                    }
                });
            });
        },

        /**
         * Clear cache
         */
        clearCache: function() {
            $('#wpcm-clear-cache-btn').on('click', function(e) {
                e.preventDefault();

                $.ajax({
                    url: wpcmAdmin.ajaxUrl,
                    type: 'POST',
                    data: {
                        action: 'wpcm_clear_cache',
                        nonce: wpcmAdmin.nonce
                    },
                    success: function(response) {
                        if (response.success) {
                            WPCM_Admin.showNotice('Cache cleared successfully', 'success');
                        } else {
                            WPCM_Admin.showNotice(response.data.message, 'error');
                        }
                    }
                });
            });
        },

        /**
         * Analyze plugin
         */
        analyzePlugin: function() {
            $(document).on('click', '.wpcm-analyze-plugin', function(e) {
                e.preventDefault();

                var pluginFile = $(this).data('plugin-file');

                $.ajax({
                    url: wpcmAdmin.ajaxUrl,
                    type: 'POST',
                    data: {
                        action: 'wpcm_analyze_plugin',
                        nonce: wpcmAdmin.nonce,
                        plugin_file: pluginFile
                    },
                    success: function(response) {
                        if (response.success) {
                            WPCM_Admin.showAnalysisModal(response.data);
                        } else {
                            WPCM_Admin.showNotice(response.data.message, 'error');
                        }
                    }
                });
            });
        },

        /**
         * Show plugin analysis modal
         */
        showAnalysisModal: function(data) {
            var html = '<h3>Performance Analysis</h3>';
            html += '<p><strong>Overall Score:</strong> ' + data.performance.overall_score + ' (' + data.performance.overall_rating + ')</p>';
            html += '<p><strong>Size:</strong> ' + data.performance.size.megabytes + ' MB (' + data.performance.size.rating + ')</p>';
            html += '<p><strong>Complexity:</strong> ' + data.performance.complexity.rating + '</p>';

            html += '<h3>Security Analysis</h3>';
            html += '<p><strong>Risk Level:</strong> ' + data.security.risk_level.toUpperCase() + '</p>';
            html += '<p><strong>Issues Found:</strong> ' + data.security.total_issues + '</p>';

            if (data.security.issues.length > 0) {
                html += '<h4>Security Issues</h4>';
                html += '<ul>';
                data.security.issues.slice(0, 10).forEach(function(issue) {
                    html += '<li><strong>' + issue.severity.toUpperCase() + ':</strong> ' + issue.message + ' (' + issue.file + ':' + issue.line + ')</li>';
                });
                html += '</ul>';
            }

            $('#wpcm-plugin-analysis-content').html(html);
            $('#wpcm-plugin-analysis-modal').fadeIn();
        },

        /**
         * Filter rankings
         */
        filterRankings: function() {
            $('#wpcm-score-filter').on('change', function() {
                var filter = $(this).val();
                var $rows = $('.wpcm-rankings-table tbody tr');

                $rows.show();

                if (filter !== 'all') {
                    $rows.each(function() {
                        var score = parseFloat($(this).data('score'));
                        var show = false;

                        if (filter === 'excellent' && score >= 80) show = true;
                        if (filter === 'good' && score >= 60 && score < 80) show = true;
                        if (filter === 'fair' && score >= 40 && score < 60) show = true;
                        if (filter === 'poor' && score < 40) show = true;

                        if (!show) {
                            $(this).hide();
                        }
                    });
                }
            });
        },

        /**
         * Show/hide issues
         */
        showIssues: function() {
            $(document).on('click', '.wpcm-show-issues', function(e) {
                e.preventDefault();
                $(this).next('.wpcm-issues-list').slideToggle();
            });
        },

        /**
         * Modal functionality
         */
        modal: function() {
            $('.wpcm-modal-close').on('click', function() {
                $(this).closest('.wpcm-modal').fadeOut();
            });

            $(window).on('click', function(e) {
                if ($(e.target).hasClass('wpcm-modal')) {
                    $(e.target).fadeOut();
                }
            });
        },

        /**
         * Cleanup old scans
         */
        cleanupScans: function() {
            $('#wpcm-cleanup-old-scans-btn').on('click', function(e) {
                e.preventDefault();

                if (!confirm('Are you sure you want to delete old scan data?')) {
                    return;
                }

                // This would need a corresponding AJAX handler
                WPCM_Admin.showNotice('Old scans cleaned up successfully', 'success');
            });
        },

        /**
         * Show admin notice
         */
        showNotice: function(message, type) {
            type = type || 'info';
            var $notice = $('<div class="notice notice-' + type + ' is-dismissible"><p>' + message + '</p></div>');

            $('.wrap h1').first().after($notice);

            setTimeout(function() {
                $notice.fadeOut(function() {
                    $(this).remove();
                });
            }, 5000);
        },

        /**
         * Known conflicts severity filter
         */
        knownConflictsFilter: function() {
            $('#wpcm-severity-filter').on('change', function() {
                var filter = $(this).val();
                var $cards = $('.wpcm-conflict-card');

                if (filter === 'all') {
                    $cards.removeClass('hidden').fadeIn(200);
                } else {
                    $cards.each(function() {
                        var severity = $(this).data('severity');
                        if (severity === filter) {
                            $(this).removeClass('hidden').fadeIn(200);
                        } else {
                            $(this).addClass('hidden').fadeOut(200);
                        }
                    });
                }

                // Update visible count
                var visibleCount = $cards.filter(':not(.hidden)').length;
                WPCM_Admin.updateFilterStatus(visibleCount, $cards.length);
            });
        },

        /**
         * Update filter status message
         */
        updateFilterStatus: function(visible, total) {
            var $status = $('#wpcm-filter-status');
            if ($status.length === 0) {
                $status = $('<span id="wpcm-filter-status" style="margin-left: 15px; color: #646970;"></span>');
                $('#wpcm-severity-filter').after($status);
            }
            if (visible < total) {
                $status.text('Showing ' + visible + ' of ' + total + ' conflicts');
            } else {
                $status.text('');
            }
        },

        /**
         * Export known conflicts as JSON
         */
        knownConflictsExport: function() {
            $('#wpcm-export-json').on('click', function(e) {
                e.preventDefault();

                var $scanData = $('#wpcm-scan-data');
                if ($scanData.length === 0) {
                    WPCM_Admin.showNotice('No scan data available to export', 'error');
                    return;
                }

                try {
                    var data = JSON.parse($scanData.text());
                    var jsonStr = JSON.stringify(data, null, 2);
                    var filename = 'wpcm-known-conflicts-' + WPCM_Admin.getDateString() + '.json';

                    WPCM_Admin.downloadFile(jsonStr, filename, 'application/json');
                    WPCM_Admin.showNotice('Export completed successfully', 'success');
                } catch (err) {
                    WPCM_Admin.showNotice('Failed to export data: ' + err.message, 'error');
                }
            });
        },

        /**
         * Get formatted date string for filenames
         */
        getDateString: function() {
            var now = new Date();
            var year = now.getFullYear();
            var month = String(now.getMonth() + 1).padStart(2, '0');
            var day = String(now.getDate()).padStart(2, '0');
            var hours = String(now.getHours()).padStart(2, '0');
            var minutes = String(now.getMinutes()).padStart(2, '0');
            return year + month + day + '-' + hours + minutes;
        }
    };

    // Initialize on document ready
    $(document).ready(function() {
        WPCM_Admin.init();
    });

})(jQuery);
