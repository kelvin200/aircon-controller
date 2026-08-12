# system-status Specification

## Purpose

Defines how the app displays the current system state and lets the user control power, mode, fan speed, and set temperature.

## Requirements

### Requirement: Display current system state
The app SHALL fetch and display the current AC state on the Status screen: power (on/off), mode (heat/cool/vent/dry), fan speed (low/medium/high), and set temperature.

#### Scenario: Status screen loads
- **WHEN** the user opens the Status screen
- **THEN** the app fetches `/status` and displays power state, mode, fan speed, and set temperature

#### Scenario: Temperature colour reflects mode
- **WHEN** the status is displayed
- **THEN** the set temperature text is blue for cool, orange for heat, green for vent, and grey for dry or off

### Requirement: Toggle system power
The app SHALL allow the user to turn the AC on or off from the Status screen.

#### Scenario: Power off
- **WHEN** the user taps the power toggle while the system is on
- **THEN** the app POSTs `{"state":"off"}` to `/system` and refreshes

#### Scenario: Power on
- **WHEN** the user taps the power toggle while the system is off
- **THEN** the app POSTs `{"state":"on"}` to `/system` and refreshes

### Requirement: Change mode
The app SHALL allow the user to select a mode (heat/cool/vent/dry) from the Status screen.

#### Scenario: Select mode
- **WHEN** the user selects a mode
- **THEN** the app POSTs `{"state":"on","mode":"<selected>"}` to `/system` and refreshes

### Requirement: Change fan speed
The app SHALL allow the user to select fan speed (low/medium/high) from the Status screen.

#### Scenario: Select fan speed
- **WHEN** the user selects a fan speed
- **THEN** the app POSTs `{"fan":"<speed>"}` to `/system` and refreshes

### Requirement: Change set temperature
The app SHALL allow the user to adjust the set temperature from the Status screen.

#### Scenario: Adjust temperature
- **WHEN** the user increments or decrements the temperature
- **THEN** the app POSTs `{"setTemp":<value>}` to `/system` and refreshes
