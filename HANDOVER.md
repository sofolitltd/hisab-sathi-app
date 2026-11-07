# দেনা পাওনা (formerly Baki Khata) — handover (updated 2026-11-07)

No secrets in this file. Secrets live in `baki-khata-api/.env*`, Vercel env vars, and `~/.baki_khata/`.

## What it is
Bangla personal দেনা-পাওনা (debt/credit) tracker — generalized from a shop-credit ledger. Android app (Flutter, offline-first SQLite) + sync API/website (Go). Rebranded 2026-10-27 to **দেনা পাওনা** (briefly "দেনা পাওনা দিবা" for a few minutes, then shortened — app was still local-dev only, not Play Store published, at rebrand time — confirmed with user before renaming applicationId). Backend/API brand and landing page text not yet updated — still says "Baki Khata" / "বাকির খাতা · Powered By: Sofol IT".

## Session 2026-11-07 — direction fixes, pabo/debo split everywhere, statement print

All of this is uncommitted, like the 2026-10-27 work below. `flutter analyze` is clean. Nothing was run on a device. The user runs the app themselves.

### Bug fix: debo-side meaning after the v8 unification (the important one)
Since v8, `baki` always means "I gave" (+balance) and `joma` means "I got" (−balance) for **every** person. Several places still assumed the old per-book flipped types, so every **debo** person was mislabelled, not only mixed ones. Fixed:
- **Helper:** `extension LedgerEntry on Ledger` (`lib/core/models/`). `grows` gives `baki` for pabo and `joma` for debo, and `shrinks` gives the opposite. Use these whenever code asks "does this entry increase this person's debt?"
- **Entry names:** use `entryWord(type)` (`lib/core/utils/utils.dart`), which returns দিলাম or পেলাম. It is used in the customer page tile, the delete confirm and the statement image. `addTitle`/`reduceTitle` remain only as state nouns (বাকি আছে / দেনা আছে …), never per entry.
- **Ledger totals:** `Store.totalsBetween(from, to, ledger)` with a ledger now returns `baki` = that side grew and `joma` = it shrank. For debo, দিলাম and পেলাম are swapped inside. This fixes the stats metric cards, recovery rate and 6-month chart. Without a ledger it is raw দিলাম/পেলাম, which the home card uses.
- **Day summary:** `DayTotals.describe` (the evening notification) uses `grows`/`shrinks`.
- **Last entry date:** `Customer.lastBakiAt` is now a getter: the last দিলাম for pabo, the last পেলাম for debo. The SQL gives `last_baki_at` and `last_joma_at`, mapped to `lastGaveAt` and `lastGotAt`.
- **Installments:** `_withPlanPaid` counts the shrinking type per customer (sign of `balance`). For debo plans that means my দিলাম, where it used to count joma.
- **Entry sheet:** the "কবে দেবে/দেবেন" fields appear only when the entry `_grows` in the person's direction (or in the entry's own direction for a new or zero-balance person). Adding a new person with পেলাম (borrowing from someone new) is allowed now; it used to be blocked as shop-era logic. The edit sheet's `_withDue` uses the same rule.
- **Direction flip:** `Store._afterChange` compares the direction before and after. If pabo⇄debo flips while a due date, reminder or plan exists, `_clearSchedule` wipes all three and writes a `ContactKind.note` history line. Reaching a zero balance now also clears `plan`, so an old plan cannot come back after a two-step flip.

### Due-date change history
- **New kind:** `ContactKind.due`, an automatic "তারিখ বদল" history row written by `Store._logDueChange` when the user replaces one existing due date with a different day. It is called from `setSchedule` and from `addEntry(updateSchedule: true)`.
- **Not logged:** first-time dates, plan-driven `_followPlan` moves and settle-clears, because those go through `_setSchedule` directly.
- **Note text:** `তারিখ: <old> → <new>`, readable on its own because older apps and the server see an unknown kind. Old apps map unknown kinds to `note` (`ContactKind.values.asNameMap()[...] ?? note`), and the server stores `kind` as free text, so no API change was needed.
- **UI:** `DueChangeCount` (`contact_log.dart`) under the due line on the customer page shows "তারিখ N বার বদলেছে". The manual log sheet hides the `due` chip.

