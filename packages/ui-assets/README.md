# UI Assets

Shared design assets and tokens used across web and iOS platforms.

## Color Palette

```
Primary: #6f8bff (indigo blue)
Primary Accent: #E6FDA3 (lime yellow)
Background: #ffffff (white) / #111827 (dark)
Text: #111827 (gray-900) / #ffffff (white)
Border: rgba(0,0,0,0.1) / rgba(255,255,255,0.1)
```

### Semantic Colors
- Success: #065f46 (emerald-800)
- Error: #dc2626 (red-600)
- Warning: #f59e0b (amber-500)
- Info: #3b82f6 (blue-500)

## Typography

**Primary Font**: EB Garamond
- Headings: 600 weight
- Body: 400 weight
- Display: 700 weight

**Font Sizes**:
- xs: 12px
- sm: 14px
- base: 16px
- lg: 18px
- xl: 20px
- 2xl: 24px

## Spacing Scale

- 1: 0.25rem (4px)
- 2: 0.5rem (8px)
- 3: 0.75rem (12px)
- 4: 1rem (16px)
- 6: 1.5rem (24px)
- 8: 2rem (32px)

## Component Styles

### Buttons
**Primary Button** (`.btn-primary`):
- Background: #6f8bff
- Text: #ffffff
- Padding: 0.5rem 1rem
- Border radius: 0.375rem
- Font weight: 500

**Secondary Button** (`.btn`):
- Background: transparent
- Border: 1px solid rgba(0,0,0,0.1)
- Padding: 0.5rem 1rem
- Border radius: 0.375rem

### Inputs
- Border: 1px solid rgba(0,0,0,0.1)
- Padding: 0.5rem
- Border radius: 0.375rem
- Focus ring: 2px #6f8bff

### Cards
- Background: #ffffff
- Border: 1px solid rgba(0,0,0,0.1)
- Border radius: 0.5rem
- Shadow: sm

## Icons & Images

Logo: `restaurantsplit-high-resolution-logo.png`
- Used in header and export
- Transparent background
- Square aspect ratio

## Platform-Specific Notes

### Web
- Uses Tailwind CSS utility classes
- CSS variables for theming
- Dark mode via `dark:` variants

### iOS
- Use SwiftUI Asset Catalog for colors
- Custom `.ttf` font file for EB Garamond
- SF Symbols where appropriate
- Adapt corner radius to iOS standards (typically slightly larger)

