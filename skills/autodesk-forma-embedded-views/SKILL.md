---
name: autodesk-forma-embedded-views
description: A guide for creating Autodesk Forma Site Design extensions using embedded views
---
# Creating Autodesk Forma Site Design Extensions using Embedded Views

## Overview

Autodesk Forma extensions with embedded views allow developers to create custom user interfaces that integrate directly into the Forma web application. Extensions are rendered as HTML/CSS/JavaScript content within iframes and can communicate with the Forma host application via the `forma-embedded-view-sdk`.

**Key Capabilities:**
- Interact with the 3D scene (select, color, hide/show elements)
- Fetch geometry and project data
- Access analysis results (sun, noise) and area metrics
- Store data to Forma's element system
- Edit proposals and add assets to library
- Invoke custom endpoints with Forma authentication

## Extension Architecture

### Hosting Requirements
- Extensions must be provided as a URL to a **statically hosted website**
- Should support **responsive design** (default width: 260px, but may vary)
- Served via HTTPS for production environments
- Can be developed locally using localhost with CORS enabled

### Placement Options

There are **three placement types** for embedded views:

1. **Floating Panel** - Most flexible option for various purposes
   - Opens when clicking extension in left icon row
   - Can be opened programmatically via `Forma.openFloatingPanel()`
   - Default size: 400x400px (configurable)
   - Limitation: Can configure either LEFT MENU PANEL or FLOATING PANEL, not both

2. **Left Menu Panel** - For managing proposals/projects
   - Similar to native Library and Collaboration panels
   - Access by clicking extension icon in left icon row

3. **Right Menu Analysis Panel** - For analyses and calculations
   - Contains fixed analysis menu tab on top
   - Accessed via extension icon in analysis menu

## SDK Installation and Setup

### Installation via npm
```bash
npm install forma-embedded-view-sdk
```

### Direct import via esm.sh
```javascript
import { Forma } from "https://esm.sh/forma-embedded-view-sdk/auto";
```

### Recommended Import Pattern
Use the **auto-import** pattern to ensure proper iframe communication setup:

```javascript
import { Forma } from "forma-embedded-view-sdk/auto";
```

The `Forma` object is an instance of `EmbeddedViewSdk` class with access to all APIs.

## Core SDK APIs

### Project Context APIs

#### Get Project Information
```javascript
const projectId = Forma.getProjectId();
const region = Forma.getRegion(); // Returns x-ads-region header value
```

#### Proposal API
```javascript
// Get current proposal ID
const proposalId = await Forma.proposal.getId();

// Get proposal revision
const revision = await Forma.proposal.getRevision();
```

### Geometry API

#### Retrieve Elements by Category
```javascript
// Get all building paths
const buildingPaths = await Forma.geometry.getPathsByCategory({ 
  category: "building" 
});

// Get triangulated geometry
const triangles = await Forma.geometry.getTriangles({ path });
// Returns Float32Array with vertex positions (x,y,z for each vertex)
```

#### Available Categories
Common categories include: `building`, `terrain`, `road`, `path`, `vegetation`

### Render API

The Render API provides **temporary visual changes** that don't persist to the proposal. All changes are automatically cleaned up when the extension closes.

#### Color/Update Meshes
```javascript
// Update mesh with custom colors
await Forma.render.updateMesh({
  id: path,
  geometryData: {
    position: Float32Array, // vertex positions (x,y,z per vertex)
    color: Uint8Array       // RGBA values per triangle (4 bytes per triangle)
  }
});

// Add new mesh to scene
const { id } = await Forma.render.addMesh({
  geometryData: { position, color },
  transform?: { ... } // Optional transformation matrix
});

// Remove rendered mesh
await Forma.render.remove({ id });

// Clean up all render changes
await Forma.render.cleanup();
```

#### Element Visibility
```javascript
// Hide single element
await Forma.render.hideElement({ path });

// Hide multiple elements
await Forma.render.hideElementsBatch({ paths: [...] });

// Show element
await Forma.render.unhideElement({ path });

// Show all hidden elements
await Forma.render.unhideAllElements();

// Set visibility for multiple elements
await Forma.render.setElementsVisibility({
  paths: [
    { path: "path1", visible: true },
    { path: "path2", visible: false }
  ]
});
```

