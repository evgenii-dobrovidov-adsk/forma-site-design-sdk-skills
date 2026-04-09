---
name: forma-site-design-extensions-ui-weave
description: Provides instructions for building consistent UIs for Autodesk Forma Site Design extensions using the Autodesk Weave design system. Covers React (Weave MUI Kit with @weave-mui/material and @weave-mui/styles) and non-React (Weave Web Components from CDN). Use when building extension UI, styling with Weave, choosing between Weave MUI and web components, or looking up available Weave components and their usage.
---
# Forma Site Design Extensions UI -- Weave

## When to use
Use this skill when the task involves:
- building or modifying the UI for a Forma Site Design extension
- styling an extension panel with the Weave design system
- choosing between Weave MUI Kit (React) and Weave Web Components (non-React)
- looking up available Weave components, attributes, or event contracts

## Choose your track
- **React** project --> use **Weave MUI Kit** (preferred)
- **Non-React** project (Preact, vanilla JS/TS, Rust/WASM, etc.) --> use **Weave Web Components**

Both tracks produce visually identical Weave-styled UIs. The Weave Web Components track is considered legacy; prefer the MUI Kit for new React projects.

**Fallback rule:** If the Weave MUI Kit (`@weave-mui/*` packages) is not available in the user's environment (e.g. npm registry access issues, missing Autodesk internal registry), fall back to Weave Web Components even for React projects. The web components are loaded from a public CDN and work universally in any framework, including React.

## How to look up component details

### React -- Weave MUI Kit
When working with Weave MUI React components, rely on these sources in priority order:
1. **Official Weave skills and Weave MCP server** -- if `weave-2-*` or `weave-3-*` skills are available in the current environment (e.g. `weave-2-component-lookup`, `weave-2-styling`), use them first. If a Weave Supernova MCP server is connected, use it to query component specs and design tokens. These are the most authoritative and up-to-date sources.
2. **TypeScript types from installed packages** -- read the `.d.ts` files in `node_modules/@weave-mui/` to discover props, variants, enums, and event signatures. Does not require any authentication.
3. **This skill** -- use the component list, styling guidance, and anti-patterns below as a quick reference.
4. **Weave MUI Storybook via Playwright** -- only as a last resort when the above sources are unavailable or ambiguous and you need visual/behavioral details. This requires the human to authenticate via Autodesk SSO, so avoid unless genuinely necessary.

### Non-React -- Weave Web Components
When working with Weave web components, rely on these sources in priority order:
1. **Official Weave skills and Weave MCP server** -- if `weave-2-*` or `weave-3-*` skills are available in the current environment, use them first. If a Weave Supernova MCP server is connected, use it to query component specs and design tokens.
2. **This skill** -- use the component list, loading patterns, event contracts, and attribute reference below.
3. **Weave Web Components Storybook** -- publicly accessible, no authentication required. Can be fetched directly without Playwright.

## React -- Weave MUI Kit

### Dependencies

```bash
npm install @weave-mui/material @weave-mui/styles @weave-mui/enums @weave-design/fonts @mui/material@^5.16.9 @emotion/react @emotion/styled
```

Notes:
- `@weave-mui/material` is the barrel package containing all Weave MUI components.
- `@weave-mui/styles` provides `ThemeProvider`, `getTheme`, `createTheme`, `themes`, and `densities`.
- `@weave-mui/enums` provides spacing enums (`spacings.XS`, `spacings.S`, `spacings.M`, etc.) and other design tokens.
- `@weave-design/fonts` provides the ArtifaktElement font CSS (the official way to load Autodesk brand fonts).
- `@mui/material` is a peer dependency required by Weave MUI.
- `@emotion/react` and `@emotion/styled` are the styling engine required by MUI 5.
- Data Grid, Date Picker, and TreeView require separate installs; see the Storybook docs for those components.

### Global setup

Three files establish the Weave foundation. Every React extension must set these up before using Weave components.

**1. Font loading** -- Autodesk brand font

**Preferred:** Import from the `@weave-design/fonts` package (already installed above):
```tsx
import '@weave-design/fonts/build/ArtifaktElement.css';
```

**Alternative:** If `@weave-design/fonts` is unavailable, create a `typography.css` with manual `@font-face` declarations:
```css
@font-face {
  font-family: 'ArtifaktElement';
  src: url('https://swc.autodesk.com/pharmacopeia/fonts/ArtifaktElement/v1.0/WOFF2/Artifakt%20Element%20Regular.woff2') format('woff2');
  font-style: normal;
  font-weight: 400;
}
@font-face {
  font-family: 'ArtifaktElement';
  src: url('https://swc.autodesk.com/pharmacopeia/fonts/ArtifaktElement/v1.0/WOFF2/Artifakt%20Element%20Bold.woff2') format('woff2');
  font-style: normal;
  font-weight: 700;
}
```

