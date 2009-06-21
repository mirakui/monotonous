CREATE TABLE IF NOT EXISTS schedules (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  status_id INTEGER UNIQUE,
  posted_at DATETIME,
  status TEXT
);

CREATE TABLE IF NOT EXISTS vars (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  key VARCHAR(100) UNIQUE,
  value TEXT
);
