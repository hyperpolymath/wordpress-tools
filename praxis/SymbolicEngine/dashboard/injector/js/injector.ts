/**
 * WP Praxis Injector Dashboard
 * Symbolic injection and rollback interface
 */

const API_BASE = window.location.origin + '/api';

// State
let manifestData: any = null;
let currentInjection: any = null;

/**
 * Initialize injector dashboard
 */
function initInjector() {
  console.log('[Injector] Initializing...');

  setupTheme();
  setupFileUpload();
  setupFormHandlers();
  loadWorkflows();
  loadInjectionHistory();

  console.log('[Injector] Ready');
}

/**
 * Setup theme toggle
 */
function setupTheme() {
  const themeToggle = document.getElementById('theme-toggle');
  const html = document.documentElement;

  const savedTheme = localStorage.getItem('theme');
  const systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const theme = savedTheme || (systemDark ? 'dark' : 'light');
  html.setAttribute('data-theme', theme);

  themeToggle?.addEventListener('click', () => {
    const currentTheme = html.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
  });
}

/**
 * Setup file upload
 */
function setupFileUpload() {
  const uploadArea = document.getElementById('manifest-upload');
  const fileInput = document.getElementById('manifest-file') as HTMLInputElement;

  uploadArea?.addEventListener('click', () => fileInput?.click());

  fileInput?.addEventListener('change', (e) => {
    const file = (e.target as HTMLInputElement).files?.[0];
    if (file) {
      handleManifestFile(file);
    }
  });

  // Drag and drop
  uploadArea?.addEventListener('dragover', (e) => {
    e.preventDefault();
    uploadArea.classList.add('dragover');
  });

  uploadArea?.addEventListener('dragleave', () => {
    uploadArea?.classList.remove('dragover');
  });

  uploadArea?.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadArea?.classList.remove('dragover');

    const file = e.dataTransfer?.files[0];
    if (file) {
      handleManifestFile(file);
    }
  });
}

/**
 * Handle manifest file upload
 */
async function handleManifestFile(file: File) {
  try {
    const text = await file.text();
    manifestData = parseManifest(text, file.name);

    // Display preview
    const preview = document.getElementById('manifest-preview');
    const content = document.getElementById('manifest-content');

    if (preview && content) {
      preview.style.display = 'block';
      content.textContent = text;
    }

    showToast('success', `Manifest loaded: ${file.name}`);
  } catch (error) {
    console.error('[Injector] Error loading manifest:', error);
    showToast('error', `Failed to load manifest: ${error}`);
  }
}

/**
 * Parse manifest (simplified)
 */
function parseManifest(text: string, filename: string): any {
  // In production, use proper YAML/TOML parsers
  try {
    if (filename.endsWith('.json')) {
      return JSON.parse(text);
    }
    // For now, return raw text for YAML/TOML
    return { raw: text, filename };
  } catch (error) {
    throw new Error('Invalid manifest format');
  }
}

/**
 * Setup form handlers
 */
function setupFormHandlers() {
  const validateBtn = document.getElementById('validate-btn');
  const injectBtn = document.getElementById('inject-btn');
  const rollbackBtn = document.getElementById('rollback-btn');

  validateBtn?.addEventListener('click', handleValidate);
  injectBtn?.addEventListener('click', handleInject);
  rollbackBtn?.addEventListener('click', handleRollback);
}

/**
 * Handle manifest validation
 */
async function handleValidate() {
  if (!manifestData) {
    showToast('warning', 'Please load a manifest first');
    return;
  }

  updateStatus('running', 'Validating manifest...');
  addLogEntry('info', 'Starting manifest validation');

  try {
    // Simulate validation (in production, call API)
    await delay(1000);

    updateStatus('success', 'Manifest is valid');
    addLogEntry('success', 'Manifest validation completed successfully');
    showToast('success', 'Manifest validation passed');
  } catch (error) {
    updateStatus('error', 'Validation failed');
    addLogEntry('error', `Validation error: ${error}`);
    showToast('error', 'Manifest validation failed');
  }
}

/**
 * Handle symbol injection
 */
async function handleInject() {
  if (!manifestData) {
    showToast('warning', 'Please load a manifest first');
    return;
  }

  const workflow = (document.getElementById('target-workflow') as HTMLSelectElement)?.value;
  const mode = (document.getElementById('injection-mode') as HTMLSelectElement)?.value;
  const env = (document.getElementById('target-env') as HTMLSelectElement)?.value;

  if (!workflow) {
    showToast('warning', 'Please select a target workflow');
    return;
  }

  // Show diff preview for dry-run mode
  if (mode === 'dry-run') {
    showDiffPreview();
    return;
  }

  updateStatus('running', 'Injecting symbols...');
  addLogEntry('info', `Starting injection: ${workflow} (${mode})`);

  try {
    // Simulate injection process
    await delay(500);
    addLogEntry('info', 'Creating baseline snapshot...');

    await delay(500);
    addLogEntry('info', 'Validating symbols...');

    await delay(1000);
    addLogEntry('info', 'Injecting symbols...');

    await delay(1000);
    addLogEntry('success', 'Symbols injected successfully');

    updateStatus('success', 'Injection completed');
    showToast('success', 'Symbols injected successfully');

    // Add to history
    addToHistory({
      workflow,
      mode,
      env,
      timestamp: new Date().toISOString(),
      status: 'success',
    });
  } catch (error) {
    updateStatus('error', 'Injection failed');
    addLogEntry('error', `Injection error: ${error}`);
    showToast('error', 'Symbol injection failed');
  }
}

