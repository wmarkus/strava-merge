# ZwiftSync

Enrich your Strava activities with Apple Watch heart rate data. One tap.

## What It Does

When you ride Zwift with an Apple Watch, your data is split:
- **Zwift** → power, cadence, speed, GPS, laps → auto-uploads to Strava
- **Apple Watch** → heart rate, calories → stays on your phone

ZwiftSync bridges the gap. It pulls the Zwift activity from Strava, merges it with your Apple Watch heart rate data, and replaces it — giving you **one clean activity** with all the data.

## How It Works

1. Finish your Zwift ride (auto-uploads to Strava as usual)
2. Open ZwiftSync on your iPhone
3. See activities missing heart rate, auto-matched to Apple Watch workouts
4. Tap **"Enrich"** → done in ~10 seconds

## Tech Stack

- Swift 6 / SwiftUI / iOS 17+
- HealthKit (per-second heart rate from Apple Watch)
- Strava API v3 (OAuth 2.0 with PKCE)
- TCX file generation for merged uploads

## Architecture

```
Strava API ──(streams)──▶ ┌──────────────┐
                          │  ZwiftSync   │ ──▶ Strava API (upload)
HealthKit ──(HR data)───▶ │  (merge)     │
                          └──────────────┘
```

## Building

Open `ZwiftSync.xcodeproj` in Xcode 16+ and build for iOS 17+.

You'll need:
- A Strava API application (register at https://www.strava.com/settings/api)
- Add your Client ID and redirect URI in `Config.swift`

## License

MIT

## Privacy

See [PRIVACY.md](PRIVACY.md) for the full privacy policy. TL;DR: all processing is on-device, no data is collected, no server backend exists.

