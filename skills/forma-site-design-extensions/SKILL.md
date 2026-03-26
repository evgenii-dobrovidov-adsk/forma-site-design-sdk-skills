---
name: forma-site-design-extensions
description: Builds Autodesk Forma Site Design embedded-view extensions with the full forma-embedded-view-sdk surface, including host-level helpers plus analysis, areaMetrics, auth, camera, colorbar, design-tool, elements, experimental, extensions, generators, geodata, geometry, integrate-elements, library, predictive-analysis, project, proposal, render, selection, settings, sun, and terrain APIs. Use when the user mentions Forma, embedded views, extension SDK, proposals, geometry, analyses, or any Forma SDK module.
---
# Forma Site Design Extensions

## When to use
Use this skill for any Autodesk Forma Site Design embedded-view task involving:
- `forma-embedded-view-sdk`
- extension setup and registration
- host-level embedded view behavior
- any SDK module in the live docs

## Source of truth
- Default stack: TypeScript + Vite + `forma-embedded-view-sdk/auto`.
- Default import:
```ts
import { Forma } from "forma-embedded-view-sdk/auto";
```
- Trust the live SDK docs over memory or outdated code.
- The docs are JS-rendered; use Playwright to inspect them.
- When a task depends on scene coordinates, transforms, GLB orientation, or unit conversions, also use the `forma-site-design-coordinate-system` skill.

## Element system mental model
The APS element-system docs describe the durable data model behind Forma content.

- A `FormaElement` is a revisioned JSON object with a `urn` plus optional `metadata`, `properties`, `representations`, and `children`.
- The URN identifies a specific revision, not just a logical object. The scheme is `urn:adsk-forma-elements:{system}:{authcontext}:{id}:{revision}`.
- Revisions are immutable. If an element changes, producers create a new revision and update references to that new revision. Changes do not propagate just because an old revision was "edited".
- `metadata` describes creation context and licensing, not the element's physical meaning.
- `properties` describe representation-independent semantics such as category, virtual-ness, and analysis figures.
- `representations` are different semantic views of the same element. Consumers must not assume every element has every representation, and must understand what each representation means, not just its raw data format.
- `children` create an element tree. The same element revision can appear multiple times under different parents and transforms.
- Child instance identity comes from child keys and paths, not from the child element URN alone.
- Child transforms are flattened 4x4 column-major affine matrices in meters. Geometry is transformed by the child's matrix and then by the parent chain.

Important representations called out in the docs:
- `volumeMesh`: visual 3D mesh in GLB form. Visible 3D objects are expected to support this. GLB is Y-up, while Forma is Z-up.
- `semanticMesh`: non-overlapping GLB subset for analysis and filtering, with semantic tags like `geometryType` and `unitId`.
- `grossFloorAreaPolygons`: gross floor area partitioning per level.
- `terrainShape`: GeoJSON terrain-aligned vector data in the project's coordinate system.
- `footprint`: 2D occupied ground projection, including overhangs.
- `volume25DCollection`: 2.5D GeoJSON-style geometry that still needs element-tree transforms applied.
- `graphBuilding`: topological partitioning of building space across levels, units, and spaces.

Key principles from the docs:
- Treat the published element specification as the source of truth; do not rely on undocumented API payload details.
- Write generic consumers that gracefully handle missing representations.
- Respect immutability and revisioning; updating content means producing a new revision and updating references.

Durable vs temporary scene content:
- The durable path in Forma is the element system plus the proposal tree. If an extension creates or updates element data and then references it from the proposal tree, that content is preserved in the project and remains available in the scene for the user to view, select, analyze, and manipulate according to the representations provided.
- Representation choice controls what the user and platform can do with the content. For example, `volumeMesh` makes something visually present in 3D, while `footprint`, `terrainShape`, `semanticMesh`, or `graphBuilding` enable other behaviors and analyses.
- Do not use the element system for ephemeral overlays, previews, highlights, or transient helpers.
- If the extension only needs to draw something temporarily in the scene, it must use render-oriented APIs such as `Forma.render.*`, `Forma.render.geojson.*`, `Forma.render.glb.*`, `Forma.render.elementColors.*`, `Forma.colorbar`, or `Forma.terrain.groundTexture.*`.

