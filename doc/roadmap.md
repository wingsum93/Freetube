# FreeTube Roadmap

## Product Goals
1. Watch YouTube without ads.
2. Keep user activity local and private.
3. No account requirement.

## Planned Features

### Phase 1 (MVP)
1. Ad-free playback.
2. Local subscriptions.
3. Local playlists.
4. Watch history.
5. Download library management.

### Phase 2
1. Better playlist management (sorting/filtering).
2. Richer library search/filter.
3. Subscription import/export UX improvements.

### Phase 3
1. Feed/browse enhancements (if added later).
2. Playback quality and resilience improvements.

## Technical Enablers (Non-Feature Scope)
1. SwiftData model persistence.
2. Swift `Process` wrapper around external Python + `yt-dlp`.
3. Runtime path validation and typed errors.
4. Background download job state machine.

## Important Interfaces and Types
1. `YTDLPClient` (metadata, stream resolution, download start).
2. `DownloadManager` (queue + progress events).
3. `PlaybackSourceResolver`.
4. SwiftData entities: `AppSettings`, `VideoRecord`, `ChannelSubscription`, `Playlist`, `PlaylistItem`, `WatchHistoryEntry`, `DownloadJob`.

## Out of Scope for MVP
1. Google sign-in/account sync.
2. Cloud sync.
3. Bundled Python runtime packaging.
4. Full trending/search provider implementation.