The Weave theme references ArtifaktElement but does **not** load it automatically. Skipping font loading causes fallback fonts and visual inconsistency.

**2. `WeaveRoot.tsx`** -- theme provider wrapper

```tsx
import { useEffect, useState } from 'react';
import { CssBaseline } from '@weave-mui/material';
import {
  ThemeProvider,
  createTheme,
  getTheme,
  densities,
  themes,
} from '@weave-mui/styles';
import '@weave-design/fonts/build/ArtifaktElement.css';
import App from './App.tsx';

function WeaveRoot() {
  const [theme, setTheme] = useState(() => createTheme({}));

  useEffect(() => {
    let cancelled = false;

    async function loadTheme() {
      try {
        const baseTheme = createTheme({});
        const weaveTheme = await getTheme(themes.LIGHT_GRAY, densities.HIGH);
        if (!cancelled) {
          setTheme(createTheme(baseTheme, weaveTheme));
        }
      } catch {
        if (!cancelled) {
          setTheme(createTheme({}));
        }
      }
    }

    void loadTheme();
    return () => { cancelled = true; };
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <App />
    </ThemeProvider>
  );
}

export default WeaveRoot;
```

Key points:
- **`getTheme()` returns a Promise**, not a theme object. You must await it or resolve it before passing to `ThemeProvider`.
- Theme and density enums use UPPER_SNAKE_CASE: `themes.LIGHT_GRAY`, `densities.HIGH`.
- Available themes: `themes.LIGHT_GRAY`, `themes.DARK_GRAY`, `themes.DARK_BLUE`.
- Available densities: `densities.LOW`, `densities.MEDIUM`, `densities.HIGH`.
- Use `themes.LIGHT_GRAY` and `densities.HIGH` for Forma extension panels.
- `CssBaseline` normalizes browser defaults to match the Weave baseline.
- The component renders immediately with a fallback theme so the UI is never blank.

**3. `main.tsx`** -- app entry point

```tsx
import { createRoot } from 'react-dom/client';
import WeaveRoot from './WeaveRoot.tsx';

createRoot(document.getElementById('root')!).render(<WeaveRoot />);
```

### Import patterns

Barrel import (recommended for most cases):
```tsx
import { Button, Typography, Stack, TextField, Alert } from '@weave-mui/material';
```

Individual package import (for tree-shaking or when only one component is needed):
```tsx
import Button from '@weave-mui/button';
import Typography from '@weave-mui/typography';
```

### Available components

**Components:**
Accordion, Autocomplete, Avatar, AvatarGroup (Avatar bundle), Badge, Bottom Sheet, Breadcrumbs, Button, Checkbox, Date Picker*, Divider, Select (Dropdown), Empty state, Global Header, IconButton, InlineEdit, MenuList (Menu), Modal, Notification, Alert (Notification banner), NotificationFlyout, NotificationToast, Popper (Popover), CircularProgress, LinearProgress, Radio, Search, Skeleton, Slider, Stepper (Step indicator), Tabs, Chip (Tag), FormLabel, TextField, Link (Text link), CardMedia (Thumbnail), Card (Tile), Switch (Toggle switch), Tooltip, TreeView*

**Shared Components:**
Container Footer, Container Header

**Table:**
Table, Data Grid* (*requires separate `@weave-mui/data-grid` install*)

**MUI Specifics (re-exported from MUI with Weave theming):**
Box, ClickAwayListener, Container, CssBaseline, FormControl, Grid, Slide, Stack, Styled, SvgIcon, Theme Provider

**Miscellaneous:**
Auto Link, Enums, Truncate Text

*Components marked with * may require separate package installs. Check the Storybook docs for exact install commands.*

### Styling approach

- Use the MUI `sx` prop for one-off styles:
  ```tsx
  <Box sx={{ backgroundColor: 'background.default', color: 'text.primary', p: 2 }}>
  ```
- Theme palette keys: `background.default`, `text.primary`, `text.secondary`
- Use spacing enums from `@weave-mui/enums` for consistent spacing:
  ```tsx
  import { spacings } from '@weave-mui/enums';
  // spacings.XS, spacings.S, spacings.M, spacings.L, spacings.XL, etc.
  <Box sx={{ padding: spacings.M, gap: spacings.S }}>
  ```
