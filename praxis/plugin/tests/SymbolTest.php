<?php
/**
 * Tests for Symbol class
 *
 * @package WPPraxis\Tests
 */

namespace WPPraxis\Tests;

use PHPUnit\Framework\TestCase;
use WPPraxis\Symbol;

class SymbolTest extends TestCase
{
    public function test_create_symbol()
    {
        $symbol = new Symbol([
            'name' => 'test_symbol',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine'
        ]);

        $this->assertEquals('test_symbol', $symbol->getName());
        $this->assertEquals('action', $symbol->getType());
        $this->assertEquals('wordpress', $symbol->getContext());
    }

    public function test_symbol_validation()
    {
        $this->expectException(\InvalidArgumentException::class);

        new Symbol([
            // Missing required fields
        ]);
    }

    public function test_symbol_with_parameters()
    {
        $params = [
            'key1' => 'value1',
            'key2' => 'value2'
        ];

        $symbol = new Symbol([
            'name' => 'test_symbol',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine',
            'parameters' => $params
        ]);

        $this->assertEquals($params, $symbol->getParameters());
        $this->assertEquals('value1', $symbol->getParameter('key1'));
    }

    public function test_symbol_serialization()
    {
        $symbol = new Symbol([
            'name' => 'test_symbol',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine'
        ]);

        $json = json_encode($symbol);
        $this->assertJson($json);

        $decoded = json_decode($json, true);
        $this->assertEquals('test_symbol', $decoded['name']);
    }

    public function test_symbol_types()
    {
        $validTypes = ['action', 'query', 'transform', 'validator'];

        foreach ($validTypes as $type) {
            $symbol = new Symbol([
                'name' => 'test',
                'type' => $type,
                'context' => 'test',
                'dispatch' => 'test'
            ]);

            $this->assertEquals($type, $symbol->getType());
        }
    }

    public function test_invalid_symbol_type()
    {
        $this->expectException(\InvalidArgumentException::class);

        new Symbol([
            'name' => 'test',
            'type' => 'invalid_type',
            'context' => 'test',
            'dispatch' => 'test'
        ]);
    }

    public function test_symbol_dependencies()
    {
        $symbol = new Symbol([
            'name' => 'dependent_symbol',
            'type' => 'action',
            'context' => 'wordpress',
            'dispatch' => 'php_engine',
            'depends_on' => ['symbol1', 'symbol2']
        ]);

        $dependencies = $symbol->getDependencies();
        $this->assertCount(2, $dependencies);
        $this->assertContains('symbol1', $dependencies);
    }

    public function test_symbol_metadata()
    {
        $metadata = [
            'description' => 'Test symbol',
            'author' => 'Test Author',
            'version' => '1.0.0'
        ];

        $symbol = new Symbol([
            'name' => 'test',
            'type' => 'action',
            'context' => 'test',
            'dispatch' => 'test',
            'metadata' => $metadata
        ]);

        $this->assertEquals($metadata, $symbol->getMetadata());
        $this->assertEquals('Test Author', $symbol->getMetadata('author'));
    }
}
