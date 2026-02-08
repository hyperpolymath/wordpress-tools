<?php
/**
 * WP Praxis Settings Page
 *
 * @package WPPraxis
 */

// Exit if accessed directly
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>

<div class="wrap wp-praxis-settings">
	<h1><?php esc_html_e( 'WP Praxis Settings', 'wp-praxis' ); ?></h1>

	<?php settings_errors(); ?>

	<form method="post" action="options.php">
		<?php
		settings_fields( 'wp_praxis_settings' );
		do_settings_sections( 'wp-praxis-settings' );
		submit_button();
		?>
	</form>

	<div class="wp-praxis-info-cards">
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'About WP Praxis', 'wp-praxis' ); ?></h2>
			<p>
				<?php
				esc_html_e(
					'WP Praxis is a modular symbolic system for WordPress workflows that combines recursive logic, metadata-driven configuration, and distributed execution.',
					'wp-praxis'
				);
				?>
			</p>
			<p>
				<strong><?php esc_html_e( 'Version:', 'wp-praxis' ); ?></strong>
				<?php echo esc_html( WP_PRAXIS_VERSION ); ?>
			</p>
			<p>
				<strong><?php esc_html_e( 'License:', 'wp-praxis' ); ?></strong>
				<?php esc_html_e( 'GNU AGPL v3', 'wp-praxis' ); ?>
			</p>
		</div>

		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Documentation', 'wp-praxis' ); ?></h2>
			<ul>
				<li>
					<a href="https://github.com/wp-praxis/wp-praxis" target="_blank">
						<?php esc_html_e( 'GitHub Repository', 'wp-praxis' ); ?>
					</a>
				</li>
				<li>
					<a href="https://github.com/wp-praxis/wp-praxis/blob/main/CLAUDE.md" target="_blank">
						<?php esc_html_e( 'Developer Guide', 'wp-praxis' ); ?>
					</a>
				</li>
				<li>
					<a href="https://github.com/wp-praxis/wp-praxis/blob/main/Docs/" target="_blank">
						<?php esc_html_e( 'Full Documentation', 'wp-praxis' ); ?>
					</a>
				</li>
			</ul>
		</div>

		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'System Information', 'wp-praxis' ); ?></h2>
			<table class="widefat">
				<tbody>
					<tr>
						<td><strong><?php esc_html_e( 'PHP Version:', 'wp-praxis' ); ?></strong></td>
						<td><?php echo esc_html( PHP_VERSION ); ?></td>
					</tr>
					<tr>
						<td><strong><?php esc_html_e( 'WordPress Version:', 'wp-praxis' ); ?></strong></td>
						<td><?php echo esc_html( get_bloginfo( 'version' ) ); ?></td>
					</tr>
					<tr>
						<td><strong><?php esc_html_e( 'Engine Path:', 'wp-praxis' ); ?></strong></td>
						<td><code><?php echo esc_html( WP_PRAXIS_ENGINE_PATH ); ?></code></td>
					</tr>
					<tr>
						<td><strong><?php esc_html_e( 'Plugin Directory:', 'wp-praxis' ); ?></strong></td>
						<td><code><?php echo esc_html( WP_PRAXIS_PLUGIN_DIR ); ?></code></td>
					</tr>
				</tbody>
			</table>
		</div>

		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Advanced Configuration', 'wp-praxis' ); ?></h2>
			<p class="description">
				<?php
				esc_html_e(
					'Additional configuration can be done by editing the manifest files or using the REST API.',
					'wp-praxis'
				);
				?>
			</p>
			<p>
				<strong><?php esc_html_e( 'REST API Endpoints:', 'wp-praxis' ); ?></strong>
			</p>
			<ul>
				<li><code>POST /wp-json/wp-praxis/v1/execute/{symbol}</code></li>
				<li><code>GET /wp-json/wp-praxis/v1/symbols</code></li>
				<li><code>GET /wp-json/wp-praxis/v1/introspect</code></li>
			</ul>
		</div>
	</div>
</div>
