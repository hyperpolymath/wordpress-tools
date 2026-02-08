<?php
/**
 * Class Test_WPCM_Security_Scanner
 *
 * @package WP_Plugin_Conflict_Mapper
 */

class Test_WPCM_Security_Scanner extends WP_UnitTestCase {

    private $scanner;
    private $plugin_scanner;

    public function setUp(): void {
        parent::setUp();
        $this->scanner = new WPCM_Security_Scanner();
        $this->plugin_scanner = new WPCM_Plugin_Scanner();
    }

    public function test_scanner_instantiation() {
        $this->assertInstanceOf('WPCM_Security_Scanner', $this->scanner);
    }

    public function test_scan_plugin_returns_structure() {
        $plugins = $this->plugin_scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $result = $this->scanner->scan_plugin($plugin_file);

            $this->assertIsArray($result);
            $this->assertArrayHasKey('total_issues', $result);
            $this->assertArrayHasKey('issues', $result);
            $this->assertArrayHasKey('risk_level', $result);
        } else {
            $this->markTestSkipped('No plugins available for security scanning');
        }
    }

    public function test_risk_levels() {
        $valid_levels = array('safe', 'low', 'medium', 'high', 'critical');
        $plugins = $this->plugin_scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $result = $this->scanner->scan_plugin($plugin_file);

            $this->assertContains($result['risk_level'], $valid_levels);
        } else {
            $this->markTestSkipped('No plugins available for security scanning');
        }
    }

    public function test_issue_structure() {
        $plugins = $this->plugin_scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $result = $this->scanner->scan_plugin($plugin_file);

            foreach ($result['issues'] as $issue) {
                $this->assertArrayHasKey('type', $issue);
                $this->assertArrayHasKey('severity', $issue);
                $this->assertArrayHasKey('file', $issue);
                $this->assertArrayHasKey('line', $issue);
                $this->assertArrayHasKey('message', $issue);
            }
        } else {
            $this->markTestSkipped('No plugins available for security scanning');
        }
    }

    public function test_severity_values() {
        $valid_severities = array('low', 'medium', 'high', 'critical');
        $plugins = $this->plugin_scanner->get_active_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $result = $this->scanner->scan_plugin($plugin_file);

            foreach ($result['issues'] as $issue) {
                $this->assertContains($issue['severity'], $valid_severities);
            }
        } else {
            $this->markTestSkipped('No plugins available for security scanning');
        }
    }
}
