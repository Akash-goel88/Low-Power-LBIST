import re
import csv
import sys
import os

if len(sys.argv) < 3:
    print("Usage: python parse_saif_rel.py <saif_file> <clock_net_name>")
    print("Example: python parse_saif_rel.py lbist.saif clk")
    sys.exit(1)

saif_file = sys.argv[1]
clk_name  = sys.argv[2]   # e.g. "clk" or "U_LBIST/clk"

csv_file = os.path.join(os.path.dirname(saif_file), "saif_toggles_relative.csv")

pattern = re.compile(
    r"\((?P<name>[A-Za-z0-9_\[\]\/\.]+)\s+"
    r"\(T0\s+(?P<T0>[0-9]+)\)\s+"
    r"\(T1\s+(?P<T1>[0-9]+)\)\s+"
    r"\(TX\s+(?P<TX>[0-9]+)\)\s+"
    r"\(TZ\s+(?P<TZ>[0-9]+)\)\s+"
    r"\(TB\s+(?P<TB>[0-9]+)\)\s+"
    r"\(TC\s+(?P<TC>[0-9]+)\)\)"
)

rows = []
clk_tc = None

with open(saif_file, "r") as f:
    for line in f:
        m = pattern.search(line)
        if m:
            name = m.group("name")
            T0 = int(m.group("T0"))
            T1 = int(m.group("T1"))
            TX = int(m.group("TX"))
            TZ = int(m.group("TZ"))
            TB = int(m.group("TB"))
            TC = int(m.group("TC"))

            rows.append({
                "name": name,
                "T0": T0,
                "T1": T1,
                "TX": TX,
                "TZ": TZ,
                "TB": TB,
                "TC": TC
            })

            if name.endswith(clk_name) or name == clk_name:
                clk_tc = TC

if clk_tc is None or clk_tc == 0:
    print(f"ERROR: Could not find clock net '{clk_name}' or TC=0")
    sys.exit(1)

# compute relative toggle ratio
for r in rows:
    r["toggle_per_clk_percent"] = (r["TC"] / clk_tc) * 100.0

# write CSV
with open(csv_file, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["net", "T0", "T1", "TC", "toggle_per_clk_percent"])
    for r in rows:
        writer.writerow([
            r["name"], r["T0"], r["T1"], r["TC"], f'{r["toggle_per_clk_percent"]:.3f}'
        ])

print(f"✔ Extracted {len(rows)} nets")
print(f"✔ Clock net '{clk_name}' TC = {clk_tc}")
print(f"✔ CSV saved at: {csv_file}")