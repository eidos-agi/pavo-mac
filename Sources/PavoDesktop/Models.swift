import Foundation

enum CaptureKind: String, Codable, CaseIterable {
    case meeting
    case personal
}

enum Mailbox: String, CaseIterable, Identifiable {
    case inbox, recent, past
    var id: String { rawValue }
    var title: String {
        switch self {
        case .inbox: "Inbox"
        case .recent: "Recent"
        case .past: "Past"
        }
    }
}

struct Recording: Identifiable, Hashable {
    var id: String
    var title: String
    var source: String
    var createdAt: Date
    var duration: TimeInterval
    var tags: [String]
    var note: String
    var transcript: String
    var status: String
}

struct Person: Identifiable, Hashable {
    var id: String
    var name: String
}

struct ContactOdds: Identifiable, Hashable {
    var id: String { personId }
    var personId: String
    var name: String
    var pct: Int
}

struct SpeakerSpan: Identifiable, Hashable {
    var id: String
    var label: String
    var start: TimeInterval
    var end: TimeInterval
    var assignedId: String
    var odds: [ContactOdds]
}

struct PackChoice: Identifiable, Hashable {
    var id: String
    var name: String
    var bind: CaptureKind
    var pct: Int
}
