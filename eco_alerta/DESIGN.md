---
name: Eco-Systemic UI
colors:
  surface: '#f8faf6'
  surface-dim: '#d8dbd7'
  surface-bright: '#f8faf6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f0'
  surface-container: '#eceeea'
  surface-container-high: '#e7e9e5'
  surface-container-highest: '#e1e3df'
  on-surface: '#191c1a'
  on-surface-variant: '#404943'
  inverse-surface: '#2e312f'
  inverse-on-surface: '#eff1ed'
  outline: '#707973'
  outline-variant: '#bfc9c1'
  surface-tint: '#2c694e'
  primary: '#0f5238'
  on-primary: '#ffffff'
  primary-container: '#2d6a4f'
  on-primary-container: '#a8e7c5'
  inverse-primary: '#95d4b3'
  secondary: '#006686'
  on-secondary: '#ffffff'
  secondary-container: '#73d2fd'
  on-secondary-container: '#005975'
  tertiary: '#005236'
  on-tertiary: '#ffffff'
  tertiary-container: '#006d48'
  on-tertiary-container: '#89edba'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b1f0ce'
  primary-fixed-dim: '#95d4b3'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#0e5138'
  secondary-fixed: '#bfe8ff'
  secondary-fixed-dim: '#73d2fd'
  on-secondary-fixed: '#001f2a'
  on-secondary-fixed-variant: '#004d65'
  tertiary-fixed: '#92f7c3'
  tertiary-fixed-dim: '#75daa8'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005235'
  background: '#f8faf6'
  on-background: '#191c1a'
  surface-variant: '#e1e3df'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The design system is built on the principles of environmental stewardship, operational efficiency, and civic trust. The target audience includes both municipal residents tracking their waste footprint and professional logistics operators managing collection routes.

The design style is **Corporate / Modern** with a strong emphasis on **Minimalism**. It utilizes expansive whitespace to reduce cognitive load in data-heavy environments, combined with a friendly, approachable character through soft geometry. The UI should evoke a sense of organized cleanliness, reliability, and proactive environmental care. Visual weight is prioritized for actionable data, while decorative elements are stripped back to ensure the interface feels lightweight and responsive.

## Colors

The palette is anchored in a spectrum of greens to reinforce the ecological focus. 
- **Primary (Eco-green):** Used for core branding, primary actions, and successful states.
- **Tertiary (Fresh-leaf):** Used for subtle backgrounds, secondary button states, and progress indicators.
- **Secondary (Clean-blue):** Specifically reserved for informational overlays, map markers, and data visualization related to logistics.
- **Accent (Alert-orange):** Used sparingly for high-priority notifications, missed collections, or critical tracking updates.
- **Neutrals:** A range of soft greys (Cool Grey 50-900) provides the structural scaffolding, ensuring the interface remains professional and legible.

## Typography

This design system utilizes **Inter** for all typography levels to ensure maximum legibility and a systematic, utilitarian feel. The type hierarchy is strictly enforced to guide users through complex tracking data.

Headlines use tighter letter-spacing and heavier weights to establish a firm visual anchor. Body text is optimized for readability with generous line heights. Labels use a medium weight to distinguish them from body content, and small labels are occasionally set in uppercase to denote category headers or metadata.

## Layout & Spacing

The system employs a **Fluid Grid** model based on an 8px square rhythm. 
- **Mobile:** 4-column grid with 16px side margins and 16px gutters.
- **Tablet:** 8-column grid with 24px side margins.
- **Desktop:** 12-column grid with a max-width of 1440px, centered on the viewport with 32px margins.

Spacing is applied through a mathematical scale (4, 8, 12, 16, 24, 32, 40, 48, 64). Components should favor `md` (24px) spacing for internal padding to maintain the "clean" and "airy" brand promise.

## Elevation & Depth

Hierarchy is established using **Tonal Layers** and **Ambient Shadows**. Instead of heavy borders, the design system uses surface color shifts to denote depth.

- **Level 0 (Base):** Neutral white or #F8F9FA.
- **Level 1 (Cards):** White surface with a very soft, diffused shadow (0px 4px 20px rgba(0,0,0,0.05)).
- **Level 2 (Modals/Popovers):** White surface with a more pronounced shadow (0px 10px 30px rgba(0,0,0,0.1)) and a subtle 1px border in a light grey tint.

Interactive elements use a slight vertical lift on hover to provide tactile feedback without appearing dated.

## Shapes

The shape language is consistently **Rounded**, using a base radius of 8px (0.5rem). 

- **Standard Elements (Buttons, Inputs, Small Cards):** 8px radius.
- **Large Containers (Feature Cards, Modals):** 16px (1rem) radius.
- **Interactive Pills (Chips, Status Tags):** Full pill (999px) radius.

This roundedness softens the technical nature of waste management data, making the app feel more accessible and user-friendly.

## Components

### Buttons
- **Primary:** Solid Eco-green with white text. 8px radius.
- **Secondary:** Ghost style with Eco-green border and text.
- **Tertiary:** Clean-blue text for inline actions.

### Inputs & Selects
Field backgrounds are a soft grey (#F1F3F5) with an 8px radius. On focus, they transition to a white background with a 2px Eco-green border.

### Status Chips
Used for tracking (e.g., "In Progress," "Collected," "Delayed"). These use low-saturation background tints of the primary/secondary/accent colors with high-saturation text of the same hue.

### Cards
Cards are the primary container for waste metrics and schedule items. They must feature a 16px padding and utilize the Level 1 shadow.

### Progress Bars
Used for waste goal tracking. Thick, rounded bars using Fresh-leaf for the "filled" state and a very light grey for the "track."

### Iconography
Icons should be 24px, linear (2px stroke), with slightly rounded terminals to match the font and shape language. Avoid filled icons unless used as a notification indicator.