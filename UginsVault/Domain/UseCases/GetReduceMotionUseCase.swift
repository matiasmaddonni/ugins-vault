//
//  GetReduceMotionUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetReduceMotionUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Bool {
        sessionRepository.reduceMotion
    }
}
