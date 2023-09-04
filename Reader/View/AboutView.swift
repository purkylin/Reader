//
//  AboutView.swift
//  Reader
//
//  Created by Purkylin King on 2023/9/4.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text(verbatim: appName()).font(.title).bold()
            Text("2023 © purkylin")
        }
        .navigationTitle("About")
    }
    
    private func appName() -> String {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return name ?? "Unknown"
    }
}

#Preview {
    AboutView()
}
