<?php
/**
 * Tests for WordPress Integration
 *
 * @package WPPraxis\Tests
 */

namespace WPPraxis\Tests;

use WP_Mock\Tools\TestCase;
use WPPraxis\Plugin;
use WPPraxis\Symbol;

class WordPressIntegrationTest extends TestCase
{
    private $plugin;

    public function setUp(): void
    {
        \WP_Mock::setUp();
        $this->plugin = new Plugin();
    }

    public function tearDown(): void
    {
        \WP_Mock::tearDown();
    }

    public function test_plugin_initialization()
    {
        \WP_Mock::expectActionAdded('init', [$this->plugin, 'init']);
        \WP_Mock::expectActionAdded('admin_menu', [$this->plugin, 'addAdminMenu']);

        $this->plugin->registerHooks();

        $this->assertConditionsMet();
    }

    public function test_admin_menu_registration()
    {
        \WP_Mock::userFunction('add_menu_page', [
            'times' => 1,
            'args' => [
                'WP Praxis',
                'WP Praxis',
                'manage_options',
                'wp-praxis',
                \WP_Mock\Functions::type('callable'),
                'dashicons-admin-generic'
            ]
        ]);

        $this->plugin->addAdminMenu();
        $this->assertConditionsMet();
    }

    public function test_nonce_verification()
    {
        \WP_Mock::userFunction('wp_verify_nonce', [
            'args' => ['test_nonce', 'wp_praxis_action'],
            'return' => true
        ]);

        $result = $this->plugin->verifyNonce('test_nonce', 'wp_praxis_action');
        $this->assertTrue($result);
    }

    public function test_capability_check()
    {
        \WP_Mock::userFunction('current_user_can', [
            'args' => ['manage_options'],
            'return' => true
        ]);

        $result = $this->plugin->userHasCapability('manage_options');
        $this->assertTrue($result);
    }

    public function test_sanitize_input()
    {
        $dirty_input = '<script>alert("xss")</script>Hello';
        $expected = 'Hello';

        \WP_Mock::userFunction('sanitize_text_field', [
            'args' => [$dirty_input],
            'return' => $expected
        ]);

        $result = $this->plugin->sanitizeInput($dirty_input);
        $this->assertEquals($expected, $result);
    }

    public function test_register_wordpress_hooks_for_symbol()
    {
        $symbol = new Symbol([
            'name' => 'wp_hook_symbol',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine',
            'wp_hook' => 'init',
            'wp_priority' => 10
        ]);

        \WP_Mock::expectActionAdded('init', \WP_Mock\Functions::type('callable'), 10);

        $this->plugin->registerSymbolHook($symbol);
        $this->assertConditionsMet();
    }

    public function test_enqueue_admin_scripts()
    {
        \WP_Mock::userFunction('wp_enqueue_script', [
            'times' => 1,
            'args' => [
                'wp-praxis-admin',
                \WP_Mock\Functions::type('string'),
                ['jquery'],
                \WP_Mock\Functions::type('string'),
                true
            ]
        ]);

        $this->plugin->enqueueAdminScripts();
        $this->assertConditionsMet();
    }

    public function test_ajax_handler_with_nonce()
    {
        $_POST['nonce'] = 'test_nonce';
        $_POST['action'] = 'wp_praxis_execute_symbol';
        $_POST['symbol_name'] = 'test_symbol';

        \WP_Mock::userFunction('wp_verify_nonce', [
            'return' => true
        ]);

        \WP_Mock::userFunction('current_user_can', [
            'return' => true
        ]);

        \WP_Mock::userFunction('wp_send_json_success', [
            'times' => 1
        ]);

        $this->plugin->handleAjaxRequest();
        $this->assertConditionsMet();
    }

    public function test_ajax_handler_without_permission()
    {
        $_POST['nonce'] = 'test_nonce';

        \WP_Mock::userFunction('wp_verify_nonce', [
            'return' => true
        ]);

        \WP_Mock::userFunction('current_user_can', [
            'return' => false
        ]);

        \WP_Mock::userFunction('wp_send_json_error', [
            'times' => 1,
            'args' => [['message' => 'Insufficient permissions']]
        ]);

        $this->plugin->handleAjaxRequest();
        $this->assertConditionsMet();
    }

    public function test_register_custom_post_type()
    {
        \WP_Mock::userFunction('register_post_type', [
            'times' => 1,
            'args' => [
                'wp_praxis_symbol',
                \WP_Mock\Functions::type('array')
            ]
        ]);

        $this->plugin->registerCustomPostTypes();
        $this->assertConditionsMet();
    }

    public function test_add_meta_box()
    {
        \WP_Mock::userFunction('add_meta_box', [
            'times' => 1,
            'args' => [
                'wp_praxis_symbol_config',
                'Symbol Configuration',
                \WP_Mock\Functions::type('callable'),
                'wp_praxis_symbol',
                'normal',
                'high'
            ]
        ]);

        $this->plugin->addMetaBoxes();
        $this->assertConditionsMet();
    }

    public function test_save_post_meta()
    {
        $post_id = 123;
        $meta_data = ['symbol_type' => 'action', 'context' => 'wordpress'];

        \WP_Mock::userFunction('update_post_meta', [
            'times' => 2
        ]);

        $this->plugin->savePostMeta($post_id, $meta_data);
        $this->assertConditionsMet();
    }
}
