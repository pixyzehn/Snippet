/**
 *  Snippet
 *  Copyright (c) Nagasawa Hiroki 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import XCTest
import SnippetCore
import Foundation

class SnippetTests: XCTestCase {
    func testPrintingOutput() throws {
        let snippet = Snippet()

        // Test by using my PRs in 2017-03-27 ~ 2017-04-03.
        guard var urlComponents = URLComponents(string: "https://api.github.com/search/issues") else {
            return
        }

        let userName = "pixyzehn"
        let startDateString = "2017-03-27"
        let endDateString = "2017-04-03"

        let query =
        """
        q=
        +type:pr
        +author:\(userName)
        +created:\(startDateString)..\(endDateString)
        +updated:\(startDateString)..\(endDateString)
        """
        urlComponents.query = query

        guard let url = urlComponents.url else {
            debugPrint("No URL from the URLComponents.")
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/vnd.github.v3.text-match+json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        snippet.loadRequest(request) { itemResponse in
            if let itemResponse = itemResponse {
                XCTAssertEqual(snippet.generateOutput(itemResponse), self.expectedOutput)
            } else {
                assertionFailure("No ItemResponse.")
            }
        }
    }

    // MARK: - Helpers

    private var expectedOutput: String {
        let output =
        """
        Total count: 6
        * [JohnSundell/Marathon] [#24](https://github.com/JohnSundell/Marathon/pull/24) Enable prefetching for scripts within Marathon
        * [JohnSundell/Files] [#8](https://github.com/JohnSundell/Files/pull/8) Fix create file at path method
        * [JohnSundell/Marathon] [#23](https://github.com/JohnSundell/Marathon/pull/23) Enable prefetching in build and package update
        * [JohnSundell/Marathon] [#19](https://github.com/JohnSundell/Marathon/pull/19) Add `--all-packages` option in remove command
        * [JohnSundell/Marathon] [#18](https://github.com/JohnSundell/Marathon/pull/18) Give suggestion to add a package if there is no such module
        * [pixyzehn/pixyzehn.github.io] [#29](https://github.com/pixyzehn/pixyzehn.github.io/pull/29) Swifty Week 19
        """
        return output
    }
}

extension SnippetTests {
    static var allTests: [(String, (SnippetTests) -> () throws -> Void)] {
        return [
            ("testPrintingOutput", testPrintingOutput)
        ]
    }
}
