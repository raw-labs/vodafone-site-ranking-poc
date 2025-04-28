# Vodafone Structured‑Data PoC – ETL to SQLite

> **One command rebuilds a fresh, query‑ready SQLite database from a folder full of Excel workbooks and post‑processing SQL scripts.**

---

## 1. What this repo does

1. **Extract** tabular data from multiple Excel files according to JSON config files.
2. **Load** the data into a single SQLite database (`output_YYYYMMDD_HHmmss.db` by default).
3. **Transform** the raw tables with reusable SQL scripts (views / materialised tables) that rely on the `nalgeon/regexp` extension.

Everything is wired together by two shell scripts:

| Script                | Purpose                                                                                              |
| --------------------- | ---------------------------------------------------------------------------------------------------- |
| `run_sqlite.sh`       | Converts each Excel file → raw SQLite table.                                                         |
| `build_everything.sh` | Full pipeline: runs `run_sqlite.sh`, then applies every `*.sql` in `sql/` with the regexp extension. |

---

## 2. Prerequisites

| Requirement                                           | Why                                                        | Quick install                                                |                        |
| ----------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------ | ---------------------- |
| **Python ≥3.9**                                       | ETL scripts (`excel_to_sqlite.py`, `apply_sql_scripts.py`) | `sudo apt install python3 python3-pip`                       |                        |
| **openpyxl**                                          | Read Excel workbooks                                       | `pip install openpyxl`                                       |                        |
| **SQLite ≥3.35** (with `loadable extensions` enabled) | Database + extension loading                               | Often already enabled; check with \`sqlite3 -cmd ".dbconfig" | grep load\_extension\` |
| **`regexp`**\*\* extension\*\*                        | Advanced pattern‑matching in post‑SQL                      | see below                                                    |                        |

### 2.1 Getting the *regexp* extension

```bash
mkdir -p /opt/projects/sqlite_ext
curl -L \
  https://github.com/nalgeon/sqlean/releases/latest/download/regexp-$(uname -s | tr A-Z a-z)-x86_64.tar.gz \
  | tar -xz -C /opt/projects/sqlite_ext/
# you should now have: /opt/projects/sqlite_ext/regexp
```

If you build SQLite from source, add `-DSQLITE_ENABLE_LOAD_EXTENSION`.

---

## 3. Folder layout (default)

```
.
├─ build_everything.sh          # master pipeline
├─ run_sqlite.sh                # raw XLSX → SQLite loader
├─ apply_sql_scripts.py         # loads regexp + executes *.sql
├─ excel_to_sqlite.py           # core ETL module
├─ *.json                       # per‑workbook extraction configs
├─ sql/                         # post‑processing SQL scripts
│  ├─ vfsites.sql
│  └─ …
└─ structured-data-poc/         # source Excel workbooks
```

Feel free to rearrange; every path is passed explicitly.

---

## 4. Quick start

```bash
# 1. clone repo & install dependencies …

# 2. run the full pipeline (creates output_YYYYMMDD_HHmmss.db)
./build_everything.sh

# 3. open the database
sqlite3 output_20250428_153210.db
sqlite> .tables
```

### 4.1 Custom targets

```bash
# custom database name
./build_everything.sh /tmp/vf.sqlite

# custom SQL directory & extension path
autumn_ext=/usr/local/lib/regexp
./build_everything.sh my.db custom_sql "$autumn_ext"
```

---

## 5. How things work

| Step                                                                   | File / function        | Key points                                      |
| ---------------------------------------------------------------------- | ---------------------- | ----------------------------------------------- |
| ① Extraction                                                           | `excel_to_sqlite.py`   | ‑ Reads Excel via *openpyxl*                    |
| ‑ Handles merged cells, dynamic regions, multi‑sheet, etc.             |                        |                                                 |
| ‑ Two type‑mapping modes: **stringAll** (everything TEXT) or **auto**. |                        |                                                 |
| ② Loader wrapper                                                       | `run_sqlite.sh`        | ‑ Accepts optional DB path                      |
| ‑ Loops over `(excel, config)` pairs                                   |                        |                                                 |
| ‑ Calls `python excel_to_sqlite.py EXCEL CONFIG DB`.                   |                        |                                                 |
| ③ Post‑processing                                                      | `apply_sql_scripts.py` | ‑ `enable_load_extension(True)`                 |
| ‑ `load_extension(<path>/regexp)`                                      |                        |                                                 |
| ‑ Streams every `*.sql` from chosen directory into `executescript()`   |                        |                                                 |
| ‑ Commits once at the end.                                             |                        |                                                 |
| ④ Orchestrator                                                         | `build_everything.sh`  | ‑ Generates timestamped DB name unless supplied |
| ‑ Runs steps ① & ③ in order.                                           |                        |                                                 |

---

## 6. Writing a config JSON

```json
{
  "tableName": "bridge",            // table to create
  "sheetName": "Sheet1",            // sheet inside the workbook
  "region"   : "A1:G914",           // optional; if omitted uses used‑range
  "headerRows": 2,                   // number of rows to stack for header
  "headerJoiner": " - ",            // glue for multi‑row headers
  "typeApproach": "stringAll",      // or "auto"

  // optional multi‑file ingestion
  "directory": "/path/to/xlsx/",
  "filenamePattern": "^([^\\s]*)\\s.*xlsx$",
  "filenameColumnName": "site_code"
}
```

See the existing `config_*.json` files for real examples.

---

## 7. Adding new post‑processing scripts

1. Drop a `*.sql` file in the **`sql/`** directory (or your custom folder).
2. Reference tables created in the extraction phase.
3. If you need other Sqlean extensions (`stats`, `fileio`, …) just add additional `conn.load_extension()` lines in `apply_sql_scripts.py`.

Order is alphabetical; prefix filenames with numbers if you need explicit ordering (`01_clean.sql`, `02_build_views.sql` …).

---

## 8. Automate on a schedule (optional)

Create a cron job:

```cron
15 2 * * * /path/to/repo/build_everything.sh /data/db/vf_$(date +\%Y\%m\%d).db >> /var/log/vf_etl.log 2>&1
```

Or run in CI to attach the artefact.

---

## 9. Troubleshooting

| Symptom                                                           | Cause / fix                                                                                                                            |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `sqlite3.OperationalError: not authorized` when loading extension | `loadable extensions` disabled; rebuild SQLite with `-DSQLITE_ENABLE_LOAD_EXTENSION=1` or install the distro package that includes it. |
| Strange header names                                              | Check `headerRows` and `headerJoiner` in the config; use `typeApproach" : "stringAll"` to skip type inference while debugging.         |
| Empty tables                                                      | Region too small or wrong `sheetName`. Enable the `print()` lines in `excel_to_sqlite.py` to trace.                                    |

---

## 10. License

MIT — see `LICENSE` file.

Let's call all of this ETL README, since the main focus is the business logic of the project, which is something completely different and based on the ETL part.

