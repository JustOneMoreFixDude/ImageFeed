@testable import ImageFeed
import XCTest

// Spy для ImagesListViewControllerProtocol.
// Это фальшивый экран, который ничего не рисует,
// а только запоминает, какие команды ему дал Presenter.
final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var updatePhotosCalled = false
    var insertRowsCalled = false
    var showBlockingProgressHUDCalled = false
    var dismissBlockingProgressHUDCalled = false
    var updateLikeCalled = false
    var showLikeErrorCalled = false
    var receivedPhotos: [Photo] = []
    var receivedIndexPaths: [IndexPath] = []
    var receivedIsLiked: Bool?
    var receivedLikeIndex: Int?
    var receivedError: Error?

    func updatePhotos(_ photos: [Photo]) {
        updatePhotosCalled = true
        receivedPhotos = photos
    }

    func insertRows(at indexPaths: [IndexPath]) {
        insertRowsCalled = true
        receivedIndexPaths = indexPaths
    }

    func showBlockingProgressHUD() {
        showBlockingProgressHUDCalled = true
    }

    func dismissBlockingProgressHUD() {
        dismissBlockingProgressHUDCalled = true
    }

    func updateLike(isLiked: Bool, at index: Int) {
        updateLikeCalled = true
        receivedIsLiked = isLiked
        receivedLikeIndex = index
    }

    func showLikeError(_ error: Error) {
        showLikeErrorCalled = true
        receivedError = error
    }
}

// Stub для ImagesListServiceProtocol.
// Это фальшивый сервис, в котором мы сами задаём фотографии
// и сами управляем результатом changeLike.
final class ImagesListServiceStub: ImagesListServiceProtocol {
    var photos: [Photo]
    var fetchPhotosNextPageCalled = false
    var changeLikeCalled = false
    var receivedPhotoId: String?
    var receivedIsLike: Bool?
    var changeLikeResult: Result<Void, Error> = .success(())
    init(photos: [Photo]) {
        self.photos = photos
    }

    func fetchPhotosNextPage(
        token: String,
        completion: @escaping (Result<[Photo], Error>) -> Void
    ) {
        fetchPhotosNextPageCalled = true
        completion(.success(photos))
    }

    func changeLike(
        photoId: String,
        isLike: Bool,
        token: String,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        changeLikeCalled = true
        receivedPhotoId = photoId
        receivedIsLike = isLike
        completion(changeLikeResult)
    }
}

// Фабрика тестовых фотографий.
// Нужна, чтобы не писать полный init Photo в каждом тесте.
private enum PhotoMockFactory {
    static func makePhoto(
        id: String = "1",
        isLiked: Bool = false
    ) -> Photo {
        Photo(
            id: id,
            size: CGSize(width: 100, height: 100),
            createdAt: nil,
            welcomeDescription: nil,
            thumbImageURL: "https://example.com/thumb.jpg",
            largeImageURL: "https://example.com/large.jpg",
            isLiked: isLiked
        )
    }
}

final class ImagesListTests: XCTestCase {

    private enum TestError: Error {
        case someError
    }

    // MARK: Test 1
    // Проверяем, что при открытии экрана Presenter просит сервис
    // загрузить первую/следующую страницу фотографий.
    func testPresenterFetchesPhotosWhenViewDidLoad() {
        // Given
        let service = ImagesListServiceStub(photos: [])
        let presenter = ImagesListPresenter(imagesListService: service)

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertTrue(service.fetchPhotosNextPageCalled)
    }

    // MARK: Test 2
    // Проверяем, что Presenter после обновления фотографий
    // передаёт новый массив во ViewController.
    func testPresenterUpdatesPhotosWhenPhotosChanged() {
        // Given
        let photo = PhotoMockFactory.makePhoto(id: "1")
        let service = ImagesListServiceStub(photos: [photo])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // When
        presenter.didReceivePhotosUpdate()

        // Then
        XCTAssertTrue(view.updatePhotosCalled)
        XCTAssertEqual(view.receivedPhotos.count, 1)
        XCTAssertEqual(view.receivedPhotos.first?.id, "1")
    }

    // MARK: Test 3
    // Проверяем, что Presenter считает indexPath новых строк
    // и просит ViewController вставить их в таблицу.
    func testPresenterInsertsRowsWhenNewPhotosAdded() {
        // Given
        let firstPhoto = PhotoMockFactory.makePhoto(id: "1")
        let secondPhoto = PhotoMockFactory.makePhoto(id: "2")
        let service = ImagesListServiceStub(photos: [firstPhoto, secondPhoto])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // When
        presenter.didReceivePhotosUpdate()

        // Then
        XCTAssertTrue(view.insertRowsCalled)
        XCTAssertEqual(view.receivedIndexPaths, [
            IndexPath(row: 0, section: 0),
            IndexPath(row: 1, section: 0)
        ])
    }

