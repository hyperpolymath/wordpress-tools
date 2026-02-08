<?php
/**
 * WP Praxis Symbols Page
 *
 * @package WPPraxis
 */

// Exit if accessed directly
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$engine  = wp_praxis()->get_engine();
$symbols = $engine ? $engine->get_symbols() : array();
?>

<div class="wrap wp-praxis-symbols">
	<h1><?php esc_html_e( 'Symbolic Registry', 'wp-praxis' ); ?></h1>

	<p class="description">
		<?php
		printf(
			/* translators: %d: number of symbols */
			esc_html__( 'Total symbols loaded: %d', 'wp-praxis' ),
			count( $symbols )
		);
		?>
	</p>

	<?php if ( empty( $symbols ) ) : ?>
		<div class="notice notice-info">
			<p>
				<?php esc_html_e( 'No symbols loaded. Upload a manifest file to load symbols.', 'wp-praxis' ); ?>
			</p>
			<p>
				<a href="<?php echo esc_url( admin_url( 'admin.php?page=wp-praxis' ) ); ?>" class="button">
					<?php esc_html_e( 'Go to Dashboard', 'wp-praxis' ); ?>
				</a>
			</p>
		</div>
	<?php else : ?>
		<div class="wp-praxis-symbols-grid">
			<?php foreach ( $symbols as $name => $symbol ) : ?>
				<?php
				$config = $symbol->get_config();
				$state  = $symbol->get_state();
				?>
				<div class="wp-praxis-symbol-card">
					<div class="symbol-header">
						<h2><?php echo esc_html( $config['name'] ); ?></h2>
						<span class="status-badge status-<?php echo esc_attr( $state['status'] ); ?>">
							<?php echo esc_html( $state['status'] ); ?>
						</span>
					</div>

					<div class="symbol-meta">
						<div class="meta-row">
							<span class="meta-label"><?php esc_html_e( 'Type:', 'wp-praxis' ); ?></span>
							<span class="meta-value"><?php echo esc_html( $config['type'] ); ?></span>
						</div>
						<div class="meta-row">
							<span class="meta-label"><?php esc_html_e( 'Context:', 'wp-praxis' ); ?></span>
							<span class="meta-value"><?php echo esc_html( $config['context'] ); ?></span>
						</div>
						<div class="meta-row">
							<span class="meta-label"><?php esc_html_e( 'Dispatcher:', 'wp-praxis' ); ?></span>
							<span class="meta-value"><?php echo esc_html( $config['dispatch'] ); ?></span>
						</div>
						<div class="meta-row">
							<span class="meta-label"><?php esc_html_e( 'Priority:', 'wp-praxis' ); ?></span>
							<span class="meta-value"><?php echo esc_html( $config['priority'] ); ?></span>
						</div>
					</div>

					<div class="symbol-stats">
						<div class="stat">
							<span class="stat-label"><?php esc_html_e( 'Executions:', 'wp-praxis' ); ?></span>
							<span class="stat-value"><?php echo esc_html( $state['executions'] ?? 0 ); ?></span>
						</div>
						<div class="stat">
							<span class="stat-label"><?php esc_html_e( 'Errors:', 'wp-praxis' ); ?></span>
							<span class="stat-value"><?php echo esc_html( count( $state['errors'] ?? array() ) ); ?></span>
						</div>
					</div>

					<?php if ( ! empty( $config['parameters'] ) ) : ?>
					<div class="symbol-parameters">
						<h3><?php esc_html_e( 'Parameters:', 'wp-praxis' ); ?></h3>
						<pre><code><?php echo esc_html( wp_json_encode( $config['parameters'], JSON_PRETTY_PRINT ) ); ?></code></pre>
					</div>
					<?php endif; ?>

					<?php if ( ! empty( $state['errors'] ) ) : ?>
					<div class="symbol-errors">
						<h3><?php esc_html_e( 'Recent Errors:', 'wp-praxis' ); ?></h3>
						<?php foreach ( array_slice( $state['errors'], -3 ) as $error ) : ?>
							<div class="error-message"><?php echo esc_html( $error ); ?></div>
						<?php endforeach; ?>
					</div>
					<?php endif; ?>

					<div class="symbol-actions">
						<button
							class="button button-primary wp-praxis-execute"
							data-symbol="<?php echo esc_attr( $name ); ?>"
						>
							<?php esc_html_e( 'Execute', 'wp-praxis' ); ?>
						</button>
						<button
							class="button wp-praxis-inspect"
							data-symbol="<?php echo esc_attr( $name ); ?>"
						>
							<?php esc_html_e( 'Inspect', 'wp-praxis' ); ?>
						</button>
					</div>

					<div class="symbol-result" id="result-<?php echo esc_attr( $name ); ?>"></div>
				</div>
			<?php endforeach; ?>
		</div>
	<?php endif; ?>

	<!-- Symbol Inspector Modal -->
	<div id="wp-praxis-inspector-modal" class="wp-praxis-modal" style="display:none;">
		<div class="modal-content">
			<span class="modal-close">&times;</span>
			<h2><?php esc_html_e( 'Symbol Inspector', 'wp-praxis' ); ?></h2>
			<div id="inspector-content"></div>
		</div>
	</div>
</div>