### pabo/debo split in the UI (no more mixed totals)
- **Shared helpers in `customers_screen.dart`:** `paboDebo(list)`, `matchesSide(c, side)` and `PaboDeboTotal`. The last one renders tappable pabo/debo chips that filter to one side; a separate round ✕ appears when a side is selected. They sit in a `Wrap`, so they drop to a new line on narrow screens. Used on the people page summary (combined with the old filter sheet) and the home "আজ এগুলো দেখুন" and "সামনের ৩ দিনে" sections, each with its own selection. Totals are always computed before the side filter, so both chips stay visible.
- **Home hero card:** the bottom strip is আজ পেলাম | আজ দিলাম. Each total (মোট পাওনা, মোট দেনা) has its own "মেয়াদ পার" line, where the old card summed both sides into one overdue number. `summarySpeech` was updated to match.
- **Amount colours:** amounts use `ledgerAccent(direction)` (teal or indigo) with a small পাব/দেব label instead of always `bakiColor` red. This applies to `CustomerCard`, the home list rows and stats `_CustomerRow`.
- **`PeopleListPage` / `openPeopleList`** (`lib/features/customers/people_list_page.dart`): one live list page with a speaker button that opens `showAudioListSheet`. It opens from home (tap a total or its মেয়াদ পার line), from profile (tap the মোট পাওনা or মোট দেনা cell; profile counts now exclude zero-balance people) and from report aging rows.
- **Report time range:** chips are দিন, ৭ দিন, মাস, বছর and সব সময়. A ‹ label › row moves the `_anchor` day, week, month or year, and tapping the label opens a date picker. The right arrow is disabled at the current period, and changing the chip resets to today. Ranges now have an end date.

### Other UI changes
- Home: removed the big দিলাম/পেলাম/ব্যক্তি quick buttons and the call button on home list rows. Calls happen from the person page.
- Top bar (logo, name and sync): only on the home tab, smaller (30px logo, 36px sync). The other tabs use their own AppBar. `Shell` only strips the top padding when `_tab == 0`.
- `NameAvatar`: with a photo, tapping opens `showPhoto`, a large dialog.
- Audio list sheet: rows reuse `CustomerCard(highlighted:, speaking:)`, with natural heights and no `itemExtent`. Auto-follow uses `GlobalKey` and `Scrollable.ensureVisible`, falling back to an estimated jump with up to 3 retries. `CustomerCard` columns are `MainAxisSize.min`; without that, cards stretched in bounded slots.
- Print sheet: has a ✕ close button and shows the first 3 month groups with "আরও N টি মাস দেখুন".

### Print = bank-statement style (`lib/features/printing/print_slips.dart`)
- **API:** `printStatement(...)` and `renderStatementPages(...)` replaced `printDueSlips` and `renderSlipPages`.
- **Layout:** app name and "<পাওনা/দেনা>র স্টেটমেন্ট" with the print time, the holder line (only when logged in, from `AuthService.instance.account`) and a 4-cell summary box. The columns are #, নাম, মোবাইল, শেষ এন্ট্রি, দেওয়ার দিন (overdue in red), টাকা and ক্রমযোগ, a running total. Rows are zebra-striped, with a month band, an উপমোট per month and a double-ruled সর্বমোট. The footer carries a disclaimer and the page number.
- **Fixed old bug:** `_paginate` used to drop the row that triggered a page break, losing one person per page. It now re-processes that row (`i--`).
- **Checked:** rendered with a throwaway `flutter test`, the same font-loader trick as below, using 70 fake rows over 3 pages. The test file was deleted afterwards.

### Removed the word "বাকি" from all user-facing text
The user's rule is that **"বাকি" should not appear anywhere in the UI.** It is shop wording, and the app now says পাওনা and দেনা. Only code identifiers (`EntryType.baki`, `lastBakiAt` and others) and comments still contain it.
- **Main source:** `LedgerText.pabo` (`lib/core/ledger.dart`) used `addTitle` 'বাকি' → 'পাওনা'. This one change also fixed every derived string: card subtitle, "… নেই", print "শেষ পাওনার মাস", statement "মোট পাওনা", entry sheet "আগের পাওনা" and the audio speech. Also `hasDue` → 'পাওনা আছে', `added` → 'নতুন পাওনা', `biggest` → 'সবচেয়ে বেশি পাওনা' and `allSettled` → 'সব পাওনা আদায় হয়েছে ✓'.
- **Other strings:** notification titles, channel name and description and the recap text (`notifications.dart`); `summarySpeech`; the people filter label; the shell + sheet subtitle; the profile recap hint; the sync pending text ('পাঠানো হয়নি'); the statement image footer, which still said the old brand "বাকি খাতা অ্যাপ" and now says "দেনা পাওনা অ্যাপ".
- **Dunning SMS** (`dueSmsBody` in `contact_log.dart`): rewritten without shop wording. It now reads "আপনার কাছে আমার ৳X পাওনা আছে। সুবিধামতো … দিয়ে দিলে ভালো হয়।"
- **Share message** (`statement_share.dart`): written from the **recipient's** point of view per direction. Pabo: "আপনার কাছে আমার পাওনা ৳X". Debo: "আমার কাছে আপনি পাবেন ৳X". A plain `addTitle` swap would have told the other person that *they* are owed.
- **Check before adding new UI text:** run `grep -rn "বাকি" lib | grep -E "'[^']*বাকি"`. It should print nothing.
- **Open question for the user:** the pabo-side "জমা" (`reduceTitle`, "অগ্রিম জমা", stats chart legend) still exists. It is also shop-ish; I offered to change it to পেলাম or আদায় and am waiting for the user's answer.

