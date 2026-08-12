package main

import (
	"database/sql"
	"encoding/json"
	"time"

	_ "modernc.org/sqlite"
)

type Schedule struct {
	ID      int64           `json:"id"`
	FireAt  int64           `json:"fireAt"`
	State   *string         `json:"state"`
	Mode    *string         `json:"mode"`
	Fan     *string         `json:"fan"`
	SetTemp *float64        `json:"setTemp"`
	Zones   json.RawMessage `json:"zones"`
	FiredAt *int64          `json:"firedAt"`
}

type AppError struct {
	ID         int64  `json:"id"`
	OccurredAt int64  `json:"occurredAt"`
	Source     string `json:"source"`
	Message    string `json:"message"`
}

func initDB(path string) *sql.DB {
	db, err := sql.Open("sqlite", path+"?_journal_mode=WAL")
	if err != nil {
		panic(err)
	}
	db.SetMaxOpenConns(1)
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS schedules (
			id       INTEGER PRIMARY KEY AUTOINCREMENT,
			fire_at  INTEGER NOT NULL,
			state    TEXT,
			mode     TEXT,
			fan      TEXT,
			set_temp REAL,
			zones    TEXT,
			fired_at INTEGER
		);
		CREATE TABLE IF NOT EXISTS errors (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			occurred_at INTEGER NOT NULL,
			source      TEXT NOT NULL,
			message     TEXT NOT NULL
		);
	`)
	if err != nil {
		panic(err)
	}
	return db
}

func insertSchedule(db *sql.DB, s Schedule) (Schedule, error) {
	var zones any
	if len(s.Zones) > 0 {
		zones = string(s.Zones)
	}
	res, err := db.Exec(
		`INSERT INTO schedules (fire_at, state, mode, fan, set_temp, zones) VALUES (?, ?, ?, ?, ?, ?)`,
		s.FireAt, s.State, s.Mode, s.Fan, s.SetTemp, zones,
	)
	if err != nil {
		return Schedule{}, err
	}
	s.ID, _ = res.LastInsertId()
	return s, nil
}

func listSchedules(db *sql.DB) ([]Schedule, error) {
	rows, err := db.Query(`SELECT id, fire_at, state, mode, fan, set_temp, zones, fired_at FROM schedules`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Schedule
	for rows.Next() {
		var s Schedule
		var zones []byte
		if err := rows.Scan(&s.ID, &s.FireAt, &s.State, &s.Mode, &s.Fan, &s.SetTemp, &zones, &s.FiredAt); err != nil {
			return nil, err
		}
		s.Zones = json.RawMessage(zones)
		out = append(out, s)
	}
	return out, rows.Err()
}

func deleteSchedule(db *sql.DB, id int64) error {
	_, err := db.Exec(`DELETE FROM schedules WHERE id = ?`, id)
	return err
}

func deletePastSchedules(db *sql.DB) error {
	_, err := db.Exec(`DELETE FROM schedules WHERE fired_at IS NOT NULL`)
	return err
}

func pendingSchedules(db *sql.DB, now int64) ([]Schedule, error) {
	rows, err := db.Query(
		`SELECT id, fire_at, state, mode, fan, set_temp, zones, fired_at FROM schedules WHERE fired_at IS NULL AND fire_at <= ?`,
		now,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Schedule
	for rows.Next() {
		var s Schedule
		var zones []byte
		if err := rows.Scan(&s.ID, &s.FireAt, &s.State, &s.Mode, &s.Fan, &s.SetTemp, &zones, &s.FiredAt); err != nil {
			return nil, err
		}
		s.Zones = json.RawMessage(zones)
		out = append(out, s)
	}
	return out, rows.Err()
}

func markFired(db *sql.DB, id int64, now int64) error {
	_, err := db.Exec(`UPDATE schedules SET fired_at = ? WHERE id = ?`, now, id)
	return err
}

func logError(db *sql.DB, source, message string) error {
	_, err := db.Exec(
		`INSERT INTO errors (occurred_at, source, message) VALUES (?, ?, ?)`,
		time.Now().Unix(), source, message,
	)
	return err
}

func listErrors(db *sql.DB) ([]AppError, error) {
	rows, err := db.Query(`SELECT id, occurred_at, source, message FROM errors ORDER BY occurred_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []AppError
	for rows.Next() {
		var e AppError
		if err := rows.Scan(&e.ID, &e.OccurredAt, &e.Source, &e.Message); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}
