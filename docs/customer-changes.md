# Generate `customer_changes.csv`

`data/sample/customer_changes.csv` is synthetic. It is not an Olist file. Step 11 uses it so `etl.LoadDimCustomer` has a changed city, state, and ZIP to close. The warehouse from Step 10 has to already be loaded, because the script copies 20 real `customer_unique_id` values from `dw.DimCustomer`.

Each data row keeps that id and replaces the address with ZIP prefix `00000`, city `scd2-city`, and state `XX`. The container reads the file at `/data/sample/customer_changes.csv`. The `data/sample` mount is already live, so a new file there does not need `docker compose up` again.

Run this from the repo folder:

```bash
set -a && source .env && set +a

python3 - << 'PY'
import csv, os, subprocess
password = os.environ["MSSQL_SA_PASSWORD"]
query = """
SET NOCOUNT ON;
SELECT TOP (20)
    d.CustomerUniqueId,
    N'00000' AS customer_zip_code_prefix,
    N'scd2-city' AS customer_city,
    N'XX' AS customer_state
FROM dw.DimCustomer AS d
WHERE d.CustomerKey <> -1
  AND d.IsCurrent = 1
  AND EXISTS (
        SELECT 1
        FROM dw.FactOrderItem AS f
        WHERE f.CustomerKey = d.CustomerKey
  )
ORDER BY d.CustomerUniqueId;
"""
result = subprocess.run(
    ["docker", "compose", "exec", "-T", "sqlserver",
     "/opt/mssql-tools18/bin/sqlcmd",
     "-S", "localhost", "-U", "sa", "-P", password, "-C",
     "-d", "OrderFlowDW", "-y", "0", "-s", "|",
     "-Q", query],
    check=True, capture_output=True, text=True)
if result.stderr.strip():
    raise SystemExit(result.stderr)
rows = []
for line in result.stdout.splitlines():
    line = line.strip()
    if not line or line.startswith("("):
        continue
    parts = [part.strip() for part in line.split("|")]
    if len(parts) == 4:
        rows.append(parts)
if len(rows) != 20:
    raise SystemExit(f"expected 20 customers, got {len(rows)}")
path = "data/sample/customer_changes.csv"
with open(path, "w", encoding="utf-8", newline="\n") as handle:
    writer = csv.writer(handle, lineterminator="\n", quoting=csv.QUOTE_ALL)
    writer.writerow(["customer_unique_id", "customer_zip_code_prefix", "customer_city", "customer_state"])
    writer.writerows(rows)
print(f"wrote {len(rows)} rows to {path}")
print(rows[0])
PY
```

`sqlcmd` on this image rejects `-W` together with `-y`, and it rejects `-h` together with `-y 0`. The script uses `-y 0` so the 32-character id is not cut off, and `SET NOCOUNT ON` hides the row count. Quotes around every field keep the ZIP prefix as `00000`.

Confirm the file:

```bash
wc -l data/sample/customer_changes.csv
head -n 3 data/sample/customer_changes.csv
```

`wc -l` prints 21. The first line is the header `customer_unique_id`, `customer_zip_code_prefix`, `customer_city`, `customer_state`. Each data row is a 32-character id, then `"00000"`, `"scd2-city"`, `"XX"`.

`expected 20 customers, got 0` means `dw.DimCustomer` or `dw.FactOrderItem` is still empty. Run the Step 10 warehouse load, then run this script again. Create the CSV before the first `EXEC etl.LoadDimCustomer`.
