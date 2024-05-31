import SwiftSyntax
import SwiftParser
import Foundation

public enum SwiftSourceSorter {
    public static func sort(contentsOf url: URL) throws -> String {
        let source = try String(contentsOf: url)
        return try sort(source: source)
    }

    public static func sort(source: String) throws -> String {
        let tree = Parser.parse(source: source)
        // TODO: Why are we relying on `first` here instead of only. What else is in the code block? (a white space token perhaps?)
        guard let codeBlockItemList = tree.children(viewMode: .sourceAccurate).first?.as(CodeBlockItemListSyntax.self) else {
            fatalError("No code block item list at root of source.")
        }
        let items = codeBlockItemList
            .sorted()
            // Make sure all items have a new line between them. TODO: This should be made more robust..
            .map { syntax in
                var syntax = syntax
                if !syntax.description.contains("\n") {
                    syntax.leadingTrivia = .newline
                }
                return syntax
            }
        let sortedCodeBlockItemList = CodeBlockItemListSyntax(items)

        var output = ""
        print(sortedCodeBlockItemList, to: &output)

        return output
    }
}

// MARK: -

public enum DeclSortOrder: Double, Comparable {
    case imports = 0
    case variables = 1
    case typeAliases = 1.25
    case protocols = 1.5
    case types = 2
    case extensions = 3
    case functions = 4
    case other = 999

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public extension CodeBlockItemListSyntax {
    func sorted() -> CodeBlockItemListSyntax {
        let codeBlockItems = children(viewMode: .sourceAccurate)
            .compactMap { $0.as(CodeBlockItemSyntax.self) }
            .sorted(using: IdentifierSortComparator())
        return CodeBlockItemListSyntax(codeBlockItems)
    }
}

public struct IdentifierSortComparator: SortComparator {
    public var order: SortOrder = .forward

    public func compare(_ lhs: CodeBlockItemSyntax, _ rhs: CodeBlockItemSyntax) -> ComparisonResult {
        .compare(lhs.sortableValue, rhs.sortableValue)
    }
}

public extension ComparisonResult {
    static func compare<C>(_ lhs: C, _ rhs: C) -> ComparisonResult where C: Comparable {
        if lhs < rhs {
            return .orderedAscending
        } else if lhs == rhs {
            return .orderedSame
        } else {
            return .orderedDescending
        }
    }
}

public extension CodeBlockItemSyntax {
    var sortableValue: Pair<DeclSortOrder, String> {
        guard let decl = children(viewMode: .sourceAccurate).only?.as(DeclSyntax.self) else {
            fatalError("No declaration in code block item.")
        }
        return decl.sortableValue
    }
}

extension SyntaxProtocol {
    func descendents(for path: [SyntaxKind], viewMode: SyntaxTreeViewMode) -> [Syntax] {
        guard let first = path.first else {
            return []
        }
        let children = children(of: first, viewMode: viewMode)
        if path.count == 1 {
            return children
        }
        let descendents: [Syntax] = children.flatMap { child in
            child.descendents(for: Array(path.dropFirst()), viewMode: viewMode)
        }
        return descendents
    }

