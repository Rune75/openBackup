# Product Requirements Document (PRD)

## Product Name: OpenBackup

### 1. Overview

OpenBackup is a lightweight, snapshot-style backup system built upon standard UNIX utilities, primarily `rsync` and `cp -al`. Leveraging Linux hard links, it creates complete daily and weekly folder structures of backed-up data without duplicating file sizes on disk. It maintains up to a year of historical state, providing disaster recovery options at varying points in time while being highly space-efficient.

### 2. Objectives

- Provide a silent and reliable rotating point-in-time recovery backup process.
- Minimize required disk space through hard link deduplication.
- Establish a long-term retention history (7 daily snapshots, 52 weekly snapshots).
- Keep backups in sync with sources by removing deleted files via `rsync --delete`.
- Provide the system administrator with email alerts regarding unexpected data modifications.

### 3. Core Features

#### 3.1. Synchronization and Hard Linking

- Utilizes `rsync --delete` to synchronize source directories directly to the newest daily target (`0_days`), copying only changed files and removing files that no longer exist in the source.
- Uses `cp -al` (archive and hard link mode) between position arrays. Files inside old array positions that have not changed will remain hard-linked to the new ones recursively, ensuring that duplicated data does not consume extra disk capacity.

#### 3.2. Daily & Weekly Retention Cycles

- **Daily Rotation (7 Days)**: Maintains a rolling window structure named `0_days` through `6_days`. The system shifts each snapshot folder forward by one position daily (e.g., `5_days` → `6_days`). The oldest daily record (`6_days`) is disposed of each cycle unless preserved in the weekly rotation. A hard-link copy of `0_days` is created as `1_days` before the new sync runs.
- **Weekly Rotation (52 Weeks)**: On Sundays (`day == 0`), before the daily rotation, the oldest daily snapshot (`6_days`) is hard-link copied into `1_weeks`, and all previous weekly snapshots are shifted up, with the oldest (`52_weeks`) being disposed of.

#### 3.3. Change Verification and Alerting

- Logs the full `rsync` output to a daily log file (`Day_<N>.log`, where N is the day of week 0–6).
- Parses the log line count via `wc -l` to detect meaningful changes.
- Triggers an email alert when the log exceeds 4 lines (indicating actual file changes beyond the standard `rsync` summary).
- Email is sent via `mailx -A gmail`, which must be pre-configured with a valid mail account.

#### 3.4. Configuration via `backup_folders.txt`

- The source directories to back up are defined in a `backup_folders.txt` file located in the backup destination directory.
- This file is read at runtime via `cat` and its contents are passed as arguments to `rsync`.
- Each line should contain an absolute path to a source directory.

### 4. Technical Architecture

OpenBackup is shell-driven and consists of two scripts operating in sequence.

#### Project Structure

```
openBackup/
├── README.md
├── LICENSE
├── src/
│   ├── backup.sh          # Main backup script
│   └── backup_roll.sh     # Daily/weekly rotation script
└── spec/
    └── PRD.md             # This document
```

#### Script Roles

- **[`src/backup.sh`](../src/backup.sh)**: The main entry point. Takes a backup target directory as its sole argument. Calls the rotation script, runs `rsync` to synchronize source data into `daily/0_days/`, writes a daily log, and sends an email alert if changes are detected.
- **[`src/backup_roll.sh`](../src/backup_roll.sh)**: The rotation orchestrator. Manages structural folder movements (`mv`) and handles chronological organization for both `daily/` and `weekly/` arrays. Automatically creates required directories on first run.

> **Note**: `backup.sh` currently expects `backup_roll.sh` to be installed at `/usr/local/bin/backup_roll.sh`.

#### Resulting Directory Layout

After running, the backup destination will contain:

```
/path/to/backup_destination/
├── backup_folders.txt       # Source folder configuration
├── Day_<N>.log              # Daily rsync log (N = day of week, 0-6)
├── daily/
│   ├── 0_days/              # Latest backup (today)
│   ├── 1_days/              # Yesterday
│   ├── 2_days/              # 2 days ago
│   │   ...
│   └── 6_days/              # 6 days ago
└── weekly/
    ├── 1_weeks/             # Last week
    ├── 2_weeks/             # 2 weeks ago
    │   ...
    └── 52_weeks/            # ~1 year ago
```

### 5. Prerequisites & Dependencies

- A Linux system with an `sh`-compatible shell
- **`rsync`** — incremental file synchronization with `--delete` support
- **`mailx`** — configured with a working mail account (e.g. `mailx -A gmail`)
- A filesystem that supports **hard links** (ext4, xfs, btrfs, etc.)

### 6. Typical Deployment

The system is typically scheduled to run once daily via cron. See the [README](../README.md) for complete setup and usage instructions including `backup_folders.txt` configuration and cron examples.

### 7. Roadmap & Future Scope

- **Intelligent Integrity Checks**: The current notification process relies on a simplistic output line count. Future improvements should provide detailed contextual reporting (e.g. distinguishing standard system logs from broad user data changes).
- **Event-driven Snapshots**: Potentially migrating from cron-based routine timers to on-demand checks, executing snapshot cycles exclusively when actual filesystem changes are detected.
