---
name: autodesk-forma-coordinate-system
description: A guide for handling coordinates and their transformations in Autodesk Forma Site Design extensions
---
# Forma Site Design coordinate & transform reference

## Short summary (one sentence)
- Forma Site Design uses a Z‑up, metre‑based scene coordinate system (scene/world coordinates); glTF is Y‑up — you must convert axes or rotate models when moving geometry between glTF and Forma Site Design; transforms in Forma Site Design are 4×4 column‑major matrices (flattened arrays) with translations at indices 12–14 (0‑based).

---

## 1) Coordinate systems — authoritative facts
- Forma Site Design scene coordinates:
  - Units: metres (projected coordinate system / SRID). Use Forma.project.get() for georeference.
  - Scene origin: (0,0,0) — typically the centre of the terrain; Z is vertical (height above mean sea level).
  - designTool.getPoint() → returns { x, y, z? } (x,y in scene coords; call terrain.getElevationAt(x,y) for surface Z).
- glTF coordinates:
  - Default: right‑handed, Y‑up (X right, Y up, Z forward in glTF local space).
  - Local to model; exporters may use different pivots/units — always verify exporter units.
- Important behaviours:
  - RenderGlbApi.add(glb) renders the GLB “as‑is” (no external transform). GLB appears at the scene origin according to the glTF node transforms inside the GLB.
  - RenderApi.addMesh( geometryData, transform ) accepts a Forma Site Design transform (4×4 column‑major) that the renderer multiplies with vertex positions — use this for per-instance transforms without editing the GLB.

---

## 2) Forma Site Design transform representation (exact format)
- A Forma Site Design transform is a flattened column‑major 4×4 array of 16 numbers:
  - Layout (indices 0..15):  
    [ m00, m10, m20, m30,  m01, m11, m21, m31,  m02, m12, m22, m32,  m03, m13, m23, m33 ]
  - Translation vector (tx,ty,tz) is stored at indices 12,13,14 (0‑based): m03, m13, m23.
  - Usage: vec4_out = M * vec4_in  (column vector convention).
- Identity:
```ts
const IDENTITY: number[] = [
  1,0,0,0,
  0,1,0,0,
  0,0,1,0,
  0,0,0,1
];
```
- Simple translation matrix to move by (x,y,z):
```ts
function translationMatrix(x:number,y:number,z:number): number[] {
  return [
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    x,y,z,1
  ];
}
```

---

## 3) The axis conversion rule (glTF ↔ Forma Site Design)
- Rotation to convert a glTF point p_g = (xg,yg,zg) into Forma Site Design scene coords p_f (when you want to *rotate* geometry instead of changing the transform):
  - Apply +90° rotation about the X axis (Rx(+90°)). This maps:
    - p_f.x = xg
    - p_f.y = -zg
    - p_f.z = yg
  - In short: gltf → Forma Site Design: (x, y, z) → ( x, -z, y )
- Conversely, to express a Forma Site Design position P_f = (Xf, Yf, Zf) as a glTF translation value when baking transforms into a GLB that will be interpreted with Y‑up, commonly used mapping is:
  - gltf_translation = ( Xf, Zf, -Yf )
  - (This is the pragmatic mapping used when creating a wrapper node inside the GLB for RenderGlbApi.add; the GLB wrapper is rotated by +90° about X and then translated by [Xf, Zf, -Yf].)
- Why this is consistent: Rx(+90°) applied to glTF coordinates yields the Forma Site Design vertical mapping (glTF Y → Forma Site Design Z). That rotation also flips the sign of the former Z axis into the new Y (hence the negative sign of Y).

---

## 4) Practical methods (pick the one you need)

### A) Render a GLB "as‑is" but placed at a world point — bake the transform into the GLB (use when using RenderGlbApi.add)
- Why: RenderGlbApi.add(glb) has no transform parameter. To place the GLB at (Xf,Yf,Zf) in Forma Site Design you must modify the GLB so its internal node transform places it at that world location.
- Steps:
  1. Create wrapper node.
  2. Rotate wrapper by +90° about X (to convert glTF Y→Forma Site Design Z).
  3. Set wrapper translation = [Xf, Zf, -Yf].
  4. Reparent original scene children under wrapper.
