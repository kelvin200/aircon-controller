# zones-grid Specification

## Purpose

Defines the zone grid: a compact, glanceable grid of the 9 fixed zones where each cell shows the zone name and its current damper value as a number, coloured when active and dimmed when inactive, with a gradient background, tap-to-toggle open/close, and a long-press value slider.

## Requirements

### Requirement: Zones render as a grid of cells

The app SHALL render all 9 fixed zones as a responsive grid, one cell per zone, where each cell shows the zone name and its current damper value as a number.

#### Scenario: Grid renders all nine zones
- **WHEN** the Status screen is displayed with a loaded status and the system is on
- **THEN** all 9 zones appear as cells in a grid, each cell showing the zone name and the current value as a number

#### Scenario: Cells fit the screen width
- **WHEN** the grid is laid out on the phone
- **THEN** cells are sized so multiple cells fit per row and the whole grid fits the available width without horizontal scrolling

### Requirement: Active and inactive cell styling

An open (active) zone's cell SHALL use the full accent colour; a closed (inactive) zone's cell SHALL use a disabled, dimmed colour.

#### Scenario: Active zone is fully coloured
- **WHEN** a zone is open
- **THEN** its cell is rendered with the full accent colour

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

### Requirement: Grid disabled when the system is off

When the system power is off, the zone grid SHALL render in a disabled state and cells SHALL NOT respond to tap or long-press.

#### Scenario: Grid is inert while off
- **WHEN** the system power is off and the user taps or long-presses a zone cell
- **THEN** no command is sent and the cell's appearance stays disabled

#### Scenario: Grid re-enables when power returns
- **WHEN** the system power turns on
- **THEN** the grid re-enables and cells respond to tap and long-press again
