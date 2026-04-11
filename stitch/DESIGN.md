# Design System Specification: High-End Community Editorial

## 1. Overview & Creative North Star
This design system is built upon the **"Organic Sanctuary"** North Star. We are moving away from the rigid, boxed-in aesthetics of traditional community apps to create a digital environment that feels breathable, premium, and editorially curated. 

While the original inspiration uses a vibrant green, we are elevating it through a sophisticated tonal system. By utilizing intentional asymmetry, varying typographic scales, and layered surfaces, we break the "template" look. The goal is to provide a sense of professional warmth where users feel they are entering a high-end club rather than a generic social feed.

---

## 2. Colors
Our color palette centers on the primary green, but expands it into a comprehensive functional range.

### Tonal Foundations
- **Primary (`#006b1b`):** Used for key actions and brand identity.
- **Surface (`#ddffe2`):** Our main background color. It is a soft, tinted neutral that feels more organic than pure white.
- **The "No-Line" Rule:** To achieve a premium look, **1px solid borders are prohibited** for sectioning. Boundaries must be defined through background color shifts. For example, a card should be `surface-container-lowest` placed on a `surface` background.
- **Surface Hierarchy & Nesting:** Treat the UI as a series of physical layers.
    - **Backdrop:** `surface`
    - **Sectioning:** `surface-container-low`
    - **Cards/Floating Elements:** `surface-container-lowest`
- **The "Glass & Gradient" Rule:** For floating navigation or high-impact hero sections, use a Glassmorphism effect: `surface` color at 80% opacity with a `backdrop-filter: blur(20px)`. 
- **Signature Textures:** Use subtle linear gradients for CTAs, transitioning from `primary` to `primary-dim`. This adds depth and "soul" that flat fills cannot replicate.

---

## 3. Typography
We utilize a dual-typeface system to balance authority with readability.

*   **Display & Headlines (Plus Jakarta Sans):** A modern, geometric sans-serif with a premium feel. Use `display-lg` and `headline-md` for community titles to create a bold, editorial presence.
*   **Body & Labels (Manrope):** A highly legible font designed for digital interfaces. Manrope’s open counters ensure that community discussions remain accessible even at `body-sm` sizes.

**Hierarchy Strategy:** 
- Use high contrast in scale. A `headline-lg` title paired with a `body-md` description creates an intentional, magazine-style layout.
- Always use `on-surface-variant` for secondary metadata (like dates or view counts) to keep the visual focus on the primary message.

---

## 4. Elevation & Depth
Depth is achieved through **Tonal Layering** rather than structural lines.

*   **The Layering Principle:** Stacking surface tiers creates a natural lift. A `surface-container-highest` element feels "closer" to the user than a `surface-container` element.
*   **Ambient Shadows:** For elements that require a floating state (like the FAB or active cards), use an extra-diffused shadow.
    - **Values:** `0px 12px 32px`
    - **Color:** Use `on-surface` at 6% opacity. This mimics natural light rather than creating a muddy grey smudge.
*   **The "Ghost Border" Fallback:** If a container lacks contrast against its background, use a "Ghost Border": `outline-variant` at 15% opacity. Never use 100% opaque borders.
*   **Glassmorphism:** Apply to the bottom navigation bar and top headers. Use `surface-bright` at 70% opacity with a blur to allow the vibrant background colors to bleed through, softening the interface edges.

---

## 5. Components

### Buttons
- **Primary:** Rounded `full`. Gradient from `primary` to `primary_dim`. Text in `on_primary`.
- **Secondary:** Surface-tinted. No border. Use `primary_container` background with `on_primary_container` text.
- **States:** On hover/press, shift the gradient intensity rather than adding a dark overlay.

### Cards & Lists
- **Rule:** **No divider lines.** 
- **Structure:** Separate list items using `1.5rem` of vertical white space or by placing each item in a `surface-container-low` pod.
- **Corners:** Use `xl` (1.5rem) for main feed cards to emphasize the "soft and friendly" atmosphere.

### Inputs & Fields
- **Styling:** Use `surface_container_high` as the background fill. 
- **Active State:** Instead of a heavy border, use a 2px `primary` bottom-bar or a subtle glow using `surface_tint`.

### Chips
- **Filter Chips:** Use `surface-container-highest` with `label-md` typography. When selected, transition to `primary` with `on-primary` text.

### Community Specific: "The Contribution Thread"
- To distinguish user-generated content, use an asymmetrical layout where the user's avatar hangs slightly off the left edge of the card, breaking the vertical grid line for a custom, high-end feel.

---

## 6. Do's and Don'ts

### Do:
- **Do** use whitespace as a functional tool. If elements feel crowded, increase the gap rather than adding a line.
- **Do** use `primary_fixed` for accent highlights in text to draw the eye to key community links.
- **Do** ensure all interactive elements have a minimum touch target of 44x44dp, regardless of their visual size.

### Don't:
- **Don't** use pure black `#000000` for text. Always use `on-surface` (`#0b361d`) to maintain the organic, green-tinted atmosphere.
- **Don't** use standard Material Design "Drop Shadows." Stick to the ambient, low-opacity tinted shadows defined in Section 4.
- **Don't** use the `none` roundedness setting. Every element, including images, should have at least `sm` corner smoothing to fit the "Organic Sanctuary" aesthetic.