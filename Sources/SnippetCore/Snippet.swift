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

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    lazy var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday is the first weekday.
        return calendar
    }()

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        guard arguments.count > 1 else {
            printHelp()
            return
        }

        var weekNumber = -1

        var expectingWeekNumber = false
        var expectingAccessToken = false
        for argument in arguments[2..<arguments.count] {
            if expectingWeekNumber {
                weekNumber = Int(argument) ?? weekNumber
            }
            if expectingAccessToken {
                accessToken = argument
            }

            switch argument {
            case "--week":
                expectingWeekNumber = true
            case "--token":
                expectingAccessToken = true
            default:
                expectingWeekNumber = false
                expectingAccessToken = false
                continue
            }
        }

        guard let accessToken = self.accessToken else {
            print(
                """
                Please add your personal access token in Githug.
                In Github, you can generate a token in Personal settings > Personal access tokens.
                Please add the token by executing `snippet --token "YOUR_PERSONAL_ACCESS_TOKEN"`
                """
            )
            return
        }

        let organization = arguments[1]
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
        urlComponents.query =
            """
            q=+type:pr+author:\(userName)
            +org:\(organization)
            +created:\(startDateString)..\(endDateString)
            +updated:\(startDateString)..\(endDateString)
            """
        print(
            """
            \(startDateString) ~ \(endDateString)
            ---------------------------------------
            """
        )

        guard let url = urlComponents.url else {
            return
        }

        var request = URLRequest(url: url)
        request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3.text-match+json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"

        loadRequest(request)
    }

    func loadRequest(_ request: URLRequest) {
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
            guard let response = response as? HTTPURLResponse, let data = data else {
                assertionFailure("Invalid response or data.")
                return
            }

            if response.statusCode != 200 {
                debugPrint("Statu code: \(response.statusCode)")
            }

            do {
                let itemResponse = try JSONDecoder().decode(ItemResponse.self, from: data)
                self?.printOutput(itemResponse)
            } catch {
                debugPrint(error)
            }

            if let error = error {
                debugPrint(error)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }

    // - MARK: Private methods

    private func printHelp() {
        print(
            """
            Snippet
            --------------
            Quickly extract your specific Github PRs with links last week (or earlier than last week) to markdown formats.

            Usage:
            - Specify an organization in Github.
            - Pass a past week number using the `--week`. The default is `-1`.

            Examples:
            - snippet Hoge
            - snippet Hoge --week -4
            """
        )
    }

    private func printOutput(_ itemResponse: ItemResponse, isShownDate: Bool = false) {
        let items = itemResponse.items

        print("Total count: \(itemResponse.totalCount)")

        for item in items {
            var repositoryURL = item.repositoryURL
            let count = "https://api.github.com/repos/".count
            let range = repositoryURL.startIndex..<repositoryURL.index(repositoryURL.startIndex, offsetBy: count)
            repositoryURL.removeSubrange(range)

            var output = "* [\(repositoryURL)] [#\(item.number)](\(item.url)) \(item.title)"
            if isShownDate {
                output += " - creaated_at: \(item.createdAt), updated_at: \(item.updatedAt)"
            }

            print(output)
        }
    }
}