## Live SDK module list
These modules are currently present in the live docs:
- `index`
- `auto`
- `analysis`
- `areaMetrics`
- `camera`
- `colorbar`
- `design-tool`
- `elements`
- `elements/types`
- `experimental`
- `extensions`
- `generators`
- `geodata`
- `geometry`
- `integrate-elements`
- `library`
- `predictive-analysis`
- `project`
- `proposal`
- `render`
- `scene/selection`
- `settings`
- `sun`
- `terrain`

## Docs-to-runtime name mapping
- `auto` -> import path that exposes the singleton `Forma`
- `design-tool` -> `Forma.designTool`
- `scene/selection` -> `Forma.selection`
- `settings` -> `Forma.settings`
- `geodata` -> `Forma.geoData`
- `integrate-elements` -> `Forma.integrateElements`
- `predictive-analysis` -> `Forma.predictiveAnalysis`
- `elements/types` -> type docs, not a separate runtime namespace

## Host-level SDK surface
The `EmbeddedViewSdk` class and `Forma` singleton also expose host helpers outside the module namespaces.

- Access and permissions:
  - `Forma.getProjectId()`
  - `Forma.getRegion()`
  - `Forma.getCanEdit()`
  - `Forma.getCanEditHub()`
  - `Forma.getCanViewHub()`
  - `Forma.getExtensionId()`
  - `Forma.getEmbeddedViewId()`
  - `Forma.getPresentationUnitSystem()`
- Embedded-view lifecycle and communication:
  - `Forma.openFloatingPanel(...)`
  - `Forma.closeEmbeddedView(...)`
  - `Forma.createMessagePort(...)`
  - `Forma.onMessagePort(...)`
  - `Forma.onEmbeddedViewStateChange(...)`
  - `Forma.onEmbeddedViewClosing(...)`
  - `Forma.onLocaleUpdate(...)`
  - `Forma.ping()`
- Error surface:
  - `RequestError`

Rules:
- `openFloatingPanel`, `closeEmbeddedView`, `createMessagePort`, `onMessagePort`, `onEmbeddedViewStateChange`, and `onEmbeddedViewClosing` are experimental.
- All SDK math and geometry APIs still operate in metric units even if `getPresentationUnitSystem()` says the UI should default to imperial.

## SDK surface map

### `index` and `auto`
- Use `forma-embedded-view-sdk/auto` for the preconfigured singleton `Forma`.
- `index` also documents `EmbeddedViewSdk`, `RequestError`, and `AuthApi`.
- Prefer `auto` unless the user explicitly needs manual SDK wiring.

### `analysis`
- Methods: `list`, `getGroundGrid`, `getNoiseAnalysis`, `getSunAnalysis`, `triggerNoise`, `triggerSun`.
- Use for reading existing analyses or triggering supported analysis runs.
- Pair `list()` with `Forma.getProjectId()` or proposal/root URN context when needed.

### `areaMetrics`
- Method: `calculate({ paths? })`.
- Use for area and metric breakdowns on selected paths or the whole current context.

### `auth`
- Methods: `configure`, `acquireTokenSilent`, `acquireTokenPopup`, `acquireTokenOverlay`, `refreshCurrentToken`.
- Prefer SDK auth helpers over custom login forms inside the iframe.
- Never hardcode secrets or embed username/password fields in the extension UI.

### `camera`
- Methods: `capture`, `getCurrent`, `move`, `subscribe`, `switchPerspective`.
- Use for screenshots, camera sync, guided navigation, and viewpoint updates.

### `colorbar`
- Methods: `add`, `remove`.
- `add()` accepts `colors`, optional `labels`, `unit`, `labelPosition`, and `onRangeFilterChange`.
- Only one colorbar is visible at a time.

### `design-tool`
- Methods: `getPoint`, `getLine`, `getPolygon`, `getExtrudedPolygon`, `onEditStart`, `onEditEnd`.
- Use when the extension needs the user to click or sketch directly in the scene.

### `elements`
- Main methods: `get`, `getByPath`, `getWorldTransform`, `editProperties`.
- Nested APIs:
  - `Forma.elements.blobs.get`
  - `Forma.elements.representations.footprint`
  - `Forma.elements.representations.graphBuilding`
  - `Forma.elements.representations.grossFloorAreaPolygons`
  - `Forma.elements.representations.volumeMesh`
  - `Forma.elements.floorStack.createFromFloors`
  - `Forma.elements.floorStack.createFromFloorsBatch`
- Use for reading stored element data, binary representations, world transforms, floor stacks, and property patches.
- Read the element-system mental model above before constructing or interpreting durable element data.

