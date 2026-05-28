//
//  GetReduceMotionUseCase.swift
//  UginsVault — Domain layer
//

import Foundation

@MainActor
public final class GetReduceMotionUseCase {

    private let sessionRepository: SessionStateStore

    public init(sessionRepository: SessionStateStore) {
        self.sessionRepository = sessionRepository
    }

    public func execute() -> Bool {
        sessionRepository.reduceMotion
    }
}
