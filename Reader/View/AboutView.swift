//
//  AboutView.swift
//  Reader
//
//  Created by Purkylin King on 2023/9/4.
//

import SwiftUI
import Kingdom
import ConfettiSwiftUI

struct AboutView: View {
    @State private var confettiValue = 0
    
    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 12) {
                Text(verbatim: appName()).font(.title).bold()
                Text("\(Date.now, format: .iso8601.year()) © Purkylin")
            }
            .containerRelativeFrame(.vertical) { h, _ in
                h / 3
            }

            Form {
                LabeledContent("App version", value: versionDescription())
                LabeledContent("Build time", value: #buildTime)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay(alignment: .bottom, content: {
            EmptyView()
                .confettiCannon(counter: $confettiValue, num: 50, radius: UIScreen.main.bounds.height * 0.8)
        })
        .navigationTitle("About")
        .task {
            try? await Task.sleep(for: .seconds(1))
            confettiValue += 1
        }
    }
    
    private func appName() -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: InfoKeys.displayName) as? String
        return value.unwrap()
    }
    
    private func appVersion() -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: InfoKeys.shortVersion) as? String
        return value.unwrap()
    }
    
    private func appBuildNumber() -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: InfoKeys.bundleVersion) as? String
        return value.unwrap()
    }
    
    private func versionDescription() -> String {
        return String(format: "%@(%@)", appVersion(), appBuildNumber())
    }
}

struct InfoKeys {
    static let bundleVersion = "CFBundleVersion"
    static let shortVersion = "CFBundleShortVersionString"
    static let displayName = "CFBundleDisplayName"
}

#Preview {
    AboutView()
}
