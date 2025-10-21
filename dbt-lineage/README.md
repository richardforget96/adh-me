# DBT Lineage Explorer

A beautiful, interactive visualization tool for exploring DBT (Data Build Tool) project lineage. View how your DBT models derive from source tables with an intuitive network graph interface.

![DBT Lineage Explorer](preview.png)

## Features

- **Interactive Network Graph**: D3.js-powered force-directed graph showing relationships between DBT models and source tables
- **Beautiful Dark Theme**: Modern UI with glassmorphism effects, gradients, and smooth animations
- **Real-time Search**: Filter nodes by name to quickly find specific tables or models
- **Node Details**: Click on any node to view its type, description, dependencies, and dependents
- **Zoom & Pan**: Fully interactive canvas with zoom controls and drag-to-pan
- **Color-coded Nodes**:
  - 🟢 **Green**: Source tables (raw data)
  - 🟡 **Orange**: Staging models
  - 🔵 **Blue**: DBT models and marts
- **Statistics Dashboard**: View total counts of models, sources, and dependencies
- **Connection Highlighting**: Click a node to highlight its direct connections

## Getting Started

### Prerequisites

- A modern web browser (Chrome, Firefox, Safari, Edge)
- A local web server (optional but recommended)

### Installation

1. Clone this repository or download the files
2. Open `index.html` in your web browser

#### Using a Local Server (Recommended)

```bash
# Using Python 3
cd dbt-lineage
python3 -m http.server 8000

# Using Node.js
npx serve

# Using PHP
php -S localhost:8000
```

Then navigate to `http://localhost:8000` in your browser.

## Usage

### Viewing the Graph

- The graph automatically loads with sample DBT lineage data
- Nodes represent tables (sources, staging, and models)
- Arrows show data flow from sources through transformations

### Interacting with Nodes

- **Click** a node to view details in the sidebar
- **Drag** nodes to rearrange the graph
- **Hover** over nodes for highlighting

### Navigation

- **Search**: Type in the search box to filter nodes by name
- **Zoom In/Out**: Use the + and - buttons or scroll wheel
- **Pan**: Click and drag the background
- **Reset**: Click "Reset View" to return to the initial state

### Customizing Data

Edit the `lineageData` object in `app.js` to add your own DBT models:

```javascript
const lineageData = {
    nodes: [
        {
            id: 'my_table',
            name: 'my_table',
            type: 'source', // 'source', 'staging', or 'model'
            description: 'Description of the table'
        },
        // Add more nodes...
    ],
    links: [
        { source: 'source_table', target: 'target_table' },
        // Add more links...
    ]
};
```

## Technology Stack

- **D3.js v7**: Force-directed graph visualization
- **Vanilla JavaScript**: No framework dependencies
- **CSS3**: Modern styling with animations and glassmorphism
- **HTML5**: Semantic structure

## File Structure

```
dbt-lineage/
├── index.html      # Main HTML structure
├── styles.css      # All styling and themes
├── app.js          # Graph logic and data
└── README.md       # This file
```

## Features in Detail

### Force-Directed Layout

The graph uses a physics simulation to automatically position nodes:
- Nodes repel each other to avoid overlap
- Connected nodes are pulled together
- The layout stabilizes into an optimal configuration

### Color Scheme

The app uses a carefully selected color palette:
- Background: Deep blue gradient (#0f0f1e → #1a1a2e → #16213e)
- Source nodes: Emerald green (#10b981)
- Staging nodes: Amber (#f59e0b)
- Model nodes: Indigo (#6366f1)

### Responsive Design

The interface adapts to different screen sizes:
- Desktop: Full sidebar with statistics
- Tablet: Reduced sidebar width
- Mobile: Collapsible sidebar

## Future Enhancements

- [ ] Import DBT manifest.json files
- [ ] Export lineage diagrams as PNG/SVG
- [ ] Advanced filtering (by type, depth, etc.)
- [ ] Column-level lineage
- [ ] SQL query preview
- [ ] Integration with dbt Cloud API
- [ ] Dark/light theme toggle
- [ ] Save/load custom layouts

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## License

MIT License - feel free to use this project for personal or commercial purposes.

## Acknowledgments

- Inspired by modern data lineage tools
- Built with D3.js force graph examples
- Design influenced by contemporary data visualization best practices
