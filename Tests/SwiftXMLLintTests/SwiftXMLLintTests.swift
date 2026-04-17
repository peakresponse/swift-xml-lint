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

@Test func malformedXSDThrows() throws {
    #expect(throws: XMLLintError.self) {
        try XMLValidator(xsd: "not xsd at all")
    }
}
