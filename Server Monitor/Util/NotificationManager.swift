//
//  NotificationManager.swift
//  Server Monitor
//
//  Created by Gandalf on 2/16/26.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        case .authorized, .provisional, .ephemeral:
            break
        case .denied:
            break
        @unknown default:
            break
        }
    }

    func notifyAppOpened() {
        let content = UNMutableNotificationContent()
        content.title = "Server Monitor"
        content.body = "Monitoring started."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "app_opened_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func notifyAfterCheck(isHealthy: Bool, statusCode: Int?, details: String?) {
        let content = UNMutableNotificationContent()
        content.title = isHealthy ? "All Good" : "Server Error"

        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)

        if let statusCode {
            if let details, !details.isEmpty {
                content.body = "HTTP \(statusCode) • \(time)\n\(details)"
            } else {
                content.body = "HTTP \(statusCode) • \(time)"
            }
        } else {
            // Network / token / other local failures
            if let details, !details.isEmpty {
                content.body = "\(time)\n\(details)"
            } else {
                content.body = "\(time)"
            }
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "server_check_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }
    
    func notifyServerError(statusCode: Int, details: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Server Error"

        if let details, !details.isEmpty {
            content.body = "HTTP \(statusCode): \(details)"
        } else {
            content.body = "HTTP \(statusCode)"
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "server_error_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func notifyServerRecovered() {
        let content = UNMutableNotificationContent()
        content.title = "Server Status"
        content.body = "All Good ✅ Server is healthy."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "server_recovered_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }
}
