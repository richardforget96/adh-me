// Sample DBT lineage data
const lineageData = {
    nodes: [
        // Source tables
        { id: 'orders', name: 'orders', type: 'source', description: 'Raw orders from e-commerce platform' },
        { id: 'customers', name: 'customers', type: 'source', description: 'Customer master data' },
        { id: 'products', name: 'products', type: 'source', description: 'Product catalog' },
        { id: 'vehicles', name: 'vehicles', type: 'source', description: 'Vehicle inventory data' },
        { id: 'receipts', name: 'receipts', type: 'source', description: 'Payment receipts' },
        { id: 'shipments', name: 'shipments', type: 'source', description: 'Shipping and delivery data' },

        // Staging models
        { id: 'stg_orders', name: 'stg_orders', type: 'staging', description: 'Cleaned and standardized orders' },
        { id: 'stg_customers', name: 'stg_customers', type: 'staging', description: 'Cleaned customer data' },
        { id: 'stg_products', name: 'stg_products', type: 'staging', description: 'Cleaned product data' },
        { id: 'stg_receipts', name: 'stg_receipts', type: 'staging', description: 'Cleaned receipt data' },

        // Intermediate models
        { id: 'int_order_items', name: 'int_order_items', type: 'model', description: 'Order line items with product details' },
        { id: 'int_customer_orders', name: 'int_customer_orders', type: 'model', description: 'Aggregated customer order history' },

        // Mart models (final)
        { id: 'fct_orders', name: 'fct_orders', type: 'model', description: 'Orders fact table with all dimensions' },
        { id: 'fct_revenue', name: 'fct_revenue', type: 'model', description: 'Revenue metrics by various dimensions' },
        { id: 'dim_customers', name: 'dim_customers', type: 'model', description: 'Customer dimension table' },
        { id: 'metrics_dashboard', name: 'metrics_dashboard', type: 'model', description: 'Business metrics for dashboards' },
    ],
    links: [
        // Source -> Staging
        { source: 'orders', target: 'stg_orders' },
        { source: 'customers', target: 'stg_customers' },
        { source: 'products', target: 'stg_products' },
        { source: 'receipts', target: 'stg_receipts' },

        // Staging -> Intermediate
        { source: 'stg_orders', target: 'int_order_items' },
        { source: 'stg_products', target: 'int_order_items' },
        { source: 'stg_orders', target: 'int_customer_orders' },
        { source: 'stg_customers', target: 'int_customer_orders' },

        // Intermediate -> Mart
        { source: 'int_order_items', target: 'fct_orders' },
        { source: 'int_customer_orders', target: 'fct_orders' },
        { source: 'stg_receipts', target: 'fct_orders' },
        { source: 'vehicles', target: 'fct_orders' },
        { source: 'shipments', target: 'fct_orders' },

        { source: 'fct_orders', target: 'fct_revenue' },
        { source: 'stg_customers', target: 'dim_customers' },
        { source: 'int_customer_orders', target: 'dim_customers' },

        { source: 'fct_revenue', target: 'metrics_dashboard' },
        { source: 'dim_customers', target: 'metrics_dashboard' },
    ]
};

// Graph configuration
const config = {
    nodeRadius: {
        source: 25,
        staging: 30,
        model: 35
    },
    nodeColors: {
        source: '#00ff00',
        staging: '#ffff00',
        model: '#00ffff'
    },
    linkDistance: 150,
    chargeStrength: -800,
    collisionRadius: 60
};

class DBTLineageGraph {
    constructor(containerId) {
        this.containerId = containerId;
        this.svg = d3.select(`#${containerId}`);
        this.width = this.svg.node().getBoundingClientRect().width;
        this.height = this.svg.node().getBoundingClientRect().height;

        this.data = JSON.parse(JSON.stringify(lineageData)); // Deep copy
        this.selectedNode = null;

        this.initGraph();
        this.updateStats();
        this.setupEventListeners();
    }

