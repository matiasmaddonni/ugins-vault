//
//  PriceSyncScheduler.swift
//  UginsVault — App entry
//
//  Registers + schedules the weekly background-refresh task that runs
//  `SyncPricesUseCase` while the app is backgrounded. Identifier is
//  also declared in `Info.plist` under
//  `BGTaskSchedulerPermittedIdentifiers` (set in `project.yml`).
//

import Foundation
import BackgroundTasks

@MainActor
public enum PriceSyncScheduler {

    public static let identifier = "com.matiasmaddonni.uginsvault.priceSync"

    /// Called once at app launch — wires the BGTaskScheduler handler.
    /// Invoking the handler from iOS does NOT require the app to be
    /// foreground; we run the sync, then re-schedule for next week.
    public static func registerTaskHandler(container: DependencyContainer = .shared) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                await handle(task: refreshTask, container: container)
            }
        }
    }

    /// Asks iOS to fire the sync task again roughly one week from now.
    /// Call when the app backgrounds (and after a manual sync, so the
    /// week clock resets).
    public static func scheduleNextRun() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Simulator + dev builds often refuse the submit ("BGTaskScheduler
            // permission denied"); production devices handle it fine.
        }
    }

    // MARK: - Private

    private static func handle(
        task: BGAppRefreshTask,
        container: DependencyContainer
    ) async {
        // Only run on Wi-Fi, matches the foreground rule.
        guard container.networkReachability.isOnWiFi else {
            task.setTaskCompleted(success: false)
            scheduleNextRun()
            return
        }

        task.expirationHandler = {
            // Best-effort — iOS will reclaim the runtime if we miss the
            // deadline. Re-schedule so we try again next week.
            scheduleNextRun()
        }

        do {
            _ = try await container.makeSyncPricesUseCase().execute(progress: nil)
            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }

        scheduleNextRun()
    }
}
