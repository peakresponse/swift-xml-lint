import CLibxml2
import Foundation

private let libxmlInit: Void = { xmlInitParser() }()
private let libxmlLock = NSLock()

public struct XMLValidationError: Sendable {
    public let line: Int
    public let column: Int
    public let message: String
    public let location: String
}

public enum XMLLintError: Error, Sendable {
    case invalidSchema(String)
    case invalidXML(String)
}

public final class XMLValidator: @unchecked Sendable {
    private let schema: xmlSchemaPtr

    public init(xsdURL: URL) throws {
        schema = try XMLValidator.parseSchema(parserCtxt: xsdURL.path.withCString { xmlSchemaNewParserCtxt($0) })
    }

    public init(xsd: String) throws {
        schema = try XMLValidator.parseSchema(parserCtxt: xsd.withCString { xmlSchemaNewMemParserCtxt($0, Int32(xsd.utf8.count)) })
    }

    private static func parseSchema(parserCtxt: xmlSchemaParserCtxtPtr?) throws -> xmlSchemaPtr {
        _ = libxmlInit
        libxmlLock.lock()
        defer { libxmlLock.unlock() }

        guard let parserCtxt else {
            throw XMLLintError.invalidSchema("Failed to create schema parser context")
        }
        defer { xmlSchemaFreeParserCtxt(parserCtxt) }

        var schemaErrors: [String] = []
        let parsed: xmlSchemaPtr? = withUnsafeMutablePointer(to: &schemaErrors) { errorsPtr in
            xmlSchemaSetParserStructuredErrors(
                parserCtxt,
                { ctxt, error in
                    guard let ctxt, let error else { return }
                    let list = ctxt.assumingMemoryBound(to: [String].self)
                    let msg = error.pointee.message.map { String(cString: $0) } ?? ""
                    list.pointee.append(msg)
                },
                errorsPtr
            )
            return xmlSchemaParse(parserCtxt)
        }

        guard let parsed else {
            throw XMLLintError.invalidSchema(schemaErrors.joined())
        }
        return parsed
    }

    deinit {
        libxmlLock.lock()
        xmlSchemaFree(schema)
        libxmlLock.unlock()
    }

    public func validate(xml: String) throws -> [XMLValidationError] {
        libxmlLock.lock()
        defer { libxmlLock.unlock() }

        let doc = xml.withCString { ptr in
            // suppress default stderr output for parse errors
            xmlSetStructuredErrorFunc(nil, { _, _ in })
            defer { xmlSetStructuredErrorFunc(nil, nil) }
            return xmlReadMemory(ptr, Int32(xml.utf8.count), nil, nil, 0)
        }
        guard let doc else {
            let msg = xmlGetLastError().flatMap { $0.pointee.message.map { String(cString: $0) } } ?? "Unknown parse error"
            throw XMLLintError.invalidXML(msg)
        }
        defer { xmlFreeDoc(doc) }

        guard let validCtxt = xmlSchemaNewValidCtxt(schema) else {
            throw XMLLintError.invalidXML("Failed to create validation context")
        }
        defer { xmlSchemaFreeValidCtxt(validCtxt) }

        var validationErrors: [XMLValidationError] = []
        withUnsafeMutablePointer(to: &validationErrors) { errorsPtr in
            xmlSchemaSetValidStructuredErrors(
                validCtxt,
                { ctxt, error in
                    guard let ctxt, let error else { return }
                    let list = ctxt.assumingMemoryBound(to: [XMLValidationError].self)
                    let msg = error.pointee.message.map { String(cString: $0) } ?? ""
                    let line = Int(error.pointee.line)
                    let col = Int(error.pointee.int2)
                    let location: String
                    if let rawNode = error.pointee.node {
                        location = xpathLocation(for: rawNode.assumingMemoryBound(to: _xmlNode.self))
                    } else if let doc = error.pointee.ctxt.map({ $0.assumingMemoryBound(to: _xmlDoc.self) }) {
                        location = xpathLocation(forLine: line, in: doc)
                    } else {
                        location = ""
                    }
                    list.pointee.append(XMLValidationError(line: line, column: col, message: msg, location: location))
                },
                errorsPtr
            )
            xmlSchemaValidateDoc(validCtxt, doc)
        }
        return validationErrors
    }
}
