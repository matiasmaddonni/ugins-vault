//
//  SetReduceMotionUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetReduceMotionUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ reduceMotion: Bool) {
        sessionRepository.saveReduceMotion(reduceMotion)
    }
}
