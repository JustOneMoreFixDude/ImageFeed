// Модель JSON ответа от GET /users/:username

struct UserResult: Decodable {
    let profileImage: ProfileImage

    // Преобразует snake_case из JSON в camelCase свойства Swift
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

// Содержит ссылки на изображения профиля пользователя
struct ProfileImage: Decodable {
    let small: String
}
