//
//  BackupManagerView.swift
//  MyAnimeList
//
//  Created by Samuel He on 8/23/25.
//

import DataProvider
import SwiftUI

struct BackupManagerView: View {
    let backupManager: BackupManager

    @Environment(\.dismiss) private var dismiss
    @State private var exportError: Error? = nil
    @State private var exportErrorOccurred: Bool = false
    @State private var restoreError: Error? = nil
    @State private var restoreErrorOccurred: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var restoreFileURL: URL? = nil
    @State private var showRestoreConfirmation: Bool = false
    @SceneStorage("BackupManagerView.restoreCompleted") private var restoreCompleted = false

    var body: some View {
        VStack {
            Image(.appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150)
                .clipShape(.proportionalRounded)
                .padding(.top)
            Text("Backup & Restore")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .padding(.bottom, 1)
            Text("Export all saved anime and preferences")
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                exportButton
                Button("Restore", systemImage: "document.badge.clock", role: .destructive) {
                    restoreCompleted = false
                    showFileImporter = true
                }
            }
            .padding(.top, 5)
            .padding(.bottom, 3)
            .buttonStyle(.borderedProminent)
            .disabled(restoreCompleted)
            if restoreCompleted {
                VStack(spacing: 6) {
                    VStack(spacing: 0) {
                        Text("Restore completed!")
                        Text("Restart app to see changes.")
                    }
                    .foregroundStyle(.green)
                    .font(.callout)
                }
                .transition(.opacityScale)
            }
            Spacer()
            Text("* For security reasons, your TMDb API Key will not be exported.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
        .alert(
            "Error exporting library",
            isPresented: $exportErrorOccurred,
            presenting: exportError
        ) { _ in
            Button("Cancel", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            "Error restoring library",
            isPresented: $restoreErrorOccurred,
            presenting: restoreError
        ) { _ in
            Button("Cancel", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Overwrite the current library?", isPresented: $showRestoreConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive, action: restore)
        } message: {
            Text("Please backup the current library before proceeding.")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.mallib]
        ) { result in
            processFileImport(result)
        }
    }

    @ViewBuilder
    private var exportButton: some View {
        LazyShareLink {
            do {
                let url = try backupManager.createBackup()
                return [url]
            } catch {
                exportErrorOccurred(error)
                return nil
            }
        } label: {
            Label("Export", systemImage: "document.badge.arrow.up")
        }
    }

    private func processFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            restoreFileURL = url
            showRestoreConfirmation = true
        case .failure(let error): restoreErrorOccurred(error)
        }
    }

    private func exportErrorOccurred(_ error: Error) {
        exportError = error
        exportErrorOccurred = true
    }

    private func restoreErrorOccurred(_ error: Error) {
        restoreError = error
        restoreErrorOccurred = true
    }

    private func restore() {
        restoreCompleted = false
        if let url = restoreFileURL {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(
                        domain: .bundleIdentifier,
                        code: 1,
                        userInfo: [url.path(): "Access denied to URL"])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                try backupManager.restoreBackup(from: url)
                withAnimation {
                    restoreCompleted = true
                }
            } catch {
                restoreErrorOccurred(error)
            }
        }
    }

    private func acknowledgeRestore() {
        restoreCompleted = false
        dismiss()
    }
}


#Preview {
    @Previewable let dataProvider = DataProvider.forPreview
    @Previewable @State var store = LibraryStore(dataProvider: .forPreview)

    BackupManagerView(backupManager: store.backupManager)
        .onAppear {
            dataProvider.generateEntriesForPreview()
        }
}
