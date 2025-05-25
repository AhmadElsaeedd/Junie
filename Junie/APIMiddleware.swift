import Foundation

enum APIMiddlewareError: Error, LocalizedError {
    case invalidURL
    case networkRequestFailed(Error)
    case serverError(statusCode: Int, data: Data?)
    case fileReadError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The backend URL was invalid."
        case .networkRequestFailed(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .serverError(let statusCode, _):
            return "Server returned an error with status code: \(statusCode)."
        case .fileReadError(let underlyingError):
            return "Failed to read audio file data: \(underlyingError.localizedDescription)"
        case .unknown:
            return "An unknown API error occurred."
        }
    }
}

class APIMiddleware {
    private let backendScheme = "https"
    private let backendHost = "e612-2001-8f8-1135-494c-9017-5395-991a-a092.ngrok-free.app"
    private let audioUploadPath = "/tasks/create/"

    private func getAudioUploadURL() -> URL? {
        var components = URLComponents()
        components.scheme = backendScheme
        components.host = backendHost
        components.path = audioUploadPath
        return components.url
    }

    func uploadAudio(fileURL: URL, completion: @escaping (Result<Void, APIMiddlewareError>) -> Void) {
        guard let uploadURL = getAudioUploadURL() else {
            print("Error: Backend URL for audio upload is invalid.")
            completion(.failure(.invalidURL))
            return
        }

        print("APIMiddleware: Attempting to upload audio from \(fileURL.path) to \(uploadURL.absoluteString)")

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        do {
            let audioData = try Data(contentsOf: fileURL)
            var httpBody = Data()

            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            // Field name "audio_file" must match what the FastAPI endpoint expects
            httpBody.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            httpBody.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            httpBody.append(audioData)
            httpBody.append("\r\n".data(using: .utf8)!)
            httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = httpBody

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("APIMiddleware: Network request failed - \(error.localizedDescription)")
                    completion(.failure(.networkRequestFailed(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("APIMiddleware: Invalid response from server.")
                    completion(.failure(.unknown)) // Or a more specific error
                    return
                }

                print("APIMiddleware: Audio upload responded. Status code: \(httpResponse.statusCode)")

                if (200..<300).contains(httpResponse.statusCode) {
                    // Success
                    if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                        print("APIMiddleware: Server response: \(responseString)")
                    }
                    completion(.success(()))
                } else {
                    // Server-side error
                    if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                        print("APIMiddleware: Server error response: \(responseString)")
                    }
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, data: data)))
                }
            }
            task.resume()

        } catch let error {
            print("APIMiddleware: Error reading audio file data - \(error.localizedDescription)")
            completion(.failure(.fileReadError(error)))
        }
    }
} 