<?php
/**
 * Class Test_WPCM_Conflict_Detector
 *
 * @package WP_Plugin_Conflict_Mapper
 */

/**
 * Conflict Detector test case.
 */
class Test_WPCM_Conflict_Detector extends WP_UnitTestCase {

    /**
     * Detector instance
     *
     * @var WPCM_Conflict_Detector
     */
    private $detector;

    /**
     * Set up test
     */
    public function setUp(): void {
        parent::setUp();
        $this->detector = new WPCM_Conflict_Detector();
    }

    /**
     * Test detector instantiation
     */
    public function test_detector_instantiation() {
        $this->assertInstanceOf('WPCM_Conflict_Detector', $this->detector);
    }

    /**
     * Test detect_conflicts returns expected structure
     */
    public function test_detect_conflicts_structure() {
        $scanner = new WPCM_Plugin_Scanner();
        $plugins = $scanner->get_active_plugins();

        $conflicts = $this->detector->detect_conflicts($plugins);

        $this->assertIsArray($conflicts);
        $this->assertArrayHasKey('hook_conflicts', $conflicts);
        $this->assertArrayHasKey('function_conflicts', $conflicts);
        $this->assertArrayHasKey('global_conflicts', $conflicts);
        $this->assertArrayHasKey('table_conflicts', $conflicts);
    }

    /**
     * Test get_conflict_summary returns statistics
     */
    public function test_get_conflict_summary() {
        $scanner = new WPCM_Plugin_Scanner();
        $plugins = $scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);

        $summary = $this->detector->get_conflict_summary($conflicts);

        $this->assertIsArray($summary);
        $this->assertArrayHasKey('total_conflicts', $summary);
        $this->assertArrayHasKey('high_severity', $summary);
        $this->assertArrayHasKey('medium_severity', $summary);
        $this->assertArrayHasKey('low_severity', $summary);
        $this->assertArrayHasKey('by_type', $summary);
    }

    /**
     * Test conflict severity values are valid
     */
    public function test_conflict_severity_values() {
        $scanner = new WPCM_Plugin_Scanner();
        $plugins = $scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);

        $valid_severities = array('low', 'medium', 'high', 'critical');

        foreach ($conflicts as $conflict_type => $conflict_list) {
            foreach ($conflict_list as $conflict) {
                if (isset($conflict['severity'])) {
                    $this->assertContains(
                        $conflict['severity'],
                        $valid_severities,
                        "Invalid severity: {$conflict['severity']}"
                    );
                }
            }
        }
    }
}
