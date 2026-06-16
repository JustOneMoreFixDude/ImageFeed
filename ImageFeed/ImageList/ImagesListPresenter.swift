import UIKit

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

protocol ImagesListViewControllerProtocol: AnyObject {
    func updatePhotos(_ photos: [Photo])
    func insertRows(at indexPaths: [IndexPath])
    func showBlockingProgressHUD()
    func dismissBlockingProgressHUD()
    func updateLike(isLiked: Bool, at index: Int)
    func showLikeError(_ error: Error)
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }

    func viewDidLoad()
    func didReceivePhotosUpdate()
    func willDisplayPhoto(at index: Int)
    func didTapLike(at index: Int)
}

// Presenter ленты фотографий.
final class ImagesListPresenter: ImagesListPresenterProtocol {

    weak var view: ImagesListViewControllerProtocol?
    private var photos: [Photo] = []
    
    private let imagesListService: ImagesListServiceProtocol
    
    init(imagesListService: ImagesListServiceProtocol = ImagesListService.shared) {
        self.imagesListService = imagesListService
    }

    func viewDidLoad() {
        imagesListService.fetchPhotosNextPage(
            token: OAuth2TokenStorage.shared.token ?? ""
        ) { _ in }
    }
    
    func didReceivePhotosUpdate() {
        let oldCount = photos.count
        let newPhotos = imagesListService.photos
        let newCount = newPhotos.count
        photos = newPhotos
        view?.updatePhotos(newPhotos)
        guard oldCount != newCount else { return }
        let indexPaths = (oldCount..<newCount).map {
            IndexPath(row: $0, section: 0)
        }
        view?.insertRows(at: indexPaths)
    }
    
    func willDisplayPhoto(at index: Int) {
        // Подгружаем следующую страницу при показе последней фотографии.
        if index + 1 == photos.count {
            imagesListService.fetchPhotosNextPage(
                token: OAuth2TokenStorage.shared.token ?? ""
            ) { _ in }
        }
    }
    
    func didTapLike(at index: Int) {
        guard photos.indices.contains(index) else { return }
        let photo = photos[index]
        view?.showBlockingProgressHUD()
        imagesListService.changeLike(
            photoId: photo.id,
            isLike: !photo.isLiked,
            token: OAuth2TokenStorage.shared.token ?? ""
        ) { [weak self] result in
            guard let self else { return }
            self.view?.dismissBlockingProgressHUD()
            switch result {
            case .success:
                let updatedPhotos = self.imagesListService.photos
                self.photos = updatedPhotos
                self.view?.updatePhotos(updatedPhotos)
                if updatedPhotos.indices.contains(index) {
                    self.view?.updateLike(isLiked: updatedPhotos[index].isLiked, at: index)
                }
            case .failure(let error):
                self.view?.showLikeError(error)
            }
        }
    }
}
