//
//  CalendarModule.swift
//  Notch
//
//  Created by Nikita Stogniy on 11/11/25.
//

import SwiftUI
import EventKit
import Combine

enum CalendarViewMode: String, CaseIterable {
    case month = "M"
    case week = "W"
    case day = "D"
}

// MARK: - Event Section
struct EventSection: Identifiable {
    let id = UUID()
    let date: Date
    let events: [EKEvent]
}

class CalendarModule: NotchModule, ObservableObject {
    let id = "calendar"
    let name = "Calendar"
    let icon = "calendar"
    let miniIcon = "calendar"
    let side: ModuleSide = .left
    @AppStorage("calendarModuleEnabled") var isEnabled: Bool = true
    let showInCollapsed = true
    let priority = 100

    @Published var upcomingEvents: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var currentDate = Date()
    @Published var viewMode: CalendarViewMode = .month
    @Published var selectedDate: Date = Date()

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
            self?.upcomingEvents = Array(events.prefix(15))
        }
    }

    // MARK: - Event Grouping and Sorting

    /// Sorts events: all-day events first, then by start time
    func sortEvents(_ events: [EKEvent]) -> [EKEvent] {
        return events.sorted { event1, event2 in
            // All-day events come first
            if event1.isAllDay && !event2.isAllDay {
                return true
            } else if !event1.isAllDay && event2.isAllDay {
                return false
            }
            // Within same type, sort by start time
            return event1.startDate < event2.startDate
        }
    }

    /// Groups events by date and returns sorted sections
    func groupEventsByDate(_ events: [EKEvent]) -> [EventSection] {
        let calendar = Calendar.current

        // Group events by day
        var groupedDict: [Date: [EKEvent]] = [:]

        for event in events {
            let dayStart = calendar.startOfDay(for: event.startDate)
            if groupedDict[dayStart] == nil {
                groupedDict[dayStart] = []
            }
            groupedDict[dayStart]?.append(event)
        }

        // Convert to sections, sort events within each section, and sort sections by date
        let sections = groupedDict.map { date, events in
            EventSection(date: date, events: sortEvents(events))
        }.sorted { $0.date < $1.date }

        return sections
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
            module: module,
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

    private var weekdayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        VStack(spacing: 1) {
            Text(weekdayAbbrev)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text(dayNumber)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(monthAbbrev)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(settings.getAccentColor().opacity(0.8))
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
    @ObservedObject var module: CalendarModule
    let onRequestAccess: () -> Void
    let onRefresh: () -> Void

    @StateObject private var settings = SettingsManager.shared

    private var calendar: Calendar {
        Calendar.current
    }

    private var currentDate: Date {
        module.currentDate
    }

    private var upcomingEvents: [EKEvent] {
        module.upcomingEvents
    }

    private var authorizationStatus: EKAuthorizationStatus {
        module.authorizationStatus
    }

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

    private var headerTitle: String {
        let formatter = DateFormatter()
        switch module.viewMode {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .week:
            formatter.dateFormat = "MMM yyyy"
        case .day:
            formatter.dateFormat = "EEEE, MMM d"
        }
        return formatter.string(from: module.selectedDate)
    }

    private func navigatePrevious() {
        switch module.viewMode {
        case .month:
            module.selectedDate = calendar.date(byAdding: .month, value: -1, to: module.selectedDate) ?? module.selectedDate
        case .week:
            module.selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: module.selectedDate) ?? module.selectedDate
        case .day:
            module.selectedDate = calendar.date(byAdding: .day, value: -1, to: module.selectedDate) ?? module.selectedDate
        }
    }

    private func navigateNext() {
        switch module.viewMode {
        case .month:
            module.selectedDate = calendar.date(byAdding: .month, value: 1, to: module.selectedDate) ?? module.selectedDate
        case .week:
            module.selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: module.selectedDate) ?? module.selectedDate
        case .day:
            module.selectedDate = calendar.date(byAdding: .day, value: 1, to: module.selectedDate) ?? module.selectedDate
        }
    }

    private func navigateToToday() {
        module.selectedDate = Date()
    }

    private func selectDate(_ date: Date) {
        module.selectedDate = date
        module.viewMode = .day
    }

    var body: some View {
        ModuleExpandedLayout(icon: "calendar", title: headerTitle) {
            HStack(spacing: 8) {
                // Navigation arrows
                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Button(action: navigateToToday) {
                    Text("Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Button(action: navigateNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                // Mode selector
                HStack(spacing: 2) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Button(action: { module.viewMode = mode }) {
                            Text(mode.rawValue)
                                .font(.system(size: 10, weight: module.viewMode == mode ? .bold : .regular))
                                .foregroundColor(module.viewMode == mode ? .white : .white.opacity(0.5))
                                .frame(width: 20, height: 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(module.viewMode == mode ? settings.getAccentColor().opacity(0.3) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Refresh button
                if isAuthorized {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
        } content: {
            // Scrollable content takes all available space
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Date and time at top of scroll content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Text(timeString)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Calendar and events content
                        // Calendar view based on mode
                        switch module.viewMode {
                        case .month:
                            CalendarGridView(currentDate: module.selectedDate, onDateSelected: selectDate)
                        case .week:
                            CalendarWeekView(currentDate: module.selectedDate, onDateSelected: selectDate)
                        case .day:
                            CalendarDayView(currentDate: module.selectedDate, events: upcomingEvents)
                        }

                        // Events list or authorization prompt (not shown in day mode)
                        if module.viewMode != .day && !isAuthorized {
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
                        } else if module.viewMode != .day && upcomingEvents.isEmpty {
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
                        } else if module.viewMode != .day {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Events")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .textCase(.uppercase)

                                // Group events by date
                                let eventSections = module.groupEventsByDate(upcomingEvents)

                                ForEach(eventSections) { section in
                                    VStack(alignment: .leading, spacing: 8) {
                                        EventSectionHeader(date: section.date)

                                        ForEach(section.events, id: \.eventIdentifier) { event in
                                            EventRow(event: event)
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let currentDate: Date
    let onDateSelected: (Date) -> Void
    @StateObject private var settings = SettingsManager.shared

    private var calendar: Calendar {
        Calendar.current
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            return []
        }

        // Получаем начало первой недели месяца
        let monthStart = monthInterval.start
        let weekdayOfFirstDay = calendar.component(.weekday, from: monthStart)
        let daysToSubtract = weekdayOfFirstDay - calendar.firstWeekday

        guard let firstDisplayDay = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthStart) else {
            return []
        }

        // Генерируем 42 дня (6 недель) - всегда покрывает любой месяц
        var dates: [Date] = []
        for dayOffset in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDisplayDay) {
                dates.append(date)
            }
        }

        return dates
    }

    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 8) {
            // Month and year header
            Text(monthYearString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayCell(date: date, currentDate: currentDate)
                        .onTapGesture {
                            onDateSelected(date)
                        }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let currentDate: Date
    @StateObject private var settings = SettingsManager.shared
    @State private var isHovered = false

    private var calendar: Calendar {
        Calendar.current
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: currentDate)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
    }

    var body: some View {
        Text(dayNumber)
            .font(.system(size: 11, weight: isToday ? .bold : .regular))
            .foregroundColor(isToday ? .white : (isCurrentMonth ? .white.opacity(0.8) : .white.opacity(0.3)))
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                Circle()
                    .fill(isToday ? settings.getAccentColor().opacity(0.8) : (isHovered ? Color.white.opacity(0.1) : Color.clear))
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Event Section Header
struct EventSectionHeader: View {
    let date: Date
    @StateObject private var settings = SettingsManager.shared

    private var formattedDate: (weekday: String, date: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")

        // Weekday abbreviated (e.g., "Пн")
        formatter.dateFormat = "EE"
        let weekday = formatter.string(from: date)

        // Date with month (e.g., "13 Ноября")
        formatter.dateFormat = "d MMMM"
        let dateString = formatter.string(from: date)

        return (weekday, dateString)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(formattedDate.weekday + ",")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(settings.getAccentColor())

            Text(formattedDate.date)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .padding(.bottom, 4)
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
            return "Весь день"
        }
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
            Text(eventTime)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSoon ? settings.getAccentColor() : .white.opacity(0.7))
                .frame(width: 80, alignment: .leading)

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

// MARK: - Calendar Week View
struct CalendarWeekView: View {
    let currentDate: Date
    let onDateSelected: (Date) -> Void
    @StateObject private var settings = SettingsManager.shared

    private var calendar: Calendar {
        Calendar.current
    }

    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return []
        }

        var dates: [Date] = []
        var date = weekInterval.start

        for _ in 0..<7 {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return dates
    }

    private var weekRange: String {
        guard let firstDay = weekDays.first, let lastDay = weekDays.last else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: firstDay)) - \(formatter.string(from: lastDay))"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(weekRange)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Days in week
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(weekDays, id: \.self) { date in
                    CalendarWeekDayCell(date: date, currentDate: Date())
                        .onTapGesture {
                            onDateSelected(date)
                        }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Week Day Cell
struct CalendarWeekDayCell: View {
    let date: Date
    let currentDate: Date
    @StateObject private var settings = SettingsManager.shared
    @State private var isHovered = false

    private var calendar: Calendar {
        Calendar.current
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var weekdaySymbol: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: currentDate)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(weekdaySymbol)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? settings.getAccentColor().opacity(0.3) : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05)))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let currentDate: Date
    let events: [EKEvent]
    @StateObject private var settings = SettingsManager.shared

    private var calendar: Calendar {
        Calendar.current
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentDate)
    }

    private var todayEvents: [EKEvent] {
        events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: currentDate)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(dayString)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            if todayEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No events on this day")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(todayEvents, id: \.eventIdentifier) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}
