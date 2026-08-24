import Foundation
import SwiftUI

@MainActor
final class Desk: ObservableObject {
    @Published var mailbox: Mailbox = .inbox
    @Published var selectedId: String?
    @Published var step: Int = 0
    @Published var packId: String = "omf"
    @Published var tags: Set<String> = []
    @Published var people: [Person]
    @Published var recordings: [Recording]
    @Published var spans: [String: [SpeakerSpan]] = [:]
    @Published var packed: Set<String> = []

    init() {
        people = Self.seedPeople
        recordings = Self.seedRecordings
        selectedId = recordings.sorted { $0.createdAt > $1.createdAt }.first { $0.status == "new" }?.id
        for rec in recordings {
            spans[rec.id] = Self.spans(for: rec, people: people)
        }
        if let rec = selected {
            packId = rec.kindGuess == .personal ? "oanf" : "omf"
            tags = Set(rec.tags)
        }
    }

    var selected: Recording? { recordings.first { $0.id == selectedId } }

    var inbox: [Recording] { recordings.filter { $0.status == "new" }.sorted { $0.createdAt > $1.createdAt } }
    var recent: [Recording] {
        let cut = Date(timeIntervalSince1970: 1_787_529_600).addingTimeInterval(-3 * 86_400)
        return recordings.filter { $0.createdAt >= cut }.sorted { $0.createdAt > $1.createdAt }
    }
    var past: [Recording] {
        recordings.filter { $0.status != "new" }.sorted { $0.createdAt > $1.createdAt }
    }

    var visible: [Recording] {
        switch mailbox {
        case .inbox: inbox
        case .recent: recent
        case .past: past
        }
    }

    var selectedSpans: [SpeakerSpan] { spans[selectedId ?? ""] ?? [] }

    var packs: [PackChoice] {
        guard let rec = selected else { return [] }
        let meeting = rec.kindGuess == .meeting ? 94 : 12
        return [
            PackChoice(id: "omf", name: "Meeting", bind: .meeting, pct: meeting),
            PackChoice(id: "oanf", name: "Personal note", bind: .personal, pct: 100 - meeting),
        ]
    }

    var stepsForPack: Int { packId == "oanf" ? 2 : 3 }

    func select(_ id: String) {
        selectedId = id
        step = 0
        if let rec = recordings.first(where: { $0.id == id }) {
            packId = rec.kindGuess == .personal ? "oanf" : "omf"
            tags = Set(rec.tags)
        }
    }

    func assign(spanId: String, personId: String) {
        guard let recId = selectedId, var list = spans[recId] else { return }
        if let i = list.firstIndex(where: { $0.id == spanId }) {
            list[i].assignedId = personId
            spans[recId] = list
        }
    }

    func addPerson(named name: String, to spanId: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let person = Person(id: "ppl_\(trimmed.lowercased())", name: trimmed)
        people.append(person)
        if let recId = selectedId, var list = spans[recId], let i = list.firstIndex(where: { $0.id == spanId }) {
            list[i].odds.insert(ContactOdds(personId: person.id, name: person.name, pct: 100), at: 0)
            list[i].assignedId = person.id
            spans[recId] = list
        }
    }

    func land() {
        guard let id = selectedId else { return }
        packed.insert(id)
        if let i = recordings.firstIndex(where: { $0.id == id }) {
            recordings[i].status = "review_pending"
        }
        if let next = inbox.first(where: { $0.id != id }) {
            select(next.id)
        }
    }

    private static let seedPeople: [Person] = [
        "You", "Leah", "Rio", "Maya", "Kai", "Dana", "Eli", "Jane", "Sam", "Alice", "Bob",
    ].map { Person(id: "ppl_\($0.lowercased())", name: $0) }

    private static let iso = ISO8601DateFormatter()

