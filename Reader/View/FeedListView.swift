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
    
    @Environment(Store.self) var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.refresh) private var refresh

    @Query private var items: [Feed]
    
    @State private var newUrl = ""
    @State private var isLoading = false
    @State private var addingFeed = false
    @State private var showAdd = false
    @State private var showSettings = false
    @State private var currentError: AlertError?
    
    @State private var toastEntry: ToastEntry?
    
    private var tip = AddFeedTip()
    
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
        .loading($addingFeed)
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
        .toast(entry: $toastEntry)
        .safeAreaInset(edge: .bottom, content: {
            toolbar
        })
        .navigationTitle(Text("Reader"))
        .onChange(of: scenePhase) { _, newValue in
            logger.trace("phase is active: \(newValue == .active)")
            if scenePhase == .active {
                Task {
                    await refresh()
                }
            }
        }
        .task {
            await refresh()
        }
        .onLoad {
            await refresh()
        }
        .task {
            // show tip if empty list
            if !AddFeedTip.donated && !items.isEmpty {
                AddFeedTip.donated = true
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar_legency: some ToolbarContent {
        // Have bug, so use HStack
        // https://developer.apple.com/forums/thread/739846?login=true
        ToolbarItem(placement: .status) {
            if let time = store.lastUpdateTime {
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
    
    private var toolbar: some View {
        HStack {
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            
            Spacer()
            
            if let time = store.lastUpdateTime {
                UpdateTimeFooter(date: time)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                EmptyView()
            }
            
            Spacer()
            
            Button {
                showAdd.toggle()
            } label: {
                Image(systemName: "plus")
            }
            .popoverTip(tip, arrowEdge: .bottom)
        }
        .padding()
        .background(.thinMaterial)
    }
    
    @MainActor
    private func refresh(force: Bool = false) async {
        if isLoading {
            return
        }
        
        isLoading = true
        logger.trace("refreshing...")
        defer {
            logger.trace("end loading")
            isLoading = false
        }
        
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
                Text(item.title).font(.headline)
                if let date = item.lastUpdateTime() {
                    Text(DateFormatterFactory.dateString(date))
                        .font(.subheadline)
                }
            }
            .badge(item.unreadCount())
            .badgeProminence(.increased)
        }
        .controlSize(.large)
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
            self.toastEntry = ToastEntry(style: .error, msg: "Invalid url")
            return
        }
        
        Task {
            addingFeed = true
            defer {
                addingFeed = false
            }
            
            do {
                try await store.addFeed(url: url)
                self.toastEntry = ToastEntry(style: .success, msg: "Add feed success")
            } catch {
                logger.error("save faield for url: \(url), \(error)")
                self.toastEntry = ToastEntry(style: .error, msg: error.localizedDescription)
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
