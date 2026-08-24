# HTTP contract (Swift talks to this)

Base: local host process. JSON only. No auth in mock mode.

## GET /api/doctor

```json
{ "plaud": { "email": "mock@plaud.local", "mode": "mock" }, "home": "…", "ledger_entries": 0, "mode": "mock" }
```

## GET /api/files

Array of `{ id, title, duration_seconds, speaker_count, tags }`.

## POST /api/ingest

```json
{ "id": "rec_standup_01", "kind": "meeting", "tags": ["work"], "force": false }
```

`kind` optional — classifier runs if omitted.

Returns a job:

```json
{
  "id": "rec_standup_01",
  "title": "Tuesday Standup",
  "kind": "meeting",
  "tags": ["work"],
  "status": "review_pending",
  "pack_path": "…",
  "sha256": "…",
  "message": "landed proposed pack; human review still open"
}
```

Statuses: `review_pending` | `skipped` | `error`.

## POST /api/sync?force=false

Ingest every listed file. Returns job array.

## GET /api/status

Ledger map keyed by Plaud id.

## Safety

- Never auto-finalize speaker identity.
- Outcomes in meeting packs are `proposed`.
- Unknown id → `status: error`.
