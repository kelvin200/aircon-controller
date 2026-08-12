# zone-control Specification

## Purpose

Defines how the app displays the nine zones and lets the user toggle each zone open or closed and change its set temperature.

## Requirements

### Requirement: Display all zones
The app SHALL display all 9 zones on the Zones screen with each zone's name, open/close state, set temperature, and measured temperature (when available).

#### Scenario: Zones screen loads
- **WHEN** the user opens the Zones screen
- **THEN** the app fetches `/status` and renders all 9 zones showing name, state, setTemp, and measuredTemp (only if measuredTemp > 0.0)

### Requirement: Toggle zone open/close
The app SHALL allow the user to open or close any zone individually.

#### Scenario: Open a zone
- **WHEN** the user taps the toggle for a closed zone
- **THEN** the app POSTs `{"state":"open"}` to `/zones/{zoneId}` and refreshes

#### Scenario: Close a zone
- **WHEN** the user taps the toggle for an open zone
- **THEN** the app POSTs `{"state":"close"}` to `/zones/{zoneId}` and refreshes

### Requirement: Change zone set temperature
The app SHALL allow the user to change the set temperature for an individual zone.

#### Scenario: Adjust zone temperature
- **WHEN** the user changes the temperature for a zone
- **THEN** the app POSTs `{"setTemp":<value>}` to `/zones/{zoneId}` and refreshes
