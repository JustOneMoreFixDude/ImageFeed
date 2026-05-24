// Данные профиля пользователя Unsplash

struct Profile {
    let username: String      // username
    let name: String          // имя пользователя
    let loginName: String     // @username
    let bio: String           // описание профиля
}

// Модель JSON ответа от GET /me
struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?

    // Преобразует snake_case из JSON в свойства Swift
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}
