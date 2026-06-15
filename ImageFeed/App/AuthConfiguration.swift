import Foundation

enum Constants {
    
//    static let accessKey = Secrets.accessKey // Secrets.swift .gitignore
//    static let secretKey = Secrets.secretKey // Secrets.swift .gitignore
    
    // Заглушки для сборки проекта у ревьюера
    static let accessKey = "YOUR_ACCESS_KEY"
    static let secretKey = "YOUR_SECRET_KEY"

    
    static let redirectURI: String = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope: String = "public+read_user+write_user+read_photos+write_photos+read_collections+write_collections+write_likes"
    static let defaultBaseURLString: String = "https://api.unsplash.com"
    enum API {
        static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
        static let unsplashTokenURLString = "https://unsplash.com/oauth/token"
    }
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURLString: String
    let authURLString: String
    static var standard: AuthConfiguration {
        AuthConfiguration(
            accessKey: Constants.accessKey,
            secretKey: Constants.secretKey,
            redirectURI: Constants.redirectURI,
            accessScope: Constants.accessScope,
            defaultBaseURLString: Constants.defaultBaseURLString,
            authURLString: Constants.API.unsplashAuthorizeURLString
        )
    }
}
