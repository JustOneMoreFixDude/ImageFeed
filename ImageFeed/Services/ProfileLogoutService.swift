import Foundation
import WebKit

final class ProfileLogoutService {
    // Общий экземпляр сервиса logout.
    static let shared = ProfileLogoutService()
    
    private init() {}
    
    // Полностью очищает данные текущего пользователя.
    func logout() {
        // Удаляем OAuth токен.
        OAuth2TokenStorage.shared.token = nil
        
        // Очищаем данные профиля.
        ProfileService.shared.cleanProfile()
        // Очищаем URL аватарки.
        ProfileImageService.shared.cleanAvatar()
        // Очищаем список фотографий.
        ImagesListService.shared.cleanPhotos()
        
        // Удаляем куки и данные WebView.
        cleanCookies()
    }
    
    // Удаляет куки и локальные данные браузера.
    private func cleanCookies() {
        // Удаляем все сохранённые куки.
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // Получаем все данные, сохранённые WebView.
        WKWebsiteDataStore.default().fetchDataRecords(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()
        ) { records in
            // Удаляем каждую найденную запись.
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: record.dataTypes,
                    for: [record],
                    completionHandler: {}
                )
            }
        }
    }
}
