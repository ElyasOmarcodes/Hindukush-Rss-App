#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hindukush RSS Explorer
======================

Give it the three site homepages. For each site it will:

  1. Append /feed/ to the main URL and read the site's main RSS.
  2. Discover EVERY category (and sub-category) three ways:
       * the WordPress REST API  (…/wp-json/wp/v2/categories)
       * the RSS <category> tags found in the main feed
       * <a href=".../category/<slug>/"> links scraped from the homepage
  3. Build the feed URL for each category  (…/category/<slug>/feed/)
  4. Fetch every feed, analyse its structure (which tags each <item> has,
     whether images/among content exist, counts, samples) and write a
     separate, human-readable report file per feed.
  5. Also save the raw feed XML for each one.
  6. Zip everything into  hindukush_rss_report.zip.

Then send me that zip and I'll wire the exact slugs + image sources into the app.

Usage
-----
    python3 rss_explorer.py
        (uses the three default Hindukush sites)

    python3 rss_explorer.py https://hindukushpa.com https://hindokosh.com https://hindukushen.com

    # options
    python3 rss_explorer.py --out myfolder --max-items 5 --timeout 30

Only needs the standard library + `requests` (falls back to urllib if requests
isn't installed).  No other dependencies.
"""

import argparse
import io
import json
import os
import re
import ssl
import sys
import time
import zipfile
from datetime import datetime
from urllib.parse import urljoin, urlparse
from xml.etree import ElementTree as ET

# ---------------------------------------------------------------------------
# HTTP helper (requests if available, else urllib) — with a browser UA so the
# sites' bot protection doesn't 403 us.
# ---------------------------------------------------------------------------
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
HEADERS = {
    "User-Agent": UA,
    "Accept": "text/html,application/xhtml+xml,application/xml,"
              "application/rss+xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ps,fa,en;q=0.8",
}

try:
    import requests  # type: ignore

    _SESSION = requests.Session()
    _SESSION.headers.update(HEADERS)

    def http_get(url, timeout):
        r = _SESSION.get(url, timeout=timeout, allow_redirects=True)
        return r.status_code, r.text, r.content
except Exception:  # pragma: no cover - fallback path
    import urllib.request

    _CTX = ssl.create_default_context()
    _CTX.check_hostname = False
    _CTX.verify_mode = ssl.CERT_NONE

    def http_get(url, timeout):
        req = urllib.request.Request(url, headers=HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=timeout, context=_CTX) as resp:
                raw = resp.read()
                return resp.status, raw.decode("utf-8", "replace"), raw
        except urllib.error.HTTPError as e:  # type: ignore
            return e.code, "", b""


# ---------------------------------------------------------------------------
# Small utilities
# ---------------------------------------------------------------------------
def log(msg):
    print(msg, flush=True)


def slugify_name(s):
    s = re.sub(r"[^\w\-]+", "_", s.strip(), flags=re.UNICODE)
    return s.strip("_") or "feed"


def localname(tag):
    """Strip the XML namespace from a tag: '{ns}title' -> 'title'."""
    return tag.split("}", 1)[1] if "}" in tag else tag


def qualified(el, nsmap):
    """Return a readable 'prefix:local' name for an element's tag."""
    tag = el.tag
    if "}" not in tag:
        return tag
    ns, local = tag[1:].split("}", 1)
    prefix = nsmap.get(ns)
    return f"{prefix}:{local}" if prefix else local


NS_PREFIXES = {
    "http://purl.org/rss/1.0/modules/content/": "content",
    "http://purl.org/dc/elements/1.1/": "dc",
    "http://search.yahoo.com/mrss/": "media",
    "http://www.w3.org/2005/Atom": "atom",
    "http://wellformedweb.org/CommentAPI/": "wfw",
    "http://purl.org/rss/1.0/modules/slash/": "slash",
    "https://www.google.com/schemas/sitemap-image/1.1": "image",
}


# ---------------------------------------------------------------------------
# Category discovery
# ---------------------------------------------------------------------------
def discover_via_rest(base, timeout):
    """WordPress REST API: the most reliable slug source."""
    cats = {}
    for page in range(1, 11):  # up to 1000 categories
        url = f"{base}/wp-json/wp/v2/categories?per_page=100&page={page}"
        try:
            status, text, _ = http_get(url, timeout)
            if status != 200 or not text.strip():
                break
            data = json.loads(text)
            if not isinstance(data, list) or not data:
                break
            for c in data:
                slug = c.get("slug")
                if slug:
                    cats[slug] = {
                        "slug": slug,
                        "name": c.get("name", ""),
                        "id": c.get("id"),
                        "parent": c.get("parent", 0),
                        "count": c.get("count", 0),
                        "source": "wp-json",
                    }
            if len(data) < 100:
                break
        except Exception as e:
            log(f"    REST page {page} failed: {e}")
            break
    return cats


def discover_via_html(base, timeout):
    """Scrape /category/<slug>/ links from the homepage + main menu."""
    slugs = {}
    try:
        status, text, _ = http_get(base + "/", timeout)
        if status == 200 and text:
            for m in re.finditer(r'/category/([^/"\'?<>\s]+)/', text):
                slug = m.group(1)
                slugs.setdefault(slug, {
                    "slug": slug, "name": "", "id": None,
                    "parent": None, "count": None, "source": "homepage-html",
                })
    except Exception as e:
        log(f"    homepage scrape failed: {e}")
    return slugs


def discover_via_main_feed(categories_seen):
    """Turn <category> labels already seen in items into candidate slugs."""
    out = {}
    for name in categories_seen:
        slug = slugify_name(name).lower().replace("_", "-")
        out.setdefault(slug, {
            "slug": slug, "name": name, "id": None,
            "parent": None, "count": None, "source": "item-category",
        })
    return out


# ---------------------------------------------------------------------------
# Feed parsing / structure analysis
# ---------------------------------------------------------------------------
IMG_RE = re.compile(r'<img[^>]+src=["\']([^"\']+)', re.I)


def analyse_feed(url, xml_text, xml_bytes, max_items):
    """Return a structured dict describing this feed."""
    info = {
        "url": url,
        "ok": False,
        "error": None,
        "channel_title": None,
        "generator": None,
        "item_count": 0,
        "item_tags": {},          # tag -> how many items have it
        "items_with_image": 0,
        "image_sources": {},      # where images were found -> count
        "namespaces": {},
        "samples": [],
    }
    if not xml_text or ("<rss" not in xml_text and "<feed" not in xml_text):
        info["error"] = "response is not an RSS/Atom feed"
        return info

    try:
        root = ET.fromstring(xml_bytes or xml_text.encode("utf-8"))
    except ET.ParseError as e:
        info["error"] = f"XML parse error: {e}"
        return info

    # namespace map (uri -> prefix)
    nsmap = dict(NS_PREFIXES)
    for m in re.finditer(r'xmlns:([\w\-]+)="([^"]+)"', xml_text):
        nsmap.setdefault(m.group(2), m.group(1))
    info["namespaces"] = {v: k for k, v in nsmap.items()}

    # channel-level
    channel = root.find("channel")
    if channel is not None:
        t = channel.find("title")
        info["channel_title"] = t.text.strip() if t is not None and t.text else None
        g = channel.find("generator")
        info["generator"] = g.text.strip() if g is not None and g.text else None
        items = channel.findall("item")
    else:
        # Atom
        items = root.findall("{http://www.w3.org/2005/Atom}entry")

    info["item_count"] = len(items)
    info["ok"] = True

    for idx, item in enumerate(items):
        present = set()
        # tally direct children tags
        for child in list(item):
            present.add(qualified(child, nsmap))
        for tag in present:
            info["item_tags"][tag] = info["item_tags"].get(tag, 0) + 1

        # image detection
        found_img, where = _find_image(item, nsmap)
        if found_img:
            info["items_with_image"] += 1
            info["image_sources"][where] = info["image_sources"].get(where, 0) + 1

        # collect a few samples
        if idx < max_items:
            info["samples"].append(_sample_item(item, nsmap, found_img))

    return info


def _child_text(item, local):
    for child in list(item):
        if localname(child.tag) == local:
            return (child.text or "").strip()
    return ""


def _find_image(item, nsmap):
    # media:content / media:thumbnail url attribute
    for child in item.iter():
        ln = localname(child.tag)
        if ln in ("content", "thumbnail") and child.get("url"):
            u = child.get("url").lower()
            if any(u.split("?")[0].endswith(ext)
                   for ext in (".jpg", ".jpeg", ".png", ".webp", ".gif")) or "media" in child.tag:
                return child.get("url"), f"{qualified(child, nsmap)}[@url]"
    # enclosure
    for child in list(item):
        if localname(child.tag) == "enclosure" and child.get("url"):
            typ = (child.get("type") or "")
            if typ.startswith("image") or re.search(r'\.(jpe?g|png|webp|gif)', child.get("url"), re.I):
                return child.get("url"), "enclosure[@url]"
    # <img> inside content:encoded or description
    for local in ("encoded", "description"):
        html = _child_text(item, local)
        m = IMG_RE.search(html)
        if m:
            return m.group(1), f"<img> inside {local}"
    return None, None


def _sample_item(item, nsmap, image):
    def g(local):
        return _child_text(item, local)

    content = g("encoded") or g("description")
    return {
        "title": g("title"),
        "link": g("link"),
        "pubDate": g("pubDate"),
        "creator": g("creator"),
        "categories": [ (c.text or "").strip()
                        for c in item if localname(c.tag) == "category" ],
        "has_content_encoded": bool(g("encoded")),
        "description_len": len(g("description")),
        "content_len": len(content),
        "image": image,
        "content_excerpt": re.sub(r"\s+", " ", content)[:280],
    }


# ---------------------------------------------------------------------------
# Report rendering
# ---------------------------------------------------------------------------
def render_report(cat, info):
    L = []
    a = L.append
    a("=" * 78)
    a(f"FEED: {info['url']}")
    a(f"Category slug : {cat.get('slug')}")
    a(f"Category name : {cat.get('name') or '(unknown)'}")
    a(f"Discovered by : {cat.get('source')}")
    if cat.get("count") is not None:
        a(f"WP post count : {cat.get('count')}")
    a("=" * 78)
    if not info["ok"]:
        a(f"STATUS: ❌ NOT A USABLE FEED  ->  {info['error']}")
        a("")
        a("Meaning: this slug is wrong OR the section has no RSS. Fix the slug")
        a("in lib/core/config/feeds.dart (open the section in a browser and copy")
        a("the real slug out of the /category/<slug>/ URL).")
        return "\n".join(L)

    a(f"STATUS         : ✅ OK")
    a(f"Channel title  : {info['channel_title']}")
    a(f"Generator      : {info['generator']}")
    a(f"Item count     : {info['item_count']}")
    a(f"Items w/ image : {info['items_with_image']} / {info['item_count']}")
    a("")
    a("Namespaces declared:")
    for pfx, uri in sorted(info["namespaces"].items()):
        a(f"    {pfx:10} = {uri}")
    a("")
    a("Per-item tags (tag -> #items that contain it):")
    for tag, n in sorted(info["item_tags"].items(), key=lambda kv: -kv[1]):
        a(f"    {tag:28} {n}")
    a("")
    a("Where the lead image comes from:")
    if info["image_sources"]:
        for src, n in sorted(info["image_sources"].items(), key=lambda kv: -kv[1]):
            a(f"    {src:34} {n}")
    else:
        a("    (no images detected in any item)")
    a("")
    a("-" * 78)
    a(f"SAMPLE ITEMS (first {len(info['samples'])}):")
    for i, s in enumerate(info["samples"], 1):
        a("-" * 78)
        a(f"[{i}] {s['title']}")
        a(f"    link            : {s['link']}")
        a(f"    pubDate         : {s['pubDate']}")
        a(f"    creator         : {s['creator'] or '(none)'}")
        a(f"    categories      : {', '.join(s['categories']) or '(none)'}")
        a(f"    content:encoded : {'yes' if s['has_content_encoded'] else 'NO'} "
          f"(len {s['content_len']}, description len {s['description_len']})")
        a(f"    image           : {s['image'] or '(none found)'}")
        a(f"    excerpt         : {s['content_excerpt']}")
    return "\n".join(L)


def render_site_summary(site, cats, results):
    L = []
    a = L.append
    a("#" * 78)
    a(f"# SITE: {site}")
    a("#" * 78)
    ok = [r for r in results if r[1]["ok"]]
    bad = [r for r in results if not r[1]["ok"]]
    a(f"Categories discovered : {len(cats)}")
    a(f"Feeds that work       : {len(ok)}")
    a(f"Feeds that DON'T work : {len(bad)}")
    a("")
    a("WORKING FEEDS (slug — items — image coverage):")
    for cat, info in sorted(ok, key=lambda x: -x[1]["item_count"]):
        cov = f"{info['items_with_image']}/{info['item_count']}"
        a(f"   ✅ {cat.get('slug'):28} {info['item_count']:>4} items   img {cov:>7}   {cat.get('name')}")
    a("")
    a("BROKEN / EMPTY FEEDS (fix or drop these slugs):")
    for cat, info in bad:
        a(f"   ❌ {cat.get('slug'):28} {info['error']}   {cat.get('name')}")
    a("")
    a("Suggested feeds.dart mapping (copy the working ones you need):")
    for cat, info in sorted(ok, key=lambda x: -x[1]["item_count"]):
        a(f"   slug: '{cat.get('slug')}'   // {cat.get('name')}  ({info['item_count']} items)")
    return "\n".join(L)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
DEFAULT_SITES = [
    "https://hindukushpa.com",   # Pashto
    "https://hindokosh.com",     # Dari
    "https://hindukushen.com",   # English
]


def normalise(url):
    url = url.strip().rstrip("/")
    if not url.startswith("http"):
        url = "https://" + url
    return url


def explore_site(site, outdir, max_items, timeout, delay):
    site = normalise(site)
    host = urlparse(site).netloc
    log(f"\n=== {site} ===")
    site_dir = os.path.join(outdir, slugify_name(host))
    raw_dir = os.path.join(site_dir, "raw_xml")
    os.makedirs(raw_dir, exist_ok=True)

    # --- main feed first (also seeds item-category slugs) ---
    main_url = site + "/feed/"
    log(f"  [main] {main_url}")
    status, text, content = http_get(main_url, timeout)
    seen_cat_names = set()
    if status == 200 and text:
        main_info = analyse_feed(main_url, text, content, max_items)
        with open(os.path.join(raw_dir, "MAIN.xml"), "w", encoding="utf-8") as f:
            f.write(text)
        with open(os.path.join(site_dir, "00_MAIN_feed.txt"), "w", encoding="utf-8") as f:
            f.write(render_report({"slug": "(main /feed/)", "name": "Home",
                                   "source": "main", "count": None}, main_info))
        for s in main_info["samples"]:
            seen_cat_names.update(s["categories"])
    else:
        log(f"    main feed HTTP {status}")

    # --- discover categories ---
    log("  discovering categories …")
    cats = {}
    cats.update(discover_via_html(site, timeout))
    for slug, c in discover_via_rest(site, timeout).items():
        cats[slug] = c  # REST wins (has names/ids)
    for slug, c in discover_via_main_feed(seen_cat_names).items():
        cats.setdefault(slug, c)
    log(f"    found {len(cats)} candidate categories")

    # --- fetch & analyse every category feed ---
    results = []
    for i, (slug, cat) in enumerate(sorted(cats.items()), 1):
        feed_url = f"{site}/category/{slug}/feed/"
        log(f"  [{i}/{len(cats)}] {feed_url}")
        try:
            status, text, content = http_get(feed_url, timeout)
            if status != 200:
                info = {"url": feed_url, "ok": False,
                        "error": f"HTTP {status}", "item_count": 0}
            else:
                info = analyse_feed(feed_url, text, content, max_items)
                if info["ok"]:
                    with open(os.path.join(raw_dir, slugify_name(slug) + ".xml"),
                              "w", encoding="utf-8") as f:
                        f.write(text)
        except Exception as e:
            info = {"url": feed_url, "ok": False, "error": str(e), "item_count": 0}

        results.append((cat, info))
        with open(os.path.join(site_dir, f"cat_{slugify_name(slug)}.txt"),
                  "w", encoding="utf-8") as f:
            f.write(render_report(cat, info))
        time.sleep(delay)

    # --- site summary ---
    with open(os.path.join(site_dir, "SUMMARY.txt"), "w", encoding="utf-8") as f:
        f.write(render_site_summary(site, cats, results))

    return {
        "site": site,
        "categories": len(cats),
        "working": sum(1 for _, i in results if i.get("ok")),
        "broken": sum(1 for _, i in results if not i.get("ok")),
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Hindukush RSS structure explorer")
    ap.add_argument("sites", nargs="*", default=DEFAULT_SITES,
                    help="site homepages (default: the 3 Hindukush sites)")
    ap.add_argument("--out", default="hindukush_rss_report",
                    help="output folder (default: hindukush_rss_report)")
    ap.add_argument("--zip", default="hindukush_rss_report.zip",
                    help="output zip filename")
    ap.add_argument("--max-items", type=int, default=4,
                    help="sample items to record per feed (default 4)")
    ap.add_argument("--timeout", type=int, default=30,
                    help="per-request timeout seconds (default 30)")
    ap.add_argument("--delay", type=float, default=0.4,
                    help="delay between requests, seconds (default 0.4)")
    args = ap.parse_args(argv)

    sites = args.sites or DEFAULT_SITES
    outdir = args.out
    if os.path.isdir(outdir):
        # keep it clean between runs
        import shutil
        shutil.rmtree(outdir)
    os.makedirs(outdir, exist_ok=True)

    started = datetime.now()
    overview = []
    for site in sites:
        try:
            overview.append(explore_site(site, outdir, args.max_items,
                                         args.timeout, args.delay))
        except Exception as e:
            log(f"!! {site} failed entirely: {e}")
            overview.append({"site": site, "error": str(e)})

    # top-level index
    with open(os.path.join(outdir, "INDEX.txt"), "w", encoding="utf-8") as f:
        f.write("Hindukush RSS report\n")
        f.write(f"Generated: {started.isoformat(timespec='seconds')}\n")
        f.write("=" * 60 + "\n\n")
        for o in overview:
            if "error" in o:
                f.write(f"{o['site']}: FAILED — {o['error']}\n")
            else:
                f.write(f"{o['site']}: {o['categories']} categories, "
                        f"{o['working']} working, {o['broken']} broken\n")
        f.write("\nOpen each site folder → SUMMARY.txt for the slug map, "
                "then cat_<slug>.txt for full per-feed structure.\n")

    # zip it
    zip_path = args.zip
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(outdir):
            for name in files:
                full = os.path.join(root, name)
                z.write(full, os.path.relpath(full, os.path.dirname(outdir)))
    log("\n" + "=" * 60)
    log(f"DONE. Report folder : {outdir}/")
    log(f"      Zip archive   : {zip_path}")
    log("Send me that zip and I'll fix the slugs + image sources in the app.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
