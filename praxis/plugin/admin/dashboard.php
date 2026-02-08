<?php
/**
 * WP Praxis Admin Dashboard
 *
 * @package WPPraxis
 */

// Exit if accessed directly
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$engine  = wp_praxis()->get_engine();
$symbols = $engine ? $engine->get_symbols() : array();
$state   = $engine ? $engine->get_state() : array();
?>

<div class="wrap wp-praxis-dashboard">
	<h1><?php esc_html_e( 'WP Praxis Dashboard', 'wp-praxis' ); ?></h1>

	<div class="wp-praxis-grid">
		<!-- Engine Status -->
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Engine Status', 'wp-praxis' ); ?></h2>
			<div class="wp-praxis-status">
				<p>
					<strong><?php esc_html_e( 'Version:', 'wp-praxis' ); ?></strong>
					<?php echo esc_html( WP_PRAXIS_VERSION ); ?>
				</p>
				<p>
					<strong><?php esc_html_e( 'Initialized:', 'wp-praxis' ); ?></strong>
					<span class="status-indicator <?php echo $state['initialized'] ? 'active' : 'inactive'; ?>">
						<?php echo $state['initialized'] ? esc_html__( 'Yes', 'wp-praxis' ) : esc_html__( 'No', 'wp-praxis' ); ?>
					</span>
				</p>
				<p>
					<strong><?php esc_html_e( 'Loaded Symbols:', 'wp-praxis' ); ?></strong>
					<?php echo esc_html( count( $symbols ) ); ?>
				</p>
				<p>
					<strong><?php esc_html_e( 'Loaded Manifests:', 'wp-praxis' ); ?></strong>
					<?php echo esc_html( count( $state['manifests'] ?? array() ) ); ?>
				</p>
			</div>
		</div>

		<!-- Quick Actions -->
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Quick Actions', 'wp-praxis' ); ?></h2>
			<div class="wp-praxis-actions">
				<a href="<?php echo esc_url( admin_url( 'admin.php?page=wp-praxis-symbols' ) ); ?>" class="button button-primary">
					<?php esc_html_e( 'View Symbols', 'wp-praxis' ); ?>
				</a>
				<a href="<?php echo esc_url( admin_url( 'admin.php?page=wp-praxis-settings' ) ); ?>" class="button">
					<?php esc_html_e( 'Settings', 'wp-praxis' ); ?>
				</a>
				<a href="<?php echo esc_url( admin_url( 'admin.php?page=wp-praxis-introspection' ) ); ?>" class="button">
					<?php esc_html_e( 'Introspection', 'wp-praxis' ); ?>
				</a>
			</div>
		</div>

		<!-- Upload Manifest -->
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Upload Manifest', 'wp-praxis' ); ?></h2>
			<form id="wp-praxis-upload-form" enctype="multipart/form-data">
				<p>
					<input type="file" name="manifest" id="manifest-file" accept=".yml,.yaml,.toml,.json" required />
				</p>
				<p>
					<button type="submit" class="button button-primary">
						<?php esc_html_e( 'Upload and Load', 'wp-praxis' ); ?>
					</button>
				</p>
				<p class="description">
					<?php esc_html_e( 'Upload a YAML, TOML, or JSON manifest file to load symbols.', 'wp-praxis' ); ?>
				</p>
			</form>
			<div id="upload-result"></div>
		</div>

		<!-- Recent Activity -->
		<?php if ( ! empty( $state['errors'] ) ) : ?>
		<div class="wp-praxis-card">
			<h2><?php esc_html_e( 'Errors', 'wp-praxis' ); ?></h2>
			<div class="wp-praxis-errors">
				<?php foreach ( $state['errors'] as $error ) : ?>
					<div class="notice notice-error inline">
						<p><?php echo esc_html( $error ); ?></p>
					</div>
				<?php endforeach; ?>
			</div>
		</div>
		<?php endif; ?>

		<!-- Loaded Symbols -->
		<?php if ( ! empty( $symbols ) ) : ?>
		<div class="wp-praxis-card wp-praxis-full-width">
			<h2><?php esc_html_e( 'Loaded Symbols', 'wp-praxis' ); ?></h2>
			<table class="wp-list-table widefat fixed striped">
				<thead>
					<tr>
						<th><?php esc_html_e( 'Name', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Type', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Context', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Dispatcher', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Status', 'wp-praxis' ); ?></th>
						<th><?php esc_html_e( 'Actions', 'wp-praxis' ); ?></th>
					</tr>
				</thead>
				<tbody>
					<?php foreach ( $symbols as $name => $symbol ) : ?>
						<?php
						$config = $symbol->get_config();
						$state  = $symbol->get_state();
						?>
						<tr>
							<td><strong><?php echo esc_html( $config['name'] ); ?></strong></td>
							<td><?php echo esc_html( $config['type'] ); ?></td>
							<td><?php echo esc_html( $config['context'] ); ?></td>
							<td><?php echo esc_html( $config['dispatch'] ); ?></td>
							<td>
								<span class="status-badge status-<?php echo esc_attr( $state['status'] ); ?>">
									<?php echo esc_html( $state['status'] ); ?>
								</span>
							</td>
							<td>
								<button
									class="button button-small wp-praxis-execute"
									data-symbol="<?php echo esc_attr( $name ); ?>"
								>
									<?php esc_html_e( 'Execute', 'wp-praxis' ); ?>
								</button>
							</td>
						</tr>
					<?php endforeach; ?>
				</tbody>
			</table>
		</div>
		<?php endif; ?>
	</div>
</div>
