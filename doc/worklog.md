# FreeTube Worklog

## 2026-02-13

### Completed in this session
1. Audited repo structure and confirmed project is scaffold-only SwiftUI + SwiftData.
2. Defined model-layer architecture into `Domain`, `Application`, and `Infrastructure`.
3. Clarified feature scope: ad-free viewing, privacy-first local data, no sign-in, local subscriptions/playlists, history/download library.
4. Reclassified `yt-dlp` usage as technical mechanism, not a product feature.
5. Locked defaults: SwiftData primary persistence, external runtime (not bundled), app-managed download directory, NewPipe-style subscription import/export.

### Decisions
1. Keep runtime configurable and validated at startup.
2. Resolve playback stream URL on-demand.
3. Support both video and audio download presets (implementation detail).

### Next implementation step
1. Implement model entities and repository/service protocols described in architecture plan.
