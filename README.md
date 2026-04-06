# OpenBackup

> **Note**: This README describes the current, active version of the OpenBackup system.

A lightweight, snapshot-style backup system built on GNU `rsync` and Linux hard links. It maintains a rolling history of **7 daily** and **52 weekly** snapshots while consuming minimal extra disk space, since unchanged files are shared across snapshots via hard links.

## Features

- **Space-efficient snapshots** — Uses `cp -al` (hard links) so each snapshot only costs disk space for files that actually changed.
- **Rolling daily retention** — Keeps the last 7 days of backups (`0_days` through `6_days`).
- **Rolling weekly retention** — Automatically promotes the oldest daily snapshot into a 52-week weekly archive every Sunday.
- **Change detection alerts** — Sends an email notification whenever the backup detects filesystem changes, acting as a basic integrity monitor.
- **Incremental sync** — Only changed files are transferred on each run via `rsync --delete`, keeping backups in sync with the source while removing deleted files.

## Project Structure

```
openBackup/
├── README.md
├── LICENSE
├── src/
│   ├── backup.sh          # Main backup script
│   └── backup_roll.sh     # Daily/weekly rotation script
└── spec/
    └── PRD.md             # Product Requirements Document
```

- **[`src/backup.sh`](src/backup.sh)** — Main entry point. Triggers rotation, runs `rsync`, and sends email alerts on detected changes.
- **[`src/backup_roll.sh`](src/backup_roll.sh)** — Handles the daily and weekly folder rotation logic.
- **[`spec/PRD.md`](spec/PRD.md)** — Detailed product requirements and design rationale.

## Prerequisites

- A Linux system with `sh`-compatible shell
- **`rsync`** — for incremental file synchronization
- **`mailx`** — for email change notifications (configured with a working mail account, e.g. `mailx -A gmail`)
- A filesystem that supports **hard links** (ext4, xfs, btrfs, etc.)

## Setup and Usage

### 1. Prepare the backup destination

Create a directory that will hold all backup data and logs:

```bash
mkdir -p /path/to/backup_destination
```

### 2. Create `backup_folders.txt`

Inside the backup destination directory, create a file called `backup_folders.txt`. This file tells `rsync` which source directories to back up. List the absolute paths separated by spaces or newlines:

```bash
cat > /path/to/backup_destination/backup_folders.txt << 'EOF'
/home/user/documents
/etc
/var/www/html
EOF
```

### 3. Install the scripts

The main script (`backup.sh`) expects `backup_roll.sh` to be installed at `/usr/local/bin/backup_roll.sh`. Copy it into place:

```bash
sudo cp src/backup_roll.sh /usr/local/bin/backup_roll.sh
sudo chmod +x /usr/local/bin/backup_roll.sh
```

### 4. Run manually

```bash
./src/backup.sh /path/to/backup_destination
```

### 5. Automate with cron

For daily automated backups, add a cronjob via `crontab -e`:

```cron
# Run OpenBackup every day at 02:00 AM
0 2 * * * /absolute/path/to/openBackup/src/backup.sh /absolute/path/to/backup_destination
```

## How It Works

### Daily rotation
Each day, `backup_roll.sh` shifts the daily snapshot folders forward by one position:

1. The oldest daily snapshot (`6_days`) is deleted.
2. Each remaining snapshot is renamed up by one (`5_days` → `6_days`, `4_days` → `5_days`, etc.).
3. A hard-link copy of `0_days` is created as `1_days` (preserving the previous day's state at zero extra cost).
4. `backup.sh` then uses `rsync --delete` to sync the latest source data into `0_days`, overwriting only changed files.

### Weekly rotation (Sundays)
On Sundays (`day == 0`), before the daily rotation runs:

1. The oldest weekly snapshot (`52_weeks`) is deleted.
2. Each remaining weekly snapshot is shifted up by one.
3. The contents of `6_days` are hard-link copied into `1_weeks`.

### Email alerts
After each `rsync` run, the script checks the log output. If more than 4 lines were logged (indicating actual file changes beyond the standard `rsync` summary), it sends an email alert with the full log attached.

### Resulting directory layout

After running, the backup destination will look like this:

```
/path/to/backup_destination/
├── backup_folders.txt       # Your source folder configuration
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

## Future Improvements

- Intelligent integrity check reporting — filter out routine changes and only flag suspicious modifications.
- Event-driven snapshots — trigger backups only when filesystem changes are detected instead of on a fixed schedule.

## History

- **10-03-2010**: Rev 1 — First revision.

## License

See [LICENSE](LICENSE) for details.
