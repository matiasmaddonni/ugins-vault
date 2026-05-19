//
//  SessionRepository.swift
//  UginsVault — Domain layer
//
//  Persists the user's lightweight session state: current phase, theme,
//  display currency, language, reduce-motion, Face ID lock. Card / stack
//  data lives in SwiftData, not here.
//
//  Exposes each value as an observable stored property so SwiftUI views
//  reading them re-render automatically when a Save method mutates them.
//

import Foundation
import Observation

public protocol SessionRepository: AnyObject, Observable {

    // MARK: - Observable state

    var phase:        AppPhase  { get }
    var theme:        AppTheme  { get }
    var currency:     Currency  { get }
    var language:     Language  { get }
    var reduceMotion: Bool      { get }
    var faceIDLock:   Bool      { get }

    // MARK: - Mutations

    func savePhase(_ phase: AppPhase)
    func saveTheme(_ theme: AppTheme)
    func saveCurrency(_ currency: Currency)
    func saveLanguage(_ language: Language)
    func saveReduceMotion(_ reduceMotion: Bool)
    func saveFaceIDLock(_ enabled: Bool)
}
