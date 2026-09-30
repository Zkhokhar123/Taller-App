# Taller Master

**Offline Flutter app for Pakistani tailor shops (درزی دکانیں)** — customers, orders, measurements, karigar slips, payments, and 58mm thermal-style printing.

> GitHub short description (paste in repo settings):  
> `Offline tailor shop POS — Urdu UI, orders, measurements, payments & thermal slips | Flutter`

## Features

- **Shop account** — register with shop name, phone, address (required); local login
- **Customers** — save and search customer records
- **Orders / suits** — garment type, Urdu measurement fields, dates, karigar assign, tags
- **Order & karigar slips** — 58mm PDF print/share; shop name from registration on slip header
- **Payments** — advance, partial payments, remaining balance per suit
- **Receive flow** — when customer receives the suit, mark received and clear remaining payment
- **Payments screen** — this month received, outstanding balance, date-wise history, suit-wise baqiya
- **Fully offline** — SQLite on device; ready for Play Store (Android)

## Tech

- Flutter (Material 3)
- SQLite (`sqflite`) + SharedPreferences
- PDF printing (`pdf` / `printing`)
- Urdu RTL UI

## Run

```bash
flutter pub get
flutter run -d android
```

Chrome (web SQLite):

```bash
flutter run -d chrome
```

## Package

- App name: **Taller Master**
- Application ID: `com.tallermaster.app`

## License

Private / your project — update as needed.