### Photos
Compression was verified on the emulator: all stored files are 53 to 98 KB, under the 100 KB cap (1280px pick → square crop → ≤640px → JPEG quality loop). Minor inefficiency left alone: every sync pull rewrites each photo file with a new name and deletes the old one.

## Planned new app: হিসাব সহায় (not started — decided 2026-11-07)
- **Decision:** the user wants a **separate** new app named **হিসাব সহায়**, and this app stays as is (no rename). One app for both normal and business users, with a role choice at the start. My recommendation, which the user agreed with: multiple "খাতা" (ব্যক্তিগত / ব্যবসা) under one account rather than a fixed role, with business modules shown only in business খাতা.
- **Design:** a new custom design system. It **must be compact** (dense lists, small type, no big hero cards), and the user dislikes the stock Material look. They liked the chat-style per-person ledger idea.
- **Folder:** `/Users/reyad/Documents/Programming/Flutter/hisab_sohay` already exists. It is the business prototype that was moved out of this repo (the "v2 dashboard" below): purchases, sales, stock and barcode, `com.sofolit.hisab_sohay`, **no git**. Still open: build the new app there (git-init and snapshot first) or in a fresh folder. Also open: stock in v1 or later, and importing data from দেনা পাওনা.
- **Plan proposed:** copy the reusable pieces (voice, notifications, print/statement, photo/crop, l10n, auth, money/date utils) and rewrite the store, models, screens and theme. Use integer paisa for money, a খাতা id and uid on every row from day 1, and a separate API/DB so the live baki-khata server is untouched.

## Session 2026-10-27 (part 2) — unified balance model, rebrand, print redesign

Picks up right after the rebrand/DB-backup work above. Everything below is done, verified, `flutter analyze` clean, including the UX flow redesign (part 3, see below) done in a follow-up session.

1. **Guest-first auth** — login is no longer a startup gate. `lib/main.dart` goes straight to `Shell()`; `AuthScreen` is now a normal pushed route (has an AppBar/back button, pops itself on success) reached from Profile's "লগইন / নতুন অ্যাকাউন্ট" card. `ProfileScreen` has a full logged-out state (local totals still show, notification settings still work, no crash). `AuthService`/`SyncService` were already null-safe everywhere — no data-layer changes needed.
2. **Unified balance/direction model (the big one)** — replaced the old `Store._flipLedger` runtime hack (which rewrote every historical entry's type each time a customer's balance crossed zero) with a clean computed model:
   - `Customer.direction` (`lib/core/models/`) — `balance > 0.009 ? pabo : balance < -0.009 ? debo : ledger` (the stored `ledger` field is now **only** a zero-balance tiebreaker, set once at creation, never mutated again).
   - `Customer.hasDue` changed to `balance.abs() > 0.009` (balance can now legitimately be negative — payable direction).
   - **DB v7→v8 one-time migration** (`Store._unifyBalanceDirection`): flips `type` (baki↔joma) once for every existing `ledger='debo'` customer's entries, so `sum(baki)-sum(joma)` becomes a single universal signed number (positive=receivable) forever after. Verified live on the user's real device data: pulled DB before/after, confirmed every debo customer's magnitude was byte-identical, only sign changed (e.g. customer 85 "Nr": `130000.0 baki` → `130000.0 joma`, same id/date/note). **No runtime entry-rewriting happens anymore, ever** — direction is always just read off balance.
   - ~45 call sites across the app changed from `customer.ledger` to `customer.direction` (store filters/totals, notifications due/owing, print sections, SMS-reminder gate, profile counts, display wording). `lib/core/database/`'s raw-SQL aggregates (`recentEntries`, `dayTotals`, `totalsBetween`) can't `GROUP BY` a non-DB column anymore, so they now pull candidate `customer_id`s from the in-memory `Store.all` (already has live balance) and filter SQL by `customer_id IN (...)`.
   - **Bonus bugs caught and fixed in the same pass**: ~8 places did raw arithmetic on `c.balance` assuming it was always positive (sort comparators in customers_screen/dashboard/stats, the "মোট" summary total in customers_screen that would never show for the দেনা tab, the installment plan's default total amount, the "সব শোধ" quick-fill button that would've written a negative number into the amount field). All now use `.balance.abs()` where the value isn't already going through `taka()` (which already does `.abs()` internally).
