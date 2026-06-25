import Foundation

/// 통합 백오피스 공개 점심 메뉴 API 클라이언트.
///
/// 기존 SlackService + GeminiService(슬랙 검색 → 이미지 다운로드 → Gemini 파싱)를 대체한다.
/// 백오피스가 이미 슬랙/Gemini 처리를 끝내 DB에 적재해 두므로, 여기선 단순 HTTP GET 한 번.
enum MenuAPIService {
    /// 통합 백오피스 prod base URL (Cloud Run: dashboard-backend).
    static let baseURL = "https://dashboard-backend-pd7opraacq-du.a.run.app"

    /// 백엔드 public_menu 의 X-Bico-Key 와 동일해야 한다 (식사 메뉴 전용 공개 키).
    static let accessKey = "1u1pK0gZ_RhdqEueFNXS9WeR7o2Xz6S3"

    /// 주간 메뉴 조회. weekStartDate=nil 이면 백엔드가 이번 주(KST) 월요일 기준으로 반환.
    static func fetchWeeklyMenu(weekStartDate: String? = nil) async throws -> WeeklyMenuResponse {
        guard var components = URLComponents(string: "\(baseURL)/api/public/lunch-menu") else {
            throw AppError.api("잘못된 API URL")
        }
        if let ws = weekStartDate {
            components.queryItems = [URLQueryItem(name: "week_start_date", value: ws)]
        }
        guard let url = components.url else {
            throw AppError.api("잘못된 API URL")
        }

        var request = URLRequest(url: url)
        request.setValue(accessKey, forHTTPHeaderField: "X-Bico-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.api("응답 형식 오류")
        }
        guard http.statusCode == 200 else {
            throw AppError.api("API 오류 (\(http.statusCode))")
        }

        return try JSONDecoder().decode(WeeklyMenuResponse.self, from: data)
    }
}

enum AppError: LocalizedError {
    case api(String)
    case noMenu

    var errorDescription: String? {
        switch self {
        case .api(let msg): return msg
        case .noMenu: return "이번 주 점심 메뉴를 찾지 못했습니다."
        }
    }
}
