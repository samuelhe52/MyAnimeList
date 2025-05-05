//
//  TMDbAPIKeyEditor.swift
//  MyAnimeList
//
//  Created by Samuel He on 2025/5/3.
//

import SwiftUI
import AlertToast

struct TMDbAPIKeyEditor: View {
    @AppStorage(.tmdbAPIKey) var apiKey: String?
    
    var isEditing: Bool = false
    @State private var apiKeyInput: String = ""
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var status: KeyCheckStatus?
    private var checking: Bool { status == .checking }
    private var checkFailed: Bool { status == .invalid }
    private var checkFailedBinding: Binding<Bool> { .init(get: { checkFailed }, set: { _ in status = nil }) }
    private var checkSuccess: Bool { status == .valid }
    private var checkSuccessBinding: Binding<Bool> { .init(get: { checkSuccess }, set: { _ in status = nil }) }
    
    var body: some View {
        VStack(spacing: 30) {
            if !isEditing {
                // Initial value absent, welcome
                Image("app_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(.buttonBorder)
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } else {
                // Initial value present, edit
                Text("Change Key")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Text("Please enter a TMDB API Key to continue.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("TMDB API Key", text: $apiKeyInput)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .focused($isTextFieldFocused)
            
            Button {
                status = .checking
                Task { await checkKey(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)) }
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Validate Key")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .toast(isPresenting: .constant(checking), offsetY: 20, alert: {
            AlertToast(displayMode: !isEditing ? .hud : .banner(.pop), type: .regular, title: "Checking key...")
        })
        .toast(isPresenting: checkFailedBinding, offsetY: 20, alert: {
            AlertToast(displayMode: !isEditing ? .hud : .banner(.pop), type: .error(.red), title: "Key check failed!")
        })
        .toast(isPresenting: checkSuccessBinding, offsetY: 20, alert: {
            AlertToast(displayMode: !isEditing ? .hud : .banner(.pop), type: .complete(.green), title: "Key saved.")
        })
        .onAppear {
            if isEditing { apiKeyInput = apiKey ?? "" }
        }
        .padding(.horizontal)
        .padding()
    }
    
    func checkKey(_ key: String) async -> Bool {
        guard !key.isEmpty else {
            status = .invalid
            return false
        }
        guard let url = URL(string: "https://api.tmdb.org/3/configuration?api_key=\(key)") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    status = .valid
                    if !isEditing {
                        isTextFieldFocused = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        apiKey = apiKeyInput
                    }
                    return true
                }
            }
        } catch {
            status = .invalid
            return false
        }
        
        status = .invalid
        return false
    }
    
    enum KeyCheckStatus {
        case checking
        case valid
        case invalid
    }
}

#Preview {
    TMDbAPIKeyEditor()
}
