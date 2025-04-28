import sys, glob, sqlite3, pathlib

db_path           = pathlib.Path(sys.argv[1]).resolve()        # output.db
sql_dir           = pathlib.Path(sys.argv[2]).resolve()        # sql/
extension_path    = pathlib.Path(sys.argv[3]).resolve()        # /opt/projects/sqlite_ext/regexp

conn = sqlite3.connect(db_path)
conn.enable_load_extension(True)                               # allow .load :contentReference[oaicite:2]{index=2}
conn.load_extension(str(extension_path))                       # REGEXP functions :contentReference[oaicite:3]{index=3}
cur  = conn.cursor()

print(f"Applying post-processing scripts...")
for sql_file in sorted(sql_dir.glob("*.sql")):
    print(f"→ {sql_file.name}")
    cur.executescript(sql_file.read_text(encoding="utf-8"))

conn.commit()
conn.close()
print("All post-processing scripts applied.")
