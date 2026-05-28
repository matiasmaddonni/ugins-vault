//
//  GetFaceIDLockUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetFaceIDLockUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Bool {
        sessionRepository.faceIDLock
    }
}
