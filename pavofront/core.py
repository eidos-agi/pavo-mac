"""Mock-first Pavo Mac core. Swap PlaudClient for CLI/MCP later."""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field


class CaptureKind(str, Enum):
    meeting = "meeting"
    personal = "personal"

    @property
    def profile(self) -> str:
        return "omf" if self is CaptureKind.meeting else "oanf"

    @property
    def pack_root(self) -> str:
        return ".meetings" if self is CaptureKind.meeting else ".notes"


class PlaudFile(BaseModel):
    id: str
    title: str
    duration_seconds: float | None = None
    speaker_count: int | None = None
    tags: list[str] = Field(default_factory=list)


class IngestRequest(BaseModel):
    id: str
    kind: CaptureKind | None = None
    tags: list[str] = Field(default_factory=list)
    force: bool = False


class JobStatus(str, Enum):
    review_pending = "review_pending"
    skipped = "skipped"
    error = "error"


class Job(BaseModel):
    id: str
    title: str
    kind: CaptureKind
    tags: list[str] = Field(default_factory=list)
    status: JobStatus
    pack_path: str | None = None
    message: str | None = None
    sha256: str | None = None


HINTS = ("standup", "stand-up", "sync", "call", "meeting", "interview", "1:1", "1-1", "weekly", "retro")

MOCK_FILES = [
    PlaudFile(id="rec_standup_01", title="Tuesday Standup", duration_seconds=920, speaker_count=4, tags=["work"]),
    PlaudFile(id="rec_memo_02", title="Voice memo — groceries", duration_seconds=45, speaker_count=1, tags=["personal"]),
    PlaudFile(id="rec_interview_03", title="Candidate interview — Jane", duration_seconds=1800, speaker_count=2, tags=["hiring"]),
    PlaudFile(id="rec_walk_04", title="Walking thoughts", duration_seconds=300, speaker_count=1, tags=[]),
]

MOCK_TRANSCRIPTS = {
    "rec_standup_01": "Alice: Status on OMF?\nBob: Pack writer lands today.\nAlice: Ship proposed only.",
    "rec_memo_02": "Need milk, eggs, and coffee filters.",
    "rec_interview_03": "Interviewer: Tell me about Prim packs.\nJane: Face documents plus validators.",
    "rec_walk_04": "Remember to draft the OANF intention doc.",
}

MOCK_NOTES = {
    "rec_standup_01": "Action: land OMF packs as proposed.",
    "rec_memo_02": "Shopping list captured.",
    "rec_interview_03": "Strong on format design; follow up on validators.",
    "rec_walk_04": "Personal note: write INTENTION.md.",
}


def classify(file: PlaudFile) -> CaptureKind:
    hay = file.title.lower()
    if any(h in hay for h in HINTS):
        return CaptureKind.meeting
    if (file.speaker_count or 0) >= 2:
        return CaptureKind.meeting
    return CaptureKind.personal


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


class PlaudClient:
    def me(self) -> dict[str, str]:
        return {"email": "mock@plaud.local", "mode": "mock"}

    def list_files(self) -> list[PlaudFile]:
        return list(MOCK_FILES)

    def get_transcript(self, file_id: str) -> str:
        return MOCK_TRANSCRIPTS.get(file_id, "")

    def get_note(self, file_id: str) -> str:
        return MOCK_NOTES.get(file_id, "")

    def download_audio(self, file_id: str, dest: Path) -> Path:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(f"MOCK-AUDIO:{file_id}".encode())
        return dest


class Ledger:
    def __init__(self, path: Path):
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self._write({})

    def _read(self) -> dict[str, Any]:
        return json.loads(self.path.read_text(encoding="utf-8"))

    def _write(self, data: dict[str, Any]) -> None:
        self.path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")

    def get(self, plaud_id: str) -> dict[str, Any] | None:
        return self._read().get(plaud_id)

    def should_skip(self, plaud_id: str, digest: str, force: bool = False) -> bool:
        if force:
            return False
        row = self.get(plaud_id)
        return bool(row and row.get("sha256") == digest)

    def upsert(self, plaud_id: str, **fields: Any) -> None:
        data = self._read()
        row = data.get(plaud_id, {})
        row.update(fields)
        data[plaud_id] = row
        self._write(data)

    def all(self) -> dict[str, Any]:
        return self._read()


def _yaml(s: str) -> str:
    return '"' + s.replace('"', '\\"') + '"'


