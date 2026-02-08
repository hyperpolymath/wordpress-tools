/**
 * WP Praxis Admin JavaScript
 *
 * @package WPPraxis
 */

(function($) {
	'use strict';

	/**
	 * WP Praxis Admin Object
	 */
	const WPPraxisAdmin = {
		/**
		 * Initialize
		 */
		init: function() {
			this.bindEvents();
			this.initAccordion();
		},

		/**
		 * Bind events
		 */
		bindEvents: function() {
			// Execute symbol
			$(document).on('click', '.wp-praxis-execute', this.executeSymbol);

			// Inspect symbol
			$(document).on('click', '.wp-praxis-inspect', this.inspectSymbol);

			// Upload manifest
			$('#wp-praxis-upload-form').on('submit', this.uploadManifest);

			// Copy introspection data
			$('#wp-praxis-copy-introspection').on('click', this.copyIntrospection);

			// Download introspection data
			$('#wp-praxis-download-introspection').on('click', this.downloadIntrospection);

			// Modal close
			$('.modal-close').on('click', this.closeModal);

			// Click outside modal to close
			$(window).on('click', function(e) {
				if ($(e.target).hasClass('wp-praxis-modal')) {
					WPPraxisAdmin.closeModal();
				}
			});
		},

		/**
		 * Initialize accordion
		 */
		initAccordion: function() {
			$('.accordion-header').on('click', function() {
				const $item = $(this).parent();
				const $content = $item.find('.accordion-content');
				const $toggle = $item.find('.accordion-toggle');

				$content.slideToggle(300);
				$toggle.text($content.is(':visible') ? '▼' : '▶');
			});
		},

		/**
		 * Execute symbol
		 */
		executeSymbol: function(e) {
			e.preventDefault();

			const $button = $(this);
			const symbolName = $button.data('symbol');
			const $result = $('#result-' + symbolName);

			if (!symbolName) {
				alert(wpPraxis.strings.error);
				return;
			}

			// Disable button
			$button.prop('disabled', true).text(wpPraxis.strings.executing);

			// Show loading in result area
			if ($result.length) {
				$result.html('<div class="notice notice-info inline"><p>' + wpPraxis.strings.executing + '</p></div>');
			}

			// Execute via AJAX
			$.ajax({
				url: wpPraxis.ajaxUrl,
				type: 'POST',
				data: {
					action: 'wp_praxis_execute_symbol',
					nonce: wpPraxis.nonce,
					symbol: symbolName
				},
				success: function(response) {
					$button.prop('disabled', false).text(wpPraxis.strings.execute || 'Execute');

					if (response.success) {
						const resultHtml = '<div class="notice notice-success inline"><p>' +
							wpPraxis.strings.success + '</p>' +
							'<pre><code>' + JSON.stringify(response.data.result, null, 2) + '</code></pre>' +
							'</div>';

						if ($result.length) {
							$result.html(resultHtml);
						} else {
							$button.after(resultHtml);
						}
					} else {
						const errorHtml = '<div class="notice notice-error inline"><p>' +
							(response.data.message || wpPraxis.strings.error) + '</p></div>';

						if ($result.length) {
							$result.html(errorHtml);
						} else {
							$button.after(errorHtml);
						}
					}

					// Auto-hide after 5 seconds
					setTimeout(function() {
						if ($result.length) {
							$result.fadeOut(300, function() { $(this).html(''); $(this).show(); });
						}
					}, 5000);
				},
				error: function(xhr, status, error) {
					$button.prop('disabled', false).text(wpPraxis.strings.execute || 'Execute');

					const errorHtml = '<div class="notice notice-error inline"><p>' +
						wpPraxis.strings.error + ': ' + error + '</p></div>';

					if ($result.length) {
						$result.html(errorHtml);
					} else {
						$button.after(errorHtml);
					}
				}
			});
		},

		/**
		 * Inspect symbol
		 */
		inspectSymbol: function(e) {
			e.preventDefault();

			const symbolName = $(this).data('symbol');

			if (!symbolName) {
				return;
			}

			// Get introspection data
			$.ajax({
				url: wpPraxis.ajaxUrl,
				type: 'POST',
				data: {
					action: 'wp_praxis_introspect',
					nonce: wpPraxis.nonce
				},
				success: function(response) {
					if (response.success && response.data.symbols && response.data.symbols[symbolName]) {
						WPPraxisAdmin.showInspector(symbolName, response.data.symbols[symbolName]);
					} else {
						alert('Failed to load symbol data');
					}
				},
				error: function() {
					alert(wpPraxis.strings.error);
				}
			});
		},

		/**
		 * Show inspector modal
		 */
		showInspector: function(symbolName, data) {
			const $modal = $('#wp-praxis-inspector-modal');
			const $content = $('#inspector-content');

			let html = '<h3>' + symbolName + '</h3>';

			// Configuration
			html += '<h4>Configuration</h4>';
			html += '<pre><code>' + JSON.stringify(data.config, null, 2) + '</code></pre>';

			// State
			html += '<h4>State</h4>';
			html += '<pre><code>' + JSON.stringify(data.state, null, 2) + '</code></pre>';

			// Environment
			if (data.environment) {
				html += '<h4>Environment</h4>';
				html += '<pre><code>' + JSON.stringify(data.environment, null, 2) + '</code></pre>';
			}

			// Trace
			if (data.trace) {
				html += '<h4>Trace</h4>';
				html += '<pre><code>' + JSON.stringify(data.trace, null, 2) + '</code></pre>';
			}

			$content.html(html);
			$modal.fadeIn(300);
		},

		/**
		 * Close modal
		 */
		closeModal: function() {
			$('.wp-praxis-modal').fadeOut(300);
		},

		/**
		 * Upload manifest
		 */
		uploadManifest: function(e) {
			e.preventDefault();

			const $form = $(this);
			const $result = $('#upload-result');
			const fileInput = document.getElementById('manifest-file');

			if (!fileInput.files.length) {
				$result.html('<div class="notice notice-error inline"><p>Please select a file</p></div>');
				return;
			}

			const formData = new FormData();
			formData.append('action', 'wp_praxis_upload_manifest');
			formData.append('nonce', wpPraxis.nonce);
			formData.append('manifest', fileInput.files[0]);

			// Show uploading message
			$result.html('<div class="notice notice-info inline"><p>Uploading...</p></div>');

			$.ajax({
				url: wpPraxis.ajaxUrl,
				type: 'POST',
				data: formData,
				processData: false,
				contentType: false,
				success: function(response) {
					if (response.success) {
						$result.html('<div class="notice notice-success inline"><p>' +
							wpPraxis.strings.uploadSuccess + '</p></div>');

						// Reset form
						$form[0].reset();

						// Reload page after 2 seconds
						setTimeout(function() {
							location.reload();
						}, 2000);
					} else {
						$result.html('<div class="notice notice-error inline"><p>' +
							(response.data.message || wpPraxis.strings.uploadError) + '</p></div>');
					}
				},
				error: function() {
					$result.html('<div class="notice notice-error inline"><p>' +
						wpPraxis.strings.uploadError + '</p></div>');
				}
			});
		},

		/**
		 * Copy introspection data to clipboard
		 */
		copyIntrospection: function(e) {
			e.preventDefault();

			const text = $('#introspection-raw code').text();

			if (navigator.clipboard) {
				navigator.clipboard.writeText(text).then(function() {
					alert('Copied to clipboard!');
				}).catch(function() {
					WPPraxisAdmin.fallbackCopy(text);
				});
			} else {
				WPPraxisAdmin.fallbackCopy(text);
			}
		},

		/**
		 * Fallback copy method
		 */
		fallbackCopy: function(text) {
			const $temp = $('<textarea>');
			$('body').append($temp);
			$temp.val(text).select();
			document.execCommand('copy');
			$temp.remove();
			alert('Copied to clipboard!');
		},

		/**
		 * Download introspection data
		 */
		downloadIntrospection: function(e) {
			e.preventDefault();

			const text = $('#introspection-raw code').text();
			const blob = new Blob([text], { type: 'application/json' });
			const url = window.URL.createObjectURL(blob);
			const a = document.createElement('a');

			a.href = url;
			a.download = 'wp-praxis-introspection-' + Date.now() + '.json';
			document.body.appendChild(a);
			a.click();
			document.body.removeChild(a);
			window.URL.revokeObjectURL(url);
		}
	};

	/**
	 * Initialize on document ready
	 */
	$(document).ready(function() {
		WPPraxisAdmin.init();
	});

})(jQuery);
