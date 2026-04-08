# Design System Specification: The Architectural Ledger

## 1. Overview & Creative North Star
### Creative North Star: "The Editorial Vault"
This design system rejects the "utilitarian app" aesthetic in favor of a high-end, editorial experience. We are moving away from the crowded, grid-heavy layouts typical of retail banking. Instead, we embrace **The Editorial Vault**: a philosophy where financial management feels like navigating a premium digital journal. 

We break the "template" look through:
*   **Intentional Asymmetry:** Off-setting headers and using generous whitespace to guide the eye.
*   **Tonal Depth:** Replacing harsh lines with sophisticated, layered surfaces.
*   **Authoritative Typography:** Using dramatic scale contrasts to create a clear information hierarchy that feels curated, not just displayed.

## 2. Visual Language: Colors & Surfaces

### The Color Palette (Material Logic)
The palette is rooted in the heritage of `primary` Red and `secondary` Navy, but expanded into a spectrum of "functional tones" to ensure the UI feels modern and balanced.

*   **Primary (The Pulse):** `#b5000b` (Primary) & `#e30613` (Container). Use these for high-intent actions.
*   **Secondary (The Foundation):** `#416182` (Secondary) & `#002A48` (On-Secondary-Fixed). This navy provides the "Trust" anchor.
*   **Tertiary (The Accent):** `#0059a8`. Used for informational highlights and secondary data visualizations.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to define sections. Layout boundaries must be achieved through:
1.  **Background Shifts:** Placing a `surface-container-low` component against a `surface` background.
2.  **Negative Space:** Using the spacing scale to create "invisible" gutters.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Each layer deeper should signify a more focused task.
*   **Base:** `surface` (#f9f9fc)
*   **Sectioning:** `surface-container-low` (#f3f3f6)
*   **Actionable Cards:** `surface-container-lowest` (#ffffff) – This creates a soft, natural "pop" against the gray base.

### The "Glass & Gradient" Rule
To elevate the experience, use **Glassmorphism** for floating elements (like bottom navigation bars or modal headers). Use `surface` colors at 80% opacity with a `20px` backdrop-blur. 
*   **Signature Texture:** Main CTAs should use a subtle linear gradient from `primary` (#b5000b) to `primary_container` (#e30613) at a 135° angle to add "soul" and dimension.

## 3. Typography: The Voice of Authority
We utilize a dual-font system to balance character with utility.

| Category | Token | Font | Size | Weight | Character |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Manrope | 3.5rem | 700 | Editorial, Bold |
| **Headline** | `headline-md`| Manrope | 1.75rem | 600 | Confident, Secure |
| **Title** | `title-md` | Inter | 1.125rem | 500 | Modern, Clean |
| **Body** | `body-lg` | Inter | 1rem | 400 | Highly Legible |
| **Label** | `label-md` | Inter | 0.75rem | 600 | Functional, Sharp |

**The Hierarchy Strategy:** Use `Manrope` for all high-level branding and balance statements to convey a premium "Magazine" feel. Use `Inter` for all transactional data and form fields to ensure absolute clarity.

## 4. Elevation & Depth: Tonal Layering

### The Layering Principle
Avoid the "flat" look by stacking container tiers.
*   **Example:** A `surface-container-highest` navigation header over a `surface-container-low` body. This creates an immediate sense of structure without a single divider line.

### Ambient Shadows
Shadows are a last resort. When used (e.g., for a floating "Send Money" button), they must be **Ambient**:
*   **Color:** `on-surface` (#1a1c1e) at 6% opacity.
*   **Blur:** 24px - 32px.
*   **Offset:** Y: 8px.
This mimics natural light hitting a matte surface rather than a digital "drop shadow."

### The "Ghost Border"
If a container requires a border for accessibility (e.g., on a white background), use the **Ghost Border**: `outline-variant` (#e9bcb6) at 15% opacity. It should be felt, not seen.

## 5. Signature Components

### Secure Inputs & Numeric Keypads
*   **Input Fields:** Use `surface-container-highest` for the field background. When focused, the "Ghost Border" transitions to a 2px `primary` red stroke.
*   **Numerical Keypad:** Large, circular keys (`rounded-full`). Numbers in `display-sm` (Manrope). Use `surface-container-low` for key backgrounds to create a tactile, physical feel.
*   **Masking:** Use a custom "Dot" glyph for PIN entry rather than standard asterisks to maintain the high-end aesthetic.

### Buttons (The BCP Signature)
*   **Primary:** High-radius (`xl` or `full`). Gradient fill (Primary to Primary-Container). No border.
*   **Secondary:** Navy (`secondary`) text on a `secondary_container` (#b7d8fe) background. High-radius.
*   **Tertiary:** No background. Bold `secondary` text with an icon.

### Cards & Lists
*   **Forbid Dividers:** Do not use horizontal lines. Use `1.5rem` (xl) vertical spacing between items or alternate between `surface-container-low` and `surface-container-lowest` to distinguish list items.

### Contextual Components
*   **The "Safety Shield" Toast:** A success/error notification using a semi-transparent glass background with high-contrast `on-error` or `on-primary` text.
*   **Wealth Progress Bar:** A custom-designed progress indicator using a gradient from `tertiary` to `secondary` to show savings goals.

## 6. Do’s and Don'ts

### Do
*   **DO** use Manrope for large currency values to make them feel "expensive."
*   **DO** leave at least 24px of horizontal padding on all screens to maintain an editorial "margin."
*   **DO** use `surface_tint` at 5% opacity as an overlay for cards to give them a subtle warmth.

### Don't
*   **DON'T** use 100% black. Use `on-surface` (#1a1c1e) for all text to keep the UI soft and sophisticated.
*   **DON'T** use sharp corners. Every actionable element must utilize the `rounded-md` (0.75rem) or `rounded-xl` (1.5rem) scale.
*   **DON'T** use standard "Success Green." Use the `tertiary` Blue for success states to maintain the brand’s color integrity, reserving Red only for critical errors.