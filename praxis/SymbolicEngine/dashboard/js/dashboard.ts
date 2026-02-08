/**
 * WP Praxis Dashboard - Main Frontend Application
 * Handles UI interactions, data fetching, and real-time updates
 */

// API Configuration
const API_BASE = window.location.origin + '/api';
const WS_URL = `ws://${window.location.host}/ws`;

// State
let ws: WebSocket | null = null;
let currentView = 'overview';
let dashboardStats: any = null;
let charts: Record<string, any> = {};

/**
 * Initialize the dashboard
 */
async function initDashboard() {
  console.log('[Dashboard] Initializing...');

  // Setup theme
  setupTheme();

  // Setup navigation
  setupNavigation();

  // Setup WebSocket
  setupWebSocket();

  // Setup refresh button
  setupRefreshButton();

  // Load initial data
  await loadDashboard Data();

  // Setup auto-refresh
  setupAutoRefresh();

  // Initialize charts
  initializeCharts();

  console.log('[Dashboard] Ready');
}

/**
 * Setup theme toggle
 */
function setupTheme() {
  const themeToggle = document.getElementById('theme-toggle');
  const html = document.documentElement;

  // Load saved theme or use system preference
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
 * Setup navigation
 */
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item[data-view]');

  navItems.forEach((item) => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const view = (item as HTMLElement).dataset.view;
      if (view) {
        switchView(view);
      }
    });
  });
}

/**
 * Switch to a different view
 */
function switchView(view: string) {
  currentView = view;

  // Update navigation
  document.querySelectorAll('.nav-item').forEach((item) => {
    item.classList.remove('active');
  });
  document.querySelector(`[data-view="${view}"]`)?.classList.add('active');

  // Update views
  document.querySelectorAll('.view').forEach((v) => {
    v.classList.remove('active');
  });
  document.getElementById(`view-${view}`)?.classList.add('active');

  // Load view data
  loadViewData(view);
}

/**
 * Setup WebSocket connection
 */
function setupWebSocket() {
  const statusDot = document.querySelector('.status-dot');
  const statusText = document.querySelector('.status-text');

  function connect() {
    console.log('[WebSocket] Connecting...');
    updateConnectionStatus('connecting', 'Connecting...');

    ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      console.log('[WebSocket] Connected');
      updateConnectionStatus('connected', 'Connected');
    };

    ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        handleWebSocketMessage(message);
      } catch (error) {
        console.error('[WebSocket] Error parsing message:', error);
      }
    };

    ws.onerror = (error) => {
      console.error('[WebSocket] Error:', error);
      updateConnectionStatus('disconnected', 'Error');
    };

    ws.onclose = () => {
      console.log('[WebSocket] Disconnected');
      updateConnectionStatus('disconnected', 'Disconnected');

      // Reconnect after 5 seconds
      setTimeout(connect, 5000);
    };
  }

  function updateConnectionStatus(status: string, text: string) {
    statusDot?.setAttribute('data-status', status);
    if (statusText) statusText.textContent = text;
  }

  connect();
}

/**
 * Handle WebSocket messages
 */
function handleWebSocketMessage(message: any) {
  console.log('[WebSocket] Message:', message.type);

  switch (message.type) {
    case 'stats_update':
      updateDashboardStats(message.payload.stats);
      break;
    case 'execution_started':
      showToast('info', `Execution started: ${message.payload.execution_id}`);
      loadViewData('executions');
      break;
    case 'execution_completed':
      showToast('success', `Execution completed successfully`);
      loadViewData('executions');
      updateDashboardStats();
      break;
    case 'execution_failed':
      showToast('error', `Execution failed`);
      loadViewData('executions');
      break;
    case 'deviation_detected':
      showToast('warning', 'Deviation detected in audit');
      break;
    case 'log_entry':
      console.log(`[Log] ${message.payload.level}: ${message.payload.message}`);
      break;
  }
}

/**
 * Setup refresh button
 */
function setupRefreshButton() {
  const refreshBtn = document.getElementById('refresh-btn');
  refreshBtn?.addEventListener('click', async () => {
    await loadDashboardData();
    showToast('success', 'Dashboard refreshed');
  });
}

/**
 * Setup auto-refresh
 */
function setupAutoRefresh() {
  setInterval(async () => {
    if (currentView === 'overview') {
      await updateDashboardStats();
    }
  }, 5000); // 5 seconds
}

/**
 * Load dashboard data
 */
async function loadDashboardData() {
  await Promise.all([updateDashboardStats(), loadViewData(currentView)]);
}

