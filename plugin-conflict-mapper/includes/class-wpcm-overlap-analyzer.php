<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Overlap Analyzer Class
 *
 * Analyzes functional overlaps between plugins
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Overlap_Analyzer class
 */
class WPCM_Overlap_Analyzer {

    /**
     * Common plugin categories and their keywords
     *
     * @var array
     */
    private $categories = array(
        'seo' => array('seo', 'search engine', 'meta', 'sitemap', 'schema', 'robots', 'yoast', 'rank math'),
        'cache' => array('cache', 'caching', 'performance', 'speed', 'optimization', 'minify', 'cdn'),
        'security' => array('security', 'firewall', 'malware', 'login', 'protect', 'wordfence', 'sucuri'),
        'backup' => array('backup', 'restore', 'migration', 'duplicate', 'updraft'),
        'forms' => array('form', 'contact', 'survey', 'gravity', 'ninja forms', 'wpforms'),
        'ecommerce' => array('woocommerce', 'shop', 'cart', 'product', 'payment', 'ecommerce', 'store'),
        'social' => array('social', 'share', 'facebook', 'twitter', 'instagram', 'linkedin'),
        'analytics' => array('analytics', 'statistics', 'tracking', 'google analytics', 'stats'),
        'media' => array('gallery', 'image', 'video', 'media', 'photo', 'slider'),
        'email' => array('email', 'newsletter', 'subscription', 'mailchimp', 'smtp'),
        'builder' => array('builder', 'elementor', 'gutenberg', 'editor', 'page builder', 'divi'),
        'spam' => array('spam', 'antispam', 'akismet', 'recaptcha', 'captcha'),
    );

    /**
     * Analyze overlaps between plugins
     *
     * @param array $plugins Array of plugins to analyze
     * @return array Array of overlap data
     */
    public function analyze_overlaps($plugins) {
        $overlaps = array();
        $plugin_categories = array();

        // Categorize plugins
        foreach ($plugins as $plugin_file => $plugin_data) {
            $categories = $this->categorize_plugin($plugin_data);
            $plugin_categories[$plugin_file] = array(
                'name' => $plugin_data['name'],
                'categories' => $categories,
            );
        }

        // Find overlapping categories
        $category_groups = array();
        foreach ($plugin_categories as $plugin_file => $data) {
            foreach ($data['categories'] as $category) {
                if (!isset($category_groups[$category])) {
                    $category_groups[$category] = array();
                }
                $category_groups[$category][] = $data['name'];
            }
        }

        // Create overlap report
        foreach ($category_groups as $category => $plugin_list) {
            if (count($plugin_list) > 1) {
                $overlaps[] = array(
                    'category' => $category,
                    'plugins' => $plugin_list,
                    'count' => count($plugin_list),
                    'severity' => $this->calculate_overlap_severity($category, count($plugin_list)),
                    'recommendation' => $this->get_category_recommendation($category, $plugin_list),
                );
            }
        }

        return $overlaps;
    }

    /**
     * Categorize a plugin based on its data
     *
     * @param array $plugin_data Plugin data
     * @return array Array of categories
     */
    private function categorize_plugin($plugin_data) {
        $found_categories = array();
        $search_text = strtolower($plugin_data['name'] . ' ' . $plugin_data['description']);

        foreach ($this->categories as $category => $keywords) {
            foreach ($keywords as $keyword) {
                if (strpos($search_text, strtolower($keyword)) !== false) {
                    $found_categories[] = $category;
                    break;
                }
            }
        }

        return array_unique($found_categories);
    }

    /**
     * Calculate overlap severity
     *
     * @param string $category Category name
     * @param int $count Number of overlapping plugins
     * @return string Severity level
     */
    private function calculate_overlap_severity($category, $count) {
        // Categories where overlap is more problematic
        $high_risk_categories = array('cache', 'security', 'seo', 'backup');

        if (in_array($category, $high_risk_categories) && $count > 1) {
            return 'high';
        } elseif ($count > 2) {
            return 'medium';
        } else {
            return 'low';
        }
    }

