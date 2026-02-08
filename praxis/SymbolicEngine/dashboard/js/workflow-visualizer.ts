/**
 * Workflow Visualizer
 * Renders workflow DAGs and dependency graphs
 */

export class WorkflowVisualizer {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private workflow: any;
  private nodes: Map<string, Node> = new Map();
  private edges: Edge[] = [];

  constructor(canvasId: string) {
    this.canvas = document.getElementById(canvasId) as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error(`Canvas element ${canvasId} not found`);
    }

    const ctx = this.canvas.getContext('2d');
    if (!ctx) {
      throw new Error('Failed to get canvas 2D context');
    }
    this.ctx = ctx;

    this.setupCanvas();
  }

  /**
   * Setup canvas dimensions
   */
  private setupCanvas() {
    const rect = this.canvas.parentElement?.getBoundingClientRect();
    if (rect) {
      this.canvas.width = rect.width;
      this.canvas.height = rect.height || 600;
    }
  }

  /**
   * Load and visualize workflow
   */
  async loadWorkflow(workflowId: string) {
    try {
      const response = await fetch(`/api/workflows/${workflowId}`);
      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error?.message || 'Failed to load workflow');
      }

      this.workflow = data.data;
      this.buildGraph();
      this.render();
    } catch (error) {
      console.error('[WorkflowVisualizer] Error loading workflow:', error);
    }
  }

  /**
   * Build graph from workflow data
   */
  private buildGraph() {
    this.nodes.clear();
    this.edges = [];

    // Create nodes for each symbol
    this.workflow.symbols?.forEach((symbol: any, index: number) => {
      const node: Node = {
        id: symbol.id,
        label: symbol.name,
        x: 100 + (index % 3) * 200,
        y: 100 + Math.floor(index / 3) * 150,
        width: 150,
        height: 60,
        type: symbol.type,
      };
      this.nodes.set(symbol.id, node);
    });

    // Create edges from dependencies
    this.workflow.dependencies?.forEach((dep: any) => {
      const fromNode = this.nodes.get(dep.from_symbol);
      const toNode = this.nodes.get(dep.to_symbol);

      if (fromNode && toNode) {
        this.edges.push({
          from: fromNode,
          to: toNode,
          type: dep.type,
        });
      }
    });
  }

  /**
   * Render the graph
   */
  render() {
    // Clear canvas
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // Draw edges first (so they're behind nodes)
    this.edges.forEach((edge) => this.drawEdge(edge));

    // Draw nodes
    this.nodes.forEach((node) => this.drawNode(node));
  }

  /**
   * Draw a node
   */
  private drawNode(node: Node) {
    const ctx = this.ctx;

    // Draw shadow
    ctx.shadowColor = 'rgba(0, 0, 0, 0.1)';
    ctx.shadowBlur = 10;
    ctx.shadowOffsetX = 0;
    ctx.shadowOffsetY = 2;

    // Draw rectangle
    ctx.fillStyle = this.getNodeColor(node.type);
    ctx.strokeStyle = '#6366f1';
    ctx.lineWidth = 2;
    this.roundRect(ctx, node.x, node.y, node.width, node.height, 8);
    ctx.fill();
    ctx.stroke();

    // Reset shadow
    ctx.shadowColor = 'transparent';

    // Draw label
    ctx.fillStyle = '#ffffff';
    ctx.font = '14px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(node.label, node.x + node.width / 2, node.y + node.height / 2);
  }

  /**
   * Draw an edge
   */
  private drawEdge(edge: Edge) {
    const ctx = this.ctx;

    const fromX = edge.from.x + edge.from.width;
    const fromY = edge.from.y + edge.from.height / 2;
    const toX = edge.to.x;
    const toY = edge.to.y + edge.to.height / 2;

    ctx.strokeStyle = edge.type === 'required' ? '#6366f1' : '#cbd5e1';
    ctx.lineWidth = edge.type === 'required' ? 2 : 1;
    ctx.setLineDash(edge.type === 'optional' ? [5, 5] : []);

    // Draw line
    ctx.beginPath();
    ctx.moveTo(fromX, fromY);
    ctx.lineTo(toX, toY);
    ctx.stroke();

    // Draw arrow head
    this.drawArrowHead(ctx, fromX, fromY, toX, toY);

    ctx.setLineDash([]);
  }

  /**
   * Draw arrow head
   */
  private drawArrowHead(
    ctx: CanvasRenderingContext2D,
    x1: number,
    y1: number,
    x2: number,
    y2: number
  ) {
    const headLength = 10;
    const angle = Math.atan2(y2 - y1, x2 - x1);

    ctx.beginPath();
    ctx.moveTo(x2, y2);
    ctx.lineTo(
      x2 - headLength * Math.cos(angle - Math.PI / 6),
      y2 - headLength * Math.sin(angle - Math.PI / 6)
    );
    ctx.moveTo(x2, y2);
    ctx.lineTo(
      x2 - headLength * Math.cos(angle + Math.PI / 6),
      y2 - headLength * Math.sin(angle + Math.PI / 6)
    );
    ctx.stroke();
  }

  /**
   * Draw rounded rectangle
   */
  private roundRect(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    radius: number
  ) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
  }

  /**
   * Get color for node type
   */
  private getNodeColor(type: string): string {
    const colors: Record<string, string> = {
      action: '#6366f1',
      query: '#3b82f6',
      transformation: '#8b5cf6',
      validation: '#10b981',
      audit: '#f59e0b',
    };
    return colors[type] || '#6b7280';
  }
}

interface Node {
  id: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
  type: string;
}

interface Edge {
  from: Node;
  to: Node;
  type: string;
}
