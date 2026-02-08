<?php
/**
 * Tests for Symbolic Engine
 *
 * @package WPPraxis\Tests
 */

namespace WPPraxis\Tests;

use PHPUnit\Framework\TestCase;
use WPPraxis\SymbolicEngine;
use WPPraxis\Symbol;

class SymbolicEngineTest extends TestCase
{
    private $engine;

    protected function setUp(): void
    {
        parent::setUp();
        $this->engine = new SymbolicEngine();
    }

    public function test_engine_initialization()
    {
        $this->assertInstanceOf(SymbolicEngine::class, $this->engine);
    }

    public function test_register_symbol()
    {
        $symbol = new Symbol([
            'name' => 'test_symbol',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine'
        ]);

        $result = $this->engine->registerSymbol($symbol);
        $this->assertTrue($result);

        $registered = $this->engine->getSymbol('test_symbol');
        $this->assertEquals($symbol->getName(), $registered->getName());
    }

    public function test_execute_symbol()
    {
        $symbol = new Symbol([
            'name' => 'test_action',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine',
            'callback' => function() {
                return 'executed';
            }
        ]);

        $this->engine->registerSymbol($symbol);
        $result = $this->engine->execute('test_action');

        $this->assertTrue($result['success']);
        $this->assertEquals('executed', $result['data']);
    }

    public function test_execute_nonexistent_symbol()
    {
        $this->expectException(\RuntimeException::class);
        $this->engine->execute('nonexistent_symbol');
    }

    public function test_symbol_dependencies_resolution()
    {
        $symbol1 = new Symbol([
            'name' => 'symbol1',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine'
        ]);

        $symbol2 = new Symbol([
            'name' => 'symbol2',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'depends_on' => ['symbol1']
        ]);

        $this->engine->registerSymbol($symbol1);
        $this->engine->registerSymbol($symbol2);

        $resolved = $this->engine->resolveDependencies('symbol2');
        $this->assertCount(2, $resolved);
        $this->assertEquals('symbol1', $resolved[0]);
        $this->assertEquals('symbol2', $resolved[1]);
    }

    public function test_circular_dependency_detection()
    {
        $symbol1 = new Symbol([
            'name' => 'symbol1',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'depends_on' => ['symbol2']
        ]);

        $symbol2 = new Symbol([
            'name' => 'symbol2',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'depends_on' => ['symbol1']
        ]);

        $this->engine->registerSymbol($symbol1);
        $this->engine->registerSymbol($symbol2);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Circular dependency');

        $this->engine->resolveDependencies('symbol1');
    }

    public function test_execute_workflow()
    {
        $executed = [];

        $symbol1 = new Symbol([
            'name' => 'init',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'callback' => function() use (&$executed) {
                $executed[] = 'init';
                return 'init complete';
            }
        ]);

        $symbol2 = new Symbol([
            'name' => 'process',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'depends_on' => ['init'],
            'callback' => function() use (&$executed) {
                $executed[] = 'process';
                return 'process complete';
            }
        ]);

        $symbol3 = new Symbol([
            'name' => 'finalize',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'depends_on' => ['process'],
            'callback' => function() use (&$executed) {
                $executed[] = 'finalize';
                return 'finalize complete';
            }
        ]);

        $this->engine->registerSymbol($symbol1);
        $this->engine->registerSymbol($symbol2);
        $this->engine->registerSymbol($symbol3);

        $result = $this->engine->executeWorkflow(['init', 'process', 'finalize']);

        $this->assertTrue($result['success']);
        $this->assertEquals(['init', 'process', 'finalize'], $executed);
    }

    public function test_rollback_on_failure()
    {
        $rollbackCalled = false;

        $symbol = new Symbol([
            'name' => 'failing_symbol',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'callback' => function() {
                throw new \Exception('Symbol execution failed');
            },
            'rollback' => function() use (&$rollbackCalled) {
                $rollbackCalled = true;
            }
        ]);

        $this->engine->registerSymbol($symbol);

        try {
            $this->engine->execute('failing_symbol');
            $this->fail('Expected exception was not thrown');
        } catch (\Exception $e) {
            $this->assertTrue($rollbackCalled);
        }
    }

    public function test_symbol_caching()
    {
        $executionCount = 0;

        $symbol = new Symbol([
            'name' => 'cached_symbol',
            'type' => 'query',
            'context' => 'test',
            'dispatch' => 'php_engine',
            'cache_enabled' => true,
            'cache_ttl' => 3600,
            'callback' => function() use (&$executionCount) {
                $executionCount++;
                return 'result';
            }
        ]);

        $this->engine->registerSymbol($symbol);

        $result1 = $this->engine->execute('cached_symbol');
        $result2 = $this->engine->execute('cached_symbol');

        $this->assertEquals(1, $executionCount);
        $this->assertEquals($result1['data'], $result2['data']);
    }
}
