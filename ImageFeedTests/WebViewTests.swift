@testable import ImageFeed
import XCTest

// Фальшивый Presenter.
// Нужен только для теста.
// Запоминает, вызывали ли у него viewDidLoad().
@MainActor
final class WebViewPresenterSpy: WebViewPresenterProtocol {
    
    var viewDidLoadCalled = false
    
    var view: WebViewViewControllerProtocol?
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didUpdateProgressValue(_ newValue: Double) {}
    
    func code(from url: URL) -> String? {
        nil
    }
}

// Фальшивый ViewController.
// Нужен только для теста.
// Запоминает, вызывали ли у него load(request:).
@MainActor
final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    
    var presenter: WebViewPresenterProtocol?
    
    var loadRequestCalled = false
    
    func load(request: URLRequest) {
        loadRequestCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {
        
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        
    }
}

final class WebViewTests: XCTestCase {
    
    // MARK: Test 1
    // Проверяем, что WebViewViewController вызывает presenter.viewDidLoad()
    // после загрузки экрана.
    @MainActor
    func testViewControllerCallsViewDidLoad() {
        
        // Загружаем Main.storyboard.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Создаём настоящий WebViewViewController из Storyboard.
        let viewController =
        storyboard.instantiateViewController(
            withIdentifier: "WebViewViewController"
        ) as! WebViewViewController
        
        // Создаём шпиона вместо настоящего Presenter.
        let presenter = WebViewPresenterSpy()
        
        // Соединяем ViewController и Presenter.
        viewController.presenter = presenter
        presenter.view = viewController
        
        // Заставляем iOS загрузить View.
        // В этот момент вызывается viewDidLoad().
        _ = viewController.view
        
        // Проверяем, что ViewController вызвал presenter.viewDidLoad().
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    // MARK: Test 2
    // Проверяем, что Presenter после viewDidLoad()
    // просит View загрузить URLRequest.
    @MainActor
    func testPresenterCallsLoadRequest() {
        
        // Создаём фальшивый экран.
        let viewController = WebViewViewControllerSpy()
        
        // Создаём настоящий AuthHelper.
        let authHelper = AuthHelper()
        
        // Создаём настоящий Presenter.
        let presenter = WebViewPresenter(authHelper: authHelper)
        
        // Даём Presenter ссылку на фальшивый экран.
        presenter.view = viewController
        
        // Просим Presenter обработать открытие экрана.
        presenter.viewDidLoad()
        
        // Проверяем, что Presenter вызвал load(request:)
        XCTAssertTrue(viewController.loadRequestCalled)
    }
    
    // MARK: Test 3
    // Проверяем, что progressView НЕ скрывается,
    // если прогресс загрузки меньше 1.0.
    @MainActor
    func testProgressVisibleWhenLessThenOne() {
        
        // Создаём настоящий AuthHelper.
        let authHelper = AuthHelper()
        
        // Создаём настоящий Presenter.
        let presenter = WebViewPresenter(authHelper: authHelper)
        
        // Прогресс меньше 1.0 — страница ещё не загрузилась полностью.
        let progress: Float = 0.6
        
        // Спрашиваем Presenter, надо ли скрывать progressView.
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // Проверяем: если прогресс меньше 1.0, progressView должен быть виден.
        XCTAssertFalse(shouldHideProgress)
    }
    
    // MARK: Test 4
    // Проверяем, что progressView скрывается,
    // когда прогресс загрузки достиг 1.0.
    @MainActor
    func testProgressHiddenWhenOne() {

        // Создаём настоящий AuthHelper.
        let authHelper = AuthHelper()

        // Создаём настоящий Presenter.
        let presenter = WebViewPresenter(authHelper: authHelper)

        // Страница полностью загрузилась.
        let progress: Float = 1.0

        // Спрашиваем Presenter, надо ли скрыть progressView.
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // Проверяем, что progressView нужно скрыть.
        XCTAssertTrue(shouldHideProgress)
    }
    
    
    // MARK: Test 5
    // Проверяем, что AuthHelper корректно собирает URL авторизации
    // и добавляет все обязательные OAuth-параметры.
    func testAuthHelperAuthURL() {

        // Берём стандартную конфигурацию авторизации приложения.
        // В ней лежат accessKey, redirectURI, scope и адрес Unsplash.
        let configuration = AuthConfiguration.standard

        // Создаём настоящий AuthHelper, который будет собирать URL авторизации.
        let authHelper = AuthHelper(configuration: configuration)

        // Просим AuthHelper собрать ссылку для OAuth-авторизации.
        let url = authHelper.authURL()

        // Превращаем URL в обычную строку для удобства проверки.
        // Если URL не удалось собрать — тест должен упасть.
        guard let urlString = url?.absoluteString else {
            XCTFail("Auth URL is nil")
            return
        }

        // Проверяем, что ссылка содержит адрес страницы авторизации Unsplash.
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        // Проверяем, что в ссылку попал accessKey нашего приложения.
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        // Проверяем, что указан корректный redirectURI.
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        // Проверяем, что используется OAuth-сценарий получения authorization code.
        XCTAssertTrue(urlString.contains("code"))
        // Проверяем, что в ссылке присутствуют необходимые права доступа (scope).
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    // MARK: Test 6
    // Проверяем, что AuthHelper корректно достаёт authorization code
    // из redirect URL после успешной авторизации.
    func testCodeFromURL() {

        // Собираем URL, который обычно приходит от Unsplash
        // после успешного входа пользователя.
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!

        // Добавляем в URL параметр code.
        // Именно его приложение потом меняет на access token.
        urlComponents.queryItems = [
            URLQueryItem(name: "code", value: "test code")
        ]

        // Получаем готовый URL.
        let url = urlComponents.url!

        // Создаём настоящий AuthHelper.
        let authHelper = AuthHelper()

        // Просим AuthHelper достать code из URL.
        let code = authHelper.code(from: url)

        // Проверяем, что получили именно тот code,
        // который положили в URL выше.
        XCTAssertEqual(code, "test code")
    }
    
}
