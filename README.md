# Pavo Mac

**The Mac host for [Pavo](https://github.com/eidos-agi/pavo).**  
Plaud inbox → download → tag → classify → land an OMF or OANF Prim pack.

This is the **mock-first** contract. Plaud I/O is mocked. Speaker identity is never auto-approved. Outcomes land as `proposed`.

```text
SwiftUI later  ──HTTP──►  same API as this repo
Web desk now   ──calls─►  pavofront core (Python / TS twin)
```

## Loop

```text
Plaud list → download audio (hash it)
           → pull transcript + note
           → classify meeting | personal (overridable)
           → write pack (OMF | OANF)
           → ledger skip on same sha256
           → status = review_pending
```

## Status

| Surface | State |
|---|---|
| Mock core + ledger + packer | shipped |
| Web desk (contract UI) | shipped as the testable host |
| SwiftUI Mac app | stub — talks the same HTTP API |
| Live Plaud CLI / MCP | not wired (adapter interface is ready) |
| `omf-validate` | post-land hook, optional |

## Python core

```bash
python3 -m pip install -e ".[dev]"
pytest -q
pavofront doctor
pavofront list
pavofront sync
pavofront ingest rec_standup_01 --tag work
```

`PAVOFRONT_HOME` defaults to `~/Eidos/PavoFront`.

## Packs

- **Meeting** → Open Meeting Format (`profile: omf`) under `.meetings/`
- **Personal** → Open Audio Notes Format draft (`profile: oanf`) under `.notes/`
- Media lives in `media/`. `artifacts/` holds **pointers + sha256** only.
- Human gate stays closed. Decisions are `status: proposed`, `owner: human`.

See [CONTRACT.md](CONTRACT.md) and [INTENTION.md](INTENTION.md).

## Swift later

`Sources/PavoMac` is a thin client for `GET /api/files`, `POST /api/ingest`, `POST /api/sync`, `GET /api/status`. Do not put packer logic in the UI.

## License

MIT — Eidos AGI
