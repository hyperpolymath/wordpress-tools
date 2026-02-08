/**
 * Semantic Graph Viewer for Sinople Theme
 *
 * Visualizes semantic relationships between constructs using WASM processor
 *
 * @package Sinople
 * @since 1.0.0
 */

(function() {
  'use strict';

  /**
   * Initialize graph viewer when DOM is ready
   */
  document.addEventListener('DOMContentLoaded', async function() {
    const graphContainer = document.querySelector('.semantic-graph');
    if (!graphContainer) return;

    try {
      await initSemanticGraph(graphContainer);
    } catch (error) {
      console.error('Failed to initialize semantic graph:', error);
      showError(graphContainer, 'Failed to load semantic graph');
    }
  });

  /**
   * Initialize Semantic Graph
   */
  async function initSemanticGraph(container) {
    // Show loading state
    container.innerHTML = '<div class="graph-loading">Loading semantic graph...</div>';

    // Fetch semantic graph data from WordPress REST API
    const response = await fetch(sinople.rest_url + 'sinople/v1/semantic-graph', {
      headers: {
        'X-WP-Nonce': sinople.nonce
      }
    });

    if (!response.ok) {
      throw new Error('Failed to fetch semantic graph data');
    }

    const data = await response.json();

    // Render graph visualization
    renderGraph(container, data);

    // Announce to screen readers
    if (window.sinople && window.sinople.announceToScreenReader) {
      window.sinople.announceToScreenReader(
        `Semantic graph loaded with ${data.nodes.length} constructs and ${data.edges.length} relationships`
      );
    }
  }

  /**
   * Render Graph Visualization
   *
   * This is a placeholder implementation. In production, you would use:
   * - D3.js for custom force-directed graphs
   * - Cytoscape.js for complex network analysis
   * - vis.js for simpler network visualizations
   */
  function renderGraph(container, data) {
    // Create SVG element
    const svg = document.createElementNS('https://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '100%');
    svg.setAttribute('height', '600');
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', `Semantic graph with ${data.nodes.length} constructs`);

    // Simple circular layout
    const width = container.clientWidth;
    const height = 600;
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 3;

    // Draw edges
    const edgesGroup = document.createElementNS('https://www.w3.org/2000/svg', 'g');
    edgesGroup.setAttribute('class', 'edges');

    data.edges.forEach(edge => {
      const sourceNode = data.nodes.find(n => n.id === edge.source);
      const targetNode = data.nodes.find(n => n.id === edge.target);

      if (!sourceNode || !targetNode) return;

      const sourceIndex = data.nodes.indexOf(sourceNode);
      const targetIndex = data.nodes.indexOf(targetNode);

      const sourceAngle = (sourceIndex / data.nodes.length) * 2 * Math.PI;
      const targetAngle = (targetIndex / data.nodes.length) * 2 * Math.PI;

      const line = document.createElementNS('https://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1', centerX + radius * Math.cos(sourceAngle));
      line.setAttribute('y1', centerY + radius * Math.sin(sourceAngle));
      line.setAttribute('x2', centerX + radius * Math.cos(targetAngle));
      line.setAttribute('y2', centerY + radius * Math.sin(targetAngle));
      line.setAttribute('stroke', '#006400');
      line.setAttribute('stroke-width', '2');
      line.setAttribute('opacity', '0.6');

      // Add title for accessibility
      const title = document.createElementNS('https://www.w3.org/2000/svg', 'title');
      title.textContent = edge.label || 'related';
      line.appendChild(title);

      edgesGroup.appendChild(line);
    });

    svg.appendChild(edgesGroup);

    // Draw nodes
    const nodesGroup = document.createElementNS('https://www.w3.org/2000/svg', 'g');
    nodesGroup.setAttribute('class', 'nodes');

    data.nodes.forEach((node, index) => {
      const angle = (index / data.nodes.length) * 2 * Math.PI;
      const x = centerX + radius * Math.cos(angle);
      const y = centerY + radius * Math.sin(angle);

      // Create node circle
      const circle = document.createElementNS('https://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', x);
      circle.setAttribute('cy', y);
      circle.setAttribute('r', '20');
      circle.setAttribute('fill', '#006400');
      circle.setAttribute('stroke', '#000');
      circle.setAttribute('stroke-width', '2');
      circle.setAttribute('tabindex', '0');
      circle.setAttribute('role', 'button');
      circle.setAttribute('aria-label', node.label);

      // Add interactivity
      circle.addEventListener('click', () => handleNodeClick(node));
      circle.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          handleNodeClick(node);
        }
      });

      // Create node label
      const text = document.createElementNS('https://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', x);
      text.setAttribute('y', y + 35);
      text.setAttribute('text-anchor', 'middle');
      text.setAttribute('fill', '#000');
      text.setAttribute('font-size', '12');
      text.textContent = node.label;

      nodesGroup.appendChild(circle);
      nodesGroup.appendChild(text);
    });

    svg.appendChild(nodesGroup);

    // Add controls
    const controls = document.createElement('div');
    controls.className = 'graph-controls';
    controls.innerHTML = `
      <label for="graph-filter">Filter constructs:</label>
      <input type="search" id="graph-filter" placeholder="Search..." aria-label="Filter constructs">
      <span role="status" aria-live="polite" id="graph-status">
        Showing ${data.nodes.length} constructs
      </span>
    `;

    container.innerHTML = '';
    container.appendChild(controls);
    container.appendChild(svg);

    // Add filter functionality
    const filterInput = controls.querySelector('#graph-filter');
    filterInput.addEventListener('input', (e) => filterGraph(e.target.value, data, svg));
  }

  /**
   * Handle Node Click
   */
  function handleNodeClick(node) {
    // Navigate to construct page
    if (node.iri) {
      window.location.href = node.iri;
    } else {
      // Fallback to WordPress permalink
      window.location.href = `${sinople.home_url}/constructs/${node.id}`;
    }
  }

  /**
   * Filter Graph
   */
  function filterGraph(query, data, svg) {
    const lowerQuery = query.toLowerCase();

    svg.querySelectorAll('circle').forEach((circle, index) => {
      const node = data.nodes[index];
      const matches = node.label.toLowerCase().includes(lowerQuery);

      circle.style.opacity = matches || !query ? '1' : '0.2';
    });

    // Update status
    const matchCount = data.nodes.filter(n =>
      n.label.toLowerCase().includes(lowerQuery)
    ).length;

    const status = document.getElementById('graph-status');
    if (status) {
      status.textContent = query
        ? `Showing ${matchCount} of ${data.nodes.length} constructs`
        : `Showing ${data.nodes.length} constructs`;
    }
  }

  /**
   * Show Error Message
   */
  function showError(container, message) {
    container.innerHTML = `
      <div class="graph-error" role="alert">
        <p><strong>Error:</strong> ${message}</p>
        <p>Please try refreshing the page or contact the administrator if the problem persists.</p>
      </div>
    `;
  }

})();