#### Element Colors API
```javascript
// Set element color
await Forma.render.elementColors.set({
  elements: [
    { path: "path1", color: { r: 255, g: 0, b: 0 } }
  ]
});

// Reset element colors
await Forma.render.elementColors.reset({ paths: ["path1", "path2"] });
```

#### Render GeoJSON
```javascript
await Forma.render.geojson.add({
  id: "my-geojson",
  geojson: { type: "FeatureCollection", features: [...] },
  style?: { fillColor, strokeColor, fillOpacity, strokeWidth }
});

await Forma.render.geojson.remove({ id: "my-geojson" });
```

#### Render GLB Models
```javascript
await Forma.render.glb.add({
  id: "my-model",
  url: "https://example.com/model.glb",
  transform?: { position, rotation, scale }
});

await Forma.render.glb.remove({ id: "my-model" });
```

### Selection API

```javascript
// Get currently selected elements
const selectedPaths = await Forma.selection.getSelection();
// Returns string[] of element paths

// Set selection
await Forma.selection.setSelection({ paths: ["path1", "path2"] });

// Listen to selection changes
Forma.selection.add((selectedPaths) => {
  console.log("Selection changed:", selectedPaths);
});
```

### Analysis API

#### List Available Analyses
```javascript
const analyses = await Forma.analysis.list({ 
  authcontext: projectId 
});

// Filter for successful analyses in current proposal
const currentProposalId = await Forma.proposal.getId();
const sunAnalysis = analyses
  .filter(({ proposalId, status }) => 
    proposalId === currentProposalId && status === "SUCCEEDED"
  )
  .find(({ analysisType }) => analysisType === "sun");
```

#### Analysis Interface
```typescript
interface Analysis {
  analysisId: string;
  analysisType: "sun" | "noise" | string;
  createdAt: number;
  proposalId: string;
  proposalRevision: string;
  status: "SUCCEEDED" | "FAILED";
  updatedAt: number;
}
```

#### Get Ground Grid Results
```javascript
const groundGrid = await Forma.analysis.getGroundGrid({ 
  analysis: sunAnalysis 
});

// AnalysisGroundGrid structure:
// {
//   grid: Float32Array | Uint8Array,  // Flat array of result values
//   mask?: Uint8Array,                // Boolean mask for valid samples
//   resolution: number,               // Meters between sample points
//   width: number,                    // Grid width (number of points)
//   height: number,                   // Grid height (number of points)
//   x0: number,                       // Upper-left corner X coordinate
//   y0: number                        // Upper-left corner Y coordinate
// }
```

#### Calculate Sample Point Coordinates
```javascript
for (let k = 0; k < N_POINTS; k++) {
  const x = x0 + resolution / 2 + resolution * Math.floor(k % width);
  const y = y0 - resolution / 2 - resolution * Math.floor(k / width);
}
```

### Area Metrics API

```javascript
// Get area metrics for elements
const metrics = await Forma.areaMetrics.calculate({
  paths: buildingPaths
});
```

### Camera API

```javascript
// Get current camera state
const camera = await Forma.camera.getState();

// Set camera position
await Forma.camera.setState({
  position: { x, y, z },
  target: { x, y, z }
});

// Zoom to elements
await Forma.camera.zoomTo({ 
  paths: ["path1", "path2"] 
});
```

### Elements API

Access Forma's element system for persistent data storage:

```javascript
// Get element by URN
const element = await Forma.elements.get({ urn });

// Get multiple elements
const elements = await Forma.elements.getBatch({ urns: [...] });
```

### Library API

```javascript
// Add item to library
await Forma.library.addItem({
  name: "My Item",
  thumbnail: "base64-image-data",
  data: { ... }
});
```

### Extensions API

```javascript
// Invoke custom endpoint with authentication
const response = await Forma.extensions.invokeEndpoint({
  endpointId: "my-endpoint",
  method: "POST",
  data: { ... }
});

// Open floating panel
await Forma.openFloatingPanel({
  url: "https://example.com/panel",
  preferredSize: { width: 400, height: 600 }
});
```

