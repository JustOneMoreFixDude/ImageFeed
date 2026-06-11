import Foundation

// Протокол хелпера авторизации.
// Нужен, чтобы Presenter зависел не от конкретного AuthHelper,
// а от договора. Потом в тестах сюда можно будет подставить Stub.
protocol AuthHelperProtocol {
    // Собирает URLRequest для открытия страницы авторизации Unsplash.
    func authRequest() -> URLRequest?
    
    // Достаёт authorization code из redirect URL после успешного логина.
    func code(from url: URL) -> String?
}

// Вспомогательный класс для OAuth-авторизации.
// Он не показывает UI и ничего не знает про WebView.
// Его работа: собрать ссылку авторизации и вытащить code из URL.
final class AuthHelper: AuthHelperProtocol {
    
    // Конфигурация с accessKey, redirectURI, scope и адресами Unsplash.
    let configuration: AuthConfiguration
    
    // По умолчанию используем обычную production-конфигурацию.
    // В тестах сюда можно передать другую конфигурацию.
    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }
    
    // Делает готовый URLRequest для WebView.
    // WebViewViewController потом просто загрузит этот request.
    func authRequest() -> URLRequest? {
        guard let url = authURL() else { return nil }
        return URLRequest(url: url)
    }

    // Собирает полный URL авторизации Unsplash с query-параметрами:
    // client_id, redirect_uri, response_type и scope.
    func authURL() -> URL? {
        guard var urlComponents = URLComponents(string: configuration.authURLString) else {
            return nil
        }
        
        // Это параметры, которые Unsplash требует для OAuth-авторизации.
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.accessKey),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope)
        ]
        
        return urlComponents.url
    }
    
    // После успешной авторизации Unsplash редиректит пользователя на redirectURI
    // и добавляет в URL параметр code. Здесь мы этот code достаём.
    func code(from url: URL) -> String? {
        if let urlComponents = URLComponents(string: url.absoluteString),
           // Проверяем, что это именно нужный redirect URL, а не любой другой переход внутри WebView.
           urlComponents.path == "/oauth/authorize/native",
           let items = urlComponents.queryItems,
           let codeItem = items.first(where: { $0.name == "code" })
        {
            return codeItem.value
        } else {
            return nil
        }
    }
    
    
}
