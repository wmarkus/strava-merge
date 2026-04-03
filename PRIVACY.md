# Privacy Policy — ZwiftSync

**Last updated: April 3, 2026**

## Overview

ZwiftSync is an iOS app that enriches Strava activities with Apple Watch heart rate data. Your privacy is important to us. This policy explains what data we access, how we use it, and what we do not do.

## Data We Access

### HealthKit (Apple Watch)
- **Heart rate samples** — read-only access to heart rate data recorded during workouts
- **Workout metadata** — start time, end time, and workout type to match with Strava activities
- We **never write** to HealthKit
- We **never store** your health data on any server

### Strava
- **Activity list** — to find activities missing heart rate data
- **Activity streams** — to read power, cadence, GPS, and other workout data
- **Upload** — to upload enriched activity files
- **Delete** — to remove the original (HR-less) activity after the enriched one is uploaded

## Data Processing

All data processing happens **entirely on your device**:
1. Heart rate data is read from HealthKit on your iPhone
2. Activity stream data is pulled from the Strava API
3. The merge happens in-memory on your device
4. The merged file is uploaded directly from your device to Strava

**We do not operate any server.** There is no backend, no database, no analytics service.

## Data We Do NOT Collect

- We do not collect personal information
- We do not track your location
- We do not use analytics or telemetry
- We do not share data with third parties
- We do not store your Strava credentials (OAuth tokens are stored in your device's Keychain)
- We do not store health data beyond the duration of the merge operation

## Third-Party Services

- **Strava API** — governed by [Strava's Privacy Policy](https://www.strava.com/legal/privacy)
- **Apple HealthKit** — governed by [Apple's Privacy Policy](https://www.apple.com/legal/privacy/)

## Data Retention

- OAuth tokens are stored in your device's Keychain and can be removed by disconnecting Strava in the app
- No health data is persisted to disk
- Enrichment history (activity IDs and timestamps only) is stored locally on your device

## Your Rights

- You can revoke HealthKit access at any time in iOS Settings → Privacy → Health
- You can revoke Strava access at any time in the app or at strava.com/settings/apps
- Deleting the app removes all local data

## Children's Privacy

ZwiftSync is not directed at children under 13 and does not knowingly collect information from children.

## Changes to This Policy

We may update this policy from time to time. Changes will be posted in the app and in this repository.

## Contact

For questions about this privacy policy, open an issue at [github.com/wmarkus/strava-merge](https://github.com/wmarkus/strava-merge/issues).
