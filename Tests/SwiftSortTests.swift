import XCTest
@testable import Support

class SwiftSortTests: XCTestCase {
    func test() throws {
        let url = URL(filePath: "/Users/schwa/Shared/Desktop Stuff/SwiftSort/Sources/Support/Support.swift")
        print(try SwiftSourceSorter.sort(contentsOf: url))
    }
}
