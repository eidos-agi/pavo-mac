from pathlib import Path

from pavofront.core import CaptureKind, IngestRequest, Pipeline, PlaudFile, classify


def test_classify():
    assert classify(PlaudFile(id="1", title="Tuesday Standup", speaker_count=1)) == CaptureKind.meeting
    assert classify(PlaudFile(id="2", title="Voice memo", speaker_count=1)) == CaptureKind.personal


def test_ingest_and_skip(tmp_path: Path):
    pipe = Pipeline(tmp_path)
    job = pipe.ingest(IngestRequest(id="rec_standup_01"))
    assert job.status.value == "review_pending"
    assert job.pack_path
    pack = Path(job.pack_path)
    assert (pack / "index.md").exists()
    assert "profile: omf" in (pack / "index.md").read_text()
    again = pipe.ingest(IngestRequest(id="rec_standup_01"))
    assert again.status.value == "skipped"


def test_personal_oanf(tmp_path: Path):
    pipe = Pipeline(tmp_path)
    job = pipe.ingest(IngestRequest(id="rec_memo_02"))
    assert job.kind == CaptureKind.personal
    assert "profile: oanf" in Path(job.pack_path, "index.md").read_text()