- Use `Stack` with `spacing` for layout:
  ```tsx
  <Stack spacing={2}>
    <Typography variant="h5">Title</Typography>
    <TextField label="Name" />
    <Button variant="contained">Submit</Button>
  </Stack>
  ```
- Use `theme.palette.*` for colors via the `sx` callback syntax when needed:
  ```tsx
  <Box sx={{ color: (theme) => theme.palette.text.primary }}>
  ```
- Use `Typography` for all text to get ArtifaktElement font and correct sizing.

### Rules and anti-patterns

**Do:**
- Always use `@weave-mui/*` components when a Weave equivalent exists. Do not use stock MUI components directly if Weave wraps them.
- Always use `theme.palette.*` or MUI palette shorthand in `sx` for colors.
- Always use spacing enums from `@weave-mui/enums` or `theme.spacing()` for spacing values.
- Always await `getTheme()` before passing the result to `ThemeProvider`.

**Do not:**
- Hardcode hex, rgb, rgba, or hsl color values. Use design tokens via theme palette.
- Hardcode pixel spacing on Weave components. Use spacing enums or theme spacing.
- Override font families. The Weave theme sets ArtifaktElement automatically.
- Use `@mui/icons-material`. If icons are needed, check the Weave MUI Storybook for the icon set available via Weave.

## Non-React -- Weave Web Components

### Global setup

Add the base stylesheet and set the font in your HTML or at runtime:

```html
<link rel="stylesheet" href="https://app.autodeskforma.eu/design-system/v2/forma/styles/base.css" />
```

Set the font on your root element:
```css
body {
  font-family: "Artifakt Element", system-ui, Avenir, Helvetica, Arial, sans-serif;
  font-size: 11px;
  line-height: 18px;
  margin: 0;
}
```

### Loading components

**Static in HTML** -- load each component as an ES module script:

```html
<script type="module" src="https://app.autodeskforma.eu/design-system/v2/weave/components/button/weave-button.js"></script>
<script type="module" src="https://app.autodeskforma.eu/design-system/v2/weave/components/input/weave-input.js"></script>
```

Then use the custom elements directly:
```html
<weave-button variant="solid">Click me</weave-button>
<weave-input placeholder="Enter value..."></weave-input>
```

**Dynamic in JS/TS** -- lazy-load at runtime:

```ts
const WEAVE_BASE = 'https://app.autodeskforma.eu/design-system/v2';
const loaded = new Set<string>();

function ensureBase(): void {
  if (loaded.has('base')) return;
  loaded.add('base');
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = `${WEAVE_BASE}/forma/styles/base.css`;
  document.head.appendChild(link);
}

function ensureComponent(componentPath: string): void {
  if (loaded.has(componentPath)) return;
  loaded.add(componentPath);
  ensureBase();
  const script = document.createElement('script');
  script.type = 'module';
  script.src = `${WEAVE_BASE}/weave/components/${componentPath}`;
  document.head.appendChild(script);
}

// Usage:
ensureComponent('button/weave-button.js');
ensureComponent('input/weave-input.js');
```

### TypeScript declarations

For JSX environments (Preact, etc.), declare the custom elements:

```ts
declare namespace JSX {
  interface IntrinsicElements {
    'weave-button': JSX.HTMLAttributes<HTMLElement> & {
      variant?: 'solid' | 'flat' | 'outlined' | 'white' | 'white-outlined';
      density?: 'high' | 'medium';
      disabled?: boolean;
      type?: string;
      iconposition?: string;
    };
    'weave-input': JSX.HTMLAttributes<HTMLElement> & {
      placeholder?: string;
      value?: string;
      disabled?: boolean;
      density?: 'high' | 'medium';
    };
    'weave-checkbox': JSX.HTMLAttributes<HTMLElement> & {
      label?: string;
      showlabel?: boolean;
      checked?: boolean;
    };
    'weave-select': JSX.HTMLAttributes<HTMLElement> & {
      density?: 'high' | 'medium';
    };
    'weave-select-option': JSX.HTMLAttributes<HTMLElement> & {
      value?: string;
    };
    'weave-toggle': JSX.HTMLAttributes<HTMLElement> & {
      checked?: boolean;
    };
    'weave-slider': JSX.HTMLAttributes<HTMLElement> & {
      min?: number;
      max?: number;
      value?: number;
    };
    'weave-banner': JSX.HTMLAttributes<HTMLElement> & {
      density?: 'high' | 'medium';
    };
  }
}
```

