<!-- coderabbit-ai-generated:v1 -->

# Tracking connections

Dream Reader includes AniList and MyAnimeList clients for title search, local title linking and explicitly requested chapter-progress updates. Tokens use Android secure storage and are excluded from backups. Linked title IDs and public client IDs are ordinary local settings and may be backed up.

## Register the application

Create an application owned by the Dream Reader operator in each service's developer settings. Use a public/native client where that distinction is available. Register this exact redirect URI:

`com.dreamreader.app.auth://oauth`

Enter the public client ID in Settings → Tracking connections → Application settings. A release can alternatively supply `ANILIST_CLIENT_ID` and `MAL_CLIENT_ID` through Flutter `--dart-define`. Never embed a client secret or another application's client identity. The service's browser consent page handles account credentials.

AniList uses its documented mobile implicit flow; MyAnimeList uses its public-client authorization code flow with PKCE and token refresh. Dream Reader checks the callback URI and authorization state before saving credentials. AniList tokens expire and require reconnection; the client refreshes expired MyAnimeList tokens when a refresh token is available.

## Link and synchronize

Open a title's tracking action, select a service and search for the matching title. Linking stores the association locally. “Send reading progress” previews an editable chapter number. The client fetches remote progress and sends the higher of that value and the confirmed local number, preserving other list fields. Different source chapter numbering can be corrected in the preview. Synchronization is explicit; it does not upload reading activity in the background.

Disconnect removes this device's stored token. To invalidate existing authorization, revoke the application in the service's account settings. Extensions run under the same application UID and are not a security sandbox; install only extensions you trust with app data.

## Verification boundary

Client tests cover rejected authorization state, PKCE request construction, credential separation, refresh-token retention and progress preservation using synthetic transport responses. Actual provider sign-in, live account search and progress writes remain unverified until valid Dream Reader client registrations and a test account are available. The pinned CodeRabbit emulate v0.0.1 catalogue was inspected; it has no AniList or MyAnimeList implementation, so another provider's OAuth emulator is not used as evidence.

Technical references: [AniList authentication](https://docs.anilist.co/guide/auth/), [AniList implicit grant](https://docs.anilist.co/guide/auth/implicit), [MyAnimeList authorization](https://myanimelist.net/apiconfig/references/authorization), [MyAnimeList API](https://myanimelist.net/apiconfig/references/api/v2), [flutter_web_auth_2](https://pub.dev/packages/flutter_web_auth_2).
