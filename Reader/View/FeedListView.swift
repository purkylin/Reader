//
//  RssSourceList.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/25.
//

import Foundation
import SwiftUI
import SwiftData
import Kingfisher
import TipKit

struct FeedListView: View, Logging {
    @Binding var selection: Feed?
    
    private var tip = AddFeedTip()
    
    @Environment(Store.self) var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase

    @Query private var items: [Feed]
    
    @State private var newUrl = ""
    @State private var isLoading = false
    @State private var showAdd = false
    @State private var showSettings = false
    @State private var currentError: AlertError?
    
    init(selection: Binding<Feed?>) {
        self._selection = selection
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(items, id: \.title) { item in
                NavigationLink(value: item) {
                    card(for: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .refreshable {
            await refresh(force: true)
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No Data", systemImage: "square.on.square")
            }
        }
        .overlay {
            if isLoading {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Add Feed", isPresented: $showAdd, actions: {
            TextField("RSS feed url", text: $newUrl)
            Button(role: .cancel) {
                
            } label: {
                Text("Cancel")
            }
            Button {
                saveAction()
            } label: {
                Text("OK")
            }
        })
        .alert(error: $currentError)
        .toolbar {
            toolbar
        }
        .navigationTitle(Text("Reader"))
        .onChange(of: scenePhase) { _, newValue in
            logger.trace("phase is active: \(newValue == .active)")
            Task {
                await refresh()
            }
        }
        .task {
            if scenePhase == .active {
                await refresh()
            }
        }
        .task {
            // show tip if empty list
            if !AddFeedTip.donated && !items.isEmpty {
                AddFeedTip.donated = true
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .status) {
//            let text = store.lastUpdateTime
//                .map { "Updated \(DateFormatterFactory.relativeString($0) )"}
//            Text(text ?? "").font(.footnote)
//                    .foregroundStyle(.secondary)
            if let time = store.lastUpdateTime {
//                Text(time, style: .relative)
                UpdateTimeFooter(date: time)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        ToolbarItem(placement: .bottomBar) {
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
        }
        ToolbarItem(placement: .bottomBar) {
            Button {
                showAdd.toggle()
            } label: {
                Image(systemName: "plus")
            }
            .popoverTip(tip, arrowEdge: .bottom)
        }
    }
    
    private func refresh(force: Bool = false) async {
        // TODO: the state is not active when pull refresh
        // guard scenePhase == .active else { return }
        await store.refresh(feeds: items, force: force)
    }
    
    @ViewBuilder
    private func card(for item: Feed) -> some View {
        HStack {
            KFImage(item.icon)
                .placeholder({
                    Image(systemName: "photo.on.rectangle.angled").resizable().foregroundStyle(.secondary)
                })
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 30)
            
            VStack(alignment: .leading) {
                Text(item.title).bold()
                if let date = item.lastUpdateTime(in: modelContext) {
                    Group {
                        Text("updated ") +
                        Text(DateFormatterFactory.relativeString(date))
                    }
                    .font(.subheadline)
                }
            }
            .badge(item.unreadCount(in: modelContext))
            .badgeProminence(.increased)
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
    
    private func saveAction() {
        guard let url = URL(string: newUrl) else {
            currentError = "Invalid url"
            return
        }
        
        Task { @MainActor in
            isLoading = true
            defer {
                isLoading = false
            }
            
            do {
                try await store.addFeed(url: url, in: modelContext)
            } catch {
                logger.error("save faield for url: \(url), \(error)")
                self.currentError = AlertError(error)
            }
        }
    }
}

struct UpdateTimeFooter: View {
    let date: Date
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    @State private var label = ""
    
    init(date: Date) {
        self.date = date
        _label = State(initialValue: DateFormatterFactory.relativeString(date))
    }
    
    var body: some View {
        Group {
            Text("Update: ") + Text(label)
        }
        .onReceive(timer) { _ in
            label = DateFormatterFactory.relativeString(date)
        }
    }
}
