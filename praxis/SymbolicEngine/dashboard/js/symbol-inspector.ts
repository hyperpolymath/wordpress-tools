/**
 * Symbol Inspector
 * Detailed symbol inspection and testing interface
 */

export class SymbolInspector {
  private containerId: string;
  private symbol: any = null;

  constructor(containerId: string) {
    this.containerId = containerId;
  }

  /**
   * Load and display symbol details
   */
  async loadSymbol(symbolId: string) {
    try {
      const response = await fetch(`/api/symbols/${symbolId}`);
      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error?.message || 'Failed to load symbol');
      }

      this.symbol = data.data;
      this.render();
    } catch (error) {
      console.error('[SymbolInspector] Error loading symbol:', error);
      this.renderError(String(error));
    }
  }

  /**
   * Render symbol details
   */
  private render() {
    const container = document.getElementById(this.containerId);
    if (!container) return;

    container.innerHTML = `
      <div class="symbol-inspector">
        <div class="inspector-header">
          <h3>${this.escapeHtml(this.symbol.name)}</h3>
          <span class="symbol-type">${this.symbol.type}</span>
        </div>

        <div class="inspector-section">
          <h4>Details</h4>
          <dl class="detail-list">
            <dt>ID:</dt>
            <dd><code>${this.symbol.id}</code></dd>

            <dt>Type:</dt>
            <dd>${this.symbol.type}</dd>

            <dt>Context:</dt>
            <dd>${this.symbol.context}</dd>

            <dt>Dispatch:</dt>
            <dd>${this.symbol.dispatch}</dd>

            <dt>Created:</dt>
            <dd>${new Date(this.symbol.created_at).toLocaleString()}</dd>

            <dt>Updated:</dt>
            <dd>${new Date(this.symbol.updated_at).toLocaleString()}</dd>
          </dl>
        </div>

        ${this.symbol.metadata?.description ? `
          <div class="inspector-section">
            <h4>Description</h4>
            <p>${this.escapeHtml(this.symbol.metadata.description)}</p>
          </div>
        ` : ''}

        <div class="inspector-section">
          <h4>Parameters</h4>
          <pre class="json-display">${JSON.stringify(this.symbol.parameters, null, 2)}</pre>
        </div>

        ${this.symbol.metadata?.tags?.length ? `
          <div class="inspector-section">
            <h4>Tags</h4>
            <div class="tag-list">
              ${this.symbol.metadata.tags.map((tag: string) => `
                <span class="tag">${this.escapeHtml(tag)}</span>
              `).join('')}
            </div>
          </div>
        ` : ''}

        <div class="inspector-actions">
          <button class="btn btn-primary" onclick="testSymbol('${this.symbol.id}')">
            Test Execution
          </button>
          <button class="btn btn-secondary" onclick="editSymbol('${this.symbol.id}')">
            Edit
          </button>
        </div>
      </div>
    `;
  }

  /**
   * Render error message
   */
  private renderError(message: string) {
    const container = document.getElementById(this.containerId);
    if (!container) return;

    container.innerHTML = `
      <div class="error-message">
        <p>Error loading symbol: ${this.escapeHtml(message)}</p>
      </div>
    `;
  }

  /**
   * Escape HTML
   */
  private escapeHtml(text: string): string {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Global functions for button handlers
(window as any).testSymbol = (id: string) => {
  console.log('Test symbol:', id);
  // Implement test execution logic
};

(window as any).editSymbol = (id: string) => {
  console.log('Edit symbol:', id);
  // Implement symbol editing logic
};
