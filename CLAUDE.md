# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build
swift build

# Run all tests
swift test

# Run a single test
swift test --filter SwiftXMLLintTests/<TestName>
```

## Architecture

This is a Swift Package (swift-tools-version 6.3, Swift 6 language mode) providing a library called `SwiftXMLLint` — an XML linting library.

- `Sources/SwiftXMLLint/` — library implementation
- `Tests/SwiftXMLLintTests/` — tests using Swift Testing framework (`@Test`, `#expect`)

The package is library-only (no executable targets) and has no external dependencies.
