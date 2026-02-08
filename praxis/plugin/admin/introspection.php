<?php
/**
 * WP Praxis Introspection Page
 *
 * @package WPPraxis
 */

// Exit if accessed directly
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$engine         = wp_praxis()->get_engine();
$introspection  = $engine ? $engine->introspect() : array();
?>

<div class="wrap wp-praxis-introspection">
	<h1><?php esc_html_e( 'Engine Introspection', 'wp-praxis' ); ?></h1>

	<p class="description">
		<?php esc_html_e( 'Deep dive into the symbolic engine state, configuration, and runtime information.', 'wp-praxis' ); ?>
	</p>

	<div class="wp-praxis-introspection-grid">
		<!-- Engine Information -->
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Engine Information', 'wp-praxis' ); ?></h2>
			<?php if ( ! empty( $introspection['engine'] ) ) : ?>
				<table class="widefat">
					<tbody>
						<?php foreach ( $introspection['engine'] as $key => $value ) : ?>
							<?php if ( ! is_array( $value ) ) : ?>
								<tr>
									<td><strong><?php echo esc_html( ucwords( str_replace( '_', ' ', $key ) ) ); ?>:</strong></td>
									<td>
										<?php
										if ( is_bool( $value ) ) {
											echo $value ? '<span class="status-indicator active">Yes</span>' : '<span class="status-indicator inactive">No</span>';
										} else {
											echo esc_html( $value );
										}
										?>
									</td>
								</tr>
							<?php endif; ?>
						<?php endforeach; ?>
					</tbody>
				</table>
			<?php endif; ?>
		</div>

		<!-- Engine State -->
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Engine State', 'wp-praxis' ); ?></h2>
			<?php if ( ! empty( $introspection['state'] ) ) : ?>
				<pre><code><?php echo esc_html( wp_json_encode( $introspection['state'], JSON_PRETTY_PRINT ) ); ?></code></pre>
			<?php endif; ?>
		</div>

		<!-- Loaded Manifests -->
		<?php if ( ! empty( $introspection['state']['manifests'] ) ) : ?>
		<div class="wp-praxis-card wp-praxis-full-width">
			<h2><?php esc_html_e( 'Loaded Manifests', 'wp-praxis' ); ?></h2>
			<table class="wp-list-table widefat fixed striped">
				<thead>
					<tr>
						<th><?php esc_html_e( 'Path', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Symbols', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Loaded At', 'wp-praxis' ); ?></th>
					</tr>
				</thead>
				<tbody>
					<?php foreach ( $introspection['state']['manifests'] as $manifest ) : ?>
						<tr>
							<td><code><?php echo esc_html( $manifest['path'] ); ?></code></td>
							<td><?php echo esc_html( $manifest['symbols'] ?? 0 ); ?></td>
							<td><?php echo esc_html( date_i18n( get_option( 'date_format' ) . ' ' . get_option( 'time_format' ), $manifest['loaded_at'] ) ); ?></td>
						</tr>
					<?php endforeach; ?>
				</tbody>
			</table>
		</div>
		<?php endif; ?>

		<!-- Symbols Introspection -->
		<?php if ( ! empty( $introspection['symbols'] ) ) : ?>
		<div class="wp-praxis-card wp-praxis-full-width">
			<h2><?php esc_html_e( 'Symbols Introspection', 'wp-praxis' ); ?></h2>
			<div class="wp-praxis-accordion">
				<?php foreach ( $introspection['symbols'] as $symbol_name => $symbol_data ) : ?>
					<div class="accordion-item">
						<div class="accordion-header">
							<h3><?php echo esc_html( $symbol_name ); ?></h3>
							<span class="accordion-toggle">▼</span>
						</div>
						<div class="accordion-content" style="display:none;">
							<h4><?php esc_html_e( 'Configuration', 'wp-praxis' ); ?></h4>
							<pre><code><?php echo esc_html( wp_json_encode( $symbol_data['config'] ?? array(), JSON_PRETTY_PRINT ) ); ?></code></pre>

							<h4><?php esc_html_e( 'State', 'wp-praxis' ); ?></h4>
							<pre><code><?php echo esc_html( wp_json_encode( $symbol_data['state'] ?? array(), JSON_PRETTY_PRINT ) ); ?></code></pre>

							<?php if ( ! empty( $symbol_data['environment'] ) ) : ?>
								<h4><?php esc_html_e( 'Environment', 'wp-praxis' ); ?></h4>
								<pre><code><?php echo esc_html( wp_json_encode( $symbol_data['environment'], JSON_PRETTY_PRINT ) ); ?></code></pre>
							<?php endif; ?>

							<?php if ( ! empty( $symbol_data['trace'] ) ) : ?>
								<h4><?php esc_html_e( 'Trace', 'wp-praxis' ); ?></h4>
								<pre><code><?php echo esc_html( wp_json_encode( $symbol_data['trace'], JSON_PRETTY_PRINT ) ); ?></code></pre>
							<?php endif; ?>
						</div>
					</div>
				<?php endforeach; ?>
			</div>
		</div>
		<?php endif; ?>

		<!-- Raw Introspection Data -->
		<div class="wp-praxis-card wp-praxis-full-width">
			<h2><?php esc_html_e( 'Raw Introspection Data', 'wp-praxis' ); ?></h2>
			<button id="wp-praxis-copy-introspection" class="button">
				<?php esc_html_e( 'Copy to Clipboard', 'wp-praxis' ); ?>
			</button>
			<button id="wp-praxis-download-introspection" class="button">
				<?php esc_html_e( 'Download JSON', 'wp-praxis' ); ?>
			</button>
			<pre id="introspection-raw"><code><?php echo esc_html( wp_json_encode( $introspection, JSON_PRETTY_PRINT ) ); ?></code></pre>
		</div>
	</div>
</div>
