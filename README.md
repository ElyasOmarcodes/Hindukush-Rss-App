# هندوکش غږ — Hindukush RSS App

> کره خبرونه زمونږ رسالت دی · اخبار دقیق رسالت ماست · Accurate news is our mission

A **Flutter** (Dart) news reader for **Hindukush Ghag**, built with a
**Material 3 Expressive**, day/night interface and shipped to **Android, iOS
and Windows** from GitHub Actions.

It reads the WordPress RSS feeds of the three Hindukush Ghag sites and lets the
user switch language + content source with one tap:

| Language | Site |
|----------|------|
| پښتو (Pashto)  | https://hindukushpa.com |
| دری (Dari)     | https://hindokosh.com |
| English        | https://hindukushen.com |

## Features

- **Splash** — expressive, springy brand animation.
- **Home** — no app bar; pull-to-refresh with a *contained loading indicator*;
  a snapping **carousel** of the newest items; and a full **sections list**
  (all 9 site sections + their subcategories).
- **List screen** — Material **search app bar** (background matches the
  screen), pull-to-refresh, soft staggered list animations, offline banner.
- **Post view** — no app bar; zoomable image with a publish-date tag; large
  bold title; author line; full HTML body; a floating **reading toolbar**
  (copy / share / save / quick settings); a **quick-settings bottom sheet**
  with live font-size + line-spacing sliders and a connected text-align group.
- **Favorites** — saved articles, kept forever & offline.
- **Settings** — language & theme pickers (with mini previews), offline
  database switch, auto-delete windows for news and read news, stored-item
  count, clear database.
- **About** — the three site links, privacy policy, rate, bug report, version.
- **Offline** — a pure-Dart **Hive** cache (no native SQLite), read-tracking,
  and time-based auto-deletion (favorites are never deleted).

## Project layout

```
lib/
  core/config/feeds.dart        ← the ONE place to edit sites & category slugs
  core/localization/strings.dart← UI strings (ps / fa / en)
  core/theme/app_theme.dart     ← Material 3 expressive light/dark theme
  data/                         ← models, RSS parser, Hive DB, repository
  state/app_state.dart          ← persisted settings + language/theme
  ui/                           ← splash, home, list, post, settings, about
tool/                           ← platform patch scripts (run in CI)
signing/                        ← release keys + how they're used (see its README)
.github/workflows/build.yml     ← multi-platform build + signing + release
```

## ⚠️ About the feed category slugs

The sites are WordPress, so every feed follows the standard convention:

- Home: `{site}/feed/`
- Category: `{site}/category/{slug}/feed/`

Two slugs were verified from the public site (`world`, `article`); the rest use
the conventional English WordPress slugs. **If a section loads empty, open that
section in a browser, copy the real slug from its URL, and fix it in
`lib/core/config/feeds.dart` only** — the entire app menu is generated from that
one file. (Live feed XML couldn't be fetched during development because the
build network blocks those domains, so the slugs are best-effort until you
confirm them against the live site.)

## Building

Everything builds in CI on every push; tagging `vX.Y.Z` also publishes a
GitHub Release with the installable files.

| Platform | Output | Signing |
|----------|--------|---------|
| Android  | `Hindukush.apk` (arm64, obfuscated) | Signed with `signing/hindukush.p12` via `apksigner` |
| iOS      | `Hindukush-unsigned.ipa` | Unsigned (sideload via AltStore/Sideloadly; App Store needs a paid Apple account) |
| Windows  | `Hindukush-Windows.zip` | `hindukush.exe` Authenticode-signed (self-signed) |

Locally:

```bash
flutter create --platforms=android,ios,windows --org com.hindukush --project-name hindukush .
bash tool/patch_android.sh        # adds INTERNET permission + label
flutter pub get
flutter run                       # or: flutter build apk --release
```

See **`signing/README.md`** for the keystore/certificate passwords and
fingerprints, and the security caveats.

## Notes on the Windows zip

Flutter Windows apps are a folder (`hindukush.exe` + a few DLLs + a `data/`
folder) and can't be collapsed to a single standalone `.exe` without an
installer (MSIX/Inno Setup). The zip therefore contains the minimal runnable
release folder. If you want a single-file installer later, an MSIX step can be
added (and would also carry the Windows signature).