def write_pack(*, root: Path, file: PlaudFile, kind: CaptureKind, tags: list[str], audio_path: Path, transcript: str, note: str) -> Path:
    pack_id = f"{kind.profile}-{file.id[:12]}"
    pack = root / kind.pack_root / pack_id
    (pack / "artifacts").mkdir(parents=True, exist_ok=True)
    (pack / "transcript").mkdir(parents=True, exist_ok=True)
    (pack / "media").mkdir(parents=True, exist_ok=True)
    if kind is CaptureKind.meeting:
        (pack / "outcomes" / "decisions").mkdir(parents=True, exist_ok=True)
    media = pack / "media" / "audio.mp3"
    media.write_bytes(audio_path.read_bytes())
    digest = sha256_file(media)
    bytes_n = media.stat().st_size
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    tag_list = ", ".join(_yaml(t) for t in tags)
    if kind is CaptureKind.meeting:
        face = f"""---
okf_version: "0.2"
omf_version: "0.1.1"
profile: omf
type: meeting
omf_id: {pack_id}
title: {_yaml(file.title)}
status: captured
sensitivity: private
source: plaud
plaud_id: {file.id}
started_at: {now}
ended_at: {now}
series: none
verified: false
tags: [{tag_list}]
plane: personal
---
# {file.title}
"""
    else:
        face = f"""---
okf_version: "0.2"
oanf_version: "0.0.1"
profile: oanf
type: audio_note
oanf_id: {pack_id}
title: {_yaml(file.title)}
status: captured
sensitivity: private
source: plaud
plaud_id: {file.id}
captured_at: {now}
tags: [{tag_list}]
plane: personal
---
# {file.title}
"""
    (pack / "index.md").write_text(face, encoding="utf-8")
    (pack / "log.md").write_text(
        f"# log\n- mock download sha256={digest} bytes={bytes_n}\n- kind={kind.value}\n- status=review_pending\n",
        encoding="utf-8",
    )
    (pack / "artifacts" / "recording.md").write_text(
        f"""---
okf_version: "0.2"
profile: {kind.profile}
artifact: recording
locator: ../media/audio.mp3
bytes: {bytes_n}
sha256: {digest}
identity: plaud:{file.id}
---
# Recording pointer
""",
        encoding="utf-8",
    )
    tx_state = "present" if transcript.strip() else "not_attempted"
    (pack / "transcript" / "index.md").write_text(
        f"""---
okf_version: "0.2"
profile: {kind.profile}
transcript: {tx_state}
source: plaud-mock
---
# Transcript
{transcript or "_No transcript._"}
""",
        encoding="utf-8",
    )
    (pack / "tags.md").write_text("# tags\n" + "\n".join(f"- {t}" for t in tags) + "\n", encoding="utf-8")
    if kind is CaptureKind.meeting and note.strip():
        (pack / "outcomes" / "decisions" / "proposed-from-note.md").write_text(
            f"---\nstatus: proposed\nowner: human\n---\n# Proposed from note\n{note}\n",
            encoding="utf-8",
        )
    sh = pack / "prims.sh"
    sh.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
PACK="$(cd "$(dirname "$0")" && pwd)"
cmd="${1:-pack}"
case "$cmd" in
  pack) (cd "$(dirname "$PACK")" && zip -r "${2:-$PACK.prim.zip}" "$(basename "$PACK")");;
  validate) echo "mock validate ok $PACK";;
  *) echo "usage: prims.sh [pack|validate]"; exit 1;;
esac
""",
        encoding="utf-8",
    )
    sh.chmod(0o755)
    return pack


class Pipeline:
    def __init__(self, home: Path, plaud: PlaudClient | None = None):
        self.home = home
        self.inbox = home / "inbox"
        self.packs = home / "packs"
        self.ledger = Ledger(home / "ledger.json")
        self.plaud = plaud or PlaudClient()
        self.inbox.mkdir(parents=True, exist_ok=True)
        self.packs.mkdir(parents=True, exist_ok=True)

    def doctor(self) -> dict[str, Any]:
        return {
            "plaud": self.plaud.me(),
            "home": str(self.home),
            "ledger_entries": len(self.ledger.all()),
            "mode": "mock",
        }

    def list_files(self) -> list[PlaudFile]:
        return self.plaud.list_files()

    def status(self) -> dict[str, Any]:
        return self.ledger.all()

    def ingest(self, req: IngestRequest) -> Job:
        files = {f.id: f for f in self.plaud.list_files()}
        if req.id not in files:
            return Job(id=req.id, title=req.id, kind=CaptureKind.personal, status=JobStatus.error, message="unknown id")
        file = files[req.id]
        kind = req.kind or classify(file)
        tags = list(dict.fromkeys([*file.tags, *req.tags]))
        audio = self.plaud.download_audio(file.id, self.inbox / file.id / "audio.mp3")
        digest = sha256_file(audio)
        if self.ledger.should_skip(file.id, digest, force=req.force):
            row = self.ledger.get(file.id) or {}
            return Job(
                id=file.id,
                title=file.title,
                kind=CaptureKind(row.get("kind", kind.value)),
                tags=tags,
                status=JobStatus.skipped,
                pack_path=row.get("pack_path"),
                sha256=digest,
                message="same sha256 in ledger",
            )
        pack = write_pack(
            root=self.packs,
            file=file,
            kind=kind,
            tags=tags,
            audio_path=audio,
            transcript=self.plaud.get_transcript(file.id),
            note=self.plaud.get_note(file.id),
        )
        self.ledger.upsert(
            file.id,
            sha256=digest,
            kind=kind.value,
            pack_path=str(pack),
            packed_at=datetime.now(timezone.utc).isoformat(),
            status=JobStatus.review_pending.value,
            tags=tags,
            title=file.title,
        )
        return Job(
            id=file.id,
            title=file.title,
            kind=kind,
            tags=tags,
            status=JobStatus.review_pending,
            pack_path=str(pack),
            sha256=digest,
            message="landed proposed pack; human review still open",
        )

    def sync(self, force: bool = False) -> list[Job]:
        return [self.ingest(IngestRequest(id=f.id, force=force)) for f in self.list_files()]
