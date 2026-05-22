import Foundation

/* Задача функции: сходить в интернет > получить JSON > превратить JSON в Swift объект */

final class ProfileService {

    //private let jsonDecoder = JSONDecoder()
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    
    static let shared = ProfileService()
    private(set) var profile: Profile?

    private init() {}

    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread) // убеждаемся, что на главном потоке

        if task != nil {
            return
        }
        
        guard let url = URL(string: Constants.defaultBaseURLString + "/me") else {
            completion(.failure(NSError(domain: "ProfileService", code: -2)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let newTask = urlSession.objectTask(for: request) {
            [weak self] (result: Result<ProfileResult, Error>) in
            
            guard let self else { return }
            
            switch result {
            case .success(let profileResult):
                let name = "\(profileResult.firstName ?? "") \(profileResult.lastName ?? "")".trimmingCharacters(in: .whitespaces)
                let newProfile = Profile(
                    username: profileResult.username,
                    name: name,
                    loginName: "@\(profileResult.username)",
                    bio: profileResult.bio ?? ""
                )
                
                self.profile = newProfile
                self.task = nil
                
                completion(.success(newProfile))
                
            case .failure(let error):
                print("[ProfileService.fetchProfile]: \(error)")
                self.task = nil
                completion(.failure(error))
            }
        }

        self.task = newTask
        newTask.resume()
    }
}