/**
 * Update dashboard statistics
 */
async function updateDashboardStats(stats?: any) {
  try {
    if (!stats) {
      const response = await fetch(`${API_BASE}/stats`);
      const data = await response.json();
      stats = data.data;
    }

    dashboardStats = stats;

    // Update stat cards
    updateElement('stat-workflows-total', stats.workflows.total);
    updateElement('stat-workflows-active', stats.workflows.active);
    updateElement('stat-workflows-paused', stats.workflows.paused);

    updateElement('stat-executions-total', stats.executions.total);
    updateElement('stat-executions-running', stats.executions.running);
    updateElement('stat-executions-success', `${stats.executions.success_rate}%`);

    updateElement('stat-audits-total', stats.audits.total_audits);
    updateElement('stat-audits-deviations', stats.audits.total_deviations);
    updateElement('stat-audits-compliance', `${stats.audits.avg_compliance_score}%`);

    const uptime = formatUptime(stats.system.uptime_seconds);
    updateElement('stat-system-uptime', uptime);
    updateElement('stat-system-memory', `${stats.system.memory_usage_mb} MB`);
    updateElement('stat-system-connections', stats.system.active_connections);

    // Update charts
    updateCharts(stats);
  } catch (error) {
    console.error('[Dashboard] Error updating stats:', error);
  }
}

/**
 * Load view-specific data
 */
async function loadViewData(view: string) {
  switch (view) {
    case 'overview':
      // Overview data is loaded via stats
      break;
    case 'workflows':
      await loadWorkflows();
      break;
    case 'executions':
      await loadExecutions();
      break;
    case 'symbols':
      await loadSymbols();
      break;
    case 'audits':
      await loadAudits();
      break;
    case 'baselines':
      await loadBaselines();
      break;
  }
}

/**
 * Load workflows
 */
async function loadWorkflows() {
  try {
    const response = await fetch(`${API_BASE}/workflows`);
    const data = await response.json();

    const tbody = document.getElementById('workflows-tbody');
    if (!tbody) return;

    if (!data.success || data.data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="loading">No workflows found</td></tr>';
      return;
    }

    tbody.innerHTML = data.data
      .map(
        (workflow: any) => `
        <tr>
          <td><strong>${escapeHtml(workflow.name)}</strong></td>
          <td><span class="status-badge ${workflow.status}">${workflow.status}</span></td>
          <td>${workflow.last_execution ? formatDate(workflow.last_execution) : 'Never'}</td>
          <td>${workflow.symbols?.length || 0}</td>
          <td>
            <button class="btn btn-secondary" onclick="viewWorkflow('${workflow.id}')">View</button>
          </td>
        </tr>
      `
      )
      .join('');
  } catch (error) {
    console.error('[Dashboard] Error loading workflows:', error);
  }
}

/**
 * Load executions
 */
async function loadExecutions() {
  try {
    const response = await fetch(`${API_BASE}/executions`);
    const data = await response.json();

    const tbody = document.getElementById('executions-tbody');
    if (!tbody) return;

    if (!data.success || data.data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="loading">No executions found</td></tr>';
      return;
    }

    tbody.innerHTML = data.data
      .map(
        (execution: any) => `
        <tr>
          <td><code>${execution.id.slice(0, 8)}</code></td>
          <td>${escapeHtml(execution.workflow_id)}</td>
          <td><span class="status-badge ${execution.status}">${execution.status}</span></td>
          <td>${formatDate(execution.started_at)}</td>
          <td>${execution.duration_ms ? `${execution.duration_ms}ms` : '-'}</td>
          <td>
            <button class="btn btn-secondary" onclick="viewExecution('${execution.id}')">View</button>
          </td>
        </tr>
      `
      )
      .join('');
  } catch (error) {
    console.error('[Dashboard] Error loading executions:', error);
  }
}

/**
 * Load symbols
 */
async function loadSymbols() {
  try {
    const response = await fetch(`${API_BASE}/symbols`);
    const data = await response.json();

    const grid = document.getElementById('symbols-grid');
    if (!grid) return;

    if (!data.success || data.data.length === 0) {
      grid.innerHTML = '<div class="loading-placeholder">No symbols found</div>';
      return;
    }

    grid.innerHTML = data.data
      .map(
        (symbol: any) => `
        <div class="stat-card">
          <div class="stat-header">
            <h3>${escapeHtml(symbol.name)}</h3>
            <span class="icon">🔣</span>
          </div>
          <div class="stat-details">
            <span class="stat-item">
              <span class="label">Type:</span>
              <span>${symbol.type}</span>
            </span>
            <span class="stat-item">
              <span class="label">Context:</span>
              <span>${symbol.context}</span>
            </span>
          </div>
        </div>
      `
      )
      .join('');
  } catch (error) {
    console.error('[Dashboard] Error loading symbols:', error);
  }
}