3. **Rebrand** — app renamed "দেনা পাওনা" (briefly "দেনা পাওনা দিবা"), new two-arrow exchange-cycle logo (teal/indigo, generated with a Pillow script, not an off-the-shelf asset), Android `applicationId`/Dart package renamed to `com.sofolit.dena_pawna`/`dena_pawna` (see the note on this below — was previously flagged as don't-touch, overridden after confirming local-dev-only). Local SQLite filename (`baki_khata.db`) deliberately **not** renamed (zero data-migration risk).
4. **Vocabulary generalization (phase 1 of 2)** — `lib/core/ledger.dart`'s `LedgerText` is the single source for all user-facing wording; `party`/`partyPlural`/`partyHint` changed from "কাস্টমার"/"পাওনাদার"/"মহাজন/সাপ্লায়ার" to neutral "ব্যক্তি"/"নাম লিখুন" everywhere at once. **Did not** yet unify the verbs to the universal "দিলাম"/"পেলাম" (see below) — that's phase 2, deliberately deferred because at the time the entry-type semantics still depended on which "book" a customer was in; now that §2 above is done, phase 2 is actually safe to do. Also: removed "দোকানের নাম"/"ঠিকানা" entirely from `Account`/profile (was shop-specific, unused by sync — confirmed zero backend dependency before removing). Added Profile as a 4th bottom-nav tab (was previously only reachable by tapping the logo, which now switches to that tab instead of pushing a route).
5. **Print redesigned** (`lib/features/printing/print_slips.dart`) — the old output was literally scissors-cut collection slips (dashed borders, 2 per page, a blank "তারিখ: ____" signature line) aimed at a shop-collector workflow. Replaced with a clean tabular statement (`#`, নাম, মোবাইল, শেষ এন্ট্রি, টাকা — black header row repeated per page, grey month-section bands, right-aligned amounts) — verified live: 75 real people now fit in 3 A4 pages instead of ~38. `PrintSection`/`printSections()` grouping logic (by month/name, sort order) is unchanged and reused.

### UX flow redesign — done (this session, part 3)
Implemented the redesign analyzed at the end of part 2. `flutter analyze` clean.
- **Removed the global পাওনা/দেনা mode switch** (`LedgerSwitch` in `lib/features/home/shell.dart` — deleted, replaced by a plain `_TopBar`: logo + "দেনা পাওনা" wordmark + sync button). `Store.ledger`/`setLedger`/`ledgerNotifier`/`text` getter all removed — there is no more app-wide "which book is open" state. `Store.customers` now just returns `Store.all` (kept the name to minimize call-site churn, but it's unfiltered — every screen that read `store.customers` automatically became unified).
- **হোম**: hero card now shows মোট পাওনা and মোট দেনা side by side (was: one number, switched by mode) plus আজ পেলাম/মেয়াদ পার combined across both directions. Due/upcoming lists are unified (mixed directions, sorted by date — no longer two parallel tab-filtered lists).
- **ব্যক্তি**: one list, everyone, unaffected by any mode (filter sheet/sort unchanged, just no longer secretly scoped).
- **"+" flow**: single FAB → small sheet asking "দিলাম" or "পেলাম" (with one-line explanation each) → `showEntrySheet`. Direction is still inferred purely from the resulting balance sign (never asked/pre-selected) — this didn't change, only the *trigger* changed (no more implicit "whichever tab is open").
- **রিপোর্ট** (`stats_screen.dart`): kept its single-direction statistics (collection rate, aging buckets, 6-month bar chart — these genuinely need one direction at a time) but the পাওনা/দেনা choice is now a **local `SegmentedButton` inside this screen only**, not global. Doesn't affect any other tab.
- **প্রিন্ট** (`print_sheet.dart`): same treatment — local পাওনা/দেনা `ChoiceChip` pair added (previously silently printed whichever tab was open; now explicit, defaults to পাওনা). Title changed from "বাকির তালিকা প্রিন্ট" to generic "তালিকা প্রিন্ট" (was the leftover mentioned below).
- **Theme**: no longer swaps primary color by mode (`buildTheme` dropped its `Ledger` param) — one fixed teal `brand` color app-wide (`lib/core/theme/theme.dart`). `ledgerAccent`/`Ledger` are still used for small per-customer accents (profile summary, due-status colors), just not for the whole app's theme.
- **Vocabulary phase 2 done**: `add`/`reduce`/`addShort`/`reduceShort`/`addSave`/`reduceSave`/`reduceWho`/`whatHint` in `LedgerText` are now identical in both `pabo`/`debo` instances — universal "দিলাম"/"পেলাম" everywhere, regardless of which direction a customer is in. **Kept** `addTitle`/`reduceTitle` (বাকি/দেনা, জমা/পরিশোধ) and `total`/`hasDue`/`due*`/`added`/`reduced`/`rate`/`biggest`/`advance`/`allSettled` as direction-specific — these are nouns describing *state* ("কোনো বাকি নেই"), not the action verb, and stay meaningful read off `c.direction` per customer.
- **Store aggregates**: `recentEntries`/`totalsBetween`/`monthly` no longer filter by the (now-gone) global ledger; they aggregate over everyone by default, with `totalsBetween`/`monthly` taking an *optional* `Ledger?` param so `stats_screen.dart` can still ask for one direction's numbers specifically.
- **Not touched / explicitly out of scope this pass**: a few pre-existing `addTitle`-as-fallback spots in `entry_sheet.dart`'s autocomplete suggestion list use the sheet's own `_t` instead of each suggested customer's own `direction` (minor, pre-existing, cosmetic only — noticed but left alone).
- Not yet done: manual on-device verification (user runs the app themselves per their usual workflow) — walk through FAB → দিলাম/পেলাম → save, Report tab's local toggle, Print sheet, and a customer whose direction flips mid-session, to confirm everything reads naturally.

## Layout (all under `/Users/reyad/Documents/Programming/Flutter/`)
| Path | What | GitHub |
|---|---|---|
| `baki-khata-app/` | Flutter app | `sofolitltd/baki-khata-app` (PUBLIC) |
| `baki-khata-api/` | Go + Gin + Neon Postgres API, landing page at `/` | `sofolitltd/baki-khata-api` (private) |

~~Dart package name `baki_khata` and Android `applicationId` `com.sofolit.baki_khata` are deliberately NOT renamed (would break updates / hyphens illegal).~~ **Update 2026-10-27**: renamed anyway — Dart package `dena_pawna`, Android `applicationId`/`namespace` `com.sofolit.dena_pawna`. Safe only because the app was confirmed still local-dev-only (not on Play Store, no installed-user base to break). If this app is ever side-loaded to real users before a Play Store release, re-verify that's still true before renaming applicationId again — it breaks the update path for anyone already on the old id. The local SQLite filename (`baki_khata.db`) was deliberately left unchanged to avoid any risk of orphaning existing on-device data.

## Live
- Site + API: https://bakikhatabd.vercel.app (primary). `baki-khata-api-silk.vercel.app` also works (redirect removed on purpose: Dart does not follow 307 on POST, v1.0.1 apps use it).
- `bakikhata.vercel.app` is taken by someone else's "Coming Soon" project; couldn't be claimed.
- Vercel: scope/team `sofolit` (SofolIT), project `baki-khata-api`, container deploy (`Dockerfile.vercel`), region `sin1`, GitHub-connected: **push to `main` auto-deploys**. CLI login must be the Sofolit account (`vercel login`, device flow); `gadget-doptor` team has an OLD `baki-khata-api` project that still needs deleting (not reachable with the current login).
- Neon DB branch `production` (ap-southeast-1). Env on Vercel: `DATABASE_URL`, `JWT_SECRET` (production only).
- Latest release: v1.2.0 (https://github.com/sofolitltd/baki-khata-app/releases). API is tagged with the same version (`baki-khata-api`, Linux binary attached; the user only wants Linux for Go and Android for Flutter). Site's Download button -> `/download` -> 302 to `releases/latest/download/baki-khata.apk`.

## Run locally
- `baki-khata-app`: `make run-e` (emulator-5554, API at 10.0.2.2:8080), `make run-d [DEVICE=id]` (real phone via LAN IP), `make run` (starts API), `make devices`.
- `baki-khata-api`: `make run` (kills old process on :8080 first), `make landing` / `npm run landing` rebuilds `landing/app.css` (Tailwind v4 CLI) — **commit the built `app.css`**.
- Debug builds use localhost/10.0.2.2; **release builds default to `bakikhatabd.vercel.app`** (`lib/core/config.dart`), override with `--dart-define=API_URL=`.

## Release procedure (app)
1. Bump `version:` in `pubspec.yaml` (currently 1.2.0+7).
2. `flutter build apk --release --split-per-abi` (~3 min; run in background).
3. Verify signature: `apksigner verify --print-certs` -> `CN=Baki Khata, O=Sofolit`.
4. Copy to `baki-khata-vX.Y.Z-{arm64-v8a,armeabi-v7a,x86_64}.apk`, **plus `baki-khata.apk` (= arm64) — required, the website download link depends on this exact name**, plus `SHA256SUMS.txt`.
5. `git tag -a vX.Y.Z`, push `main` + tag, `gh release create vX.Y.Z ... --latest` (release notes in Bangla, user-facing).

## Release procedure (API)
1. Commit and push `main` -> Vercel auto-deploys to production (~2 min). On startup `internal/database/schema.sql` runs (`CREATE ... IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS`), so migrations must stay additive and idempotent.
2. Check the deploy with `vercel inspect <deployment-url>` (`status ● Ready`); grepping `vercel ls` output in a loop was unreliable. Smoke test: `GET /` 200, `GET /sync/pull` without token -> 401 JSON.
3. Tag with the same version as the app, `gh release create` with **only a Linux amd64 binary** (`CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w"`) + `SHA256SUMS.txt`. The user wants Linux only for Go, Android only for Flutter.
4. Deploy the API before (or with) an app release that adds synced fields. New synced fields follow the `extra_phones`/`plan` pattern: pointer in the Go DTO + `COALESCE($n, customers.col)` so older apps that don't send the field don't wipe it; the app keeps its local value when a pull lacks the key.
Signing: `android/key.properties` (gitignored) -> `~/.baki_khata/upload-keystore.jks`. **Back this up off-machine; losing it means no more updates for installed apps.** Without key.properties the build silently signs with the debug key.

## Code layout (feature-first, refactored 2026-11-07)
Hard rule from the user: **no file over 300 lines**, in either repo. Split by feature, not by type.

App (`lib/`, package `dena_pawna`, imports are `package:dena_pawna/...`):
- `main.dart` boots the services; `app.dart` is the `MaterialApp`.
- `core/` holds what every feature shares: `database/` (`Store`, one library split into `part` files by domain: customers, entries, logs, schedule, stats, sync, plus `schema.dart` migrations), `models/` (one file per entity, `models.dart` re-exports them), `notifications/` (`Notifier` + `DailyNotifier` part), `voice/` (`voice.dart` re-exports numbers, phonetic and `MicButton`), `photo/`, `theme/`, `utils/`, `widgets/` (`NameAvatar`, `PinField`, `PhoneField`, `confirmDelete`), `ledger.dart`, `l10n.dart`, `config.dart`. `core/` never imports from `features/`.
- `features/<name>/` holds screens, sheets and a `widgets/` folder: `auth`, `sync`, `home` (shell + top bar), `dashboard`, `customers` (list, filters, card, picker, people list, audio player), `customer_detail` (screen, form, edit-entry and reminder sheets, `openCustomer`), `entries` (entry sheet, due reminder), `installment`, `contact_log`, `stats`, `profile`, `printing`, `statement`. `contact_log.dart` and `installment.dart` are barrels exposing each feature's public API.
- Big private classes were split with `part` files (Store, print painter, statement image) so behaviour didn't change.

API (`baki-khata-api`): `main.go` wires everything; `internal/database`, `internal/auth`, `internal/datasync` (`/sync/*`), `internal/landing` (+ `web/` assets).

## Architecture notes
- Notifications are 100% local (`flutter_local_notifications`, scheduled from SQLite data). No FCM/server push. Per-customer reminders (default 10:00, time pickable everywhere via `lib/features/entries/due_reminder.dart`), morning summary (default 10:00, every day) and end-of-day recap (default 22:00; a time before 05:00 reports the previous day). Times live in SharedPreferences, editable in Profile. Text is fixed at schedule time, so `Store.scheduleDaily()` rebuilds both daily notifications on every data change.
- Sync: `lib/features/sync/`. PIN is kept in `flutter_secure_storage` so the app can (re)login silently (offline-at-login, expired 90-day JWT). Wrong PIN clears it and the sheet asks for PIN once. Sheet shows last sync time (persisted) + pushed/pulled counts.
- Auth lockout server-side: 5 wrong PINs -> 15 min lock. bcrypt PIN hashes.
- Voice: `lib/core/voice/` — TTS (`flutter_tts`, Bangla voice only, Bangla number words) on home hero, customer screen and the customers list player (`lib/features/customers/audio_list_sheet.dart`); `MicButton` (`speech_to_text`) on both searches, entry amount (parses spoken Bangla numbers), notes and name fields. Needs RECORD_AUDIO (declared). Depends on Google speech/TTS having Bangla on the device.
- Calls/SMS from the UI go through `callAndLog`/`smsAndLog` (`lib/features/contact_log/`), which pick a number when there are several and write a contact-history row; the raw launchers are `callPhone`/`sendSms` in `lib/core/utils/utils.dart` (manifest `<queries>` for tel/sms/RecognitionService/TTS_SERVICE present).
- Shared pieces: `CustomerCard` (customers list + home search), `DueReminderFields` / `confirmReminderAt` (`lib/features/entries/due_reminder.dart`), `pickCustomer` (`lib/features/customers/customer_picker.dart`).
- DB schema version is 8 (`lib/core/database/`, `onUpgrade` steps are cumulative — v8 is the balance-direction unification, see Session 2026-10-27 part 2 above).
- Landing is embedded in the Go binary (`internal/landing/landing.go`, `go:embed` of `internal/landing/web/`). `Dockerfile.vercel` copies `main.go` + `internal/`, so new landing files only need adding to the embed directive. Gin `GET` routes don't answer HEAD (use GET when testing).
- Same Neon DB is used by local API runs and prod — don't write demo data through the API.

## v1.1.0 additions
- DB v6: `customers.extra_phones` (newline-separated, max 2) and `contact_logs` (call/sms/visit/note history). Both sync; the app only pushes `contact_logs` after a pull response contains `logs` (old servers would drop them silently).
- Printing (`lib/features/printing/print_slips.dart`) and the statement image (`lib/features/statement/statement_image.dart`) draw pages with Flutter's text engine into PNGs, because the `pdf` package can't shape Bangla conjuncts. PDF text is therefore not selectable.
- Photo crop is pure Flutter (`lib/core/photo/crop_screen.dart`), no native cropper.
- TTS reads everything with the Bangla voice (an English voice for English-written names was tried in v1.1.0 and sounded odd in the list player; v1.2.0 transliterates them instead). Falls back to Google TTS when the default engine lacks Bangla (manifest `<queries>` has TTS_SERVICE).

## v1.2.0 additions
- Installments (`lib/features/installment/`): one plan per customer stored as JSON in `customers.plan` (DB v7, synced, old clients keep it). No separate rows: jomas dated on/after `plan.from` count toward it (`Store._withPlanPaid`). While a plan runs, `Store._followPlan` keeps the customer's due date/reminder on the current installment; new baki during a plan stays outside it.
- Time picker is 12-hour: `lib/l10n.dart` overrides Flutter's bn `timeOfDayFormatRaw` (24h) and the app forces `alwaysUse24HourFormat: false`.
- Past reminder times: `confirmReminderAt` asks (10 min / 1 hour / tomorrow) instead of silently shifting; saves show "রিমাইন্ডার আসবে: …".
- Exact alarms: `SCHEDULE_EXACT_ALARM` declared; asked once on the first reminder, status/grant in Profile. On grant (detected on resume) `Store.rescheduleAll()` re-schedules in exact mode.
- TTS: English-letter words are transliterated to Bangla for speech only (`banglaForSpeech`, rule-based + small word list) because the bn voice mangles Latin text.

## v2 dashboard experiment — dropped (2026-11-07)
The user dropped this approach entirely. No v2 code is left in this repo or in the API (checked: no `lib/v2/`, `v2_*` screens, `V2Store`, `baki_khata_v2.db` or `mobile_scanner`). The "v2" mentioned in `lib/core/database/schema.dart` is the old SQLite schema version, which is unrelated.

## Gotchas hit this session
- `vercel link` appended a `VERCEL_OIDC_TOKEN` to `baki-khata-api/.env.local` (gitignored; DB vars intact).
- The emulator (`emulator-5554`) holds the user's real test data incl. a profile with a real-looking name/shop/address — don't screenshot the profile screen. The demo-data trick used for landing screenshots: pull `databases/baki_khata.db` via `adb run-as`, edit with python sqlite3 (`dirty=0`), push back, restore the backup afterwards. `adb` is not on PATH: `$ANDROID_SDK/platform-tools/adb` (sdk.dir in `android/local.properties`).
- Mic permission on the emulator was revoked after testing.
- There is no `test/` dir. Logic and rendering were checked with throwaway `flutter test` files (deleted afterwards): pure functions (installment math, transliteration), and image output by rendering with the bundled font loaded via `FontLoader` and writing PNGs to the scratchpad. Reuse that trick to eyeball print/statement layouts.
- `grep` on Bangla string literals sometimes misses (different Unicode composition of the same text); match on nearby ASCII code instead when editing.
- `flutter_tts` `speak()` with `awaitSpeakCompletion(true)` also returns when `stop()` is called — the list player relies on a run counter to ignore stale loops.
- Flutter's `bn` Material localization is 24-hour by design; see `lib/l10n.dart` before touching locale/delegates (only the first delegate of a type is used, so ours must stay first).

## Not verified / open
- **2026-11-07 work is not tested on a device.** Things to walk through:
  - A mixed person: give 1000, then get 1500. Check the দিলাম/পেলাম names, "দেব ৳500", the old due date cleared with a history line, and the report's দেনা side numbers.
  - A debo installment plan, to see that progress moves on দিলাম.
  - Changing a due date twice, to see the history count.
  - The pabo/debo chips and ✕ on narrow screens.
  - Audio sheet auto-follow on a long list.
  - The report ‹ › arrows and the date picker.
  - Printing a real statement through the system dialog.
- Statement image (`statement_image.dart`): if the direction flipped partway through the history, the running-balance column shows only the absolute amount, not which side it was on.
- None of the 2026-11-07 work is committed. The 2026-10-27 rebrand work in the working tree is also still uncommitted.
- Never installed the release APKs on a real phone. Untested on device: Bangla STT/TTS quality and the transliterated names, the exact-alarm permission flow (Android 14 opens a settings page), notification timing, printing via the system print dialog, sharing to WhatsApp, photo crop orientation on portrait camera photos, installments end-to-end (set a plan, add a joma, next date should move).
- Landing page checked at desktop width only (headless Chrome can't do narrow widths).
- Old `gadget-doptor` Vercel project still exists (see above). Old releases v1.0.0 (points to dead-to-be old URL) and v1.0.1 still listed.
- `baki-khata-api` repo is private (fine). Local `.iml` files still carry old names (IDE-generated).
- Proposed to the user, not started (waiting for their pick): old-customer handling — "last transaction" age filter (3/6/12/24 months), year chips, "oldest first" sort, archive for paid + inactive customers, marking very old baki as doubtful so totals show it separately. Also discussed: per-customer credit limit warning.
- Ideas not started: voice settings toggle, FCM push, rate limiting beyond per-account lockout, battery-optimization shortcut for OEMs that kill alarms.

## Working with this user
- No "বাকি" in UI text (decided 2026-11-07). Use পাওনা and দেনা, and দিলাম or পেলাম for entries. Text that another person reads (SMS, share messages) must be phrased from that person's side.
- Communicates in Bangla (sometimes Banglish/voice-typed); all UI text, release notes and messages to them are Bangla. **Target audience was redefined 2026-10-27**: no longer shop owners specifically — the app is now positioned as a general personal দেনা-পাওনা tracker for anyone (businessman, student, individual lending to a friend). Avoid shop/business-specific wording or framing in new UI text; simple words, AM/PM time, no jargon, still applies.
- Asks for many small UI changes in a row; they expect each one done and reported briefly. Product decisions they made: every reminder defaults to 10:00 and is editable; Bangla-only voice; history on its own page; installments start simple (no per-installment rows).
- "Push/deploy" means: commit both repos, push (API auto-deploys), tag the same version on both, GitHub releases (APKs; Linux binary for the API).
