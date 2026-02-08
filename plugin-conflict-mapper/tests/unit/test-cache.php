<?php
/**
 * Class Test_WPCM_Cache
 *
 * @package WP_Plugin_Conflict_Mapper
 */

/**
 * Cache test case.
 */
class Test_WPCM_Cache extends WP_UnitTestCase {

    /**
     * Cache instance
     *
     * @var WPCM_Cache
     */
    private $cache;

    /**
     * Set up test
     */
    public function setUp(): void {
        parent::setUp();
        $this->cache = new WPCM_Cache();
    }

    /**
     * Tear down test
     */
    public function tearDown(): void {
        $this->cache->clear_all();
        parent::tearDown();
    }

    /**
     * Test cache instantiation
     */
    public function test_cache_instantiation() {
        $this->assertInstanceOf('WPCM_Cache', $this->cache);
    }

    /**
     * Test set and get
     */
    public function test_set_and_get() {
        $key = 'test_key';
        $value = array('test' => 'data');

        $this->cache->set($key, $value, 60);
        $retrieved = $this->cache->get($key);

        $this->assertEquals($value, $retrieved);
    }

    /**
     * Test get returns false for non-existent key
     */
    public function test_get_nonexistent_returns_false() {
        $result = $this->cache->get('nonexistent_key');
        $this->assertFalse($result);
    }

    /**
     * Test delete
     */
    public function test_delete() {
        $key = 'test_key';
        $value = 'test_value';

        $this->cache->set($key, $value, 60);
        $this->cache->delete($key);
        $retrieved = $this->cache->get($key);

        $this->assertFalse($retrieved);
    }

    /**
     * Test remember functionality
     */
    public function test_remember() {
        $key = 'remember_key';
        $call_count = 0;

        $callback = function() use (&$call_count) {
            $call_count++;
            return 'computed_value';
        };

        // First call should execute callback
        $result1 = $this->cache->remember($key, $callback, 60);
        $this->assertEquals('computed_value', $result1);
        $this->assertEquals(1, $call_count);

        // Second call should use cached value
        $result2 = $this->cache->remember($key, $callback, 60);
        $this->assertEquals('computed_value', $result2);
        $this->assertEquals(1, $call_count, 'Callback should not be called again');
    }

    /**
     * Test clear_all
     */
    public function test_clear_all() {
        $this->cache->set('key1', 'value1', 60);
        $this->cache->set('key2', 'value2', 60);

        $this->cache->clear_all();

        $this->assertFalse($this->cache->get('key1'));
        $this->assertFalse($this->cache->get('key2'));
    }
}