    private static let seedRecordings: [Recording] = [
        rec("rec_ff_16", "Customer discovery", "fireflies", "2026-08-24T16:20:00Z", 2715, ["product"],
            "Same pack face across sources.",
            "Maya: What would make the pack useful on Monday?\nKai: Same face on every source."),
        rec("rec_board_06", "Board check-in", "google-meet", "2026-08-24T15:10:00Z", 1920, ["work"],
            "Proposed: keep review gate closed.",
            "Dana: Keep the vault closed until review.\nEli: Packs stay proposed."),
        rec("rec_memo_07", "Voice memo — parking", "plaud", "2026-08-24T12:44:00Z", 18, ["personal"],
            "Parking location.", "Level P2, near the stairs. Ticket on the dash."),
        rec("rec_zoom_19", "Zoom with Rio", "zoom", "2026-08-24T11:05:00Z", 2040, ["product"],
            "Speaker gate still open. Audio is hashed.",
            "Leah: Did Plaud keep the audio or just the notes?\nRio: Real file. Hash is on the manifest."),
        rec("rec_sync_05", "Weekly product sync", "fireflies", "2026-08-23T15:00:00Z", 2460, ["product"],
            "Proposed: freeze tagging schema this week.",
            "Kai: Route notes after proof, not before.\nSam: Tags live on the pack face."),
        rec("rec_walk_04", "Walking thoughts", "plaud", "2026-08-22T19:05:00Z", 300, ["notes"],
            "Personal note: write INTENTION.md.",
            "Remember to draft the OANF intention doc before Friday."),
    ]

    private static func rec(
        _ id: String, _ title: String, _ source: String, _ created: String,
        _ duration: TimeInterval, _ tags: [String], _ note: String, _ transcript: String
    ) -> Recording {
        Recording(
            id: id, title: title, source: source,
            createdAt: iso.date(from: created) ?? Date(),
            duration: duration, tags: tags, note: note, transcript: transcript, status: "new"
        )
    }

    private static func spans(for rec: Recording, people: [Person]) -> [SpeakerSpan] {
        let names = rec.transcript.split(separator: "\n").compactMap { line -> String? in
            guard let c = line.firstIndex(of: ":") else { return nil }
            let n = String(line[..<c])
            return n.count < 24 ? n : nil
        }
        let unique = Array(NSOrderedSet(array: names)) as? [String] ?? names
        if unique.isEmpty {
            let odds = rank(label: "You", people: people, blob: rec.transcript + rec.title)
            return [SpeakerSpan(id: "\(rec.id):solo", label: "SPEAKER_00", start: 0, end: rec.duration,
                                assignedId: odds.first?.personId ?? people[0].id, odds: odds)]
        }
        let slice = max(8, rec.duration / Double(unique.count))
        return unique.enumerated().map { i, label in
            let odds = rank(label: label, people: people, blob: rec.transcript + " " + rec.title)
            let start = Double(i) * slice
            let end = i == unique.count - 1 ? rec.duration : start + slice
            return SpeakerSpan(
                id: "\(rec.id):\(label.lowercased())",
                label: label, start: start, end: end,
                assignedId: odds.first?.personId ?? people[0].id,
                odds: odds
            )
        }
    }

    private static func rank(label: String, people: [Person], blob: String) -> [ContactOdds] {
        let lab = label.lowercased()
        let low = blob.lowercased()
        let weights: [(Person, Double)] = people.map { p in
            var w = 0.04
            if p.name.lowercased() == lab { w += 6 }
            else if p.name.lowercased().hasPrefix(lab) || lab.hasPrefix(p.name.lowercased()) { w += 2 }
            if low.contains(p.name.lowercased()) { w += 1.6 }
            return (p, w)
        }
        let sum = max(0.001, weights.reduce(0.0) { $0 + $1.1 })
        var used = 0
        var out: [ContactOdds] = weights.enumerated().map { i, pair in
            let pct = i == weights.count - 1 ? max(0, 100 - used) : Int((100 * pair.1 / sum).rounded())
            used += pct
            return ContactOdds(personId: pair.0.id, name: pair.0.name, pct: pct)
        }
        out.sort { $0.pct == $1.pct ? $0.name < $1.name : $0.pct > $1.pct }
        return out
    }
}

extension Recording {
    var kindGuess: CaptureKind {
        source == "plaud" && duration < 400 ? .personal : .meeting
    }
}