### `elements/types`
- Treat this module as the canonical data-shape reference for `FormaElement`, representations, transforms, metadata, traffic data, and related contracts.
- Read these types before constructing low-level element payloads or interpreting element responses.

### `experimental`
- `Forma.experimental.analysis.putCatalogItem`
- `Forma.experimental.housing.listTemplates`
- `Forma.experimental.housing.createFromLine`
- The live docs also expose `Forma.experimental.render`.
- Experimental APIs are subject to change without notice. Do not treat them as stable production defaults.

### `extensions`
- `Forma.extensions.invokeEndpoint({ extensionId, endpointId, authcontext?, payload })`
- `Forma.extensions.storage.setObject`
- `Forma.extensions.storage.getTextObject`
- `Forma.extensions.storage.getBinaryObject`
- `Forma.extensions.storage.listObjects`
- `Forma.extensions.storage.deleteObject`
- Use `extensions.storage` for extension-owned persisted blobs or text; use `getCanEditHub()` and `getCanViewHub()` when working in hub scope.

### `generators`
- Methods: `list`, `put`.
- Supporting docs also cover `Generator`, `GeneratorSchemaV1`, `ExtensionEndpointRunner`, and `ExtensionScriptRunner`.
- Use when the task is about registering or updating generator definitions.

### `geodata`
- Method: `upload`.
- Supported `dataType` values currently include `buildings`, `roads`, and `property-boundaries`.
- Use for GeoJSON-based uploads that should land in Forma's library and geodata flows.

### `geometry`
- Methods: `getFootprint`, `getPathsByCategory`, `getPathsForVirtualElements`, `getPathsInsidePolygons`, `getTriangles`.
- `getFootprint()` does not traverse children.
- For composite elements, `getTriangles()` is often the better fallback when no direct footprint exists.

### `integrate-elements`
- Methods: `uploadFile`, `createUrn`, `createElementV2`, `updateElementV2`, `batchIngestElementsV2`, `createElementHierarchy`.
- Use this module to create or update persistent element URNs and representations before attaching them to proposals.
- This is the main bridge between uploaded geometry data and proposal mutation APIs.
- Writing here is part of the durable element-system path, not the temporary render path.

### `library`
- Methods: `createItem`, `updateItem`, `deleteItem`.
- Use for extension-managed library entries rather than proposal scene edits.
- Mutation requires edit access.

### `predictive-analysis`
- Methods: `getWindParameters`, `predictWind`.
- Use for wind prediction flows and related derived grids.

### `project`
- Methods: `get`, `getGeoLocation`.
- Pair with host helpers like `getProjectId()` and `getRegion()`.
- Use for project metadata, location-aware features, and contextual auth scopes.

### `proposal`
- Methods: `get`, `getAll`, `getId`, `getRootUrn`, `subscribe`, `awaitProposalPersisted`, `addElement`, `removeElement`, `replaceElement`, `replaceTerrain`, `updateElements`, `create`, `update`, `duplicate`, `switch`, `delete`.
- Use for current proposal context, proposal lifecycle, and persistent scene-tree edits.
- Mutation requires edit access; `updateElements()` is the preferred batch operation for mixed add, replace, and remove work.
- Referencing elements from the proposal tree is what makes durable element-system content appear and persist in the scene.

### `render`
- Core methods: `addMesh`, `updateMesh`, `remove`, `cleanup`, `hideElement`, `hideElementsBatch`, `unhideElement`, `unhideElementsBatch`, `unhideAllElements`, `setElementsVisibility`.
- Nested APIs:
  - `Forma.render.elementColors.set`
  - `Forma.render.elementColors.clear`
  - `Forma.render.elementColors.clearAll`
  - `Forma.render.geojson.add`
  - `Forma.render.geojson.update`
  - `Forma.render.geojson.remove`
  - `Forma.render.geojson.cleanup`
  - `Forma.render.glb.add`
  - `Forma.render.glb.update`
  - `Forma.render.glb.remove`
  - `Forma.render.glb.cleanup`
- Use for temporary overlays, visibility changes, GLB previews, GeoJSON overlays, and per-element color overrides.
- Render APIs are for transient scene output only; they do not create durable element-system content.

### `scene/selection`
- Methods: `getSelection`, `subscribe`.
- `subscribe()` callbacks receive `{ paths }`.
- Use for user-driven element context and reactive UI tied to current selection.

