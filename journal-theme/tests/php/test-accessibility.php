<?php
/**
 * Tests for inc/accessibility.php
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Sinople_Accessibility
 */
class Test_Sinople_Accessibility extends SinopleTestCase {
	/**
	 * Test skip links output
	 */
	public function test_sinople_skip_links(): void {
		ob_start();
		sinople_skip_links();
		$output = ob_get_clean();

		$this->assertHasAriaAttribute( $output, 'aria-label' );
		$this->assertStringContainsString( 'skip-link', $output );
		$this->assertStringContainsString( '#main-content', $output );
		$this->assertStringContainsString( '#primary-navigation', $output );
	}

	/**
	 * Test screen reader text helper
	 */
	public function test_sinople_screen_reader_text(): void {
		$text = 'Screen reader only text';

		ob_start();
		sinople_screen_reader_text( $text );
		$output = ob_get_clean();

		$this->assertStringContainsString( 'screen-reader-text', $output );
		$this->assertStringContainsString( $text, $output );
	}

	/**
	 * Test ARIA current attribute for navigation
	 */
	public function test_sinople_aria_current(): void {
		$post_id = $this->create_test_post();
		$this->go_to( get_permalink( $post_id ) );

		$aria = sinople_aria_current( $post_id );

		$this->assertStringContainsString( 'aria-current', $aria );
		$this->assertStringContainsString( 'page', $aria );
	}

	/**
	 * Test reduced motion CSS generation
	 */
	public function test_sinople_reduced_motion_css(): void {
		ob_start();
		sinople_reduced_motion_css();
		$output = ob_get_clean();

		$this->assertStringContainsString( '@media (prefers-reduced-motion: reduce)', $output );
		$this->assertStringContainsString( 'animation: none', $output );
		$this->assertStringContainsString( 'transition: none', $output );
	}

	/**
	 * Test landmark ARIA labels
	 */
	public function test_sinople_landmark_label(): void {
		$label = sinople_landmark_label( 'navigation', 'Primary' );

		$this->assertStringContainsString( 'aria-label', $label );
		$this->assertStringContainsString( 'Primary navigation', $label );
	}

	/**
	 * Test accessibility controls widget output
	 */
	public function test_accessibility_controls_widget(): void {
		ob_start();
		the_widget( 'Sinople_Accessibility_Controls_Widget' );
		$output = ob_get_clean();

		// Widget should output controls for font size, theme, and contrast
		$this->assertStringContainsString( 'accessibility-controls', $output );
		$this->assertStringContainsString( 'button', $output );
		$this->assertHasAriaAttribute( $output, 'aria-label' );
	}
}
