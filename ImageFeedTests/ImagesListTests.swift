

@testable import ImageFeed
import XCTest

// Spy для ImagesListViewControllerProtocol.
// Это фальшивый экран, который ничего не рисует,
// а только запоминает, какие команды ему дал Presenter.
final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {

    // Presenter передал новый массив фотографий во View.
    var updatePhotosCalled = false

    // Presenter попросил вставить новые строки в таблицу.
    var insertRowsCalled = false

    // Presenter попросил показать блокирующий HUD.
    var showBlockingProgressHUDCalled = false

    // Presenter попросил скрыть блокирующий HUD.
    var dismissBlockingProgressHUDCalled = false

    // Presenter попросил обновить сердечко лайка у ячейки.
    var updateLikeCalled = false

    // Presenter сообщил View об ошибке лайка.
    var showLikeErrorCalled = false

    // Данные, которые Presenter передал во View.
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

    // Фотографии, которые сервис отдаёт Presenter.
    var photos: [Photo]

    // Флаг: вызывалась ли загрузка следующей страницы.
    var fetchPhotosNextPageCalled = false

    // Флаг: вызывался ли запрос изменения лайка.
    var changeLikeCalled = false

    // Запоминаем параметры, с которыми Presenter вызвал changeLike.
    var receivedPhotoId: String?
    var receivedIsLike: Bool?

    // Результат, который вернёт changeLike.
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

final class ImagesListTests: XCTestCase {

    // MARK: - Test data

    // Метод для создания тестовых фотографий.
    // Так нам не приходится каждый раз руками писать весь init Photo.
    private func makePhoto(
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

    private enum TestError: Error {
        case someError
    }

    // MARK: Test 1
    // Проверяем, что при открытии экрана Presenter просит сервис
    // загрузить первую/следующую страницу фотографий.
    func testPresenterFetchesPhotosWhenViewDidLoad() {

        // Создаём фальшивый сервис.
        let service = ImagesListServiceStub(photos: [])

        // Создаём настоящий Presenter, но передаём ему фальшивый сервис.
        let presenter = ImagesListPresenter(imagesListService: service)

        // Сообщаем Presenter, что экран загрузился.
        presenter.viewDidLoad()

        // Проверяем, что Presenter попросил сервис загрузить фотографии.
        XCTAssertTrue(service.fetchPhotosNextPageCalled)
    }

    // MARK: Test 2
    // Проверяем, что Presenter после обновления фотографий
    // передаёт новый массив во ViewController.
    func testPresenterUpdatesPhotosWhenPhotosChanged() {

        // В сервисе лежит одна новая фотография.
        let photo = makePhoto(id: "1")
        let service = ImagesListServiceStub(photos: [photo])

        // Создаём Presenter и фальшивый экран.
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Имитируем уведомление о том, что фотографии обновились.
        presenter.didReceivePhotosUpdate()

        // Проверяем, что Presenter передал фотографии во ViewController.
        XCTAssertTrue(view.updatePhotosCalled)
        XCTAssertEqual(view.receivedPhotos.count, 1)
        XCTAssertEqual(view.receivedPhotos.first?.id, "1")
    }

    // MARK: Test 3
    // Проверяем, что Presenter считает indexPath новых строк
    // и просит ViewController вставить их в таблицу.
    func testPresenterInsertsRowsWhenNewPhotosAdded() {

        // В сервисе лежат две новые фотографии.
        let firstPhoto = makePhoto(id: "1")
        let secondPhoto = makePhoto(id: "2")
        let service = ImagesListServiceStub(photos: [firstPhoto, secondPhoto])

        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Имитируем обновление фотографий.
        presenter.didReceivePhotosUpdate()

        // Проверяем, что Presenter попросил вставить строки.
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

        let photo = makePhoto(id: "1")
        let service = ImagesListServiceStub(photos: [photo])

        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Первый раз Presenter синхронизирует одну фотографию.
        presenter.didReceivePhotosUpdate()

        // Сбрасываем флаг, чтобы проверить именно второй вызов.
        view.insertRowsCalled = false
        view.receivedIndexPaths = []

        // Второй раз количество фотографий не изменилось.
        presenter.didReceivePhotosUpdate()

        // Проверяем, что новых строк вставлять не надо.
        XCTAssertFalse(view.insertRowsCalled)
        XCTAssertTrue(view.receivedIndexPaths.isEmpty)
    }

    // MARK: Test 5
    // Проверяем, что при показе последней фотографии Presenter
    // просит сервис загрузить следующую страницу.
    func testPresenterFetchesNextPageWhenLastPhotoWillDisplay() {

        let firstPhoto = makePhoto(id: "1")
        let secondPhoto = makePhoto(id: "2")
        let service = ImagesListServiceStub(photos: [firstPhoto, secondPhoto])

        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Сначала синхронизируем фотографии внутри Presenter.
        presenter.didReceivePhotosUpdate()

        // Сбрасываем флаг после первого обновления.
        service.fetchPhotosNextPageCalled = false

        // Имитируем ситуацию: таблица показывает последнюю фотографию.
        presenter.willDisplayPhoto(at: 1)

        // Проверяем, что Presenter попросил загрузить следующую страницу.
        XCTAssertTrue(service.fetchPhotosNextPageCalled)
    }

    // MARK: Test 6
    // Проверяем, что если показывается НЕ последняя фотография,
    // Presenter НЕ просит грузить следующую страницу.
    func testPresenterDoesNotFetchNextPageWhenNotLastPhotoWillDisplay() {

        let firstPhoto = makePhoto(id: "1")
        let secondPhoto = makePhoto(id: "2")
        let service = ImagesListServiceStub(photos: [firstPhoto, secondPhoto])

        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Сначала синхронизируем фотографии внутри Presenter.
        presenter.didReceivePhotosUpdate()

        // Сбрасываем флаг после первого обновления.
        service.fetchPhotosNextPageCalled = false

        // Имитируем ситуацию: таблица показывает первую фотографию, но она не последняя.
        presenter.willDisplayPhoto(at: 0)

        // Проверяем, что следующую страницу грузить не надо.
        XCTAssertFalse(service.fetchPhotosNextPageCalled)
    }

    // MARK: Test 7
    // Проверяем успешный сценарий лайка:
    // Presenter показывает HUD, вызывает changeLike, скрывает HUD,
    // обновляет фотографии и сердечко у ячейки.
    func testPresenterUpdatesLikeWhenChangeLikeSucceeded() {

        // Изначально фото не лайкнуто.
        let oldPhoto = makePhoto(id: "1", isLiked: false)
        let service = ImagesListServiceStub(photos: [oldPhoto])

        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Синхронизируем фото внутри Presenter.
        presenter.didReceivePhotosUpdate()

        // После успешного changeLike сервис будет хранить уже лайкнутое фото.
        let updatedPhoto = makePhoto(id: "1", isLiked: true)
        service.photos = [updatedPhoto]
        service.changeLikeResult = .success(())

        // Имитируем нажатие лайка на первой фотографии.
        presenter.didTapLike(at: 0)

        // Проверяем, что Presenter показал и скрыл HUD.
        XCTAssertTrue(view.showBlockingProgressHUDCalled)
        XCTAssertTrue(view.dismissBlockingProgressHUDCalled)

        // Проверяем, что Presenter вызвал сервис с правильными параметрами.
        XCTAssertTrue(service.changeLikeCalled)
        XCTAssertEqual(service.receivedPhotoId, "1")
        XCTAssertEqual(service.receivedIsLike, true)

        // Проверяем, что Presenter обновил фотографии во View.
        XCTAssertTrue(view.updatePhotosCalled)
        XCTAssertEqual(view.receivedPhotos.first?.isLiked, true)

        // Проверяем, что Presenter обновил лайк у конкретной ячейки.
        XCTAssertTrue(view.updateLikeCalled)
        XCTAssertEqual(view.receivedIsLiked, true)
        XCTAssertEqual(view.receivedLikeIndex, 0)
    }

    // MARK: Test 8
    // Проверяем ошибочный сценарий лайка:
    // Presenter показывает HUD, вызывает changeLike, скрывает HUD
    // и сообщает ViewController об ошибке.
    func testPresenterShowsErrorWhenChangeLikeFailed() {

        let photo = makePhoto(id: "1", isLiked: false)
        let service = ImagesListServiceStub(photos: [photo])
        service.changeLikeResult = .failure(TestError.someError)

        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Синхронизируем фото внутри Presenter.
        presenter.didReceivePhotosUpdate()

        // Имитируем нажатие лайка.
        presenter.didTapLike(at: 0)

        // Проверяем, что HUD показали и скрыли.
        XCTAssertTrue(view.showBlockingProgressHUDCalled)
        XCTAssertTrue(view.dismissBlockingProgressHUDCalled)

        // Проверяем, что Presenter сообщил об ошибке.
        XCTAssertTrue(view.showLikeErrorCalled)
        XCTAssertNotNil(view.receivedError)

        // При ошибке лайк обновляться не должен.
        XCTAssertFalse(view.updateLikeCalled)
    }

    // MARK: Test 9
    // Проверяем защиту от неверного индекса:
    // если пользователь нажал лайк по индексу, которого нет,
    // Presenter ничего не должен делать.
    func testPresenterDoesNothingWhenLikeIndexIsInvalid() {

        let service = ImagesListServiceStub(photos: [])
        let presenter = ImagesListPresenter(imagesListService: service)
        let view = ImagesListViewControllerSpy()
        presenter.view = view

        // Имитируем нажатие лайка по несуществующему индексу.
        presenter.didTapLike(at: 0)

        // Проверяем, что сетевой запрос не был вызван.
        XCTAssertFalse(service.changeLikeCalled)

        // Проверяем, что HUD не показывался.
        XCTAssertFalse(view.showBlockingProgressHUDCalled)
        XCTAssertFalse(view.dismissBlockingProgressHUDCalled)
    }
}
