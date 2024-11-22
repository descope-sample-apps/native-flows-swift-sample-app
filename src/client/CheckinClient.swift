
import Foundation

class CheckinClient: HTTPClient, @unchecked Sendable {

    init() {
        super.init(baseURL: serverBaseURL)
    }

    override var basePath: String {
        return "api/checkout"
    }

    // Load Checkin

    struct CheckinResponse: JSONResponse {
        let checkin: Checkin?
    }

    func loadCheckin(sessionJwt: String) async throws -> CheckinResponse {
        let headers = [
            "Authorization": "Bearer \(sessionJwt)"
        ]
        return try await get("checkin", headers: headers)
    }

    // Send Checkin

    func sendCheckin(sessionJwt: String) async throws {
        let headers = [
            "Authorization": "Bearer \(sessionJwt)"
        ]
        try await post("checkin", headers: headers)
    }
}
