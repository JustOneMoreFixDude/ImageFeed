import Foundation

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let jsonDecoder = JSONDecoder()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.API.unsplashTokenURLString) else {
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        guard let authTokenUrl = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        
        return request
    }
    
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {

        // UI should show loader before calling this service.
        // UIBlockingProgressHUD.show()

        guard task == nil
        else {
            // UI should hide loader in completion.
            // UIBlockingProgressHUD.dismiss()
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        guard lastCode != code
        else {
            // UI should hide loader in completion.
            // UIBlockingProgressHUD.dismiss()
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        //task?.cancel() // we no longer need the old request

        lastCode = code
        guard
            let request = makeOAuthTokenRequest(code: code)
        else {
            // UI should hide loader in completion.
            // UIBlockingProgressHUD.dismiss()
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let newTask = urlSession.data(for: request) { [weak self] result in
            
            // UI should hide loader in completion.
            // UIBlockingProgressHUD.dismiss()
            
            guard let self else { return }
            
            self.task = nil
            self.lastCode = nil
            
            switch result {
            case .success(let data):
                do {
                    let responseBody = try self.jsonDecoder.decode(OAuthTokenResponseBody.self, from: data)
                    OAuth2TokenStorage.shared.token = responseBody.accessToken
                    completion(.success(responseBody.accessToken))
                } catch {
                    print("Decoding error: \(error)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                print("Network error: \(error)")
                completion(.failure(error))
            }
        }
        self.task = newTask
        newTask.resume()
        
    }
    
}