### `settings`
- Main method: `get`.
- Nested API:
  - `Forma.settings.buildingFunctions.add`
  - `Forma.settings.buildingFunctions.update`
  - `Forma.settings.buildingFunctions.delete`
- Use for reading and managing project-level building functions via `Forma.settings`.
- `get()` returns all project building functions, including the three built-in defaults: `residential`, `commercial`, and `unspecified`.
- `buildingFunctions.add({ name, color? })` creates a project-level building function and returns the updated `SettingsResponse`.
- `buildingFunctions.update({ id, name, color? })` updates a custom building function and returns the updated `SettingsResponse`.
- `buildingFunctions.delete({ id })` deletes a custom building function and returns the updated `SettingsResponse`.
- `color` values are hex strings such as `#FF5733`.
- `update()` and `delete()` return an error when the `id` belongs to a built-in building function.

### `sun`
- Methods: `getDate`, `setDate`.
- Use for sun-state-driven UI or analysis setup.

### `terrain`
- Core methods: `getBbox`, `getElevationAt`, `getPads`, `addPads`, `applyPads`.
- Nested API:
  - `Forma.terrain.groundTexture.add`
  - `Forma.terrain.groundTexture.remove`
  - `Forma.terrain.groundTexture.updatePosition`
  - `Forma.terrain.groundTexture.updateTextureData`
- Use for terrain inspection, elevation-aware placement, terrain pads, and projected ground textures.

## Choose the right family
- Temporary visualization: prefer `render`, `colorbar`, and sometimes `terrain.groundTexture`; this is transient scene output.
- Persistent scene content: use `integrate-elements`, `elements.floorStack`, and `proposal`; this is the durable path for content that should stay in the scene for the user.
- Read-only geometry and metadata: use `project`, `geometry`, `elements`, `terrain`, `selection`, `camera`.
- Project-level configuration: use `settings` and `settings.buildingFunctions` for building function definitions and colors.
- Scene picking or sketching: use `design-tool` and `selection`.
- Authenticated backend or storage workflows: use `auth`, `extensions`, `extensions.storage`, `library`, `generators`.
- Advanced analysis workflows: use `analysis`, `areaMetrics`, `predictiveAnalysis`, `sun`, and `experimental.analysis` if the task explicitly depends on it.
- Unstable or preview capabilities: treat `experimental` and the experimental host helpers as opt-in, task-specific surfaces.

## Practical rules
- Decide first whether the task is temporary or persistent.
- Check `await Forma.getCanEdit()` before proposal, element, terrain, library, or storage mutation.
- Check `getCanEditHub()` or `getCanViewHub()` when a workflow targets hub-scoped storage.
- Keep embedded-view UIs narrow and responsive.
- Use `Forma.proposal.subscribe()` or `Forma.selection.subscribe()` when cached UI state depends on changing host state.
- Use `RequestError` for SDK-specific request failures.
- Use flattened 4x4 column-major transforms for Forma scene transforms.
- For detailed coordinate-handling guidance, also use the `forma-site-design-coordinate-system` skill.
- Treat the built-in building functions `residential`, `commercial`, and `unspecified` as immutable defaults; do not call `update()` or `delete()` on their IDs.
- `render.glb.add()` takes a binary `ArrayBuffer`, not a URL.
- `render.GeometryData.color` is RGBA per vertex.
- `geometry.getFootprint()` does not traverse children.

## Stale patterns to avoid
Do not generate these older patterns unless the current code clearly and intentionally wraps them:
- `Forma.proposal.getRevision()`
- `Forma.selection.add(...)`
- `Forma.camera.getState()`, `setState()`, or `zoomTo()`
- `Forma.render.elementColors.reset(...)`
- `Forma.render.glb.add({ url: ... })`
- `Forma.library.addItem(...)`
- `Forma.extensions.invokeEndpoint({ method, data })`

## Live docs
- `https://app.autodeskforma.com/forma-embedded-view-sdk/docs/`
- `https://app.autodeskforma.com/forma-embedded-view-sdk/docs/modules.html`
- `https://app.autodeskforma.com/forma-embedded-view-sdk/docs/classes/index.EmbeddedViewSdk.html`
- `https://aps.autodesk.com/en/docs/forma/v1/working-with-forma/element-system/forma-element-specification/`
- `https://aps.autodesk.com/en/docs/forma/v1/working-with-forma/element-system/key-principles/`

When an API is uncertain, verify the relevant live docs page with Playwright before generating code.
