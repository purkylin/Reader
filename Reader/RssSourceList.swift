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

struct RssSourceList: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RssSource]
    @State private var showAddSource = false
    @State private var newUrl = ""
    @State private var errMsg: String?
    @State private var isLoading = false
    
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
        .alert("Add RSS", isPresented: $showAddSource, actions: {
            TextField("RSS subscription url", text: $newUrl)
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSource = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: RssSource.self) { source in
            RssSourceDetail(source: source)
        }
        .navigationTitle(Text("My RSS"))
        .task {
            await refresh()
        }
    }
    
    @ViewBuilder
    private func view(for item: RssSource) -> some View {
        HStack {
            KFImage(item.logo)
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
                        Text("last udpate: ") +
                        Text(date, style: .relative) +
                        Text(" ago")
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
    
    private func fetchSource(url: URL) async throws -> RssSourceDTO {
        let (data, _) = try await URLSession.shared.data(from: url)
        let source = try RssSourceDTO.parse(data: data)
        return source
    }
    
    @MainActor
    private func addSource(url: URL) async throws {
        let dto = try await fetchSource(url: url)
        let newSource =  RssSource(url: url, title: dto.title, link: dto.link, desc: dto.desc, logo: dto.logo, items: [])
        modelContext.insert(newSource)
        try modelContext.save()
        
        try await newSource.updateFeeds(dto.items)
    }
    
    @MainActor
    private func updateSource(_ source: RssSource) async throws {
        let dto = try await fetchSource(url: source.url)
        try await source.updateFeeds(dto.items)
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
                try await addSource(url: url)
            } catch {
                self.errMsg = error.localizedDescription
            }
        }
    }
    
    private func refresh() async {
        for item in items {
            do {
                try await updateSource(item)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension RssSource {
    static func getSource(by name: String, in context: ModelContext) throws -> RssSource? {
        let predicate = #Predicate<RssSource> { $0.title == name }
        return try context.fetch(FetchDescriptor(predicate: predicate)).first
    }
    
    @MainActor
    func lastUpdateTime() -> Date? {
        guard let context = self.context else { fatalError("Can't get context") }
        let name = self.title
        let predicate = #Predicate<RssFeed> { $0.source?.title == name }
        return try? context.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.pubDate, order: .reverse)])).first?.pubDate
    }
    
    func unreadCount() -> Int {
        guard let context = self.context else {
            fatalError("Get context failed")
        }
        
        let name = self.title
        let predicate = #Predicate<RssFeed> { $0.source?.title == name && $0.viewed == false }
        return try! context.fetch(FetchDescriptor(predicate: predicate)).count
    }
    
    @MainActor
    func updateFeeds(_ items: [RssSourceDTO.Item]) async throws {
        let lastUdateTime = self.lastUpdateTime() ?? Date(timeIntervalSince1970: 0)
        
        for item in items {
            // TODO: update if exists
            if item.pubDate > lastUdateTime {
                let feed = RssFeed(title: item.title, link: item.link, content: item.content, pubDate: item.pubDate, author: item.author)
                feed.source = self
                context?.insert(feed)
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
