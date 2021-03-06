/**
 *  Snippet
 *  Copyright (c) Nagasawa Hiroki 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import TSCUtility

public final class Snippet {
    private let accessTokenKey = "PERSONAL_ACCESS_TOKEN"
    private var accessToken: String? {
        get {
            let defaults = UserDefaults.standard
            return defaults.string(forKey: accessTokenKey)
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: accessTokenKey)
            defaults.synchronize()
        }
    }

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    private lazy var uiDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "E MMM d"
        return dateFormatter
    }()

    private lazy var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday is the first weekday.
        return calendar
    }()

    public init() {}

    public func run() throws {
        let weekNumber: Int
        let organization: String

        var arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

        if let org = arguments.first, !org.hasPrefix("--") {
            organization = org
            arguments = Array(arguments.dropFirst())
        } else {
            organization = ""
        }

        let parser = ArgumentParser(usage: "<organization>", overview: """
            Quickly extract your specific Github PRs with links last week (or earlier than last week) to markdown formats.
            Specify an organization in Github. (The default is your all repositories.)
            """)

        let tokenArgument = parser.add(option: "--token", kind: String.self, usage: """
            Register your access token for repo (Full control of private repositories) in Github using the `--token` at first.
            """)

        let weekArgument = parser.add(option: "--week", kind: Int.self, usage: """
            Pass a past week number using the `--week`. (The default is `-1`)
            """)

        let parsedArguments = try parser.parse(arguments)

        if let week = parsedArguments.get(weekArgument) {
            weekNumber = week
        } else {
            weekNumber = -1
        }

        if let token = parsedArguments.get(tokenArgument) {
            accessToken = token
        }

        guard let accessToken = self.accessToken else {
            printErrorForAccessToken()
            return
        }

        /// Get elements for query.
        let userName = try Process().launchBash(with: "git config github.user")
        let now = Date()

        var components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)
        components.weekday = 2

        let mondayInWeek = calendar.date(from: components) ?? now

        let startDate = calendar.date(byAdding: .day, value: 7 * weekNumber, to: mondayInWeek) ?? mondayInWeek
        let endDate = calendar.date(byAdding: .day, value: 7 * (weekNumber + 1), to: mondayInWeek) ?? mondayInWeek

        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        guard var urlComponents = URLComponents(string: "https://api.github.com/search/issues") else {
            return
        }

        var query =
        """
        q=
        +type:pr
        +author:\(userName)
        """
        if !organization.isEmpty {
            query += "+org:\(organization)"
        }
        query +=
        """
        +created:\(startDateString)..\(endDateString)
        +updated:\(startDateString)..\(endDateString)
        """
        urlComponents.query = query

        print(
            """
            \(startDateString) ~ \(endDateString) in \(!organization.isEmpty ? organization : "all repositories")
            ---------------------------------------
            """
        )

        guard let url = urlComponents.url else {
            debugPrint("No URL from the URLComponents.")
            return
        }

        var request = URLRequest(url: url)
        request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3.text-match+json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"

        loadRequest(request) { [weak self] itemResponse in
            if let itemResponse = itemResponse, let output = self?.generateOutput(itemResponse) {
                print(output)
            }
        }
    }

    // - MARK: Public methods

    public func loadRequest(_ request: URLRequest, completion: @escaping (Issues?) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, error -> Void in
            guard let response = response as? HTTPURLResponse, let data = data else {
                assertionFailure("Invalid response or data.")
                return
            }

            if response.statusCode != 200 {
                debugPrint("Statu code: \(response.statusCode)")
            }

            if let error = error {
                debugPrint(error)
                completion(nil)
            }

            do {
                let decoder = JSONDecoder()
                if #available(OSX 10.12, *) {
                    decoder.dateDecodingStrategy = .iso8601
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                }
                let issues = try decoder.decode(Issues.self, from: data)
                completion(issues)
            } catch {
                debugPrint(error)
                completion(nil)
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()
    }

    public func generateOutput(_ itemResponse: Issues) -> String {
        let items = itemResponse.items.sorted(by: { $0.createdAt > $1.createdAt })

        var output = ""
        output += "Total count: \(itemResponse.totalCount)\n\n"

        for (index, item) in items.enumerated() {
            var repositoryURL = item.repositoryURL
            let count = "https://api.github.com/repos/".count
            let range = repositoryURL.startIndex..<repositoryURL.index(repositoryURL.startIndex, offsetBy: count)
            repositoryURL.removeSubrange(range)

            let dateString = uiDateFormatter.string(from: item.updatedAt)

            output += "* [*\(dateString)*] [\(repositoryURL)] [#\(item.number)](\(item.url)) \(item.title)"

            if index >= 0 && index != (items.count - 1) {
                output += "\n"
            }
        }
        return output
    }

    // - MARK: Private methods

    private func printErrorForAccessToken() {
        print(
            """
            Please add your personal access token for repo (Full control of private repositories) in Github.
            In Github, you can generate a token for repo in Personal settings > Personal access tokens.
            Please add the token by executing `snippet --token [YOUR_PERSONAL_ACCESS_TOKEN]` at first.
            """
        )
    }
}
