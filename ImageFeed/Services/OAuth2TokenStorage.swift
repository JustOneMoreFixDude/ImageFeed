import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}
    
    private let tokenKey = "OAuthToken"

    var token: String? {
        get {
            //UserDefaults.standard.string(forKey: "OAuthToken")
            KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            //UserDefaults.standard.set(newValue, forKey: "OAuthToken")
            
            if let newValue {
                KeychainWrapper.standard.set(newValue, forKey: tokenKey)
            } else {
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
}
