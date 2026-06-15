import UIKit

// Протокол сервиса ленты фотографий.
// Нужен, чтобы Presenter зависел не от ImagesListService.shared напрямую,
// а от договора. В тестах сюда можно будет подставить Stub.
protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }

    func fetchPhotosNextPage(
        token: String,
        completion: @escaping (Result<[Photo], Error>) -> Void
    )

    func changeLike(
        photoId: String,
        isLike: Bool,
        token: String,
        _ completion: @escaping (Result<Void, Error>) -> Void
    )
}

extension ImagesListService: ImagesListServiceProtocol { }

// Протокол экрана ленты фотографий.
// Через него Presenter будет просить ViewController обновить таблицу.
protocol ImagesListViewControllerProtocol: AnyObject {
    func updatePhotos(_ photos: [Photo])
    func insertRows(at indexPaths: [IndexPath])
    func showBlockingProgressHUD()
    func dismissBlockingProgressHUD()
    func updateLike(isLiked: Bool, at index: Int)
    func showLikeError(_ error: Error)
}

// Протокол Presenter для ленты фотографий.
// ViewController знает только этот протокол, а не конкретный ImagesListPresenter.
protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }

    // ViewController сообщает Presenter, что экран загрузился.
    func viewDidLoad()
    func didReceivePhotosUpdate()
    func willDisplayPhoto(at index: Int)
    func didTapLike(at index: Int)
}

// Presenter
// Он принимает решения: когда загрузить фото, когда обновить таблицу, когда обработать лайк.
final class ImagesListPresenter: ImagesListPresenterProtocol {

    weak var view: ImagesListViewControllerProtocol?
    private var photos: [Photo] = []
    
    // Сервис, через который Presenter загружает фото и меняет лайки.
    private let imagesListService: ImagesListServiceProtocol
    
    // В приложении используется настоящий ImagesListService.shared.
    // В тестах можно будет передать фейковый сервис.
    init(imagesListService: ImagesListServiceProtocol = ImagesListService.shared) {
        self.imagesListService = imagesListService
    }

    func viewDidLoad() {
        // При открытии экрана запускаем первую загрузку фотографий.
        imagesListService.fetchPhotosNextPage(
            token: OAuth2TokenStorage.shared.token ?? ""
        ) { _ in }
    }
    
    func didReceivePhotosUpdate() {
        // Сколько фотографий было до обновления.
        let oldCount = photos.count
        
        // Забираем актуальные фотографии из сервиса.
        let newPhotos = imagesListService.photos
        
        // Сколько фотографий стало после обновления.
        let newCount = newPhotos.count
        
        // Обновляем локальный массив Presenter.
        photos = newPhotos
        
        // Просим ViewController обновить свой массив фотографий.
        view?.updatePhotos(newPhotos)
        
        // Если новых фотографий нет, таблицу обновлять не нужно.
        guard oldCount != newCount else { return }
        
        // Создаём indexPath только для новых строк.
        let indexPaths = (oldCount..<newCount).map {
            IndexPath(row: $0, section: 0)
        }
        
        // Просим ViewController вставить новые строки в таблицу.
        view?.insertRows(at: indexPaths)
    }
    
    func willDisplayPhoto(at index: Int) {
        // Если пользователь дошёл до последней фотографии,
        // загружаем следующую страницу.
        if index + 1 == photos.count {
            imagesListService.fetchPhotosNextPage(
                token: OAuth2TokenStorage.shared.token ?? ""
            ) { _ in }
        }
    }
    
    func didTapLike(at index: Int) {
        // Проверяем, что индекс существует в массиве фотографий.
        guard photos.indices.contains(index) else { return }

        // Берём фотографию, для которой пользователь нажал лайк.
        let photo = photos[index]

        // Просим ViewController заблокировать интерфейс на время сетевого запроса.
        view?.showBlockingProgressHUD()

        // Просим сервис поставить или снять лайк.
        imagesListService.changeLike(
            photoId: photo.id,
            isLike: !photo.isLiked,
            token: OAuth2TokenStorage.shared.token ?? ""
        ) { [weak self] result in
            guard let self else { return }

            // Запрос завершился — можно разблокировать интерфейс.
            self.view?.dismissBlockingProgressHUD()

            switch result {
            case .success:
                // Забираем обновлённый массив фотографий из сервиса.
                let updatedPhotos = self.imagesListService.photos
                self.photos = updatedPhotos

                // Синхронизируем массив фотографий во ViewController.
                self.view?.updatePhotos(updatedPhotos)

                // Обновляем сердечко у конкретной ячейки.
                if updatedPhotos.indices.contains(index) {
                    self.view?.updateLike(isLiked: updatedPhotos[index].isLiked, at: index)
                }

            case .failure(let error):
                // Сообщаем ViewController, что произошла ошибка.
                self.view?.showLikeError(error)
            }
        }
    }
}
