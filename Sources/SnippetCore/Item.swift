//
//  Item.swift
//  SnippetCore
//
//  Created by pixyzehn on 8/15/17.
//

import Foundation

struct Item: Codable {
    // swiftlint:disable identifier_name
    private enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case url = "html_url"
        case repositoryURL = "repository_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    let id: UInt
    let number: UInt
    let title: String
    let url: String
    let repositoryURL: String
    let createdAt: String
    let updatedAt: String
}
