<?php
/**
 * Class Test_WPCM_Minimal_Scanner
 *
 * @package WP_Plugin_Conflict_Mapper
 */

/**
 * Minimal Scanner test case.
 */
class Test_WPCM_Minimal_Scanner extends WP_UnitTestCase {

    /**
     * Scanner instance
     *
     * @var WPCM_Minimal_Scanner
     */
    private $scanner;

    /**
     * Set up test
     */
    public function setUp(): void {
        parent::setUp();
        $this->scanner = new WPCM_Minimal_Scanner();
    }

    /**
     * Test scanner instantiation
     */
    public function test_scanner_instantiation() {
        $this->assertInstanceOf('WPCM_Minimal_Scanner', $this->scanner);
    }

    /**
     * Test known conflicts are loaded
     */
    public function test_known_conflicts_loaded() {
        $conflicts = $this->scanner->get_known_conflicts();

        $this->assertIsArray($conflicts);
        $this->assertNotEmpty($conflicts, 'Known conflicts database should not be empty');
    }

    /**
     * Test known conflict structure
     */
    public function test_known_conflict_structure() {
        $conflicts = $this->scanner->get_known_conflicts();

        foreach ($conflicts as $conflict) {
            $this->assertArrayHasKey('plugin_a', $conflict);
            $this->assertArrayHasKey('plugin_b', $conflict);
            $this->assertArrayHasKey('type', $conflict);
            $this->assertArrayHasKey('severity', $conflict);
            $this->assertArrayHasKey('description', $conflict);
            $this->assertArrayHasKey('resolution', $conflict);
        }
    }

    /**
     * Test valid severity values in database
     */
    public function test_valid_severity_values() {
        $conflicts = $this->scanner->get_known_conflicts();
        $valid_severities = array('critical', 'high', 'medium', 'low');

        foreach ($conflicts as $conflict) {
            $this->assertContains(
                $conflict['severity'],
                $valid_severities,
                "Invalid severity: {$conflict['severity']}"
            );
        }
    }

    /**
     * Test valid type values in database
     */
    public function test_valid_type_values() {
        $conflicts = $this->scanner->get_known_conflicts();
        $valid_types = array('conflict', 'overlap', 'incompatible', 'performance');

        foreach ($conflicts as $conflict) {
            $this->assertContains(
                $conflict['type'],
                $valid_types,
                "Invalid type: {$conflict['type']}"
            );
        }
    }

    /**
     * Test scan returns array
     */
    public function test_scan_returns_array() {
        $result = $this->scanner->scan();

        $this->assertIsArray($result);
    }

    /**
     * Test quick_scan returns expected structure
     */
    public function test_quick_scan_structure() {
        $result = $this->scanner->quick_scan();

        $this->assertIsArray($result);
        $this->assertArrayHasKey('total_conflicts', $result);
        $this->assertArrayHasKey('critical_conflicts', $result);
        $this->assertArrayHasKey('high_conflicts', $result);
        $this->assertArrayHasKey('medium_conflicts', $result);
        $this->assertArrayHasKey('low_conflicts', $result);
        $this->assertArrayHasKey('conflicts_by_type', $result);
        $this->assertArrayHasKey('conflicts', $result);
        $this->assertArrayHasKey('scan_time', $result);
    }

    /**
     * Test check_pair with known conflict
     */
    public function test_check_pair_known_conflict() {
        $result = $this->scanner->check_pair('wordpress-seo', 'all-in-one-seo-pack');

        $this->assertNotNull($result);
        $this->assertIsArray($result);
        $this->assertEquals('overlap', $result['type']);
        $this->assertEquals('critical', $result['severity']);
    }

    /**
     * Test check_pair with reversed order
     */
    public function test_check_pair_reversed_order() {
        $result = $this->scanner->check_pair('all-in-one-seo-pack', 'wordpress-seo');

        $this->assertNotNull($result);
        $this->assertIsArray($result);
    }

    /**
     * Test check_pair with no conflict
     */
    public function test_check_pair_no_conflict() {
        $result = $this->scanner->check_pair('nonexistent-plugin-a', 'nonexistent-plugin-b');

        $this->assertNull($result);
    }

    /**
     * Test get_conflicts_for_plugin
     */
    public function test_get_conflicts_for_plugin() {
        $conflicts = $this->scanner->get_conflicts_for_plugin('wordpress-seo');

        $this->assertIsArray($conflicts);
        $this->assertNotEmpty($conflicts);

        foreach ($conflicts as $conflict) {
            $this->assertTrue(
                $conflict['plugin_a'] === 'wordpress-seo' || $conflict['plugin_b'] === 'wordpress-seo'
            );
        }
    }

