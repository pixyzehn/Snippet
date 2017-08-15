//
//  ItemResponse.swift
//  SnippetCore
//
//  Created by pixyzehn on 8/15/17.
//

import Foundation

struct ItemResponse: Codable {
    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }

    let totalCount: Int
    let incompleteResults: Bool
    let items: [Item]
}
