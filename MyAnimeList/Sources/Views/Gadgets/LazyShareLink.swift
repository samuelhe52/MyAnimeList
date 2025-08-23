//
//  LazyShareLink.swift
//  MyAnimeList
//
//  Created by Samuel He on 2024/10/3.
//

import SwiftUI

struct LazyShareLink<Title: View, Icon: View>: View {
    let label: Label<Title, Icon>
    let prepareData: () -> [Any]?

    init(_ text: LocalizedStringKey = "Share", prepareData: @escaping () -> [Any]?)
    where Title == Text, Icon == Image {
        self.label = .init(text, systemImage: "square.and.arrow.up")
        self.prepareData = prepareData
    }
    
    init(prepareData: @escaping () -> [Any]?, label: () -> Label<Title, Icon>) {
        self.label = label()
        self.prepareData = prepareData
    }

    var body: some View {
        Button(action: openShare, label: { label })
    }

    private func openShare() {
        guard let data = prepareData() else {
            return
        }
        let activityVC = UIActivityViewController(activityItems: data, applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // otherwise iPad crashes
            let thisViewVC = UIHostingController(rootView: self)
            activityVC.popoverPresentationController?.sourceView = thisViewVC.view
        }

        // Get the root view controller
        let rootViewController = UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?
            .rootViewController
        guard let rootViewController else { return }
        
        // Check if there is an existing presented view controller
        if let presentedVC = rootViewController.presentedViewController {
            // Dismiss the presented view controller if needed
            presentedVC.dismiss(animated: true, completion: {
                rootViewController.present(activityVC, animated: true, completion: nil)
            })
        } else {
            // No presented view controller, proceed to present the share sheet
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}
