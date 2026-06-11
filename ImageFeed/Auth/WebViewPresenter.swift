import Foundation

// Протокол презентера для WebViewViewController.
// ViewController знает только этот протокол, а не конкретный класс WebViewPresenter.
// Это нужно, чтобы в тестах подставлять PresenterSpy.
public protocol WebViewPresenterProtocol {
    // Ссылка на экран. Через неё Presenter просит ViewController обновить UI.
    var view: WebViewViewControllerProtocol? { get set }
    
    // ViewController сообщает Presenter, что экран загрузился.
    func viewDidLoad()
    
    // ViewController сообщает Presenter новое значение прогресса загрузки WebView.
    func didUpdateProgressValue(_ newValue: Double)
    
    // Presenter просит AuthHelper достать authorization code из URL.
    func code(from url: URL) -> String?
}

final class WebViewPresenter: WebViewPresenterProtocol {
    
    // weak, чтобы не было retain cycle:
    // ViewController держит Presenter, Presenter слабо держит ViewController.
    weak var view: WebViewViewControllerProtocol?
    
    // Хелпер, который знает детали OAuth: как собрать request и как достать code.
    var authHelper: AuthHelperProtocol
    
    // Передаём helper снаружи, чтобы Presenter было проще тестировать.
    // В приложении передаём настоящий AuthHelper, в тестах можно передать Stub.
    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }
    
    // Presenter сам не парсит URL, а делегирует это AuthHelper.
    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }
    
    // WebView сообщил новый прогресс загрузки.
    // Presenter решает, какое значение показать и нужно ли скрыть progressView.
    func didUpdateProgressValue(_ newValue: Double) {
        // WebView отдаёт Double, а UIProgressView ждёт Float.
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)
        
        // Решаем, загрузка уже завершена или progressView ещё должен быть виден.
        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }
    
    // Возвращает true, когда progress почти равен 1.0.
    // Почти — потому что Float/Double лучше сравнивать с небольшой погрешностью.
    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }
    
    // Экран загрузился.
    // Presenter собирает request авторизации через AuthHelper,
    // просит экран загрузить request и выставляет начальный progress = 0.
    func viewDidLoad() {
        guard let request = authHelper.authRequest() else { return }
        
        view?.load(request: request)
        didUpdateProgressValue(0)
        
    }
}
