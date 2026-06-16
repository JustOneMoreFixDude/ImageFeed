import Foundation

// Протокол презентера для WebViewViewController.
public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }

    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

final class WebViewPresenter: WebViewPresenterProtocol {

    weak var view: WebViewViewControllerProtocol?

    var authHelper: AuthHelperProtocol

    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }

    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }

    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)

        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }

    // Возвращает true, когда загрузка завершена.
    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }

    func viewDidLoad() {
        guard let request = authHelper.authRequest() else { return }

        view?.load(request: request)
        didUpdateProgressValue(0)
    }
}
