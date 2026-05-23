// Модель JSON ответа с OAuth token от Unsplash

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    
    // Преобразует snake_case из JSON в свойства Swift
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
