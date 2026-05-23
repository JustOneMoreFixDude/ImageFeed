import Foundation

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
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
              
        guard lastCode != code
        else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        task?.cancel()
        task = nil
        
        lastCode = code
        guard
            let request = makeOAuthTokenRequest(code: code)
        else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let newTask = urlSession.objectTask(for: request) {
            [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            
            guard let self else { return }
            
            self.task = nil
            self.lastCode = nil
            
            switch result {
            case .success(let responseBody):
                OAuth2TokenStorage.shared.token = responseBody.accessToken
                completion(.success(responseBody.accessToken))
            case .failure(let error):
                print("[OAuth2Service.fetchOAuthToken]: \(error)")
                completion(.failure(error))
            }
        }
        self.task = newTask
        newTask.resume()
        
    }
    
}