- Example (using @gltf-transform/core):
```ts
import { WebIO, MathUtils } from '@gltf-transform/core';

async function bakeTransformIntoGlb(glbArrayBuffer: ArrayBuffer, Xf:number, Yf:number, Zf:number, scale=1){
  const io = new WebIO();
  const doc = await io.readBinary(new Uint8Array(glbArrayBuffer));
  const root = doc.getRoot();

  // Create wrapper node:
  const wrapper = doc.createNode('forma_wrapper');
  // +90° about X: quaternion [sin(θ/2), 0, 0, cos(θ/2)] with θ = +PI/2
  const s = Math.sin(Math.PI/4), c = Math.cos(Math.PI/4);
  wrapper.setRotation([s, 0, 0, c]);   // glTF quaternion order [x,y,z,w]
  wrapper.setScale([scale, scale, scale]);

  // Translation in glTF to place in Forma Site Design world point
  wrapper.setTranslation([Xf, Zf, -Yf]);

  // Reparent all scene root children under wrapper
  for (const scene of root.listScenes()) {
    const children = scene.listChildren();
    for (const child of children) scene.removeChild(child);
    for (const child of children) wrapper.addChild(child);
    scene.addChild(wrapper);
  }

  const out = await io.writeBinary(doc);
  return out.buffer; // pass to Forma.render.glb.add({ glb: out.buffer })
}
```
- Notes:
  - If your model exporter uses different conventions/pivots, test and adjust the rotation sign (+90 vs −90) and translation mapping.
  - Units: if exporter units ≠ metres, apply scale.

### B) Render as a mesh instance with a Forma Site Design transform (use RenderApi.addMesh)
- Why: addMesh accepts a Forma Site Design transform array — easiest when you convert glTF to GeometryData and want to apply rotation/scale/translation on the server/viewer side.
- Strategy: keep vertex coordinates from the glTF (triangle soup or indexed), and pass a Forma Site Design transform that encodes (rotation, scale, translation).
- Example: rotate +90° about X, uniform scale s, translate to (Xf,Yf,Zf). Column‑major flattened matrix:
```ts
// Build (scale*s) * Rx(+90°) with translation [Xf,Yf,Zf] in column-major:
function makeFormaTransform_Rx90_scale_translate(s:number, Xf:number, Yf:number, Zf:number): number[] {
  // Rx(+90) * s:
  // [ s,  0, 0, 0,
  //   0,  0, s, 0,
  //   0, -s, 0, 0,
  //   Xf, Yf, Zf, 1 ]
  return [
     s, 0,  0, 0,
     0, 0,  s, 0,
     0, -s, 0, 0,
     Xf, Yf, Zf, 1
  ];
}

// Usage with geometry extracted from GLB:
const transform = makeFormaTransform_Rx90_scale_translate(0.1, Xf, Yf, Zf);
await Forma.render.addMesh({ geometryData, transform });
```
- If you instead prefer converting vertex positions to Forma Site Design coordinates on CPU, transform each vertex (xg,yg,zg) → ( xg, -zg, yg ) and supply identity transform.

### C) Add a proposal element (integrateElements + proposal.addElement)
- Use integrateElements.uploadFile → integrateElements.createElementV2(representations:{ volumeMesh:{ type:'linked', blobId } }).
- When creating element / placing into proposal you *can* provide a Forma Site Design transform (the same flattened column-major array).
```ts
// createElement + add to proposal with transform
const { blobId } = await integrate.uploadFile({ data: arrayBuffer });
const { urn } = await integrate.createElementV2({
  representations: { volumeMesh: { type: 'linked', blobId } }
});
await Forma.proposal.addElement({ urn, transform }); // transform is Forma Site Design 4x4 array
```
- If the element’s internal geometry is glTF (Y‑up), either:
  - Bake rotation into the GLB (Approach A), or
  - Provide an element transform that both rotates and translates (compose in the 4×4 matrix) — but elements expect transforms in Forma Site Design scene coordinates, therefore the transform must represent the rotation that maps glTF local coordinates to Forma Site Design coordinates (i.e., Rx(+90) included).

---

## 5) How to compute an element’s world transform (hierarchy)
- Element world transform = multiply parent transforms down the hierarchy:
  - worldTransform = T_root × T_child × ... × T_target
  - Use column‑major matrix multiplication; matrix multiply is not commutative — respect order.
- Example (pseudo):
```ts
// multiply column-major matrices a and b => c = a * b
function mul4(a:number[], b:number[]): number[] {
  const c = new Array(16).fill(0);
  for (let r=0; r<4; r++) for (let ccol=0; ccol<4; ccol++) {
    let v = 0;
    for (let k=0; k<4; k++) {
      // a[r,k] * b[k,ccol]
      v += a[k*4 + r] * b[ccol*4 + k]; // because of column-major storage
    }
    c[ccol*4 + r] = v;
  }
  return c;
}
```
- Use getWorldTransform if the SDK exposes it; otherwise compute via parent chain.

