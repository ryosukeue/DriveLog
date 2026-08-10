# DriveLog CloudKit setup

The app uses the `iCloud.com.ryosukeue.DriveLog` container and its public database.
Before distributing a production build, open CloudKit Console for that container and verify these
record types created by a development build:

- `DriveLogProfile`: `ownerRecordName` (String), `displayName` (String), `updatedAt` (Date/Time)
- `DriveLogFriendship`: `participants` (List of String), `createdAt` (Date/Time), `updatedAt` (Date/Time)
- `DriveLogMonthlyDistance`: `ownerRecordName` (String), `monthKey` (String),
  `distanceMeters` (Double), `updatedAt` (Date/Time)

Add a queryable index for `DriveLogFriendship.participants`. Friend invitations also keep a local
fallback on the accepting device, but this index is required for the inviter to discover the new
friendship. Deploy the development schema to production before TestFlight or App Store release.

Public friend IDs use additional `DriveLogProfile` records whose record name starts with
`friend_id_`. They reuse the existing profile fields, so no additional record type or query index is
required. QR codes contain the app-only `drivelog://friend?id=...` URL. Shared text contains only the
friend ID and App Store download URL.

The public database contains only the display name, friend relationship, month key, and total
monthly distance. Routes, location events, vehicle audio identifiers, and photos remain local.
