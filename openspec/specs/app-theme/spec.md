# app-theme Specification

## Purpose

Defines the visual design system for the Android app: a near-black navy canvas with a subtle square grid, layered charcoal surfaces with hairline borders, a restrained set of vivid accent colours, gradient primary actions, and a compact status pill component — establishing a polished dark developer-tool aesthetic.

## Requirements

### Requirement: Dark navy canvas with subtle grid pattern

The app SHALL render all screens on a near-black navy canvas overlaid with a subtle square grid pattern, with no heavy shadows.

#### Scenario: App renders on the dark canvas
- **WHEN** any screen is displayed
- **THEN** the background is a near-black navy colour and a faint square grid pattern is visible across the full canvas

#### Scenario: Depth comes from layered tones
- **WHEN** a panel sits on the canvas
- **THEN** depth between the panel and the canvas is established by layered background tones and thin outlines rather than drop shadows

### Requirement: Charcoal panel surfaces with hairline borders

Interactive and informational panels SHALL use low-contrast charcoal fills, crisp 1px borders, and soft corner radii between 12 and 20 px.

#### Scenario: Panels are rounded and outlined
- **WHEN** a card or panel is rendered
- **THEN** it has a charcoal-toned fill, a thin hairline border, and a corner radius between 12 and 20 px

### Requirement: Vivid accents applied sparingly

The palette SHALL use coral-red for the product identity and warnings, and electric blue, violet, cyan, orange, and green for status and category accents, applied sparingly so the dark canvas stays dominant.

#### Scenario: Accent colours map to meaning
- **WHEN** a status or category is shown
- **THEN** its accent colour comes from the fixed set (coral, blue, violet, cyan, orange, green) and is applied to small elements (icons, dots, active states), not large filled areas

### Requirement: Gradient primary actions

Primary action buttons SHALL use a pink-to-purple gradient fill with a light icon; destructive actions SHALL use a transparent red fill with a red border.

#### Scenario: Primary action is a gradient
- **WHEN** the primary action button (such as the add-schedule button) is rendered
- **THEN** it has a pink-to-purple gradient background and a white/light icon

#### Scenario: Destructive action is outlined red
- **WHEN** a destructive action (such as delete) is rendered
- **THEN** it uses a transparent red fill and a red border

### Requirement: Typography hierarchy

Text SHALL use a clean sans-serif with off-white headings, cool-grey body copy, tiny uppercase section labels, and monospace styling for numeric values, IDs, and codes, with a clear size hierarchy.

#### Scenario: Section labels are uppercase and tiny
- **WHEN** a section heading label is shown above a group of controls
- **THEN** it is a small, uppercase, letter-spaced label in a muted colour

#### Scenario: Numeric values use monospace
- **WHEN** a temperature, damper percentage, or ID is displayed
- **THEN** it is rendered in a monospace face, visually distinct from prose text

### Requirement: Compact outlined status pills

Statuses SHALL render as compact outlined pills with a coloured dot and a short label, such as On, Off, Cool, or an error state.

#### Scenario: Status renders as a pill
- **WHEN** the current system state or a per-item status is shown
- **THEN** it appears as a compact outlined pill with a coloured dot and a short label

#### Scenario: Pill colour reflects the status
- **WHEN** the status changes (for example from Off to On, or to an error)
- **THEN** the pill's dot and outline colour update to match the new status