    initGraph() {
        // Clear existing content
        this.svg.selectAll('*').remove();

        // Create container group for zoom
        this.container = this.svg.append('g');

        // Setup zoom behavior
        this.zoom = d3.zoom()
            .scaleExtent([0.1, 4])
            .on('zoom', (event) => {
                this.container.attr('transform', event.transform);
            });

        this.svg.call(this.zoom);

        // Add arrow markers for links
        this.svg.append('defs').append('marker')
            .attr('id', 'arrowhead')
            .attr('viewBox', '-10 -10 20 20')
            .attr('refX', 20)
            .attr('refY', 0)
            .attr('markerWidth', 8)
            .attr('markerHeight', 8)
            .attr('orient', 'auto')
            .append('path')
            .attr('d', 'M-6,-6 L 0,0 L -6,6')
            .attr('class', 'link-arrow');

        // Create force simulation
        this.simulation = d3.forceSimulation(this.data.nodes)
            .force('link', d3.forceLink(this.data.links)
                .id(d => d.id)
                .distance(config.linkDistance))
            .force('charge', d3.forceManyBody().strength(config.chargeStrength))
            .force('center', d3.forceCenter(this.width / 2, this.height / 2))
            .force('collision', d3.forceCollide().radius(config.collisionRadius))
            .on('tick', () => this.ticked());

        // Create links
        this.link = this.container.append('g')
            .selectAll('path')
            .data(this.data.links)
            .enter().append('path')
            .attr('class', 'link')
            .attr('marker-end', 'url(#arrowhead)');

        // Create node groups
        this.node = this.container.append('g')
            .selectAll('g')
            .data(this.data.nodes)
            .enter().append('g')
            .attr('class', 'node')
            .call(d3.drag()
                .on('start', (event, d) => this.dragStarted(event, d))
                .on('drag', (event, d) => this.dragged(event, d))
                .on('end', (event, d) => this.dragEnded(event, d)))
            .on('click', (event, d) => this.nodeClicked(event, d))
            .on('mouseenter', (event, d) => this.nodeHovered(event, d))
            .on('mouseleave', () => this.nodeUnhovered());

        // Add circles to nodes
        this.node.append('circle')
            .attr('r', d => config.nodeRadius[d.type])
            .attr('fill', d => config.nodeColors[d.type])
            .attr('stroke', '#fff')
            .attr('stroke-width', 2)
            .style('filter', 'drop-shadow(0 0 8px currentColor)');

        // Add labels to nodes
        this.node.append('text')
            .attr('class', 'node-label')
            .attr('dy', d => config.nodeRadius[d.type] + 20)
            .text(d => d.name);

        // Add type indicators (small text on nodes)
        this.node.append('text')
            .attr('class', 'node-type')
            .attr('dy', 5)
            .attr('text-anchor', 'middle')
            .attr('font-size', '10px')
            .attr('fill', '#fff')
            .attr('font-weight', 'bold')
            .text(d => d.type[0].toUpperCase());
    }

    ticked() {
        this.link.attr('d', d => {
            const dx = d.target.x - d.source.x;
            const dy = d.target.y - d.source.y;
            const dr = Math.sqrt(dx * dx + dy * dy);

            // Calculate the point on the edge of target circle
            const targetRadius = config.nodeRadius[d.target.type];
            const offsetX = (dx * targetRadius) / dr;
            const offsetY = (dy * targetRadius) / dr;

            return `M${d.source.x},${d.source.y} L${d.target.x - offsetX},${d.target.y - offsetY}`;
        });

        this.node.attr('transform', d => `translate(${d.x},${d.y})`);
    }

    dragStarted(event, d) {
        if (!event.active) this.simulation.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
        this.svg.classed('dragging', true);
    }

    dragged(event, d) {
        d.fx = event.x;
        d.fy = event.y;
    }

    dragEnded(event, d) {
        if (!event.active) this.simulation.alphaTarget(0);
        d.fx = null;
        d.fy = null;
        this.svg.classed('dragging', false);
    }

    nodeClicked(event, d) {
        event.stopPropagation();
        this.selectedNode = d;
        this.updateNodeInfo(d);
        this.highlightConnections(d);
    }

    nodeHovered(event, d) {
        d3.select(event.currentTarget).classed('highlighted', true);
    }

    nodeUnhovered() {
        this.node.classed('highlighted', false);
    }

