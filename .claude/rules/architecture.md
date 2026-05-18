# Clean Architecture — Strict Rules

## Layer Separation

The app follows Clean Architecture in 3 layers. Dependencies always point inward:

```
Presentation → Domain ← Data
```

### Domain (the innermost layer)
- Location: `UginsVault/domain/`
- Contains: Use Cases, Repository Protocols, Entities
- **FORBIDDEN**: importing UIKit, SwiftUI, Combine, SwiftData, or any external framework
- Pure Swift only

### Data (implements Domain)
- Location: `UginsVault/data/`
- Contains: Repositories (implementations), DataSources (remote/local)
- May import: Foundation, SwiftData, networking libs
- **FORBIDDEN**: importing SwiftUI or UIKit
- Repositories implement the protocols defined in Domain

### Presentation (consumes Domain)
- Location: `UginsVault/feature/*/ui/` and `UginsVault/feature/*/viewmodel/`
- Contains: Views (SwiftUI), ViewModels
- May import: SwiftUI, Combine
- **FORBIDDEN**: accessing DataSources directly — always through Use Cases

## DI Rules
- Singleton container in `UginsVault/di/DependencyContainer.swift`
- Factory methods for each dependency
- ViewModels receive Use Cases via injection

## Repositories
- Always define the protocol FIRST in `UginsVault/domain/repositoryProtocol/`
- Then implement in `UginsVault/data/repositories/`
