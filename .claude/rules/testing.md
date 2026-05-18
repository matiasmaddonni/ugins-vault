# Testing — Swift Testing Framework

## Framework
- Use **Swift Testing** (NOT XCTest)
- Macros: `@Test`, `@Suite`, `#expect`, `#require`

## Structure

```swift
import Testing
@testable import UginsVault

@Suite("ClassName Tests")
@MainActor
struct ClassNameTests {
    @Test("scenario description - Given/When/Then")
    func testScenario() async throws {
        // Arrange
        // Act
        // Assert
        #expect(result == expected)
    }
}
```

## Rules
- Minimum coverage: ≥ 90% on classes under test
- Descriptive names following Given-When-Then
- `@MainActor` on suites that test ViewModels
- One test file per class/struct under test
- Location: `UginsVaultTests/` mirroring the structure of `UginsVault/`

## Mock Strategy
- Protocol-based: each protocol has a mock
- Mock implementations separated by layer
- Mocks must be simple and controllable (set return values, verify calls)

## What to Test per Layer

### Domain (Use Cases)
- Mock repository protocols
- Test complete business logic
- Cover edge cases and errors

### Data (Repositories)
- Mock DataSource protocols
- Test data mapping
- Test error handling

### Presentation (ViewModels)
- Mock Use Cases
- Test state changes (@Published)
- Test loading states and error handling
