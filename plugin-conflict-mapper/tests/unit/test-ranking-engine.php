<?php
/**
 * Class Test_WPCM_Ranking_Engine
 *
 * @package WP_Plugin_Conflict_Mapper
 */

class Test_WPCM_Ranking_Engine extends WP_UnitTestCase {

    private $engine;
    private $scanner;
    private $detector;
    private $overlap_analyzer;

    public function setUp(): void {
        parent::setUp();
        $this->engine = new WPCM_Ranking_Engine();
        $this->scanner = new WPCM_Plugin_Scanner();
        $this->detector = new WPCM_Conflict_Detector();
        $this->overlap_analyzer = new WPCM_Overlap_Analyzer();
    }

    public function test_engine_instantiation() {
        $this->assertInstanceOf('WPCM_Ranking_Engine', $this->engine);
    }

    public function test_rank_plugins_returns_array() {
        $plugins = $this->scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);
        $overlaps = $this->overlap_analyzer->analyze_overlaps($plugins);

        $ranked = $this->engine->rank_plugins($plugins, $conflicts, $overlaps);
        $this->assertIsArray($ranked);
    }

    public function test_ranked_plugin_structure() {
        $plugins = $this->scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);
        $overlaps = $this->overlap_analyzer->analyze_overlaps($plugins);

        $ranked = $this->engine->rank_plugins($plugins, $conflicts, $overlaps);

        foreach ($ranked as $plugin) {
            $this->assertArrayHasKey('score', $plugin);
            $this->assertArrayHasKey('score_breakdown', $plugin);
            $this->assertArrayHasKey('issues', $plugin);
            $this->assertArrayHasKey('recommendations', $plugin);
        }
    }

    public function test_score_range() {
        $plugins = $this->scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);
        $overlaps = $this->overlap_analyzer->analyze_overlaps($plugins);

        $ranked = $this->engine->rank_plugins($plugins, $conflicts, $overlaps);

        foreach ($ranked as $plugin) {
            $this->assertGreaterThanOrEqual(0, $plugin['score']);
            $this->assertLessThanOrEqual(100, $plugin['score']);
        }
    }

    public function test_get_comparative_ranking() {
        $plugins = $this->scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);
        $overlaps = $this->overlap_analyzer->analyze_overlaps($plugins);

        $ranked = $this->engine->rank_plugins($plugins, $conflicts, $overlaps);
        $comparative = $this->engine->get_comparative_ranking($ranked);

        $this->assertIsArray($comparative);
        foreach ($comparative as $data) {
            $this->assertArrayHasKey('rank', $data);
            $this->assertArrayHasKey('percentile', $data);
            $this->assertArrayHasKey('total_plugins', $data);
        }
    }

    public function test_get_priority_actions() {
        $plugins = $this->scanner->get_active_plugins();
        $conflicts = $this->detector->detect_conflicts($plugins);
        $overlaps = $this->overlap_analyzer->analyze_overlaps($plugins);

        $ranked = $this->engine->rank_plugins($plugins, $conflicts, $overlaps);
        $actions = $this->engine->get_priority_actions($ranked);

        $this->assertIsArray($actions);
    }
}
