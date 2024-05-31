// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import SwiftSyntax
import SwiftParser
import Foundation
import Support

@main
struct SwiftSort: ParsableCommand {

    @Argument(help: "The swift source file to sort.")
    var path: String

    public mutating func run() throws {
        let url = URL(filePath: path)
        print(try SwiftSourceSorter.sort(contentsOf: url))
    }
}
