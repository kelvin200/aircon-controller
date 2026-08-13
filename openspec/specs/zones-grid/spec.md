# zones-grid Specification

## Purpose

Defines the zone grid: a compact, glanceable grid of the 9 fixed zones where each cell shows the zone name and its current damper value as a number, coloured when active and dimmed when inactive, with a gradient background, tap-to-toggle open/close, and a long-press value slider.

## Requirements

### Requirement: Zones render as a grid of cells

The app SHALL render all 9 fixed zones on a dedicated Zones page (not inside the Status screen) as a responsive grid, one cell per zone, where each cell shows the zone name and its current damper value as a number. The zone name SHALL be the display name supplied by the backend status payload for that zone; the app SHALL NOT contain any hardcoded identifying zone-name constants in source or tests.

#### Scenario: Grid renders all nine zones
- **WHEN** the Zones page is displayed with a loaded status
- **THEN** all 9 zones appear as cells in a grid, each cell showing the zone name and the current value as a number, where the name is taken from the backend status payload

#### Scenario: Cells fit the screen width
- **WHEN** the grid is laid out on the phone
- **THEN** cells are sized so multiple cells fit per row and the whole grid fits the available width without horizontal scrolling

#### Scenario: No identifying names are committed
- **WHEN** the source tree is inspected, including tests and committed configuration
- **THEN** no real/private zone names appear as hardcoded constants (a generic fallback such as the zone id is used when a name is unavailable)

### Requirement: Active and inactive cell styling

An open (active) zone's cell SHALL use the full accent colour; a closed (inactive) zone's cell SHALL use a disabled, dimmed colour.

When the system is **on**, the accent is the current mode accent colour. When the system is **off**, the accent is black.

#### Scenario: Active zone is fully coloured
- **WHEN** a zone is open
- **THEN** its cell is rendered with the full accent colour

#### Scenario: Active zone uses mode accent when on
- **WHEN** the system is on and a zone is open
- **THEN** its cell is rendered with the full mode accent colour

#### Scenario: Active zone uses black accent when off
- **WHEN** the system is off and a zone is open
- **THEN** its cell is rendered with black as the accent colour, clearly distinct from the dimmed inactive cells

#### Scenario: Inactive zone is dimmed
- **WHEN** a zone is closed
- **THEN** its cell is rendered in a disabled, dimmed colour clearly distinct from an active cell

### Requirement: Gradient grid background

The zone grid SHALL render on a gradient background — a gradient across the whole grid where feasible, otherwise a per-cell gradient.

#### Scenario: Grid shows a gradient
- **WHEN** the zone grid is displayed
- **THEN** the grid background is a gradient (whole-grid or per-cell) rather than a flat fill

### Requirement: Tap toggles zone open/close

Tapping a zone cell SHALL toggle that zone between open and close by sending the corresponding zone command, and the cell's styling SHALL update to reflect the new state.

#### Scenario: Tap closes an open zone
- **WHEN** the user taps an active (open) zone cell
- **THEN** the app sends a close command for that zone and the cell updates to the inactive styling

#### Scenario: Tap opens a closed zone
- **WHEN** the user taps an inactive (closed) zone cell
- **THEN** the app sends an open command for that zone and the cell updates to the active styling

#### Scenario: Toggle failure reverts the cell
- **WHEN** a toggle command fails
- **THEN** the cell reverts to its previous styling

### Requirement: Long-press reveals a value slider

Long-pressing a zone cell SHALL reveal a slider (0–100) for adjusting that zone's damper value; adjusting and committing the slider SHALL send a value command for that zone.

#### Scenario: Long-press reveals the slider
- **WHEN** the user long-presses a zone cell
- **THEN** a slider for that zone's value (0–100) appears, pre-filled with the zone's current value

#### Scenario: Slider commit sends the value
- **WHEN** the user finishes adjusting the slider
- **THEN** the app sends the new value command for that zone and the cell's number updates to the new value

#### Scenario: Value command failure reverts the number
- **WHEN** a value command fails
- **THEN** the cell's displayed value reverts to its previous value

### Requirement: Zones are always interactive

Zone cells SHALL respond to tap and long-press whether the system is on or off, so the user can stage zone open/close and damper values before (or without) turning the system on.

#### Scenario: Tap toggles a zone while the system is off
- **WHEN** the system is off and the user taps a zone cell
- **THEN** the app sends the corresponding zone command and the cell updates to reflect the new state

#### Scenario: Long-press reveals the slider while the system is off
- **WHEN** the system is off and the user long-presses a zone cell
- **THEN** the value slider appears and commits a value command when adjusted
