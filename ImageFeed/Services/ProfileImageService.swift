import Foundation

final class ProfileImageService {

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?

    static let shared = ProfileImageService()
    
    static let didChangeNotification = Notification.Name(
        rawValue: "ProfileImageProviderDidChange"
    )
    
    private init() {}
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread) // убеждаемся, что на главном потоке
        
        if task != nil {
            return
        }
        
        guard let token = OAuth2TokenStorage.shared.token else {
            return
        }
        
        guard let url = URL(string: Constants.defaultBaseURLString + "/users/\(username)") else {
            completion(.failure(NSError(domain: "ProfileImageService", code: -2)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let newTask = urlSession.objectTask(for: request) {
            [weak self] (result: Result<UserResult, Error>) in

            guard let self else { return }

            switch result {
            case .success(let userResult):
                let avatarURL = userResult.profileImage.small

                self.task = nil

                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": avatarURL]
                )

                completion(.success(avatarURL))

            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: \(error)")
                self.task = nil
                completion(.failure(error))
            }
        }
        self.task = newTask
        newTask.resume()
    }
}
