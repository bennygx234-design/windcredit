import Foundation
import UserNotifications

/// Local reminders before the policy renews (no server needed).
enum ReminderService {
    static let ids = ["renewal-30", "renewal-7"]

    /// Asks permission (only when the user taps "Remind me"), then schedules 30- and 7-day reminders at 9 am.
    static func schedule(renewal: Date, savingsText: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        for (id, days) in zip(ids, [30, 7]) {
            guard let day = Calendar.current.date(byAdding: .day, value: -days, to: renewal), day > .now else { continue }
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
            comps.hour = 9
            let content = UNMutableNotificationContent()
            content.title = "Your policy renews in \(days) days"
            content.body = "Send your wind-mitigation report to your agent before renewal. You could save \(savingsText) a year."
            content.sound = .default
            try? await center.add(UNNotificationRequest(identifier: id, content: content,
                                                        trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
        }
        return true
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
