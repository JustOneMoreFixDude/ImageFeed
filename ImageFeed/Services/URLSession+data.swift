import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

// общий обработчик сетевого ответа
extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let task = dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(NetworkError.urlRequestError(error)))
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.urlSessionError))
                    return
                }

                guard (200..<300).contains(response.statusCode) else {
                    if let data {
                        print(String(data: data, encoding: .utf8) ?? "")
                    }
                    completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                    return
                }

                guard let data else {
                    completion(.failure(NetworkError.urlSessionError))
                    return
                }

                completion(.success(data))
            }
        }

        return task
    }
}
