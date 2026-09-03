# Stash

Personal finance app for MYR — budgets, savings goals, bills, and reports.

Built with **Flutter** (Android first). Data stays on-device in Phase 1.

## Phase 1 features

- Quick add expense / income (amount, date, category)
- Day / week / month total budgets with overspend warning
- Savings goals (travel, emergency, down payment, custom) with configurable display fields
- Accounts + balance overview (optional 1:1 goal binding)
- Bills list (e.g. maintenance fee) — mark paid, optional calendar
- Recurring templates
- Reports: month spend, category pie, trend, savings, vs last month
- Dark theme, EN / 中文

## Phase 2 (bank import)

- Paste HLB / TnG SMS or notification text → parse amount → review queue
- Optional Android **notification listener** (Settings → Bank import → enable)
- Confirm / dismiss before writing to ledger
- Auto category hints (food, transport, shopping, bills)

## Run

```bash
flutter pub get
flutter test
flutter run
```

### Android (this PC)

```bash
flutter build apk --debug
```

### Cloud iOS build (no Mac required on your PC)

This repo includes GitHub Actions that build on a **cloud Mac**:

1. Push to GitHub (`main`)
2. Open the repo → **Actions** tab
3. Wait for **Build / iOS (macOS cloud)**
4. Download artifact `stash-ios-unsigned`

```text
.github/workflows/build.yml   ← Android APK + iOS unsigned
codemagic.yaml                ← optional Codemagic config
```

**Important**

| Goal | Need |
|---|---|
| Prove iOS compiles in the cloud | ✅ Free GitHub Actions (already set up) |
| Install on a real iPhone | Apple Developer account (USD ~99/year) + signing certs |
| Publish to App Store | Same as above + App Store Connect |

Unsigned cloud builds **cannot** be installed on a phone. They only confirm the iOS project builds.

Optional Codemagic: https://codemagic.io → sign in with GitHub → pick this repo.

## Project layout

```
lib/
  core/          theme, i18n, format helpers
  data/          SQLite models + database
  providers/     Riverpod
  features/      home, transactions, goals, bills, budget, accounts, reports, settings
```

## Roadmap

- **Phase 2:** ✅ SMS / notification parsing + review inbox
- **Phase 3:** Real bank / TnG API research + Play Store polish
