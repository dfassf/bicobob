import Foundation

enum GeminiService {
    private static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    static func analyzeMenu(imageBase64: String, apiKey: String) async throws -> [DayMenu] {
        guard !apiKey.isEmpty else {
            throw AppError.gemini("Gemini API Key가 설정되지 않았습니다.")
        }

        // Strip data URL prefix if present
        let pureB64: String
        if let commaIndex = imageBase64.firstIndex(of: ",") {
            pureB64 = String(imageBase64[imageBase64.index(after: commaIndex)...])
        } else {
            pureB64 = imageBase64
        }

        let prompt = """
        이 이미지는 이번 주 점심 메뉴표입니다. 월요일부터 금요일까지 모든 요일의 메뉴를 JSON 배열로 추출해주세요.
        반드시 아래 JSON 형식으로만 답변하세요. 설명이나 다른 텍스트 없이 JSON만 출력하세요:
        [
          {"day":"월","lunch":["메뉴1","메뉴2"],"dinner":["메뉴1","메뉴2"]},
          {"day":"화","lunch":["메뉴1","메뉴2"],"dinner":["메뉴1","메뉴2"]},
          {"day":"수","lunch":["메뉴1","메뉴2"],"dinner":["메뉴1","메뉴2"]},
          {"day":"목","lunch":["메뉴1","메뉴2"],"dinner":["메뉴1","메뉴2"]},
          {"day":"금","lunch":["메뉴1","메뉴2"],"dinner":["메뉴1","메뉴2"]}
        ]
        석식이 없는 날은 dinner를 빈 배열로 하세요. 메뉴 항목에 가격이나 괄호 안 설명이 있으면 포함하세요.
        """

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        ["inline_data": ["mime_type": "image/png", "data": pureB64]]
                    ]
                ]
            ]
        ]

        let url = URL(string: "\(endpoint)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw AppError.gemini("API 오류 (\(httpResponse.statusCode)): \(bodyStr)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let candidates = json["candidates"] as? [[String: Any]] ?? []
        let content = candidates.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]] ?? []
        let rawText = (parts.first?["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract JSON array
        let jsonStr = extractJsonArray(rawText)

        let menuData = jsonStr.data(using: .utf8)!
        let menus = try JSONDecoder().decode([DayMenu].self, from: menuData)
        return menus
    }

    private static func extractJsonArray(_ raw: String) -> String {
        guard let start = raw.firstIndex(of: "["),
              let end = raw.lastIndex(of: "]") else {
            return raw
        }
        return String(raw[start...end])
    }
}
