<?php
/**
 * Class Test_WPCM_Database
 *
 * @package WP_Plugin_Conflict_Mapper
 */

class Test_WPCM_Database extends WP_UnitTestCase {

    private $database;

    public function setUp(): void {
        parent::setUp();
        $this->database = new WPCM_Database();
    }

    public function tearDown(): void {
        // Clean up test data
        global $wpdb;
        $wpdb->query("TRUNCATE TABLE {$wpdb->prefix}wpcm_scans");
        $wpdb->query("TRUNCATE TABLE {$wpdb->prefix}wpcm_conflicts");
        parent::tearDown();
    }

    public function test_database_instantiation() {
        $this->assertInstanceOf('WPCM_Database', $this->database);
    }

    public function test_save_scan() {
        $scan_data = array(
            'plugin_count' => 10,
            'conflict_count' => 5,
            'overlap_count' => 3,
            'scan_type' => 'manual',
            'full_data' => array('test' => 'data'),
        );

        $scan_id = $this->database->save_scan($scan_data);
        $this->assertGreaterThan(0, $scan_id);
    }

    public function test_get_scan() {
        $scan_data = array(
            'plugin_count' => 10,
            'conflict_count' => 5,
            'overlap_count' => 3,
            'scan_type' => 'manual',
            'full_data' => array('test' => 'data'),
        );

        $scan_id = $this->database->save_scan($scan_data);
        $scan = $this->database->get_scan($scan_id);

        $this->assertNotNull($scan);
        $this->assertEquals($scan_id, $scan->id);
        $this->assertEquals(10, $scan->plugin_count);
    }

    public function test_get_recent_scans() {
        // Create multiple scans
        for ($i = 0; $i < 5; $i++) {
            $this->database->save_scan(array(
                'plugin_count' => $i,
                'conflict_count' => 0,
                'overlap_count' => 0,
                'scan_type' => 'test',
                'full_data' => array(),
            ));
        }

        $scans = $this->database->get_recent_scans(3);
        $this->assertCount(3, $scans);
    }

    public function test_save_conflicts() {
        $scan_id = $this->database->save_scan(array(
            'plugin_count' => 1,
            'conflict_count' => 1,
            'overlap_count' => 0,
            'scan_type' => 'test',
            'full_data' => array(),
        ));

        $conflicts = array(
            'hook_conflicts' => array(
                array(
                    'plugins' => array('Plugin A', 'Plugin B'),
                    'severity' => 'high',
                ),
            ),
        );

        $result = $this->database->save_conflicts($scan_id, $conflicts);
        $this->assertTrue($result);
    }

    public function test_get_scan_conflicts() {
        $scan_id = $this->database->save_scan(array(
            'plugin_count' => 1,
            'conflict_count' => 1,
            'overlap_count' => 0,
            'scan_type' => 'test',
            'full_data' => array(),
        ));

        $conflicts = array(
            'hook_conflicts' => array(
                array(
                    'plugins' => array('Plugin A', 'Plugin B'),
                    'severity' => 'high',
                ),
            ),
        );

        $this->database->save_conflicts($scan_id, $conflicts);
        $saved_conflicts = $this->database->get_scan_conflicts($scan_id);

        $this->assertNotEmpty($saved_conflicts);
    }

    public function test_get_statistics() {
        // Create some test data
        $this->database->save_scan(array(
            'plugin_count' => 10,
            'conflict_count' => 5,
            'overlap_count' => 2,
            'scan_type' => 'test',
            'full_data' => array(),
        ));

        $stats = $this->database->get_statistics();

        $this->assertIsArray($stats);
        $this->assertArrayHasKey('total_scans', $stats);
        $this->assertArrayHasKey('avg_conflicts', $stats);
    }

    public function test_cleanup_old_scans() {
        // Create old scan data would require manipulating dates
        // For now, just test the function runs
        $deleted = $this->database->cleanup_old_scans(365);
        $this->assertGreaterThanOrEqual(0, $deleted);
    }
}
