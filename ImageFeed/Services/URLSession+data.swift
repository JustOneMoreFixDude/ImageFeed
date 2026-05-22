import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

// общий обработчик сетевого ответа
/* Задача функции:
 > делает request
 > URLSession
 > Проверка ошибок
 > проверка statusCode
 > возвращает Data*/

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let task = dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    print("[dataTask]: urlRequestError - \(error)")
                    completion(.failure(NetworkError.urlRequestError(error)))
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    print("[dataTask]: urlSessionError - response is nil")
                    completion(.failure(NetworkError.urlSessionError))
                    return
                }

                guard (200..<300).contains(response.statusCode) else {
                    print("[dataTask]: httpStatusCode - \(response.statusCode)")
                    if let data {
                        print("[dataTask]: response data - \(String(data: data, encoding: .utf8) ?? "")")
                    }
                    completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                    return
                }

                guard let data else {
                    print("[dataTask]: urlSessionError - data is nil")
                    completion(.failure(NetworkError.urlSessionError))
                    return
                }

                completion(.success(data))
            }
        }

        return task
    }
    
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        
        let task = data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let object = try decoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    print("[objectTask]: DecodingError - \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "")")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        return task
    }
    
}
