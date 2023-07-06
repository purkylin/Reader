//
//  WebView.swift
//  Reader
//
//  Created by Purkylin King on 2023/6/27.
//

import Foundation
import SafariServices
import SwiftUI
import UIKit

struct WebView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SFSafariViewController

    var url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<WebView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ safariViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<WebView>) {
    }
}