    /**
     * Get recommendation for category overlap
     *
     * @param string $category Category name
     * @param array $plugins List of plugins in category
     * @return string Recommendation text
     */
    private function get_category_recommendation($category, $plugins) {
        $count = count($plugins);

        $recommendations = array(
            'cache' => "You have {$count} caching plugins active. This can cause conflicts and reduce performance. Keep only one caching plugin.",
            'security' => "Multiple security plugins ({$count}) may conflict. Choose one comprehensive security solution.",
            'seo' => "{$count} SEO plugins detected. Multiple SEO plugins can create duplicate meta tags. Use only one SEO plugin.",
            'backup' => "{$count} backup plugins found. Multiple backup solutions waste resources. Choose one reliable backup plugin.",
            'forms' => "{$count} form plugins active. Consider consolidating to one form solution to reduce overhead.",
            'social' => "You have {$count} social sharing plugins. These often have overlapping features - one should be sufficient.",
            'spam' => "{$count} anti-spam plugins detected. One good anti-spam solution is usually enough.",
        );

        if (isset($recommendations[$category])) {
            return $recommendations[$category];
        }

        return "You have {$count} plugins in the {$category} category. Review if all are necessary.";
    }

    /**
     * Get popular alternatives for a category
     *
     * @param string $category Category name
     * @return array Array of recommended plugins
     */
    public function get_category_alternatives($category) {
        $alternatives = array(
            'seo' => array(
                'Yoast SEO' => 'Comprehensive SEO solution with excellent documentation',
                'Rank Math' => 'Feature-rich SEO plugin with built-in advanced features',
                'The SEO Framework' => 'Lightweight and fast SEO plugin',
            ),
            'cache' => array(
                'WP Rocket' => 'Premium caching solution with excellent support',
                'W3 Total Cache' => 'Free, comprehensive caching plugin',
                'WP Super Cache' => 'Simple and reliable caching solution',
            ),
            'security' => array(
                'Wordfence Security' => 'Comprehensive security with firewall and malware scanner',
                'Sucuri Security' => 'Security auditing, malware scanning, and hardening',
                'iThemes Security' => 'Easy-to-use security hardening plugin',
            ),
            'backup' => array(
                'UpdraftPlus' => 'Popular backup and restoration plugin',
                'BackWPup' => 'Complete backup solution with multiple destinations',
                'Duplicator' => 'Backup and migration tool',
            ),
            'forms' => array(
                'WPForms' => 'User-friendly drag-and-drop form builder',
                'Gravity Forms' => 'Powerful forms with advanced features',
                'Contact Form 7' => 'Simple and flexible contact form',
            ),
        );

        return isset($alternatives[$category]) ? $alternatives[$category] : array();
    }

    /**
     * Analyze hook usage patterns for similarities
     *
     * @param array $plugins Array of plugins
     * @return array Similar hook usage patterns
     */
    public function analyze_hook_patterns($plugins) {
        $scanner = new WPCM_Plugin_Scanner();
        $patterns = array();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $hooks = $scanner->scan_plugin_hooks($plugin_file);
            $all_hooks = array_merge($hooks['actions'], $hooks['filters']);

            foreach ($plugins as $other_file => $other_data) {
                if ($plugin_file === $other_file) {
                    continue;
                }

                $other_hooks = $scanner->scan_plugin_hooks($other_file);
                $other_all_hooks = array_merge($other_hooks['actions'], $other_hooks['filters']);

                $common_hooks = array_intersect($all_hooks, $other_all_hooks);

                if (count($common_hooks) > 5) { // Threshold for similarity
                    $similarity = (count($common_hooks) / max(count($all_hooks), count($other_all_hooks))) * 100;

                    if ($similarity > 20) { // 20% similarity threshold
                        $patterns[] = array(
                            'plugin1' => $plugin_data['name'],
                            'plugin2' => $other_data['name'],
                            'common_hooks' => count($common_hooks),
                            'similarity' => round($similarity, 2),
                        );
                    }
                }
            }
        }

        return $patterns;
    }
}
