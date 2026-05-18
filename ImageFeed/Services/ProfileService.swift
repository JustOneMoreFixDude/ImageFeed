import Foundation

final class ProfileService {

    private let jsonDecoder = JSONDecoder()
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

        let newTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.task = nil
                    completion(.failure(error))
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    self.task = nil
                    completion(.failure(NSError(domain: "ProfileService", code: -1)))
                }
                return
            }

            do {
                let profileResult = try self.jsonDecoder.decode(ProfileResult.self, from: data)
                let name = "\(profileResult.firstName ?? "") \(profileResult.lastName ?? "")"
                    .trimmingCharacters(in: .whitespaces)

                let newProfile = Profile(
                    username: profileResult.username,
                    name: name,
                    loginName: "@\(profileResult.username)",
                    bio: profileResult.bio ?? ""
                )
                DispatchQueue.main.async {
                    self.profile = newProfile
                    self.task = nil
                    completion(.success(newProfile))
                }
            } catch {
                DispatchQueue.main.async {
                    self.task = nil
                    completion(.failure(error))
                }
            }
        }

        self.task = newTask
        newTask.resume()
    }
}