    /**
     * Test get_recommendations
     */
    public function test_get_recommendations() {
        $mock_conflicts = array(
            array(
                'conflict' => array(
                    'plugin_a'    => 'test-a',
                    'plugin_b'    => 'test-b',
                    'type'        => 'overlap',
                    'severity'    => 'high',
                    'description' => 'Test conflict',
                    'resolution'  => 'Test resolution',
                ),
            ),
        );

        $recommendations = $this->scanner->get_recommendations($mock_conflicts);

        $this->assertIsArray($recommendations);
        $this->assertCount(1, $recommendations);
        $this->assertEquals('Test resolution', $recommendations[0]['action']);
    }

    /**
     * Test recommendations are sorted by severity
     */
    public function test_recommendations_sorted_by_severity() {
        $mock_conflicts = array(
            array(
                'conflict' => array(
                    'plugin_a'    => 'test-a',
                    'plugin_b'    => 'test-b',
                    'type'        => 'overlap',
                    'severity'    => 'low',
                    'description' => 'Low priority',
                    'resolution'  => 'Low fix',
                ),
            ),
            array(
                'conflict' => array(
                    'plugin_a'    => 'test-c',
                    'plugin_b'    => 'test-d',
                    'type'        => 'conflict',
                    'severity'    => 'critical',
                    'description' => 'Critical issue',
                    'resolution'  => 'Critical fix',
                ),
            ),
        );

        $recommendations = $this->scanner->get_recommendations($mock_conflicts);

        $this->assertEquals('critical', $recommendations[0]['severity']);
        $this->assertEquals('low', $recommendations[1]['severity']);
    }

    /**
     * Test get_database_stats
     */
    public function test_get_database_stats() {
        $stats = $this->scanner->get_database_stats();

        $this->assertIsArray($stats);
        $this->assertArrayHasKey('total_entries', $stats);
        $this->assertArrayHasKey('by_severity', $stats);
        $this->assertArrayHasKey('by_type', $stats);
        $this->assertArrayHasKey('verified_count', $stats);
        $this->assertArrayHasKey('unique_plugins', $stats);

        $this->assertGreaterThan(0, $stats['total_entries']);
        $this->assertGreaterThan(0, $stats['unique_plugins']);
    }

    /**
     * Test export_json
     */
    public function test_export_json() {
        $scan_result = $this->scanner->quick_scan();
        $json = $this->scanner->export_json($scan_result);

        $this->assertIsString($json);
        $this->assertJson($json);

        $decoded = json_decode($json, true);
        $this->assertArrayHasKey('total_conflicts', $decoded);
    }

    /**
     * Test custom data file loading
     */
    public function test_custom_data_file() {
        // Create a temporary test data file
        $temp_file = sys_get_temp_dir() . '/test-conflicts.php';
        file_put_contents($temp_file, '<?php return array(array(
            "plugin_a" => "test-plugin-a",
            "plugin_b" => "test-plugin-b",
            "type" => "conflict",
            "severity" => "high",
            "description" => "Test conflict",
            "resolution" => "Test resolution",
            "verified" => true,
            "reported_date" => "2025-01-01",
        ));');

        $scanner = new WPCM_Minimal_Scanner($temp_file);
        $conflicts = $scanner->get_known_conflicts();

        $this->assertCount(1, $conflicts);
        $this->assertEquals('test-plugin-a', $conflicts[0]['plugin_a']);

        unlink($temp_file);
    }

    /**
     * Test database contains verified entries
     */
    public function test_database_has_verified_entries() {
        $stats = $this->scanner->get_database_stats();

        $this->assertGreaterThan(0, $stats['verified_count'], 'Database should have verified entries');
    }

    /**
     * Test database covers major plugin categories
     */
    public function test_database_covers_major_categories() {
        $conflicts = $this->scanner->get_known_conflicts();
        $plugins = array();

        foreach ($conflicts as $conflict) {
            $plugins[$conflict['plugin_a']] = true;
            $plugins[$conflict['plugin_b']] = true;
        }

        // Check for major plugin types
        $major_plugins = array(
            'wordpress-seo',      // SEO
            'woocommerce',        // E-commerce
            'wordfence',          // Security
            'w3-total-cache',     // Cache
            'elementor',          // Page builder
            'updraftplus',        // Backup
            'contact-form-7',     // Forms
        );

        $found_count = 0;
        foreach ($major_plugins as $plugin) {
            if (isset($plugins[$plugin])) {
                $found_count++;
            }
        }

        $this->assertGreaterThanOrEqual(5, $found_count, 'Database should cover major plugin categories');
    }
}
