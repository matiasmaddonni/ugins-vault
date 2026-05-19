//
//  SetReduceMotionUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class SetReduceMotionUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute(_ reduceMotion: Bool) {
        sessionRepository.saveReduceMotion(reduceMotion)
    }
}