/**
 * Handle rollback
 */
async function handleRollback() {
  const snapshot = (document.getElementById('rollback-select') as HTMLSelectElement)?.value;

  if (!snapshot) {
    showToast('warning', 'Please select a snapshot to restore');
    return;
  }

  if (!confirm('Are you sure you want to rollback? This will restore the selected snapshot.')) {
    return;
  }

  updateStatus('running', 'Rolling back...');
  addLogEntry('info', `Rolling back to snapshot: ${snapshot}`);

  try {
    // Simulate rollback
    await delay(2000);

    updateStatus('success', 'Rollback completed');
    addLogEntry('success', 'Rollback completed successfully');
    showToast('success', 'Successfully rolled back to previous state');
  } catch (error) {
    updateStatus('error', 'Rollback failed');
    addLogEntry('error', `Rollback error: ${error}`);
    showToast('error', 'Rollback failed');
  }
}

/**
 * Update injection status display
 */
function updateStatus(status: 'idle' | 'running' | 'success' | 'error', message: string) {
  const statusDisplay = document.getElementById('injection-status');
  if (!statusDisplay) return;

  const icons = {
    idle: '⏸️',
    running: '⚙️',
    success: '✅',
    error: '❌',
  };

  statusDisplay.innerHTML = `
    <div class="status-${status}">
      <span class="icon">${icons[status]}</span>
      <p>${message}</p>
    </div>
  `;
}

/**
 * Add log entry
 */
function addLogEntry(level: 'info' | 'success' | 'warning' | 'error', message: string) {
  const logDisplay = document.getElementById('progress-log');
  if (!logDisplay) return;

  // Remove placeholder
  const placeholder = logDisplay.querySelector('.log-placeholder');
  if (placeholder) placeholder.remove();

  const entry = document.createElement('div');
  entry.className = `log-entry ${level}`;

  const timestamp = new Date().toLocaleTimeString();
  entry.innerHTML = `
    <span class="timestamp">[${timestamp}]</span>
    <span class="message">${message}</span>
  `;

  logDisplay.appendChild(entry);
  logDisplay.scrollTop = logDisplay.scrollHeight;
}

/**
 * Load workflows
 */
async function loadWorkflows() {
  try {
    const response = await fetch(`${API_BASE}/workflows`);
    const data = await response.json();

    const select = document.getElementById('target-workflow') as HTMLSelectElement;
    if (!select) return;

    if (data.success && data.data.length > 0) {
      select.innerHTML =
        '<option value="">Select workflow...</option>' +
        data.data
          .map((w: any) => `<option value="${w.id}">${w.name}</option>`)
          .join('');
    }
  } catch (error) {
    console.error('[Injector] Error loading workflows:', error);
  }
}

/**
 * Load injection history
 */
async function loadInjectionHistory() {
  // In production, load from API
  const history = JSON.parse(localStorage.getItem('injection_history') || '[]');

  const historyList = document.getElementById('injection-history');
  if (!historyList) return;

  if (history.length === 0) return;

  historyList.innerHTML = history
    .slice(-5)
    .reverse()
    .map(
      (item: any) => `
      <div class="history-item">
        <div class="history-item-header">
          <div class="history-item-title">${item.workflow}</div>
          <div class="history-item-time">${new Date(item.timestamp).toLocaleString()}</div>
        </div>
        <div class="history-item-details">
          ${item.mode} • ${item.env} • ${item.status}
        </div>
      </div>
    `
    )
    .join('');
}

/**
 * Add to injection history
 */
function addToHistory(item: any) {
  const history = JSON.parse(localStorage.getItem('injection_history') || '[]');
  history.push(item);
  localStorage.setItem('injection_history', JSON.stringify(history.slice(-20)));
  loadInjectionHistory();
}

/**
 * Show diff preview modal
 */
function showDiffPreview() {
  const modal = document.getElementById('diff-modal');
  const diffViewer = document.getElementById('diff-viewer');

  if (modal && diffViewer) {
    modal.classList.add('active');
    diffViewer.innerHTML = '<pre>Diff preview would appear here...</pre>';
  }
}

/**
 * Close diff modal
 */
(window as any).closeDiffModal = function () {
  const modal = document.getElementById('diff-modal');
  modal?.classList.remove('active');
};

/**
 * Confirm injection from modal
 */
(window as any).confirmInjection = function () {
  (window as any).closeDiffModal();
  handleInject();
};

/**
 * Show toast notification
 */
function showToast(type: 'success' | 'error' | 'warning' | 'info', message: string) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  toast.style.cssText = `
    padding: 1rem;
    background: var(--color-bg-elevated);
    border: 1px solid var(--color-border);
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-lg);
  `;

  container.appendChild(toast);

  setTimeout(() => toast.remove(), 5000);
}

/**
 * Utility: Delay
 */
function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initInjector);
} else {
  initInjector();
}
