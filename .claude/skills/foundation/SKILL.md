---
name: foundation
description: >
  Generates and develops the Domain and Data layers of a feature following Clean Architecture.
  Creates UseCase, Repository Protocol, Repository Implementation, DataSource Protocol, DataSource Implementation,
  registers in DI Container, and generates unit tests for all 3 layers with coverage >= 90%.
  Use when you need to create business logic, repositories, data sources, or tests for a feature.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: "<FeatureName>"
---

# Foundation — The UginsVault Project

Create the Domain and Data layers of a feature, including DI and tests for all 3 layers (Domain, Data, Presentation tests against the existing ViewModel if any).

## Source of truth

- [`.claude/rules/architecture.md`](../../rules/architecture.md) — strict layer separation
- [`.claude/rules/swift-conventions.md`](../../rules/swift-conventions.md)
- [`.claude/rules/testing.md`](../../rules/testing.md) — Swift Testing, mocks, coverage ≥ 90%
- [`.claude/project-config.md`](../../project-config.md)

## Argument

`$ARGUMENTS` is the feature name in **PascalCase** (e.g. `UserProfile`, `Equipment`). If empty, ask the user.

## Step 1 — File layout

```
UginsVault/
├── domain/
│   ├── useCases/<Feature>UseCase.swift
│   └── repositoryProtocol/<Feature>RepositoryProtocol.swift
└── data/
    ├── repositories/<Feature>Repository.swift
    ├── datasources/
    │   ├── protocols/<Feature>DataSourceProtocol.swift
    │   ├── remote/<Feature>RemoteDataSource.swift
    │   └── local/<Feature>LocalDataSource.swift            (if applicable)
    └── model/<Feature>Models.swift                          (DTOs + toDomain)

UginsVaultTests/
├── domain/<Feature>UseCaseTests.swift
├── data/<Feature>RepositoryTests.swift
├── data/Mock<Feature>DataSource.swift
└── feature/<featureLower>/<Feature>ViewModelTests.swift   (if the VM exists)
```

## Step 2 — Layer rules (the non-obvious parts)

### Domain
- Pure Swift only. **Never** import `SwiftUI`, `UIKit`, `Combine`, `SwiftData`, or any other framework — not even unnecessarily.
- Repository defined as **protocol first** in `domain/repositoryProtocol/`, implementation later in `data/repositories/`.
- UseCase: one public `execute(...)` returning the Domain model. Dependencies via init, no singletons.
- DTOs live in Data (`data/model/<Feature>Models.swift`); the Repository maps DTO → Domain model.

### Data
- Two DataSource protocols when both remote and local exist (`<Feature>DataSourceProtocol`, `<Feature>LocalDataSourceProtocol`). The Repository receives both.
- Local DataSource imports `SwiftData`; remote uses `URLSession` with `async/await`.
- Repository pattern: it coordinates remote + local and does the DTO→Domain mapping.

### DI (`UginsVault/di/DependencyContainer.swift`)
- `private(set) lazy var` for DataSources, Repositories, UseCases.
- `func make<Feature>ViewModel() -> <Feature>ViewModel` factory for ViewModels.
- Wiring chain: DataSource → Repository → UseCase → ViewModel.

```swift
private(set) lazy var <feature>RemoteDataSource: <Feature>DataSourceProtocol = {
    <Feature>RemoteDataSource()
}()

private(set) lazy var <feature>Repository: <Feature>RepositoryProtocol = {
    <Feature>Repository(remoteDataSource: <feature>RemoteDataSource)
}()

private(set) lazy var <feature>UseCase: <Feature>UseCase = {
    <Feature>UseCase(repository: <feature>Repository)
}()

func make<Feature>ViewModel() -> <Feature>ViewModel {
    <Feature>ViewModel(useCase: <feature>UseCase)
}
```

## Step 3 — Tests (Swift Testing, coverage ≥ 90%)

### Mock pattern (project convention)

Every protocol gets a `Mock<Type>` with **spy** + **stub** properties:

```swift
@testable import UginsVault

class Mock<Feature>DataSource: <Feature>DataSourceProtocol {
    // Spy
    var fetchCalled = false
    var fetchCallCount = 0
    // Stub
    var fetchResult: Result<[<Feature>DTO], Error> = .success([])

    func fetch<Feature>() async throws -> [<Feature>DTO] {
        fetchCalled = true
        fetchCallCount += 1
        return try fetchResult.get()
    }
}
```

### Test layout

- `@Suite("…Tests")` per class under test
- `@MainActor` on suites that touch ViewModels
- One file per class under test, mirroring `UginsVault/` structure
- Names follow Given-When-Then; use `// Arrange / Act / Assert` comments
- Cover success paths, error paths, and edge cases

### UseCase test skeleton

```swift
@Suite("<Feature>UseCase Tests")
struct <Feature>UseCaseTests {
    private let mockRepository = Mock<Feature>Repository()
    private var sut: <Feature>UseCase { <Feature>UseCase(repository: mockRepository) }

    @Test("execute returns data when repository succeeds")
    func executeReturnsDataOnSuccess() async throws {
        mockRepository.fetchResult = .success([<Feature>Model(id: "1")])
        let result = try await sut.execute()
        #expect(result.count == 1)
        #expect(mockRepository.fetchCalled)
    }

    @Test("execute throws when repository fails")
    func executeThrowsOnFailure() async throws {
        mockRepository.fetchResult = .failure(NSError(domain: "t", code: -1))
        await #expect(throws: Error.self) { try await sut.execute() }
    }
}
```

Repository tests follow the same shape but assert DTO→Domain mapping. ViewModel tests use `@MainActor`.

## Step 4 — Final checklist

1. **No UI imports in Domain:**
   ```bash
   grep -rn "import SwiftUI\|import UIKit\|import Combine\|import SwiftData" UginsVault/domain/
   ```
   Must return empty.
2. **DI registration verified** in `DependencyContainer.swift`.
3. **`/build`** passes.
4. **`/test`** passes (and Step 3 of `/test` confirms ≥ 90% coverage on every changed file).
