import Foundation
import UserNotifications

enum ReminderService {
    static let ids = ["renewal-30", "renewal-7"]

    // Only called from the "Turn on reminder" button, so the permission prompt has context.
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
