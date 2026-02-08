<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later OR Palimpsest-0.8
 *
 * @package WP_Plugin_Conflict_Mapper
 * @license AGPL-3.0-or-later OR Palimpsest-0.8
 */
/**
 * Integration Tests for REST API
 *
 * @package WP_Plugin_Conflict_Mapper
 */

class Test_WPCM_REST_API extends WP_UnitTestCase {

    private $api;
    private $admin_user;

    public function setUp(): void {
        parent::setUp();
        $this->api = new WPCM_REST_API();
        $this->api->init();

        // Create admin user for permission tests
        $this->admin_user = $this->factory->user->create(array(
            'role' => 'administrator',
        ));
    }

    public function test_api_instantiation() {
        $this->assertInstanceOf('WPCM_REST_API', $this->api);
    }

    public function test_routes_registered() {
        $routes = rest_get_server()->get_routes();

        $this->assertArrayHasKey('/wpcm/v1/plugins', $routes);
        $this->assertArrayHasKey('/wpcm/v1/scan', $routes);
        $this->assertArrayHasKey('/wpcm/v1/scans', $routes);
        $this->assertArrayHasKey('/wpcm/v1/stats', $routes);
    }

    public function test_get_plugins_endpoint() {
        wp_set_current_user($this->admin_user);

        $request = new WP_REST_Request('GET', '/wpcm/v1/plugins');
        $response = rest_get_server()->dispatch($request);

        $this->assertEquals(200, $response->get_status());
        $data = $response->get_data();
        $this->assertArrayHasKey('success', $data);
        $this->assertTrue($data['success']);
    }

    public function test_get_plugins_permission() {
        wp_set_current_user(0); // No user

        $request = new WP_REST_Request('GET', '/wpcm/v1/plugins');
        $response = rest_get_server()->dispatch($request);

        $this->assertEquals(403, $response->get_status());
    }

    public function test_run_scan_endpoint() {
        wp_set_current_user($this->admin_user);

        $request = new WP_REST_Request('POST', '/wpcm/v1/scan');
        $response = rest_get_server()->dispatch($request);

        $this->assertEquals(200, $response->get_status());
        $data = $response->get_data();
        $this->assertArrayHasKey('success', $data);
        $this->assertArrayHasKey('scan_id', $data);
    }

    public function test_get_stats_endpoint() {
        wp_set_current_user($this->admin_user);

        $request = new WP_REST_Request('GET', '/wpcm/v1/stats');
        $response = rest_get_server()->dispatch($request);

        $this->assertEquals(200, $response->get_status());
        $data = $response->get_data();
        $this->assertArrayHasKey('success', $data);
        $this->assertArrayHasKey('data', $data);
    }
}
