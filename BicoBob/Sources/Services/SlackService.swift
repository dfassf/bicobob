import Foundation

enum SlackService {
    private static let usersAPI = "https://slack.com/api/users.list"
    private static let searchAPI = "https://slack.com/api/search.messages"

    // MARK: - Username Resolution

    static func resolveUsername(token: String, displayName: String) async throws -> String {
        // ASCII-only names don't need resolution
        if displayName.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "." || $0 == "-") }) {
            return displayName
        }

        var cursor = ""
        while true {
            var components = URLComponents(string: usersAPI)!
            components.queryItems = [URLQueryItem(name: "limit", value: "200")]
            if !cursor.isEmpty {
                components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
            }

            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            guard json["ok"] as? Bool == true else {
                throw AppError.slack(json["error"] as? String ?? "unknown")
            }

            if let members = json["members"] as? [[String: Any]] {
                for member in members {
                    let realName = member["real_name"] as? String ?? ""
                    let dn = (member["profile"] as? [String: Any])?["display_name"] as? String ?? ""
                    if realName == displayName || dn == displayName {
                        if let name = member["name"] as? String {
                            return name
                        }
                    }
                }
            }

            let next = (json["response_metadata"] as? [String: Any])?["next_cursor"] as? String ?? ""
            if next.isEmpty { break }
            cursor = next
        }

        return displayName
    }

    // MARK: - Search Messages

    static func checkMessageTs(token: String, channelName: String, username: String) async throws -> String? {
        let slackUsername = try await resolveUsername(token: token, displayName: username)
        let weekKey = DateUtils.currentWeekKey()
        let query = "from:@\(slackUsername) in:\(channelName) \"\(weekKey)\" BICO TABLE"

        let matches = try await searchMessages(token: token, query: query, count: 1)
        return matches.first(where: { ($0["text"] as? String)?.contains(weekKey) == true })?["ts"] as? String
    }

    static func fetchLunchImages(token: String, channelName: String, username: String) async throws -> [LunchImage] {
        let slackUsername = try await resolveUsername(token: token, displayName: username)
        let weekKey = DateUtils.currentWeekKey()
        let query = "from:@\(slackUsername) in:\(channelName) \"\(weekKey)\" BICO TABLE"

        let matches = try await searchMessages(token: token, query: query, count: 5)

        var images: [LunchImage] = []
        for msg in matches {
            let msgText = msg["text"] as? String ?? ""
            guard msgText.contains(weekKey) else { continue }
            let msgTs = msg["ts"] as? String ?? ""

            guard let files = msg["files"] as? [[String: Any]] else { continue }
            for file in files {
                let mime = file["mimetype"] as? String ?? ""
                guard mime.hasPrefix("image/") else { continue }

                let url = (file["url_private"] as? String)
                    ?? (file["thumb_1024"] as? String)
                    ?? (file["thumb_720"] as? String)
                    ?? (file["thumb_480"] as? String)
                    ?? ""
                guard !url.isEmpty else { continue }

                // Download image
                var imgRequest = URLRequest(url: URL(string: url)!)
                imgRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let (imgData, _) = try await URLSession.shared.data(for: imgRequest)

                guard imgData.count > 100 else { continue }

                let b64 = imgData.base64EncodedString()
                let dataUrl = "data:\(mime);base64,\(b64)"

                images.append(LunchImage(
                    base64DataUrl: dataUrl,
                    filename: file["name"] as? String ?? "",
                    timestamp: msgTs,
                    messageText: msgText
                ))
            }
        }

        return images
    }

    // MARK: - Private

    private static func searchMessages(token: String, query: String, count: Int) async throws -> [[String: Any]] {
        var components = URLComponents(string: searchAPI)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "sort", value: "timestamp"),
            URLQueryItem(name: "sort_dir", value: "desc"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard json["ok"] as? Bool == true else {
            throw AppError.slack(json["error"] as? String ?? "unknown")
        }

        let messages = json["messages"] as? [String: Any]
        return messages?["matches"] as? [[String: Any]] ?? []
    }
}

enum AppError: LocalizedError {
    case slack(String)
    case gemini(String)
    case noMenu

    var errorDescription: String? {
        switch self {
        case .slack(let msg): return "Slack: \(msg)"
        case .gemini(let msg): return "Gemini: \(msg)"
        case .noMenu: return "이번 주 점심 메뉴를 찾지 못했습니다."
        }
    }
}
