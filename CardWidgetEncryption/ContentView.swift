//
//  ContentView.swift
//  CardWidgetEncryption
//
//  Created by William Gallegos on 1/23/25.
//

import SwiftUI
import CryptoKit

struct ContentView: View {
    @State private var cardNumber: String = ""
    @State private var expirationDate: String = ""
    @State private var cvv: String = ""
    
    var body: some View {
        Form {
            Section {
                Text("We need people to try to find security flaws with this system. We want to have a widget that can show you how much money is in your bank account. We also want to be 100% sure that everyone’s information cannot be accessed by a third-party app on iOS, macOS, and visionOS running iOS 17, macOS Sonoma, or visionOS 1 or later.")
                Text("For obvious reasons, do not put real information in here.")
                    .bold()
            }
            
            Section("Card Details") {
                SecureField("Card Number", text: $cardNumber)
                TextField("Expiration Date", text: $expirationDate)
                SecureField("CVV", text: $cvv)
            }
            
            Button("Save") {
                saveCardNumber()
            }
        }
        .navigationTitle("Card Info")
    }
    
    private func saveCardNumber() {
        guard !cardNumber.isEmpty, !expirationDate.isEmpty, !cvv.isEmpty else {
            print("WILLIDEBUG: Not all info was provided")
            return
        }
        
        let cardInfo = "\(cardNumber)|\(expirationDate)|\(cvv)"
        do {
            try saveTokenToAppGroup(token: cardInfo)
        } catch {
            fatalError("WILLIDEBUG: Couldn't Encrypt")
        }
    }
    
    private func saveTokenToAppGroup(token: String) throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw NSError(domain: "CardInputError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert token to Data."])
        }

        let key = loadEncryptionKey()
        let sealedBox = try AES.GCM.seal(tokenData, using: key)
        guard let encryptedData = sealedBox.combined else {
            throw NSError(domain: "EncryptionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to combine encrypted data."])
        }

        if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.WilliamGallegos.WidgetHolder") {
            let fileURL = sharedURL.appendingPathComponent("encryptedCardToken")
            try encryptedData.write(to: fileURL)
            print("WILLIDEBUG: Saved")
        } else {
            throw NSError(domain: "AppGroupError", code: 0, userInfo: [NSLocalizedDescriptionKey: "App Group container not accessible."])
        }
    }
    
    private func loadEncryptionKey() -> SymmetricKey {
        let keychainKey = "encryptionKey"

        let accessGroup = "group.com.WilliamGallegos.WidgetHolder"

        if let keyData = try? KeychainHelper.load(key: keychainKey, accessGroup: accessGroup) {
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data(Array($0)) }

        do {
            try KeychainHelper.save(key: keychainKey, data: newKeyData, accessGroup: accessGroup)
        } catch {
            fatalError("Failed to save the encryption key to Keychain: \(error.localizedDescription)")
        }

        return newKey
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
