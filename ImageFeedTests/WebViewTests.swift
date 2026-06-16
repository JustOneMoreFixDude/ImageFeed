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

// Spy для WebViewViewControllerProtocol.
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
    @MainActor
    func testViewControllerCallsViewDidLoad() {
        // Given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            withIdentifier: "WebViewViewController"
        ) as! WebViewViewController
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        _ = viewController.view

        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    // MARK: Test 2
    @MainActor
    func testPresenterCallsLoadRequest() {
        // Given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        presenter.view = viewController

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertTrue(viewController.loadRequestCalled)
    }
    
    // MARK: Test 3
    @MainActor
    func testProgressVisibleWhenLessThenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6

        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // Then
        XCTAssertFalse(shouldHideProgress)
    }
    
    // MARK: Test 4
    @MainActor
    func testProgressHiddenWhenOne() {
        // Given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0

        // When
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // Then
        XCTAssertTrue(shouldHideProgress)
    }
    
    
    // MARK: Test 5
    func testAuthHelperAuthURL() {
        // Given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)

        // When
        let url = authHelper.authURL()
        guard let urlString = url?.absoluteString else {
            XCTFail("Auth URL is nil")
            return
        }

        // Then
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    // MARK: Test 6
    func testCodeFromURL() {
        // Given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [
            URLQueryItem(name: "code", value: "test code")
        ]
        let url = urlComponents.url!
        let authHelper = AuthHelper()

        // When
        let code = authHelper.code(from: url)

        // Then
        XCTAssertEqual(code, "test code")
    }
    
}
