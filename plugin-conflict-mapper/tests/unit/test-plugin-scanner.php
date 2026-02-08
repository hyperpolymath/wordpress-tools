<?php
/**
 * Class Test_WPCM_Plugin_Scanner
 *
 * @package WP_Plugin_Conflict_Mapper
 */

/**
 * Plugin Scanner test case.
 */
class Test_WPCM_Plugin_Scanner extends WP_UnitTestCase {

    /**
     * Scanner instance
     *
     * @var WPCM_Plugin_Scanner
     */
    private $scanner;

    /**
     * Set up test
     */
    public function setUp(): void {
        parent::setUp();
        $this->scanner = new WPCM_Plugin_Scanner();
    }

    /**
     * Test scanner instantiation
     */
    public function test_scanner_instantiation() {
        $this->assertInstanceOf('WPCM_Plugin_Scanner', $this->scanner);
    }

    /**
     * Test get_all_plugins returns array
     */
    public function test_get_all_plugins_returns_array() {
        $plugins = $this->scanner->get_all_plugins();
        $this->assertIsArray($plugins);
    }

    /**
     * Test get_active_plugins returns array
     */
    public function test_get_active_plugins_returns_array() {
        $plugins = $this->scanner->get_active_plugins();
        $this->assertIsArray($plugins);
    }

    /**
     * Test plugin data structure
     */
    public function test_plugin_data_structure() {
        $plugins = $this->scanner->get_all_plugins();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $this->assertIsString($plugin_file);
            $this->assertArrayHasKey('name', $plugin_data);
            $this->assertArrayHasKey('version', $plugin_data);
            $this->assertArrayHasKey('is_active', $plugin_data);
            $this->assertIsBool($plugin_data['is_active']);
        }
    }

    /**
     * Test get_plugin_size
     */
    public function test_get_plugin_size() {
        $plugins = $this->scanner->get_all_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $size = $this->scanner->get_plugin_size($plugin_file);
            $this->assertIsInt($size);
            $this->assertGreaterThanOrEqual(0, $size);
        } else {
            $this->markTestSkipped('No plugins available for testing');
        }
    }

    /**
     * Test scan_plugin_hooks returns expected structure
     */
    public function test_scan_plugin_hooks_structure() {
        $plugins = $this->scanner->get_all_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $hooks = $this->scanner->scan_plugin_hooks($plugin_file);

            $this->assertIsArray($hooks);
            $this->assertArrayHasKey('actions', $hooks);
            $this->assertArrayHasKey('filters', $hooks);
            $this->assertIsArray($hooks['actions']);
            $this->assertIsArray($hooks['filters']);
        } else {
            $this->markTestSkipped('No plugins available for testing');
        }
    }

    /**
     * Test scan_plugin_functions returns array
     */
    public function test_scan_plugin_functions_returns_array() {
        $plugins = $this->scanner->get_all_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $functions = $this->scanner->scan_plugin_functions($plugin_file);
            $this->assertIsArray($functions);
        } else {
            $this->markTestSkipped('No plugins available for testing');
        }
    }

    /**
     * Test get_plugin_complexity returns integer
     */
    public function test_get_plugin_complexity_returns_integer() {
        $plugins = $this->scanner->get_all_plugins();

        if (!empty($plugins)) {
            $plugin_file = array_key_first($plugins);
            $complexity = $this->scanner->get_plugin_complexity($plugin_file);
            $this->assertIsInt($complexity);
            $this->assertGreaterThanOrEqual(0, $complexity);
        } else {
            $this->markTestSkipped('No plugins available for testing');
        }
    }
}
