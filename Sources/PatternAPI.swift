import Foundation
import UIKit

struct PatternAPIResponse: Decodable, Sendable {
    let id: String
    let labels: [String]
    let artifacts: Artifacts

    struct Artifacts: Decodable, Sendable {
        let yaml: String
        let svg: String
        let printableSvg: String
        let printablePdf: String
        let previewPng: String
        let specificationJson: String

        enum CodingKeys: String, CodingKey {
            case yaml
            case svg
            case printableSvg = "printable_svg"
            case printablePdf = "printable_pdf"
            case previewPng = "preview_png"
            case specificationJson = "specification_json"
        }
    }
}

enum PatternAPIError: LocalizedError {
    case invalidServerURL
    case imageEncodingFailed
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Enter the server URL, for example http://192.168.1.42:8000."
        case .imageEncodingFailed:
            return "The selected image could not be converted to JPEG."
        case .server(let status, let message):
            return "Server error \(status): \(message)"
        }
    }
}

struct PatternAPIClient {
    let baseURL: URL

    init(serverURL: String) throws {
        guard let url = URL(string: serverURL),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw PatternAPIError.invalidServerURL
        }
        baseURL = url
    }

    func createPattern(image: UIImage, labels: [String]) async throws -> PatternAPIResponse {
        guard let jpeg = image.jpegData(compressionQuality: 0.9) else {
            throw PatternAPIError.imageEncodingFailed
        }
        let boundary = "GarmentCode-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "v1/patterns"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(boundary: boundary, imageData: jpeg, labels: labels)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PatternAPIError.server(status: 0, message: "No HTTP response received")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PatternAPIError.server(status: http.statusCode, message: message)
        }
        return try JSONDecoder().decode(PatternAPIResponse.self, from: data)
    }

    func artifactURL(_ relativePath: String) -> URL? {
        URL(string: relativePath, relativeTo: baseURL)?.absoluteURL
    }

    private func multipartBody(boundary: String, imageData: Data, labels: [String]) -> Data {
        var body = Data()
        func append(_ text: String) { body.append(text.data(using: .utf8)!) }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"photo\"; filename=\"garment.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"labels\"\r\n\r\n")
        append(String(data: try! JSONEncoder().encode(labels), encoding: .utf8)!)
        append("\r\n--\(boundary)--\r\n")
        return body
    }
}
