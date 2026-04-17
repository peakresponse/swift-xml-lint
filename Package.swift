// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-xml-lint",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftXMLLint",
            targets: ["SwiftXMLLint"]
        ),
    ],
    targets: [
        .target(
            name: "CLibxml2",
            publicHeadersPath: "include"
        ),
        .target(
            name: "SwiftXMLLint",
            dependencies: ["CLibxml2"]
        ),
        .testTarget(
            name: "SwiftXMLLintTests",
            dependencies: ["SwiftXMLLint"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
