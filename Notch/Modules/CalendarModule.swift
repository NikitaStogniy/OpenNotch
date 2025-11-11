//
//  CalendarModule.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI
import EventKit
import Combine

class CalendarModule: NotchModule, ObservableObject {
    let id = "calendar"
    let name = "Calendar"
    let icon = "calendar"
    @AppStorage("calendarModuleEnabled") var isEnabled: Bool = true
    let showInCollapsed = true
    let priority = 100

    @Published var upcomingEvents: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var currentDate = Date()

    private let eventStore = EKEventStore()
    private var timer: Timer?

    init() {
        checkAuthorizationStatus()
        startTimer()
        fetchUpcomingEvents()
    }

    deinit {
        timer?.invalidate()
    }

    private func startTimer() {
        // Update current date every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
            self?.fetchUpcomingEvents()
        }
    }

    private func checkAuthorizationStatus() {
        if #available(macOS 14.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }

    func requestAccess() {
        print("🔐 CalendarModule: requestAccess() called")
        print("🔐 Current authorization status: \(authorizationStatus.rawValue)")

        if #available(macOS 14.0, *) {
            print("🔐 Requesting full access (macOS 14+)")
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                print("🔐 Full access callback: granted=\(granted), error=\(String(describing: error))")
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .fullAccess : .denied
                    print("🔐 Updated status to: \(self?.authorizationStatus.rawValue ?? -1)")
                    if granted {
                        self?.fetchUpcomingEvents()
                    }
                }
            }
        } else {
            print("🔐 Requesting access (legacy)")
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                print("🔐 Access callback: granted=\(granted), error=\(String(describing: error))")
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    print("🔐 Updated status to: \(self?.authorizationStatus.rawValue ?? -1)")
                    if granted {
                        self?.fetchUpcomingEvents()
                    }
                }
            }
        }
    }

    func fetchUpcomingEvents() {
        let isAuthorized: Bool
        if #available(macOS 14.0, *) {
            isAuthorized = authorizationStatus == .fullAccess
        } else {
            isAuthorized = authorizationStatus == .authorized
        }

        guard isAuthorized else { return }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        DispatchQueue.main.async { [weak self] in
            self?.upcomingEvents = Array(events.prefix(5))
        }
    }

    func collapsedView() -> AnyView {
        AnyView(CalendarCollapsedView(date: currentDate))
    }

    func expandedView() -> AnyView {
        AnyView(CalendarExpandedViewWrapper(module: self))
    }
}

// MARK: - Expanded View Wrapper
struct CalendarExpandedViewWrapper: View {
    @ObservedObject var module: CalendarModule

    var body: some View {
        CalendarExpandedView(
            currentDate: module.currentDate,
            upcomingEvents: module.upcomingEvents,
            authorizationStatus: module.authorizationStatus,
            onRequestAccess: {
                print("🔘 Wrapper calling module.requestAccess()")
                module.requestAccess()
            },
            onRefresh: {
                module.fetchUpcomingEvents()
            }
        )
    }
}

// MARK: - Collapsed View
struct CalendarCollapsedView: View {
    let date: Date
    @StateObject private var settings = SettingsManager.shared

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(monthAbbrev)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(settings.getAccentColor().opacity(0.8))

            Text(dayNumber)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(settings.getAccentColor().opacity(0.15))
        )
    }
}

// MARK: - Expanded View
struct CalendarExpandedView: View {
    let currentDate: Date
    let upcomingEvents: [EKEvent]
    let authorizationStatus: EKAuthorizationStatus
    let onRequestAccess: () -> Void
    let onRefresh: () -> Void

    @StateObject private var settings = SettingsManager.shared

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: currentDate)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentDate)
    }

    private var isAuthorized: Bool {
        if #available(macOS 14.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(settings.getAccentColor())

                    Spacer()

                    if isAuthorized {
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(dateString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(timeString)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Events list or authorization prompt
            if !isAuthorized {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("Calendar Access Required")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Allow access to view your upcoming events")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    Button(action: {
                        print("🔘 Grant Access button pressed")
                        onRequestAccess()
                    }) {
                        Text("Grant Access")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(settings.getAccentColor())
                            )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if upcomingEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green.opacity(0.6))

                    Text("No upcoming events")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    Text("You're all clear for the next 7 days")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Events")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)

                        ForEach(upcomingEvents, id: \.eventIdentifier) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Event Row
struct EventRow: View {
    let event: EKEvent
    @StateObject private var settings = SettingsManager.shared

    private var eventTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if event.isAllDay {
            return "All day"
        }
        return formatter.string(from: event.startDate)
    }

    private var eventDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: event.startDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(event.startDate)
    }

    private var isSoon: Bool {
        let hoursUntil = Calendar.current.dateComponents([.hour], from: Date(), to: event.startDate).hour ?? 0
        return hoursUntil >= 0 && hoursUntil < 2
    }

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(eventDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(eventTime)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSoon ? settings.getAccentColor() : .white.opacity(0.7))
            }
            .frame(width: 60, alignment: .leading)

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled Event")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                        Text(location)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            // Status indicator
            if isSoon {
                Circle()
                    .fill(settings.getAccentColor())
                    .frame(width: 6, height: 6)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isSoon ? 0.08 : 0.04))
        )
    }
}
