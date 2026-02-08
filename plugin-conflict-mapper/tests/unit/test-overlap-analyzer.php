<?php
/**
 * Class Test_WPCM_Overlap_Analyzer
 *
 * @package WP_Plugin_Conflict_Mapper
 */

class Test_WPCM_Overlap_Analyzer extends WP_UnitTestCase {

    private $analyzer;
    private $scanner;

    public function setUp(): void {
        parent::setUp();
        $this->analyzer = new WPCM_Overlap_Analyzer();
        $this->scanner = new WPCM_Plugin_Scanner();
    }

    public function test_analyzer_instantiation() {
        $this->assertInstanceOf('WPCM_Overlap_Analyzer', $this->analyzer);
    }

    public function test_analyze_overlaps_returns_array() {
        $plugins = $this->scanner->get_active_plugins();
        $overlaps = $this->analyzer->analyze_overlaps($plugins);
        $this->assertIsArray($overlaps);
    }

    public function test_overlap_structure() {
        $plugins = $this->scanner->get_active_plugins();
        $overlaps = $this->analyzer->analyze_overlaps($plugins);

        foreach ($overlaps as $overlap) {
            $this->assertArrayHasKey('category', $overlap);
            $this->assertArrayHasKey('plugins', $overlap);
            $this->assertArrayHasKey('count', $overlap);
            $this->assertArrayHasKey('severity', $overlap);
            $this->assertArrayHasKey('recommendation', $overlap);
        }
    }

    public function test_category_alternatives() {
        $alternatives = $this->analyzer->get_category_alternatives('seo');
        $this->assertIsArray($alternatives);
        $this->assertNotEmpty($alternatives);
    }

    public function test_analyze_hook_patterns() {
        $plugins = $this->scanner->get_active_plugins();
        $patterns = $this->analyzer->analyze_hook_patterns($plugins);
        $this->assertIsArray($patterns);
    }

    public function test_severity_levels() {
        $plugins = $this->scanner->get_active_plugins();
        $overlaps = $this->analyzer->analyze_overlaps($plugins);

        $valid_severities = array('low', 'medium', 'high');
        foreach ($overlaps as $overlap) {
            $this->assertContains($overlap['severity'], $valid_severities);
        }
    }
}
