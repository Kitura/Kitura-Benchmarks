import Foundation

struct Small: Codable {
    let A: Int
    let B: Double
    let C: String
    struct Nested: Codable {
        let X: Int
        let Y: Double
        let Z: [Int]
    }
    let D: Nested
    let E: UInt
    let F: Int8
    let G: Int16
    let H: Int32
    let I: Int64
    let J: UInt8
    let K: UInt16
    let L: UInt32
    let M: UInt64
}