## Authentication and HTTP APIs

### Using Forma HTTP APIs

To call Forma or APS HTTP APIs, you need a **three-legged access token** obtained via OAuth 2.0 Authorization Code Grant flow with PKCE.

### Configure Auth
```javascript
Forma.auth.configure({
  clientId: "YOUR_APS_CLIENT_ID",
  callbackUrl: "http://localhost:8080/auth",
  scopes: ["data:read", "data:write"]
});
```

### Acquire Token with Overlay
```javascript
const tokenResponse = await Forma.auth.acquireTokenOverlay();
// Displays permission overlay if no token exists
// Opens popup for OAuth flow
// Returns: { accessToken: string, expiresIn: number, ... }
```

### Call Forma API
```javascript
const projectRes = await fetch(
  `https://developer.api.autodesk.com/forma/project/v1alpha/projects/${encodeURIComponent(Forma.getProjectId())}`,
  {
    headers: {
      authorization: `Bearer ${tokenResponse.accessToken}`,
      "x-ads-region": Forma.getRegion(),
      accept: "application/json"
    }
  }
);
const projectData = await projectRes.json();
```

### Service Account Configuration
In the extension management page, add your APS app's `clientId` as a service account under the **Integration** section.

## Extension Configuration (YAML)

Configure floating panels via YAML in the extension management **Buttons** section:

```yaml
- label: My Extension
  actions:
    click:
      type: OPEN_FLOATING_PANEL
      url: https://example.com/my-extension
      preferredSize:  # Optional
        width: 400
        height: 600
```

### Embedded View Configuration
Configure left/right panel views in the **Embedded views** section by selecting placement and specifying URL.

### Endpoints Configuration
Add custom endpoints in the **Endpoints** section to use with `invokeEndpoint()`. These endpoints receive Forma-specific authentication.

### Secret for Endpoints
Set a secret in **Secret used with endpoints** section. Forma includes this in request headers as `x-forma-extension-secret` for validation.

## Development Best Practices

### Local Development Setup
```bash
# Using Vite with Preact and TypeScript
npm init preact

# Install SDK
npm install forma-embedded-view-sdk

# Configure port in vite.config.ts
export default defineConfig({
  plugins: [preact()],
  server: {
    port: 8080,  // Match extension configuration
  }
});

# Start dev server
npm run dev
```

### Storage Considerations

**Important:** Modern browsers use **storage partitioning** for iframes. This means:
- Cookies and localStorage in the embedded view are isolated from the same domain accessed directly
- Each iframe has its own storage partition
- Users may need to re-authenticate even if logged in on your domain

### Authentication Best Practices

**DO NOT** include username/password fields directly in the extension (phishing risk).

**DO** use popup-based authentication:
```javascript
// Open authentication popup
const loginWindow = window.open(
  "https://example.com/login",
  "extension-login"
);

// In login page, send token back via postMessage
window.opener.postMessage(
  JSON.stringify({ token: data }),
  "https://example.com"  // Specify origin for security
);

// In extension, listen for token
window.addEventListener("message", (event) => {
  if (event.origin !== "https://example.com") return;
  
  const data = JSON.parse(event.data);
  localStorage.setItem("token", data.token);
});
```

### Error Handling

```javascript
import { RequestError } from "forma-embedded-view-sdk";

try {
  await Forma.geometry.getTriangles({ path });
} catch (error) {
  if (error instanceof RequestError) {
    console.error("API request failed:", error.message);
  }
}
```

## Example: Color Buildings Extension

Complete example of selecting and coloring buildings:

```javascript
import { render } from 'preact';
import { Forma } from "forma-embedded-view-sdk/auto";
import { useState, useEffect } from "preact/hooks";
import { RgbaColor, RgbaColorPicker } from "powerful-color-picker";

const DEFAULT_COLOR = { r: 0, g: 255, b: 255, a: 1.0 };