---

## 6) Common gotchas & checklist (test & debug steps)
- Always confirm exporter units (Blender/3ds/SketchUp may export in metres or cm).
- Test orientation first by placing a single GLB at a known location (e.g., scene origin) and check which axis is up; adjust rotation sign accordingly.
- If geometry appears at the origin when you expected it at an element position, you forgot to bake transform into GLB for RenderGlbApi.add.
- If model looks mirrored or upside down, flip rotation sign (+90 ↔ −90) and re-test.
- If placement horizontally off by a constant offset, model pivot is non‑zero — subtract model pivot from desired world point or apply compensating translation.
- For performance, when adding many instances, prefer addMesh with a transform (no GLB reupload) or reusing the same URN for elements (cached blobId/URN).

---

## 7) Minimal conversion utilities (TypeScript snippets you can copy)

- Flattened column-major helper + translation builder:
```ts
export type TransformMatrix = [number,number,number,number, number,number,number,number, number,number,number,number, number,number,number,number];

export function identity(): TransformMatrix {
  return [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1];
}

export function translation(x:number,y:number,z:number): TransformMatrix {
  return [1,0,0,0, 0,1,0,0, 0,0,1,0, x,y,z,1];
}

// Rx(+90°) with uniform scale s:
export function rx90ScaleTranslate(s:number, tx:number, ty:number, tz:number): TransformMatrix {
  return [
    s, 0,  0, 0,
    0, 0,  s, 0,
    0, -s, 0, 0,
    tx, ty, tz, 1
  ];
}
```

- Quick glTF→Forma Site Design vertex conversion (triangle soup):
```ts
// For every vertex [xg, yg, zg] -> [xf, yf, zf] = [xg, -zg, yg]
for (let i = 0; i < positions.length; i += 3) {
  const xg = positions[i], yg = positions[i+1], zg = positions[i+2];
  positions[i]   = xg;      // xf
  positions[i+1] = -zg;     // yf
  positions[i+2] = yg;      // zf
}
```

- Baking transform into GLB wrapper (repeat of earlier, copy/paste ready):
```ts
import { WebIO } from '@gltf-transform/core';
const io = new WebIO();
const doc = await io.readBinary(new Uint8Array(glbBuffer));
// create wrapper + rotate + translate (Xf,Yf,Zf)
const wrapper = doc.createNode('forma_wrapper');
// +90° about X -> quaternion [sin(pi/4),0,0,cos(pi/4)]
wrapper.setRotation([Math.SQRT1_2, 0, 0, Math.SQRT1_2]);
// translation in glTF coords to place at Forma Site Design (Xf,Yf,Zf)
wrapper.setTranslation([ Xf, Zf, -Yf ]);
// reparent, write binary, pass to Forma.render.glb.add(...)
```

---

## 8) Which approach to choose (decision table)
- You need model instances with independent transforms (no GLB edit) and want viewer to handle transforms → use RenderApi.addMesh(geometryData, transform) or proposal elements with transform (preferred where persistence is needed).
- You must render the *exact* GLB mesh (materials, morph targets, animation) without converting to mesh arrays and do not need per‑instance transform outside the GLB → bake the transform into the GLB and use RenderGlbApi.add.
- You want persistent elements stored in the proposal → upload blob once (cache blobId/URN) + integrate.createElementV2 + proposal.addElement({ urn, transform }).

---

## 9) Final checklist (copy/paste before each placement)
1. Pick XY via designTool.getPoint(); then Z = await terrain.getElevationAt({x,y}).
2. Decide approach: (A) bake+RenderGlb, (B) addMesh with transform, or (C) create proposal element with transform.
3. If approach A: bake Rx(+90°) into GLB & set glTF translation = [Xf, Zf, -Yf].
4. If approach B: extract geometry (triangle soup recommended), call Forma.render.addMesh(geometryData, transformMatrix). Use transformMatrix that encodes rotation Rx(+90°), scale, and translation [Xf,Yf,Zf].
5. If approach C (proposal element): upload once, createElementV2 with blobId (cache URN), then proposal.addElement({ urn, transform }), where transformMatrix is in Forma Site Design coordinates (include rotation if model still in glTF orientation).
6. Test at origin first (scale small) to validate orientation, then place at final coordinates.

---

## 10) Additional help
- If you want, I can:
  - Produce a small utility module (TS) that exports: buildFormaTransform(rotationXDeg, rotationYDeg, rotationZDeg, scale, tx,ty,tz), convertGltfVerticesToForma(), and bakeGlbForForma() — ready to drop into your repo and unit test quickly.
