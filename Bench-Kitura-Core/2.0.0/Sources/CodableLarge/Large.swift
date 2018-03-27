import Foundation

struct Large {
    struct ProgramList {
        let programs: [Program]
    }

    let programList: ProgramList
}

struct Program {
    let title: String
    let description: String?
    let subtitle: String?
    let season: Int?
    let episode: Int?
    let chanId: String
    let recording: Recording
}

struct Recording {
    enum RecGroup: String, Codable {
        case Deleted = "Deleted"
        case Default = "Default"
        case LiveTV = "LiveTV"
        case Unknown
    }

    enum Status: String, Codable {
        case None = "0"
        case Recorded = "-3"
        case Recording = "-2"
        case Unknown
    }

    let recordId: String
    let recGroup: RecGroup
    let startTs: String
    let status: Status
}
