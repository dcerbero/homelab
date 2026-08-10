#!/usr/bin/env python3
import json
import shutil
import sqlite3
import sys
from datetime import datetime

LEGACY_RENAMES = {
    "Pi-hole": "pihole-yoda",
    "openclaw": "openclaw-yoda",
    "grafana": "grafana-talos",
}
NEW_TO_LEGACY = {new: old for old, new in LEGACY_RENAMES.items()}


def slugify(title):
    return title.lower().strip().replace(" ", "-")


def main():
    if len(sys.argv) != 4:
        print("usage: seed_tiles.py <tiles.json> <settings.json> <app.sqlite>", file=sys.stderr)
        return 2

    tiles_file, settings_file, db_path = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        with open(tiles_file) as f:
            tiles = json.load(f)
        with open(settings_file) as f:
            settings = json.load(f)
    except (OSError, ValueError) as e:
        print(f"error reading config: {e}", file=sys.stderr)
        return 2

    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
    except sqlite3.Error as e:
        print(f"error opening {db_path}: {e}", file=sys.stderr)
        return 2

    shutil.copy2(db_path, db_path + ".bak")
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def existing_id(title, item_type=None):
        if item_type is None:
            cur.execute(
                "SELECT id FROM items WHERE title=? AND user_id=1 AND deleted_at IS NULL",
                (title,),
            )
        else:
            cur.execute(
                "SELECT id FROM items WHERE title=? AND type=? AND user_id=1 AND deleted_at IS NULL",
                (title, item_type),
            )
        row = cur.fetchone()
        return row[0] if row else None

    desired_titles = [tile["title"] for tile in tiles]
    changed = 0

    # Categorias: una por tag distinto, ordenadas alfabeticamente.
    tag_order = 0
    tag_ids = {}
    for tag in sorted({tile["tag"] for tile in tiles if tile.get("tag")}, key=str.lower):
        tag_id = existing_id(tag, item_type=1)
        if tag_id is None:
            cur.execute(
                "INSERT INTO items (title, url, colour, pinned, `order`, created_at, "
                "updated_at, type, user_id) VALUES (?,?,?,1,?,?,?,1,1)",
                (tag, slugify(tag), None, tag_order, now, now),
            )
            tag_id = cur.lastrowid
            print(f"created category {tag} (id {tag_id})")
        else:
            cur.execute(
                "UPDATE items SET pinned=1, `order`=?, updated_at=? WHERE id=?",
                (tag_order, now, tag_id),
            )
            print(f"category {tag} exists (id {tag_id})")
        tag_ids[tag] = tag_id
        tag_order += 1

    # Orden derivado: alfabetico dentro de cada categoria.
    tiles = sorted(tiles, key=lambda t: (t.get("tag", "").lower(), t["title"].lower()))
    per_tag_counter = {}

    for tile in tiles:
        title = tile["title"]
        tag = tile.get("tag")
        colour = tile.get("colour")
        icon = tile.get("icon")
        url = tile.get("url", "")
        per_tag_counter[tag] = per_tag_counter.get(tag, 0)
        order = per_tag_counter[tag]
        per_tag_counter[tag] += 1

        row_id = existing_id(title)
        if row_id is None and title in NEW_TO_LEGACY:
            row_id = existing_id(NEW_TO_LEGACY[title])
        if row_id is None:
            cur.execute(
                "INSERT INTO items (title, colour, icon, url, pinned, `order`, "
                "created_at, updated_at, type, user_id) VALUES (?,?,?,?,1,?,?,?,0,1)",
                (title, colour, icon, url, order, now, now),
            )
            row_id = cur.lastrowid
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

        category_id = tag_ids.get(tag)
        if category_id is not None:
            cur.execute("DELETE FROM item_tag WHERE item_id=?", (row_id,))
            cur.execute(
                "INSERT INTO item_tag (item_id, tag_id) VALUES (?, ?)",
                (row_id, category_id),
            )
            print(f"linked {title} -> {tag}")

    # Limpieza: borrar tiles (type=0) que ya no estan en tiles.json.
    placeholders = ",".join("?" * len(desired_titles))
    cur.execute(
        f"SELECT id FROM items WHERE type=0 AND user_id=1 AND deleted_at IS NULL "
        f"AND title NOT IN ({placeholders})",
        desired_titles,
    )
    orphan_ids = [row[0] for row in cur.fetchall()]
    for item_id in orphan_ids:
        cur.execute("DELETE FROM item_tag WHERE item_id=?", (item_id,))
        cur.execute("DELETE FROM items WHERE id=?", (item_id,))
        changed += 1
        print(f"cleaned {item_id}")

    # Settings del dashboard desde settings.json.
    for key, value in settings.items():
        cur.execute(
            "UPDATE settings SET value=? WHERE key=? AND value != ?",
            (value, key, value),
        )
        if cur.rowcount:
            changed += 1
            print(f"setting {key} -> {value}")

    conn.commit()
    conn.close()
    print(f"done: {changed} row(s) affected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
