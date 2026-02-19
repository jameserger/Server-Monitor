//
//  BackgroundTaskManager.swift
//  Server Monitor
//
//  Created by Gandalf on 2/16/26.
//
import Foundation
import BackgroundTasks

@MainActor
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private init() {}

    private let refreshTaskId = "com.erger.Server-Monitor.refresh"

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskId, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: task)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskId)

        // Use the user-chosen interval as an "earliest" hint.
        let seconds = max(60, UserDefaults.standard.double(forKey: "checkIntervalSeconds"))
        request.earliestBeginDate = Date(timeIntervalSinceNow: seconds)

        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Always schedule the next one.
        scheduleAppRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            // New instance is fine; @AppStorage persists state used to prevent spam.
            let service = GravyService()
            await service.getPlans()
            task.setTaskCompleted(success: true)
        }
    }
}

