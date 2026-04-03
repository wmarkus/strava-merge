# App Store Review Notes — ZwiftSync

## HealthKit Usage

ZwiftSync reads heart rate data and workout metadata from HealthKit to enrich Strava cycling activities that are missing heart rate information. This is a legitimate fitness data integration use case.

### NSHealthShareUsageDescription
"ZwiftSync reads your Apple Watch heart rate data to enrich Strava activities with heart rate information that was recorded during your cycling workouts."

### NSHealthUpdateUsageDescription
"ZwiftSync does not write to Apple Health."

### Data types accessed (read-only):
- `HKQuantityTypeIdentifierHeartRate` — to merge heart rate into cycling activities
- `HKWorkoutType` — to match Apple Watch workouts with Strava activities by time

## Strava API Usage

The app uses the Strava API v3 with OAuth 2.0 (PKCE flow) to:
1. Read the user's recent activities
2. Pull activity stream data (time, GPS, power, cadence, altitude)
3. Delete the original activity (after user confirmation)
4. Upload an enriched activity with heart rate data
5. Update activity metadata (name, description, gear)

Strava API scopes: `activity:read_all`, `activity:write`

## Demo Account

To test the app, you'll need:
- A Strava account with at least one VirtualRide activity that has no heart rate data
- An Apple Watch that recorded a workout overlapping with that Strava activity

If you need test credentials, please contact the developer.

## Key User Flow

1. User connects Strava via OAuth
2. User grants HealthKit read access
3. App shows Strava activities missing heart rate
4. App auto-matches to Apple Watch workouts by time overlap
5. User taps "Enrich" → app merges data and replaces the activity
6. User is warned that kudos/comments will be lost before confirming

## Privacy

- All processing is on-device
- No server backend
- No data collection or analytics
- See PRIVACY.md for full privacy policy