Vanilla TS without JSX can skip this and use `document.createElement('weave-button')` directly.

### Event handling

Weave web components emit standard DOM events and `CustomEvent`s:

- **Click** (buttons): standard `click` event -- use `addEventListener('click', handler)` or framework equivalent (e.g. Preact `onClick`).
- **Change on text inputs** (`weave-input`): `CustomEvent` -- read `(e as CustomEvent).detail?.value`.
- **Change on checkbox/toggle** (`weave-checkbox`, `weave-toggle`): `CustomEvent` -- read `(e as CustomEvent).detail?.checked`.
- **Change on select** (`weave-select`): `CustomEvent` -- read `(e as CustomEvent).detail` for the selected value.

Example with a text input:
```ts
const input = document.createElement('weave-input') as HTMLElement;
input.setAttribute('placeholder', 'Enter name...');
input.addEventListener('change', ((e: CustomEvent) => {
  console.log('New value:', e.detail?.value);
}) as EventListener);
```

Example with a checkbox:
```ts
const cb = document.createElement('weave-checkbox') as HTMLElement;
cb.setAttribute('label', 'Enable feature');
cb.setAttribute('showlabel', '');
cb.addEventListener('change', ((e: CustomEvent) => {
  console.log('Checked:', e.detail?.checked);
}) as EventListener);
```

### Available components

**Weave Components:**
Accordion, Avatar, Avatarbundle, Badge, Banner, Buttons, Checkbox, Dropdown (Select), Input, Floating, Flyout, Header, Icons, Slider+Input, Menu Container, Menu, Modal, Progress, Radio, Search box, Skeleton item, Slider, Tab, Text link, Tile, Timestamp, Toggle, BubbleTooltips, Tooltips

**Forma Components** (higher-level, built on Weave):
Alert, AlertsV2, Analysis, Compass, Context menu, Dropdown (Select), Tooltips, Header, HomeLink, HorizontalBarChart, Icons, Logo, Navbar, ProjectHeader, SelectNative, Sidebar, SubmodeHeader, Tabs, Toast, Toolbar, ViewOnlyBanner

### Known component script paths

These paths are relative to `https://app.autodeskforma.eu/design-system/v2/weave/components/`:

```
button/weave-button.js
input/weave-input.js
banner/weave-banner.js
checkbox/weave-checkbox.js
dropdown/weave-select.js
toggle/weave-toggle.js
slider/weave-slider.js
```

For components not listed here, the path generally follows `{component-name}/weave-{component-name}.js`. Verify against the Storybook docs when in doubt.

### Common attributes

- `variant`: `solid`, `flat`, `outlined`, `white`, `white-outlined` (buttons)
- `density`: `high`, `medium` (inputs, selects, banners)
- `disabled`: boolean attribute
- `showlabel`: boolean attribute (checkbox -- show the label text)
- `label`: string attribute (checkbox label text, input labels)

## Extension UI guidelines

These apply to both tracks:

- Build for narrow embedded-view panels first. Prefer a single-column layout.
- Use high density (`densities.HIGH` in React, `density="high"` in web components) for compact extension panels.
- Use `Accordion` for advanced or secondary settings sections.
- Use `Stack` (React) or CSS flexbox (non-React) for vertical layout with consistent spacing.
- Use feedback components (`Alert`/`Banner`, `CircularProgress`/`LinearProgress`/`Progress`) for loading, error, warning, and success states.
- Use `Modal` only for blocking confirmation or focused workflows.
- Use `Flyout` or `Menu` for lightweight secondary actions.
- Use `Tabs` only when the UI naturally splits into distinct views or modes.
- Use `Card`/`Tile` when the user needs to choose between a small set of visual options.
- Wrap all text in `Typography` (React) to get correct font and sizing.

## Live docs
- Weave MUI Storybook (v4.5.0): `https://pages.git.autodesk.com/design-system/weave-mui/v-4-5-0/?path=/docs/documentation-getting-started--docs`
- Weave Web Components Storybook: `https://app.autodeskforma.eu/design-system/v2/docs/?path=/docs/forma-component-library--docs`

The Weave MUI Storybook requires Autodesk SSO authentication and must be accessed via Playwright (the human will need to authenticate in the browser window). The Web Components Storybook is publicly accessible and can be fetched directly without Playwright.

Trust the live Storybook docs over memory or outdated code. Use Playwright to inspect the Weave MUI docs when you need component details beyond what this skill covers.
