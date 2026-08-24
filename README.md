# Pavo Mac

**Pavo CLI is the engine. This repo is the inbox.**

Mac host for [Pavo](https://github.com/eidos-agi/pavo): Plaud (and other sources) → download → tag → classify → land an OMF or OANF Prim pack.

## SwiftUI Mac app

macOS 14+, Xcode 15+:

```text
open Package.swift
```

Run the **PavoDesktop** scheme.

Three-pane mail desk:

1. **What is this?** Meeting (OMF) vs personal note (OANF), exclusive %.
2. **Who was on this call?** Detected speaker on the left, contact picker on the right, options ordered by match %. Every speaker always has a name.
3. **Tags**, then land a **proposed** pack. Human gate stays closed.

Inbox is unorganized only. Recent is last 3 days. Past is already packed.

Do not put packer logic in Swift. The intelligence plane remains `eidos-agi/pavo`.

## Python mock core

```bash
python3 -m pip install -e ".[dev]"
pytest -q
pavofront doctor
```

See [CONTRACT.md](CONTRACT.md) and [INTENTION.md](INTENTION.md).

## License

MIT — Eidos AGI
