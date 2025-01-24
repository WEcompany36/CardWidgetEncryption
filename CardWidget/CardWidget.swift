//
//  CardWidget.swift
//  CardWidget
//
//  Created by William Gallegos on 1/23/25.
//

import WidgetKit
import SwiftUI
import CryptoKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), balance: "$0.00")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), balance: fetchCard())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let balance = fetchCard()
            let entry = SimpleEntry(date: entryDate, balance: balance)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func fetchCard() -> String {
        do {
            if let sharedURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.WilliamGallegos.WidgetHolder") {
                let fileURL = sharedURL.appendingPathComponent("encryptedCardToken")
                let encryptedData = try Data(contentsOf: fileURL)

                // Decrypt the token
                let key = loadEncryptionKey()
                let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
                let decryptedData = try AES.GCM.open(sealedBox, using: key)

                guard let cardToken = String(data: decryptedData, encoding: .utf8) else {
                    return "Error: Invalid token"
                }

                return cardToken
            } else {
                return "Error: No token"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let balance: String
}

struct CardWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.balance)
        }
        .padding()
    }
}

struct CardWidget: Widget {
    let kind: String = "CardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CardWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Bank Balance Widget")
        .description("View your current bank balance securely.")
    }
}

#Preview(as: .systemSmall) {
    CardWidget()
} timeline: {
    SimpleEntry(date: .now, balance: Provider().fetchCard())
    SimpleEntry(date: .now, balance: "$1234.56")
}
