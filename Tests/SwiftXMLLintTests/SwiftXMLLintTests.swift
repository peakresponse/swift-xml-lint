import Foundation
import Testing
@testable import SwiftXMLLint

private let testXSD = """
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="root">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="child" type="xs:string"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
"""

private let validXML = "<root><child>hello</child></root>"
private let invalidXML = "<root></root>"

@Test func validXMLPassesValidation() throws {
    let validator = try XMLValidator(xsd: testXSD)
    let errors = try validator.validate(xml: validXML)
    #expect(errors.isEmpty)
}

@Test func invalidXMLReturnsErrors() throws {
    let validator = try XMLValidator(xsd: testXSD)
    let errors = try validator.validate(xml: invalidXML)
    #expect(!errors.isEmpty)
    #expect(errors[0].line > 0)
}

@Test func malformedXMLThrows() throws {
    let validator = try XMLValidator(xsd: testXSD)
    #expect(throws: XMLLintError.self) {
        try validator.validate(xml: "not xml at all")
    }
}

@Test func initFromXSDURL() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xsd")
    try testXSD.write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    let validator = try XMLValidator(xsdURL: url)
    let errors = try validator.validate(xml: validXML)
    #expect(errors.isEmpty)
}

@Test func xsdInclude() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let typesXSD = """
    <?xml version="1.0" encoding="UTF-8"?>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      <xs:simpleType name="nonEmptyString">
        <xs:restriction base="xs:string">
          <xs:minLength value="1"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:schema>
    """

    let mainXSD = """
    <?xml version="1.0" encoding="UTF-8"?>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      <xs:include schemaLocation="types.xsd"/>
      <xs:element name="root">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="child" type="nonEmptyString"/>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
    </xs:schema>
    """

    try typesXSD.write(to: dir.appendingPathComponent("types.xsd"), atomically: true, encoding: .utf8)
    let mainURL = dir.appendingPathComponent("main.xsd")
    try mainXSD.write(to: mainURL, atomically: true, encoding: .utf8)

    let validator = try XMLValidator(xsdURL: mainURL)
    let validErrors = try validator.validate(xml: "<root><child>hello</child></root>")
    #expect(validErrors.isEmpty)
    let invalidErrors = try validator.validate(xml: "<root><child></child></root>")
    #expect(!invalidErrors.isEmpty)
}

@Test func malformedXSDThrows() throws {
    #expect(throws: XMLLintError.self) {
        try XMLValidator(xsd: "not xsd at all")
    }
}
