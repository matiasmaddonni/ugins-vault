//
//  SetFaceIDLockUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetFaceIDLockUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ enabled: Bool) {
        sessionRepository.saveFaceIDLock(enabled)
    }
}
