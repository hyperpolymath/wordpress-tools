<?php
/**
 * Class Test_WPCM_Performance_Analyzer
 *
 * @package WP_Plugin_Conflict_Mapper
 */

class Test_WPCM_Performance_Analyzer extends WP_UnitTestCase {

    private $analyzer;
    private $scanner;

    public function setUp(): void {
        parent::setUp();
        $this->analyzer = new WPCM_Performance_Analyzer();
        $this->scanner = new WPCM_Plugin_Scanner();
    }

    public function test_analyzer_instantiation() {
        $this->assertInstanceOf('WPCM_Performance_Analyzer', $this->analyzer);
    }

    public function test_analyze_plugin_structure() {
        $plugins = $this->scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $analysis = $this->analyzer->analyze_plugin($plugin_file);

            $this->assertIsArray($analysis);
            $this->assertArrayHasKey('size', $analysis);
            $this->assertArrayHasKey('complexity', $analysis);
            $this->assertArrayHasKey('database_impact', $analysis);
            $this->assertArrayHasKey('asset_impact', $analysis);
            $this->assertArrayHasKey('hooks_count', $analysis);
        } else {
            $this->markTestSkipped('No plugins available for analysis');
        }
    }

    public function test_generate_report() {
        $plugins = $this->scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $analysis = $this->analyzer->analyze_plugin($plugin_file);
            $report = $this->analyzer->generate_report($analysis);

            $this->assertArrayHasKey('overall_score', $report);
            $this->assertArrayHasKey('overall_rating', $report);
            $this->assertGreaterThanOrEqual(0, $report['overall_score']);
            $this->assertLessThanOrEqual(100, $report['overall_score']);
        } else {
            $this->markTestSkipped('No plugins available for analysis');
        }
    }

    public function test_rating_values() {
        $valid_ratings = array('excellent', 'good', 'fair', 'poor');
        $plugins = $this->scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $analysis = $this->analyzer->analyze_plugin($plugin_file);
            $report = $this->analyzer->generate_report($analysis);

            $this->assertContains($report['overall_rating'], $valid_ratings);
        } else {
            $this->markTestSkipped('No plugins available for analysis');
        }
    }

    public function test_size_metrics() {
        $plugins = $this->scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $analysis = $this->analyzer->analyze_plugin($plugin_file);

            $this->assertArrayHasKey('bytes', $analysis['size']);
            $this->assertArrayHasKey('megabytes', $analysis['size']);
            $this->assertArrayHasKey('rating', $analysis['size']);
            $this->assertArrayHasKey('score', $analysis['size']);
        } else {
            $this->markTestSkipped('No plugins available for analysis');
        }
    }
}
