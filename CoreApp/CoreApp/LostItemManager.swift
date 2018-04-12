//
//  LostItemManager.swift
//  CoreApp
//
//  Created by Andrew Finke on 4/11/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import SWXMLHash

class LostItemManager {

    // MARK: - Types

    struct LostItemRecord: Codable, Equatable {

        let category: String
        let name: String
        let count: Int

        static func ==(lhs: LostItemRecord, rhs: LostItemRecord) -> Bool {
            return lhs.category == rhs.category && lhs.name == rhs.name
        }
    }

    struct LostItemDiff {
        let item: LostItemRecord
        let emoji: String
        let diff: Int
    }

    // MARK: - Properties

    static private let itemEmojiMap = [
        "MiscellaneousPortfolio": "💼",
        "Carry Bag / LuggageBriefcase": "💼",
        "Carry Bag / LuggageBackpack": "🎒",
        "Carry Bag / LuggageShoulder bag": "👜",
        "Carry Bag / LuggageTote bag": "👜",
        "Carry Bag / LuggageHandbag": "👜",
        "Carry Bag / LuggageShopping bag": "🛍️",
        "JewelryWatch": "⌚️",
        "ElectronicsComputer Accessories": "⌨️",
        "Home FurnishingsDishware": "🍽️ ",
        "Sports EquipmentBicycle": "🚲",
        "CurrencyForeign Currency": "💷",
        "AccessoriesHat": "🎩",
        "AccessoriesGloves": "🥊 ",
        "Eye WearSunglasses": "🕶️",
        "FootwearSneakers": "👟",
        "IdentificationDebit Card": "💳",
        ]

    static private let categoryEmojiMap = [
        "Home Furnishings": "🏠",
        "Sports Equipment": "⚾",
        "Identification": "🆔",
        "Entertainment (Music/Movies/Games)": "🎮",
        "Footwear": "👞",
        "Currency": "💵",
        "Musical Instrument": "🎺",
        "Jewelry": "💍",
        "Wallet/Purse": "👛",
        "Clothing": "👚",
        "Cell Phone/Telephone/Communication Device": "📱",
        "Toys": "🎱",
        "Electronics": "🖥️",
        "Carry Bag / Luggage": "👝",
        "Eye Wear": "👓",
        "Tickets": "🎟️",
        "Book": "📖",
        "Medical Equipment & Medication": "💊",
        "Tools": "🔨",
        "Keys": "🔑",
        ]

    // MARK: - Helpers

    static func lostItemDiffs() -> [LostItemDiff] {
        var initalLostItemRecords = [LostItemRecord]()
        if let initalData = UserDefaults.standard.data(forKey: "initalData"), let json = try? JSONDecoder().decode([LostItemRecord].self, from: initalData) {
            initalLostItemRecords = json
        } else {
            initalLostItemRecords = fetchItemRecords()
            let jsonData = try! JSONEncoder().encode(initalLostItemRecords)
            UserDefaults.standard.set(jsonData, forKey: "initalData")
        }

        var allDiffItems = [LostItemDiff]()
        for newItemRecord in fetchItemRecords() {
            guard let index = initalLostItemRecords.index(of: newItemRecord) else {
                fatalError()
            }

            let initalRecordItem = initalLostItemRecords[index]
            let countDiff = newItemRecord.count - initalRecordItem.count

            if countDiff != 0 {
                let key = newItemRecord.category + newItemRecord.name
                if let emoji = itemEmojiMap[key] {
                    // specific emoji
                    let itemDiff = LostItemDiff(item: newItemRecord,
                                                emoji: emoji,
                                                diff: countDiff)
                    allDiffItems.append(itemDiff)
                } else if let emoji = categoryEmojiMap[newItemRecord.category] {
                    // category emoji
                    let itemDiff = LostItemDiff(item: newItemRecord,
                                                emoji: emoji,
                                                diff: countDiff)
                    allDiffItems.append(itemDiff)

                    print(newItemRecord)
                    print(countDiff)
                } else {
                    // no emoji set
                    print(newItemRecord)
                    print(countDiff)
                }
            }
        }
        return allDiffItems
    }

    // MARK: - Helpers

    // blocks main thread until done
    static private func fetchItemRecords() -> [LostItemRecord] {
        guard let url = URL(string: "https://advisory.mtanyct.info/LPUWebServices/CurrentLostProperty.aspx"), let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) else {
            fatalError()
        }

        let xml = SWXMLHash.parse(string)

        var items = [LostItemRecord]()
        for category in xml["LostProperty"]["Category"].all {
            guard let categoryName = category.element?.allAttributes["Category"]?.text else {
                fatalError()
            }
            for subCategory in category["SubCategory"].all {
                if let attributes: [String: XMLAttribute] = subCategory.element?.allAttributes,
                    let name = attributes["SubCategory"]?.text,
                    let count = attributes["count"]?.text {
                    items.append(LostItemRecord(category: categoryName, name: name, count: Int(count)!))
                }
            }
        }
        return items
    }

}