    // MARK: Test 4
    // Проверяем, что Presenter НЕ вставляет строки,
    // если количество фотографий не увеличилось.
    func testPresenterDoesNotInsertRowsWhenPhotosCountDidNotChange() {
        // Given
        let photo = PhotoMockFactory.makePhoto(id: "1")
        let service = ImagesListServiceStub(photos: [photo])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.didReceivePhotosUpdate()
        view.insertRowsCalled = false
        view.receivedIndexPaths = []

        // When
        presenter.didReceivePhotosUpdate()

        // Then
        XCTAssertFalse(view.insertRowsCalled)
        XCTAssertTrue(view.receivedIndexPaths.isEmpty)
    }

    // MARK: Test 5
    // Проверяем, что при показе последней фотографии Presenter
    // просит сервис загрузить следующую страницу.
    func testPresenterFetchesNextPageWhenLastPhotoWillDisplay() {
        // Given
        let firstPhoto = PhotoMockFactory.makePhoto(id: "1")
        let secondPhoto = PhotoMockFactory.makePhoto(id: "2")
        let service = ImagesListServiceStub(photos: [firstPhoto, secondPhoto])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.didReceivePhotosUpdate()
        service.fetchPhotosNextPageCalled = false

        // When
        presenter.willDisplayPhoto(at: 1)

        // Then
        XCTAssertTrue(service.fetchPhotosNextPageCalled)
    }

    // MARK: Test 6
    // Проверяем, что если показывается НЕ последняя фотография,
    // Presenter НЕ просит грузить следующую страницу.
    func testPresenterDoesNotFetchNextPageWhenNotLastPhotoWillDisplay() {
        // Given
        let firstPhoto = PhotoMockFactory.makePhoto(id: "1")
        let secondPhoto = PhotoMockFactory.makePhoto(id: "2")
        let service = ImagesListServiceStub(photos: [firstPhoto, secondPhoto])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.didReceivePhotosUpdate()
        service.fetchPhotosNextPageCalled = false

        // When
        presenter.willDisplayPhoto(at: 0)

        // Then
        XCTAssertFalse(service.fetchPhotosNextPageCalled)
    }

    // MARK: Test 7
    // Проверяем успешный сценарий лайка:
    // Presenter показывает HUD, вызывает changeLike, скрывает HUD,
    // обновляет фотографии и сердечко у ячейки.
    func testPresenterUpdatesLikeWhenChangeLikeSucceeded() {
        // Given
        let oldPhoto = PhotoMockFactory.makePhoto(id: "1", isLiked: false)
        let updatedPhoto = PhotoMockFactory.makePhoto(id: "1", isLiked: true)
        let service = ImagesListServiceStub(photos: [oldPhoto])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view
        presenter.didReceivePhotosUpdate()
        service.photos = [updatedPhoto]
        service.changeLikeResult = .success(())

        // When
        presenter.didTapLike(at: 0)

        // Then
        XCTAssertTrue(view.showBlockingProgressHUDCalled)
        XCTAssertTrue(view.dismissBlockingProgressHUDCalled)
        XCTAssertTrue(service.changeLikeCalled)
        XCTAssertEqual(service.receivedPhotoId, "1")
        XCTAssertEqual(service.receivedIsLike, true)
        XCTAssertTrue(view.updatePhotosCalled)
        XCTAssertEqual(view.receivedPhotos.first?.isLiked, true)
        XCTAssertTrue(view.updateLikeCalled)
        XCTAssertEqual(view.receivedIsLiked, true)
        XCTAssertEqual(view.receivedLikeIndex, 0)
    }

    // MARK: Test 8
    // Проверяем ошибочный сценарий лайка:
    // Presenter показывает HUD, вызывает changeLike, скрывает HUD
    // и сообщает ViewController об ошибке.
    func testPresenterShowsErrorWhenChangeLikeFailed() {
        // Given
        let photo = PhotoMockFactory.makePhoto(id: "1", isLiked: false)
        let service = ImagesListServiceStub(photos: [photo])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        service.changeLikeResult = .failure(TestError.someError)
        presenter.view = view
        presenter.didReceivePhotosUpdate()

        // When
        presenter.didTapLike(at: 0)

        // Then
        XCTAssertTrue(view.showBlockingProgressHUDCalled)
        XCTAssertTrue(view.dismissBlockingProgressHUDCalled)
        XCTAssertTrue(view.showLikeErrorCalled)
        XCTAssertNotNil(view.receivedError)
        XCTAssertFalse(view.updateLikeCalled)
    }

    // MARK: Test 9
    // Проверяем защиту от неверного индекса:
    // если пользователь нажал лайк по индексу, которого нет,
    // Presenter ничего не должен делать.
    func testPresenterDoesNothingWhenLikeIndexIsInvalid() {
        // Given
        let service = ImagesListServiceStub(photos: [])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // When
        presenter.didTapLike(at: 0)

        // Then
        XCTAssertFalse(service.changeLikeCalled)
        XCTAssertFalse(view.showBlockingProgressHUDCalled)
        XCTAssertFalse(view.dismissBlockingProgressHUDCalled)
    }
}
