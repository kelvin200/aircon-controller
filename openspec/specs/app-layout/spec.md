# app-layout Specification

## Purpose

Defines the app chrome and screen organisation for the redesigned UI: a compact header with app identity and a live system status, a restyled Android-idiomatic navigation with a tinted active state, and a card-based layout for the Status screen that groups power, temperature, mode/fan, and zones into distinct sections.

## Requirements

### Requirement: Header with app identity and live status

The app SHALL show a compact header at the top of the screen containing the app identity and a live system status pill that reflects the current power state.

#### Scenario: Header shows identity and state
- **WHEN** the app is open
- **THEN** the header shows the app identity on one side and a system status pill (for example On / Off) that reflects the current state from the latest status fetch

#### Scenario: Status pill updates with state
- **WHEN** the power state changes (toggled on or off, or changed by a schedule)
- **THEN** the header's status pill updates to the new state on the next status refresh

### Requirement: Restyled navigation with tinted active state

Navigation SHALL expose the three top-level areas (Status, Schedules, Errors) using an Android-idiomatic bottom bar restyled to the dark theme, with the active destination clearly tinted.

#### Scenario: Active destination is tinted
- **WHEN** a destination is selected
- **THEN** it is rendered with a distinct tinted highlight against the dark theme, clearly distinguishable from the unselected destinations

### Requirement: Status screen organised into cards

The Status screen SHALL organise its content into large rounded cards with generous padding: a power card (power switch and system status), a temperature card, a mode & fan card, and a zones card.

#### Scenario: Status content is grouped into cards
- **WHEN** the Status screen is displayed with a loaded status
- **THEN** power, temperature, mode & fan, and zones each appear as a separate card section with clear internal padding

#### Scenario: All sections remain reachable
- **WHEN** the content is taller than the screen
- **THEN** the screen scrolls so every card section remains reachable

### Requirement: Schedules and Errors screens use the shared theme

The Schedules and Error Log screens SHALL use the shared dark theme, card lists, status pills, and gradient primary action in place of the current default styling.

#### Scenario: Schedule list renders as dark cards
- **WHEN** the Schedules screen is displayed
- **THEN** schedule entries render as outlined cards with pill-styled status details and a gradient floating action button for adding a schedule

#### Scenario: Error log renders as dark cards
- **WHEN** the Error Log screen is displayed
- **THEN** error entries render as outlined cards with a source badge/pill and the timestamp and message in the shared typography
