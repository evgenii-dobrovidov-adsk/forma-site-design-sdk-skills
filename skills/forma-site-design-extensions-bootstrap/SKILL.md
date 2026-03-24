---
name: forma-site-design-extensions-bootstrap
description: Bootstraps Autodesk Forma Site Design embedded-view extensions by scaffolding a Vite + React TypeScript app, adding the Forma SDK and Weave UI Kit dependencies, inspecting Weave docs and component metadata, and then implementing the user’s requested extension with the `forma-site-design-extensions` skill. Use when starting a new Forma extension from scratch.
---
# Forma Site Design Extensions Bootstrap

## When to use
Use this skill when the user wants to:
- create a new Autodesk Forma Site Design extension
- scaffold an extension from scratch
- start from a simple Vite + React TypeScript app
- build a new extension UI with the Weave UI Kit

## Default scaffold
Create a simple Vite + React TypeScript app first:

```bash
npm create vite@latest <extension-name> -- --template react-ts
cd <extension-name>
npm install
npm install forma-embedded-view-sdk
```

Then add the Weave UI Kit package or packages required by the target environment.

Rules:
- Do not guess internal package names for Weave. Inspect the current codebase, lockfile, or official Weave docs before installing Weave packages.
- Keep the scaffold simple. Prefer the default Vite structure unless the prompt clearly requires more.
- Keep the app on React. Do not switch to Preact or add Preact compatibility shims unless the user explicitly asks for that.
- After scaffolding, do not stop at setup. Continue and create the actual extension requested in the user’s prompt.

## After scaffolding
Once the project exists and dependencies are installed:
1. Read the user’s prompt carefully.
2. Apply the `forma-site-design-extensions` skill for the actual Forma SDK behavior and extension implementation.
3. If the extension involves coordinates, transforms, or GLB orientation, also apply the `forma-site-design-coordinate-system` skill.

## Local testing outside Forma
The extension should be testable in a normal browser tab during local development, not only inside the Forma embedded-view host.

Important constraint from local testing:
- Do not eagerly import `forma-embedded-view-sdk/auto` at the top level when standalone preview matters.
- A static import can fail outside Forma because the SDK expects host query parameters such as `origin` during module evaluation.

Use this pattern instead:
1. Detect whether the Forma host context appears to be available by checking for the required query parameter.
2. Dynamically import `forma-embedded-view-sdk/auto` only when that host context is present.
3. Store the loaded SDK instance in component state or a ref.
4. Keep the UI renderable outside Forma with a safe preview mode.
5. Disable or guard host-only actions such as scene picking, host messaging, and SDK-dependent queries until the SDK is loaded.

Preview-mode expectations:
- The panel UI should render at a local dev URL such as `http://localhost:5173/`.
- Show a clear message that the app is running in preview mode outside Forma.
- Keep purely visual and form-based UI work testable without the host.
- Avoid crashing the app just because host initialization is unavailable.

## Weave UI Kit workflow
The UI for the extension should be created with the Weave UI Kit.

Start with the Weave docs:
- Use Playwright to inspect:
  - `https://pages.git.autodesk.com/design-system/weave-mui/v-4-5-0/?path=/docs/documentation-getting-started--docs`
- If that page is inaccessible in the current environment, do not block on it.

If a Storybook MCP is available, use the Storybook URL linked from the Weave docs to inspect available components and prop details before coding.

## How to build UIs with Weave
Prefer Weave components over raw HTML controls whenever a matching Weave component exists.

Recommended component families:
- Actions: `Button`, `IconButton`, `LinkButton`, `Text link`
- Inputs: `Input`, `Search box`, `Dropdown (Select)`, `Checkbox`, `Radio/Group`, `Toggle`, `Slider`, `Slider+Input`
- Structure: `Accordion`, `Tab`, `Tile`, `Header`
- Overlays and menus: `Modal`, `Flyout`, `Menu`
- Feedback: `Banner`, `Progress/Bar`, `Progress/Ring`, `Badge`, `Tooltips`

Default UI guidance for extensions:
- Build for narrow embedded-view panels first.
- Prefer a single-column layout unless the prompt clearly needs more structure.
- Use Weave controls for all main user interaction, not mixed ad-hoc HTML inputs.
- Prefer `density="high"` when a component supports density, since extension panels are usually compact.
- Use Weave feedback components for loading, error, warning, and success states.
- Use `Accordion` for advanced settings.
- Use `Tab` only when the prompt naturally splits the UI into distinct views or modes.
- Use `Modal` only for blocking confirmation or focused workflows.
- Use `Flyout` or `Menu` for lightweight secondary actions.
- Use `Tile` when the user needs to choose between a small set of visual options or modes.

## Verified Weave interaction notes
From Storybook component metadata:
- `Button` and `IconButton` support variants such as `solid`, `flat`, `outlined`, `white`, and `white-outlined`.
- `Input`, `Dropdown (Select)`, and `Banner` support `high` and `medium` density.
- `Dropdown (Select)` emits `change` with `event.detail` like `{ text, value }`.
- `Search box` emits `input` and `change` with `event.detail.value`.
- `Toggle` emits `input` and `change` with `event.detail.checked` and `event.detail.value`.
- `Tab` emits `change` with an index in the event detail.
- `Modal` exposes `title`, `content`, and optional `actions`.

This means:
- Read the component event contract before wiring state.
- Prefer React-native Weave components when the package provides them.
- If a Weave package exposes custom elements instead of React components, wrap them carefully and handle non-standard events explicitly.
- Keep form state explicit in React and adapt event payloads carefully.

## Implementation pattern
Use this order:
1. Scaffold the Vite + React TypeScript project.
2. Install `forma-embedded-view-sdk`.
3. Set up local-preview-safe SDK loading so the app can render outside Forma.
4. Install the required Weave package or packages for the environment.
5. Inspect Weave docs with Playwright.
6. If a Storybook MCP is available, inspect concrete component props using the Storybook URL linked from the Weave docs.
7. Build the first functional UI in Weave.
8. Apply the `forma-site-design-extensions` skill to implement the requested extension behavior.
9. Refine the UI so the Weave components match the workflow and panel constraints.

## Conditional follow-up skill
After creating the UI, if a skill named `forma-weave-kit` is available in the current environment, apply it to refine:
- component choice
- layout
- spacing
- interaction details
- overall Weave-specific polish

If `forma-weave-kit` is not available, continue using the Weave docs and, when available, Storybook component details from the Storybook URL linked in the docs as the UI source of truth.

## Deliverable expectation
This bootstrap flow should result in:
- a working Vite + React TypeScript extension project
- Forma SDK wiring via `forma-embedded-view-sdk/auto`
- local browser preview that still renders outside the Forma host
- a UI built with Weave components
- extension behavior implemented from the user’s prompt through the `forma-site-design-extensions` skill

## Verification
Before finishing:
- run the local dev server if appropriate
- verify the app renders in a normal browser tab outside Forma
- verify standalone preview does not use a top-level `forma-embedded-view-sdk/auto` import
- verify the UI shows a safe preview-mode state when host query parameters are missing
- verify host-only actions are disabled or guarded until the SDK is loaded
- run a production build
- fix TypeScript or bundling issues
- ensure the extension uses Weave for its visible UI
- ensure temporary scene output uses render APIs and persistent scene content follows the durable Forma element/proposal path described by the `forma-site-design-extensions` skill
