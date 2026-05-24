import UIKit

// Сервис для загрузки фотографий из Unsplash.
// Он НЕ отвечает за экран и таблицу.
// Его задача:
// - сходить в сеть;
// - получить JSON с фотографиями;
// - превратить PhotoResult в Photo;
// - сохранить все загруженные фото в массив photos;
// - сообщить экрану, что появились новые данные.

final class ImagesListService {
    
    // Singleton: один общий экземпляр сервиса на всё приложение.
    // Нужен, чтобы массив photos был один, а не создавался заново в разных местах.
    static let shared = ImagesListService()
    // Закрываем init, чтобы снаружи нельзя было случайно создать второй ImagesListService.
    private init() {}
    
    // URLSession выполняет сетевые запросы.
    private let urlSession = URLSession.shared
    // Текущий сетевой запрос.
    // Если task != nil, значит загрузка уже идёт и второй запрос запускать нельзя.
    private var task: URLSessionTask?
    
    // Все фотографии, которые уже загрузили из сети.
    // private(set) значит: снаружи можно читать, но менять можно только внутри сервиса.
    private(set) var photos: [Photo] = []
    // Номер последней успешно загруженной страницы.
    // Нужен, чтобы понимать, какую страницу грузить следующей.
    private var lastLoadedPage: Int? // номер последней скачанной страницы
    
    // Уведомление: сервис сообщает экрану, что массив photos изменился.
    // ViewController подпишется на это уведомление и обновит таблицу.
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    // Превращает строку даты из JSON в Date.
    // JSON приходит примерно так: "2016-05-03T11:00:28-04:00".
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    // Загружает следующую страницу фотографий.
    // token нужен для Authorization header.
    // completion временно оставлен, чтобы было проще видеть результат или ошибку.
    func fetchPhotosNextPage(token: String, completion: @escaping (Result<[Photo], Error>) -> Void) {
        // Если страниц ещё не грузили, lastLoadedPage nil, значит грузим страницу 1.
        // Если уже грузили, берём следующую страницу.
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        // Защита от повторного запроса.
        // Например, willDisplay может сработать несколько раз подряд.
        if task != nil {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        // Собираем URL для запроса списка фотографий.
        // page — номер страницы, per_page — сколько фото загрузить за один раз.
        guard let url = URL(string: Constants.defaultBaseURLString + "/photos?page=\(nextPage)&per_page=10") else {
            completion(.failure(NSError(domain: "ImagesListService", code: -2)))
            return
        }
        
        // Создаём URLRequest на основе URL.
        var request = URLRequest(url: url)
        // GET означает: мы хотим получить данные с сервера.
        request.httpMethod = "GET"
        // Добавляем токен авторизации, как в ProfileService.
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Запускаем сетевой запрос.
        // objectTask сам получит Data и декодирует JSON в [PhotoResult].
        let newTask = urlSession.objectTask(for: request) {
            [weak self] (result: Result<[PhotoResult], Error>) in
            
            // self слабый, чтобы не было лишнего удержания сервиса в замыкании.
            // Если self уже пропал — выходим.
            guard let self else { return }
            
            switch result {
            // Успешно получили массив PhotoResult из JSON.
            case .success(let photoResults):
                // Превращаем каждый PhotoResult из JSON в Photo для приложения.
                // map проходит по массиву и возвращает новый массив.
                let newPhotos = photoResults.map{ photoResult in
                    // Здесь будет дата уже в формате Date, а не строка.
                    let createdAt: Date?
                    
                    if let createdAtString = photoResult.createdAt {
                        createdAt = self.dateFormatter.date(from: createdAtString)
                    } else {
                        createdAt = nil
                    }
                    // Создаём нормальную модель Photo, с которой будет работать UI.
                    return Photo(
                        id: photoResult.id,
                        size: CGSize(width: photoResult.width, height: photoResult.height),
                        createdAt: createdAt,
                        welcomeDescription: photoResult.description,
                        thumbImageURL: photoResult.urls.thumb,
                        largeImageURL: photoResult.urls.full,
                        isLiked: photoResult.likedByUser
                    )
                    
                }
                // photos читает таблица на главном потоке,
                // поэтому обновляем photos тоже на главном потоке.
                DispatchQueue.main.async {
                    // Добавляем новые фото в конец уже загруженного массива.
                    self.photos.append(contentsOf: newPhotos)
                    // Запоминаем, что эта страница успешно загружена.
                    self.lastLoadedPage = nextPage
                    // Запрос завершился, теперь можно будет запустить следующий.
                    self.task = nil
                    // Сообщаем подписчикам, что photos изменился.
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                    // Возвращаем наружу только что загруженные фото.
                    completion(.success(newPhotos))
                }
            // Ошибка сети или декодинга JSON.
            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: \(error)")
                self.task = nil
                completion(.failure(error))
            }
        }
        // Сохраняем task, чтобы знать: запрос сейчас выполняется.
        self.task = newTask
        // Реально запускаем запрос.
        newTask.resume()
        
    }
    
    
    
}
