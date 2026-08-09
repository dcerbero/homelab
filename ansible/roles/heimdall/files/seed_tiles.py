#!/usr/bin/env python3
import json
import shutil
import sqlite3
import sys
from datetime import datetime

LEGACY_TITLE = "Pi-hole"


def main():
    if len(sys.argv) != 3:
        print("usage: seed_tiles.py <tiles.json> <app.sqlite>", file=sys.stderr)
        return 2

    tiles_file, db_path = sys.argv[1], sys.argv[2]

    try:
        with open(tiles_file) as f:
            tiles = json.load(f)
    except (OSError, ValueError) as e:
        print(f"error reading {tiles_file}: {e}", file=sys.stderr)
        return 2

    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
    except sqlite3.Error as e:
        print(f"error opening {db_path}: {e}", file=sys.stderr)
        return 2

    shutil.copy2(db_path, db_path + ".bak")
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def existing_id(title):
        cur.execute(
            "SELECT id FROM items WHERE title=? AND user_id=1 AND deleted_at IS NULL",
            (title,),
        )
        row = cur.fetchone()
        return row[0] if row else None

    legacy_id = existing_id(LEGACY_TITLE)
    changed = 0

    for i, tile in enumerate(tiles):
        title = tile["title"]
        colour = tile.get("colour")
        icon = tile.get("icon")
        url = tile.get("url", "")
        order = tile.get("order", i)

        row_id = legacy_id if title == "pihole-pi" and legacy_id is not None else None
        if row_id is None:
            row_id = existing_id(title)
        if row_id is None:
            cur.execute(
                "INSERT INTO items (title, colour, icon, url, pinned, `order`, "
                "created_at, updated_at, type, user_id) VALUES (?,?,?,?,1,?,?,?,0,1)",
                (title, colour, icon, url, order, now, now),
            )
            changed += 1
            print(f"inserted {title}")
        else:
            cur.execute(
                "UPDATE items SET title=?, url=?, icon=?, colour=?, pinned=1, "
                "`order`=?, updated_at=?, class=NULL, appid=NULL, appdescription=NULL, "
                "description=NULL WHERE id=?",
                (title, url, icon, colour, order, now, row_id),
            )
            changed += cur.rowcount
            print(f"updated {title}")

    conn.commit()
    conn.close()
    print(f"done: {changed} row(s) affected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
