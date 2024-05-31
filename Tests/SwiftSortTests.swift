import XCTest
@testable import Support

class SwiftSortTests: XCTestCase {
    func test() throws {
        let input = """
            import Import2
            extension Struct2 { }
            func func1() {}
            struct Struct2 { }
            extension Struct1 { }
            import Import1
            let x = 10
            struct Struct1 { }

            """
        let output = try SwiftSourceSorter.sort(source: input)
        let expectedOutput = """

            import Import1
            import Import2
            let x = 10
            struct Struct1 { }
            struct Struct2 { }
            extension Struct1 { }
            extension Struct2 { }
            func func1() {}

            """

//        print(String(repeating: "#", count: 80))
//        print(expectedOutput)
//        print(String(repeating: "#", count: 80))
//        print(output)
//        print(String(repeating: "#", count: 80))

        XCTAssertEqual(expectedOutput, output)

        // This is a bit silly but it's a quick way to generate some variations.
        for _ in 0..<100 {
            let input = input.split(separator: "\n").shuffled().joined(separator: "\n")
            let output = try SwiftSourceSorter.sort(source: input)
            XCTAssertEqual(expectedOutput, output)
        }
    }
}