function App() {
  const [buildingPaths, setBuildingPaths] = useState([]);
  const [selectedColor, setSelectedColor] = useState(DEFAULT_COLOR);

  useEffect(() => {
    Forma.geometry
      .getPathsByCategory({ category: "building" })
      .then(setBuildingPaths);
  }, []);

  const colorBuildings = async () => {
    const selectedPaths = await Forma.selection.getSelection();
    
    for (let path of selectedPaths) {
      if (buildingPaths.includes(path)) {
        const position = await Forma.geometry.getTriangles({ path });
        const numTriangles = position.length / 3;
        const color = new Uint8Array(numTriangles * 4);
        
        for (let i = 0; i < numTriangles; i++) {
          color[i * 4 + 0] = selectedColor.r;
          color[i * 4 + 1] = selectedColor.g;
          color[i * 4 + 2] = selectedColor.b;
          color[i * 4 + 3] = Math.round(selectedColor.a * 255);
        }
        
        await Forma.render.updateMesh({ 
          id: path, 
          geometryData: { position, color } 
        });
      }
    }
  };

  const reset = () => {
    Forma.render.cleanup();
    setSelectedColor(DEFAULT_COLOR);
  };

  return (
    <>
      <div>Total buildings: {buildingPaths?.length}</div>
      <RgbaColorPicker 
        color={selectedColor} 
        onChange={setSelectedColor} 
      />
      <button onClick={colorBuildings}>Color Buildings</button>
      <button onClick={reset}>Reset</button>
    </>
  );
}

render(<App />, document.getElementById('app'));
```

## Advanced Features

### Design Tools API
Create custom design tools with user interaction in the 3D scene.

### Terrain API
```javascript
// Access terrain data
const terrainData = await Forma.terrain.get();
```

### Sun API
```javascript
// Get sun position at specific time
const sunPosition = await Forma.sun.getPosition({ 
  date: new Date() 
});

// Set sun state for visualization
await Forma.sun.setState({ 
  azimuth: 180, 
  altitude: 45 
});
```

### Generators API
Access and manipulate Forma's generative design capabilities.

### Predictive Analysis API
Run and retrieve predictive analysis results.

## Key SDK Modules Summary

- **analysis** - Access analysis results (sun, noise, etc.)
- **areaMetrics** - Calculate area and volume metrics
- **auth** - OAuth authentication for HTTP APIs
- **camera** - Control 3D camera view
- **colorbar** - Display analysis color legends
- **design-tool** - Create custom design tools
- **elements** - Access Forma's element system
- **experimental** - Experimental features (subject to change)
- **extensions** - Invoke endpoints, open panels
- **generators** - Generative design capabilities
- **geodata** - Geographic data utilities
- **geometry** - Get geometry data from elements
- **integrate-elements** - Write data to element system
- **library** - Add items to asset library
- **predictive-analysis** - Predictive analysis features
- **project** - Project-level information
- **proposal** - Proposal management
- **render** - Temporary visual changes (color, hide/show, add meshes)
- **scene/selection** - Selection management
- **sun** - Sun position and visualization
- **terrain** - Terrain data access

## Resources

- **Developer Guide:** https://aps.autodesk.com/en/docs/forma/v1/embedded-views/introduction/
- **SDK Documentation:** https://app.autodeskforma.com/forma-embedded-view-sdk/docs/
- **Tutorial:** https://aps.autodesk.com/en/docs/forma/v1/embedded-views/tutorial/
- **NPM Package:** https://www.npmjs.com/package/forma-embedded-view-sdk
- **Example Repository:** https://github.com/spacemakerai/color-buildings-tutorial

**Note:** The documentation websites are JavaScript-rendered applications and cannot be accessed via standard HTTP fetch. To programmatically access or update this information, you must use **Playwright MCP** to navigate and interact with the pages dynamically.

## Important Notes

1. **All render changes are temporary** - They don't persist to the proposal and are cleaned up when the extension closes
2. **HTTPS required** for production - Use localhost for development
3. **Storage is partitioned** - Extensions have isolated cookies/localStorage
4. **Authentication via popup** - Don't embed login forms directly
5. **Element paths are immutable** - Use paths to reference geometry consistently
6. **Coordinate system** - All coordinates are relative to project's `refPoint`
7. **Analysis grid coordinates** - Calculate using resolution, width, x0, y0
8. **Color format** - Use RGBA Uint8Array (4 bytes per triangle, not per vertex)
