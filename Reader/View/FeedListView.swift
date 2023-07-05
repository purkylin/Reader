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

struct FeedListView: View, Logging {
    private let store = RSSStore()
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase

    @Query private var items: [Feed]
    
    @State private var newUrl = ""
    @State private var errMsg: String?
    @State private var isLoading = false
    @State private var showAdd = false
    @State var showSettings = false
    
    var body: some View {
        List {
            ForEach(items, id: \.title) { item in
                NavigationLink(value: item) {
                    view(for: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("No Data", systemImage: "quare.on.square")
            }
        }
        .overlay {
            if isLoading {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(store)
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
        .error(text: $errMsg)
        .toolbar {
            toolbar
        }
        .navigationDestination(for: Feed.self) { feed in
            FeedDetailView(feed: feed)
        }
        .navigationTitle(Text("My RSS"))
        .refreshable {
            await refresh(force: true)
        }
        .task {
            await refresh()
        }
        .onChange(of: scenePhase) { _, newValue in
            logger.trace("phase is active: \(newValue == .active)")
            Task {
                await refresh()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .status) {
            if let date = store.lastUpdateTime {
                Text("Updated \(DateFormatterFactory.relativeString(date))").font(.footnote)
                    .foregroundStyle(.secondary)
                
            } else {
                Text("")
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
        }
    }
    
    private func refresh(force: Bool = false) async {
        guard scenePhase == .active else { return }
        await store.refresh(feeds: items, force: force)
    }
    
    @ViewBuilder
    private func view(for item: Feed) -> some View {
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
                if let date = item.lastUpdateTime() {
                    Group {
                        Text("updated ") +
                        Text(DateFormatterFactory.relativeString(date))
                    }
                    .font(.subheadline)
                }
            }
            .badge(item.unreadCount())
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
            errMsg = "Invalid url"
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
                self.errMsg = error.localizedDescription
            }
        }
    }
}

extension View {
    func error(text: Binding<String?>) -> some View {
        self.modifier(CustomErrorAlert(text: text))
    }
}

struct CustomErrorAlert: ViewModifier {
    @Binding var text: String?
    
    func body(content: Content) -> some View {
        let hasError = Binding<Bool>(
            get: {
                return self.text != nil
            },
            set: { _ in
                self.text = nil
            }
        )
        
        return content.alert("Error", isPresented: hasError) {
            EmptyView()
        } message: {
            Text(text ?? "")
        }
    }
}