    highlightConnections(node) {
        // Reset all highlights
        this.node.classed('highlighted', false);
        this.link.classed('highlighted', false);

        // Highlight selected node
        this.node.filter(d => d.id === node.id).classed('highlighted', true);

        // Highlight connected nodes and links
        this.link.each(function(l) {
            if (l.source.id === node.id || l.target.id === node.id) {
                d3.select(this).classed('highlighted', true);
            }
        });

        this.node.each(function(n) {
            const isConnected = lineageData.links.some(l =>
                (l.source === node.id && l.target === n.id) ||
                (l.target === node.id && l.source === n.id)
            );
            if (isConnected) {
                d3.select(this).classed('highlighted', true);
            }
        });
    }

    updateNodeInfo(node) {
        const dependencies = this.data.links
            .filter(l => l.target.id === node.id)
            .map(l => l.source.name || l.source);

        const dependents = this.data.links
            .filter(l => l.source.id === node.id)
            .map(l => l.target.name || l.target);

        let html = `
            <div class="info-title">${node.name}</div>
            <div class="info-row">
                <span class="info-label">Type:</span> ${node.type}
            </div>
            <div class="info-row">
                <span class="info-label">Description:</span><br/>
                ${node.description}
            </div>
        `;

        if (dependencies.length > 0) {
            html += `
                <div class="info-dependencies">
                    <strong>Dependencies (${dependencies.length}):</strong>
                    <ul class="dependency-list">
                        ${dependencies.map(d => `<li>${d}</li>`).join('')}
                    </ul>
                </div>
            `;
        }

        if (dependents.length > 0) {
            html += `
                <div class="info-dependencies">
                    <strong>Dependents (${dependents.length}):</strong>
                    <ul class="dependency-list">
                        ${dependents.map(d => `<li>${d}</li>`).join('')}
                    </ul>
                </div>
            `;
        }

        document.getElementById('nodeInfo').innerHTML = html;
    }

    updateStats() {
        const modelCount = this.data.nodes.filter(n => n.type === 'model').length;
        const sourceCount = this.data.nodes.filter(n => n.type === 'source').length;
        const stagingCount = this.data.nodes.filter(n => n.type === 'staging').length;

        document.getElementById('totalModels').textContent = modelCount + stagingCount;
        document.getElementById('totalSources').textContent = sourceCount;
        document.getElementById('totalDeps').textContent = this.data.links.length;
    }

    resetView() {
        this.svg.transition().duration(750).call(
            this.zoom.transform,
            d3.zoomIdentity
        );
        this.node.classed('highlighted', false);
        this.link.classed('highlighted', false);
        this.selectedNode = null;
        document.getElementById('nodeInfo').innerHTML = '<p class="info-empty">SELECT A SIGNAL TO ANALYZE...</p>';
    }

    zoomIn() {
        this.svg.transition().duration(300).call(this.zoom.scaleBy, 1.3);
    }

    zoomOut() {
        this.svg.transition().duration(300).call(this.zoom.scaleBy, 0.7);
    }

    search(query) {
        if (!query) {
            this.node.style('opacity', 1);
            this.link.style('opacity', 1);
            return;
        }

        const lowerQuery = query.toLowerCase();

        this.node.style('opacity', d =>
            d.name.toLowerCase().includes(lowerQuery) ? 1 : 0.2
        );

        this.link.style('opacity', l => {
            const sourceName = (l.source.name || l.source).toLowerCase();
            const targetName = (l.target.name || l.target).toLowerCase();
            return (sourceName.includes(lowerQuery) || targetName.includes(lowerQuery)) ? 1 : 0.1;
        });
    }

    setupEventListeners() {
        // Reset button
        document.getElementById('resetBtn').addEventListener('click', () => {
            this.resetView();
        });

        // Zoom controls
        document.getElementById('zoomIn').addEventListener('click', () => {
            this.zoomIn();
        });

        document.getElementById('zoomOut').addEventListener('click', () => {
            this.zoomOut();
        });

        // Search
        document.getElementById('searchBox').addEventListener('input', (e) => {
            this.search(e.target.value);
        });

        // Click outside to deselect
        this.svg.on('click', () => {
            this.resetView();
        });

        // Handle window resize
        window.addEventListener('resize', () => {
            this.width = this.svg.node().getBoundingClientRect().width;
            this.height = this.svg.node().getBoundingClientRect().height;
            this.simulation.force('center', d3.forceCenter(this.width / 2, this.height / 2));
            this.simulation.alpha(0.3).restart();
        });
    }
}

// Initialize the graph when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const graph = new DBTLineageGraph('graph');
});
