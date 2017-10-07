/**
 *  Snippet
 *  Copyright (c) Nagasawa Hiroki 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public final class Snippet {
    private let arguments: [String]

    private var accessToken: String? {
        get {
            return UserDefaults.standard.object(forKey: "PERSONAL_ACCESS_TOKEN") as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "PERSONAL_ACCESS_TOKEN")
            UserDefaults.standard.synchronize()
        }
    }

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    private lazy var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday is the first weekday.
        return calendar
    }()

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        /// Set default parameters.
        var weekNumber = -1
        var organization = ""

        /// Check arguments and options.
        var expectingWeekNumber = false
        var expectingAccessToken = false
        for argument in arguments[1..<arguments.count] {
            if expectingWeekNumber {
                weekNumber = Int(argument) ?? weekNumber
            }
            if expectingAccessToken {
                accessToken = argument
            }

            switch argument {
            case "help":
                printHelp()
                return
            case let x where !x.hasPrefix("--") && !expectingWeekNumber && !expectingAccessToken:
                organization = x
            case "--week":
                expectingWeekNumber = true
                expectingAccessToken = false
            case "--token":
                expectingWeekNumber = false
                expectingAccessToken = true
            default:
                expectingWeekNumber = false
                expectingAccessToken = false
                continue
            }
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

    public func loadRequest(_ request: URLRequest, completion: @escaping (ItemResponse?) -> Void) {
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
                let itemResponse = try decoder.decode(ItemResponse.self, from: data)
                completion(itemResponse)
            } catch {
                debugPrint(error)
                completion(nil)
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()
    }

    public func generateOutput(_ itemResponse: ItemResponse, isShownDate: Bool = false) -> String {
        let items = itemResponse.items.sorted(by: { $0.createdAt > $1.createdAt })

        var output = ""
        output += "Total count: \(itemResponse.totalCount)\n"

        for (index, item) in items.enumerated() {
            var repositoryURL = item.repositoryURL
            let count = "https://api.github.com/repos/".count
            let range = repositoryURL.startIndex..<repositoryURL.index(repositoryURL.startIndex, offsetBy: count)
            repositoryURL.removeSubrange(range)

            output += "* [\(repositoryURL)] [#\(item.number)](\(item.url)) \(item.title)"

            if isShownDate {
                output += " - creaated_at: \(item.createdAt), updated_at: \(item.updatedAt)"
            }
            if index >= 0 && index != (items.count - 1) {
                output += "\n"
            }
        }
        return output
    }

    // - MARK: Private methods

    private func printHelp() {
        print(
            """
            Snippet
            --------------
            Quickly extract your specific Github PRs with links last week (or earlier than last week) to markdown formats.

            Usage:
            - Specify an organization in Github. (The default is your all repositories.)
            - Pass a past week number using the `--week`. (The default is `-1`)
            - Register your access token for repo (Full control of private repositories) in Github using the `--token` at first.

            Examples:
            - snippet --week 0
            - snippet Org
            - snippet Org --week -4
            - snippet Org --token [YOUR_PERSONAL_ACCESS_TOKEN]
            """
        )
    }

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
