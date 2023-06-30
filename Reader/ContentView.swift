//
//  ContentView.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            RssSourceList()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

struct DateFormatterFactory {
    static let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter
    }()
    
    static func dateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return timeFormatter.string(from: date)
        } else {
            return dateFormatter.string(from: date)
        }
    }
    
    static func relativeString(_ date: Date) -> String {
        if date.addingTimeInterval(60) > .now {
            return "Just now"
        }
        
        return relativeFormatter.localizedString(for: date, relativeTo: .now)
    }
}