    func children(of kind: SyntaxKind, viewMode: SyntaxTreeViewMode) -> [Syntax] {
        return children(viewMode: viewMode).filter { syntax in
            syntax.kind == kind
        }
    }
}

public extension DeclSyntax {
    var sortableValue: Pair<DeclSortOrder, String> {
        switch kind {
        case .importDecl:
            guard let importPathComponentList = children(of: .importPathComponentList, viewMode: .sourceAccurate).only else {
                fatalError("Could not get importPathComponentList from importDecl.")
            }
            return Pair(.imports, importPathComponentList.description)
        case .structDecl, .enumDecl, .classDecl, .actorDecl:
            guard let identifier = identifierAfterKeyword(viewMode: .sourceAccurate) else {
                fatalError("Could not get identifier for declaration..")
            }
            return Pair(.types, identifier)
        case .extensionDecl:
            guard let extensionDecl = self.as(ExtensionDeclSyntax.self) else {
                fatalError("Could not convert decl to ExtensionDeclSyntax.")
            }
            let identifier = extensionDecl.name.description
            return Pair(.extensions, identifier)
        case .functionDecl:
            guard let functionDecl = self.as(FunctionDeclSyntax.self) else {
                fatalError("Could not convert decl to FunctionDeclSyntax.")
            }
            let identifier = functionDecl.name.description
            return Pair(.functions, identifier)
        case .variableDecl:
            guard let identifier = identifierAfterKeyword(viewMode: .sourceAccurate) else {
                fatalError("Could not identifier for declaration..")
            }
            return Pair(.variables, identifier)
        case .protocolDecl:
            guard let identifier = identifierAfterKeyword(viewMode: .sourceAccurate) else {
                fatalError("Could not identifier for declaration..")
            }
            return Pair(.protocols, identifier)
        case .ifConfigDecl:
            // TODO: If there's just one decl in the ifconfig block - we should order it by type. Otherwise sort the contents of the block?
            return Pair(.other, self.description)
        case .typeAliasDecl:
            // TODO: Extract name from typealias
            return Pair(.typeAliases, self.description)
        default:
            fatalError("Unknown kind: \(kind)")
        }
    }
}

public extension DeclSyntaxProtocol {
    func identifiers(viewMode: SyntaxTreeViewMode) -> [String] {
        let tokens = tokens(viewMode: viewMode)
        return tokens.compactMap { token in
            if case let .identifier(identifier) = token.tokenKind {
                return identifier
            } else {
                return nil
            }
        }
    }

    func identifierAfterKeyword(viewMode: SyntaxTreeViewMode) -> String? {
        let tokens = [TokenSyntax](tokens(viewMode: viewMode))

        let keywordIndex = tokens.firstIndex { token in
            if case let .keyword(keyword) = token.tokenKind {
                switch kind {
                case .functionDecl:
                    return keyword == .func
                case .enumDecl:
                    return keyword == .enum
                case .structDecl:
                    return keyword == .struct
                case .extensionDecl:
                    return keyword == .extension
                case .variableDecl:
                    return keyword == .let || keyword == .var
                case .classDecl:
                    return keyword == .class
                case .actorDecl:
                    return keyword == .actor
                case .protocolDecl:
                    return keyword == .protocol
                default:
                    fatalError("Could not get keyword.")
                }
            } else {
                return false
            }
        }
        guard let keywordIndex else {
            return nil
        }
        let identifierIndex = tokens.index(after: keywordIndex)
        if case let .identifier(identifier) = tokens[identifierIndex].tokenKind {
            return identifier
        } else {
            return nil
        }

    }
}

public extension ExtensionDeclSyntax {
    var name: String {
        let children = children(viewMode: .sourceAccurate)
        let keywordIndex = children.firstIndex { child in
            guard let child = child.as(TokenSyntax.self) else {
                return false
            }
            return child.tokenKind == .keyword(.extension)
        }
        guard let keywordIndex else {
            fatalError()
        }
        let nameIndex = children.index(after: keywordIndex)
        let name = children[nameIndex]
        return name.description
    }
}

public extension Sequence {
    var only: Element? {
        var iterator = makeIterator()
        let first = iterator.next()
        if iterator.next() != nil {
            return nil
        }
        return first
    }
}

extension SyntaxProtocol {
    func onlyToken(viewMode: SyntaxTreeViewMode) -> TokenSyntax? {
        tokens(viewMode: viewMode).only
    }
}

public func dumpKinds <C>(_ c: C) where C: Collection, C.Element == Syntax {
    for child in c {
        print(child.kind)
    }
}

public func dumpTokens(_ c: some DeclSyntaxProtocol) {
    let tokens = [TokenSyntax](c.tokens(viewMode: .sourceAccurate))
    print(tokens)
}

public struct Pair <T0, T1> {
    public var p0: T0
    public var p1: T1

    public init(_ p0: T0, _ p1: T1) {
        self.p0 = p0
        self.p1 = p1
    }
}

extension Pair: Equatable where T0: Equatable, T1: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.p0 == rhs.p0 && lhs.p1 == rhs.p1
    }
}

extension Pair: Comparable where T0: Comparable, T1: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.p0 < rhs.p0 {
            return true
        } else if lhs.p0 == rhs.p0 {
            return lhs.p1 < rhs.p1
        } else {
            return false
        }

    }
}
