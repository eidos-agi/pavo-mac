from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from .core import CaptureKind, IngestRequest, Pipeline


def home_dir() -> Path:
    return Path(os.environ.get("PAVOFRONT_HOME", Path.home() / "Eidos" / "PavoFront"))


def main(argv: list[str] | None = None) -> None:
    p = argparse.ArgumentParser(prog="pavofront")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("doctor")
    sub.add_parser("list")
    sub.add_parser("status")
    sp = sub.add_parser("sync")
    sp.add_argument("--force", action="store_true")
    ip = sub.add_parser("ingest")
    ip.add_argument("id")
    ip.add_argument("--kind", choices=[k.value for k in CaptureKind])
    ip.add_argument("--tag", action="append", default=[])
    ip.add_argument("--force", action="store_true")
    args = p.parse_args(argv)
    pipe = Pipeline(home_dir())
    if args.cmd == "doctor":
        print(json.dumps(pipe.doctor(), indent=2))
    elif args.cmd == "list":
        print(json.dumps([f.model_dump() for f in pipe.list_files()], indent=2))
    elif args.cmd == "status":
        print(json.dumps(pipe.status(), indent=2))
    elif args.cmd == "sync":
        print(json.dumps([j.model_dump() for j in pipe.sync(force=args.force)], indent=2))
    elif args.cmd == "ingest":
        job = pipe.ingest(
            IngestRequest(
                id=args.id,
                kind=CaptureKind(args.kind) if args.kind else None,
                tags=args.tag,
                force=args.force,
            )
        )
        print(json.dumps(job.model_dump(), indent=2))


if __name__ == "__main__":
    main()
