import sqlite3
import random
from datetime import date, timedelta

rng = random.Random(2026)

conn = sqlite3.connect("zepto_festive.db")
cur = conn.cursor()

cur.executescript("""
DROP TABLE IF EXISTS skus;
DROP TABLE IF EXISTS calendar_weeks;
DROP TABLE IF EXISTS weekly_sales;
DROP TABLE IF EXISTS committed_orders;

CREATE TABLE skus (
    sku_id INTEGER PRIMARY KEY,
    sku_name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit_price_inr INTEGER NOT NULL,
    lead_time_days INTEGER
);
CREATE TABLE calendar_weeks (
    week_no INTEGER PRIMARY KEY,
    week_start TEXT NOT NULL,
    season TEXT NOT NULL
);
CREATE TABLE weekly_sales (
    week_no INTEGER NOT NULL,
    sku_id INTEGER NOT NULL,
    units_sold INTEGER NOT NULL,
    stockout_days INTEGER NOT NULL,
    PRIMARY KEY (week_no, sku_id),
    FOREIGN KEY (week_no) REFERENCES calendar_weeks(week_no),
    FOREIGN KEY (sku_id) REFERENCES skus(sku_id)
);
CREATE TABLE committed_orders (
    sku_id INTEGER PRIMARY KEY,
    committed_weekly_units INTEGER NOT NULL,
    FOREIGN KEY (sku_id) REFERENCES skus(sku_id)
);
""")

# (sku_id, name, category, price, lead_time_days, base_weekly_units)
sku_rows = [
    (1,  "Kaju Katli 250 g",            "Sweets & Mithai",     320, 3, 900),
    (2,  "Soan Papdi 500 g",            "Sweets & Mithai",     210, 3, 700),
    (3,  "Gulab Jamun Tin 1 kg",        "Sweets & Mithai",     260, 4, 520),
    (4,  "Motichoor Ladoo 500 g",       "Sweets & Mithai",     280, 3, 430),
    (5,  "Almonds 500 g",               "Dry Fruits & Gifting", 480, 5, 640),
    (6,  "Cashew Nuts 500 g",           "Dry Fruits & Gifting", 520, 5, 560),
    (7,  "Assorted Dry Fruit Box 1 kg", "Dry Fruits & Gifting", 990, 6, 300),
    (8,  "Pistachio 250 g",             "Dry Fruits & Gifting", 450, 5, 240),
    (9,  "Namkeen Mix 400 g",           "Snacks & Beverages",  140, 2, 1500),
    (10, "Potato Chips Family Pack",    "Snacks & Beverages",   60, 2, 2100),
    (11, "Cola 2 L",                    "Snacks & Beverages",   95, 2, 1800),
    (12, "Roasted Makhana 100 g",       "Snacks & Beverages",  120, 2, 800),
    (13, "Diya Set (12 pcs)",           "Pooja & Decor",        99, 4, 350),
    (14, "Rangoli Colour Pack",         "Pooja & Decor",        75, 4, 220),
    (15, "Pooja Thali Set",             "Pooja & Decor",       349, 5, 160),
    (16, "LED Fairy Lights 10 m",       "Pooja & Decor",       299, 6, 280),
    (17, "Incense Sticks (6 packs)",    "Pooja & Decor",       110, 3, 900),
    (18, "Toran Door Hanging",          "Pooja & Decor",       199, 5, 130),
    (19, "Ghee 1 L",                    "Sweets & Mithai",     640, 4, 1100),
    (20, "Dates 500 g",                 "Dry Fruits & Gifting", 260, 4, 700),
]
# New launch with no sales history and no confirmed lead time yet
new_launch = (21, "Millet Ladoo Gift Box 300 g", "Sweets & Mithai", 340, None)

cur.executemany("INSERT INTO skus VALUES (?,?,?,?,?)", [r[:5] for r in sku_rows])
cur.execute("INSERT INTO skus VALUES (?,?,?,?,?)", new_launch)

week1_start = date(2025, 2, 10)
FESTIVE = set(range(37, 41)) | set(range(89, 93))
cal = []
for w in range(1, 93):
    cal.append((w, (week1_start + timedelta(days=7 * (w - 1))).isoformat(),
                "Festive" if w in FESTIVE else "Regular"))
cur.executemany("INSERT INTO calendar_weeks VALUES (?,?,?)", cal)

UPLIFT = {"Sweets & Mithai": 2.4, "Dry Fruits & Gifting": 2.0,
          "Snacks & Beverages": 1.4, "Pooja & Decor": 3.0}

sales = []
for w in range(1, 89):
    for (sid, name, cat, price, lead, base) in sku_rows:
        level = base * (1 + 0.002 * w)
        if w in FESTIVE:
            level *= UPLIFT[cat]
        noise = max(0.5, rng.gauss(1.0, 0.08))
        p_stockout = 0.30 if w in FESTIVE else 0.05
        if rng.random() < p_stockout:
            days = rng.randint(1, 3)
        else:
            days = 0
        units = int(round(level * noise * (1 - days / 7.0)))
        sales.append((w, sid, units, days))
cur.executemany("INSERT INTO weekly_sales VALUES (?,?,?,?)", sales)

COMMITTED = {1: 2300, 2: 1900, 3: 1400, 4: 1100, 5: 1450, 6: 1500, 7: 700, 8: 540,
             9: 2450, 10: 3700, 11: 2900, 12: 1200, 13: 1330, 14: 700, 15: 500,
             16: 900, 17: 3200, 18: 400, 19: 3100, 20: 1900}
cur.executemany("INSERT INTO committed_orders VALUES (?,?)", list(COMMITTED.items()))

conn.commit()
conn.close()
print("zepto_festive.db created.")
