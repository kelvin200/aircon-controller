package main

import (
	"database/sql"
	"path/filepath"
	"testing"
)

func newTestDB(t *testing.T) *sql.DB {
	t.Helper()
	dir := t.TempDir()
	db := initDB(filepath.Join(dir, "test.db"))
	t.Cleanup(func() { db.Close() })
	return db
}

func TestDeleteAllErrorsClearsRows(t *testing.T) {
	db := newTestDB(t)
	if err := logError(db, "handler", "boom"); err != nil {
		t.Fatalf("seed error: %v", err)
	}
	if err := logError(db, "scheduler", "bang"); err != nil {
		t.Fatalf("seed error: %v", err)
	}
	if errs, _ := listErrors(db); len(errs) != 2 {
		t.Fatalf("expected 2 seeded errors, got %d", len(errs))
	}
	if err := deleteAllErrors(db); err != nil {
		t.Fatalf("deleteAllErrors: %v", err)
	}
	if errs, _ := listErrors(db); len(errs) != 0 {
		t.Fatalf("expected 0 errors after clear, got %d", len(errs))
	}
}

func TestGetScheduleReturnsNilWhenMissing(t *testing.T) {
	db := newTestDB(t)
	s, err := getSchedule(db, 999)
	if err != nil {
		t.Fatalf("getSchedule: %v", err)
	}
	if s != nil {
		t.Fatalf("expected nil for missing schedule, got %#v", s)
	}
}

func TestTriggerDeletesSchedule(t *testing.T) {
	db := newTestDB(t)
	created, err := insertSchedule(db, Schedule{FireAt: 1, State: ptrStr("on")})
	if err != nil {
		t.Fatalf("insert: %v", err)
	}
	got, err := getSchedule(db, created.ID)
	if err != nil {
		t.Fatalf("getSchedule: %v", err)
	}
	if got == nil || got.State == nil || *got.State != "on" {
		t.Fatalf("unexpected schedule %#v", got)
	}
	if err := deleteSchedule(db, created.ID); err != nil {
		t.Fatalf("deleteSchedule: %v", err)
	}
	after, _ := getSchedule(db, created.ID)
	if after != nil {
		t.Fatalf("expected schedule gone after delete, got %#v", after)
	}
}

func ptrStr(s string) *string { return &s }