/**
 * Load audits
 */
async function loadAudits() {
  try {
    const response = await fetch(`${API_BASE}/audits`);
    const data = await response.json();

    const tbody = document.getElementById('audits-tbody');
    if (!tbody) return;

    if (!data.success || data.data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="loading">No audits found</td></tr>';
      return;
    }

    tbody.innerHTML = data.data
      .map(
        (audit: any) => `
        <tr>
          <td><code>${audit.id.slice(0, 8)}</code></td>
          <td>${escapeHtml(audit.workflow_id)}</td>
          <td>${audit.summary?.total_deviations || 0}</td>
          <td>${audit.summary?.compliance_score || 0}%</td>
          <td>${formatDate(audit.started_at)}</td>
          <td>
            <button class="btn btn-secondary" onclick="viewAudit('${audit.id}')">View</button>
          </td>
        </tr>
      `
      )
      .join('');
  } catch (error) {
    console.error('[Dashboard] Error loading audits:', error);
  }
}

/**
 * Load baselines
 */
async function loadBaselines() {
  try {
    const response = await fetch(`${API_BASE}/baselines`);
    const data = await response.json();

    const tbody = document.getElementById('baselines-tbody');
    if (!tbody) return;

    if (!data.success || data.data.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="loading">No baselines found</td></tr>';
      return;
    }

    tbody.innerHTML = data.data
      .map(
        (baseline: any) => `
        <tr>
          <td><strong>${escapeHtml(baseline.name)}</strong></td>
          <td>${escapeHtml(baseline.workflow_id)}</td>
          <td>${baseline.is_normative ? '✓' : '-'}</td>
          <td>${formatDate(baseline.created_at)}</td>
          <td>
            <button class="btn btn-secondary" onclick="viewBaseline('${baseline.id}')">View</button>
          </td>
        </tr>
      `
      )
      .join('');
  } catch (error) {
    console.error('[Dashboard] Error loading baselines:', error);
  }
}

/**
 * Initialize charts
 */
function initializeCharts() {
  // Execution timeline chart
  const timelineCtx = document.getElementById('execution-timeline-chart') as HTMLCanvasElement;
  if (timelineCtx) {
    charts.timeline = new (window as any).Chart(timelineCtx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [
          {
            label: 'Completed',
            data: [],
            borderColor: '#10b981',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
          },
          {
            label: 'Failed',
            data: [],
            borderColor: '#ef4444',
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
      },
    });
  }

  // Workflow status chart
  const statusCtx = document.getElementById('workflow-status-chart') as HTMLCanvasElement;
  if (statusCtx) {
    charts.status = new (window as any).Chart(statusCtx, {
      type: 'doughnut',
      data: {
        labels: ['Active', 'Paused', 'Error'],
        datasets: [
          {
            data: [0, 0, 0],
            backgroundColor: ['#10b981', '#f59e0b', '#ef4444'],
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
      },
    });
  }
}

/**
 * Update charts with new data
 */
function updateCharts(stats: any) {
  // Update workflow status chart
  if (charts.status) {
    charts.status.data.datasets[0].data = [
      stats.workflows.active,
      stats.workflows.paused,
      stats.workflows.error,
    ];
    charts.status.update();
  }
}

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
    animation: slideIn 0.3s ease;
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.remove();
  }, 5000);
}

/**
 * Utility: Update element text content
 */
function updateElement(id: string, value: any) {
  const el = document.getElementById(id);
  if (el) el.textContent = String(value);
}

/**
 * Utility: Format date
 */
function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleString();
}

/**
 * Utility: Format uptime
 */
function formatUptime(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  return `${hours}h ${minutes}m`;
}

/**
 * Utility: Escape HTML
 */
function escapeHtml(text: string): string {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Global functions for button handlers
(window as any).viewWorkflow = (id: string) => console.log('View workflow:', id);
(window as any).viewExecution = (id: string) => console.log('View execution:', id);
(window as any).viewAudit = (id: string) => console.log('View audit:', id);
(window as any).viewBaseline = (id: string) => console.log('View baseline:', id);

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDashboard);
} else {
  initDashboard();
}
