import UIKit
import WebKit

// список того, что экран должен уметь.
public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

// Протокол для передачи результата авторизации обратно в AuthViewController.
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) // vc - тот кто вызывает
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// Экран авторизации Unsplash внутри WebView.
// Показывает страницу логина и получает OAuth code после успешного входа.
final class WebViewViewController: UIViewController & WebViewViewControllerProtocol {
    
    var presenter: (any WebViewPresenterProtocol)?
    
    func load(request: URLRequest) {
        webView.load(request)
    }
    
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!
    
    // Делегат получает результат авторизации.
    weak var delegate: WebViewViewControllerDelegate?
    
    // Наблюдатель за изменением прогресса загрузки страницы в WebView.
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        // Первичная настройка экрана после загрузки View из Storyboard.
        super.viewDidLoad()
        
        // Добавляю identifier самому WKWebView для UI-тестов
        webView.accessibilityIdentifier = "UnsplashWebView"
        
        // Будем получать события переходов внутри WebView.
        webView.navigationDelegate = self
        
        // Открываем страницу авторизации Unsplash.
        presenter?.viewDidLoad()
        
        // Следим за прогрессом загрузки страницы.
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
             options: [.new]
        ) { [weak self] _, _ in
            guard let self else { return }
            self.presenter?.didUpdateProgressValue(self.webView.estimatedProgress)
        }
    }
    
    // Нажатие на кнопку «Назад». Отменяем авторизацию.
    @IBAction private func didTapBackButton(_ sender: Any?) {
        // Сообщаем делегату, что пользователь отменил авторизацию.
        delegate?.webViewViewControllerDidCancel(self)
    }
    
    // Вызывается после появления экрана на экране пользователя.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Обновляем индикатор прогресса.
        presenter?.didUpdateProgressValue(webView.estimatedProgress)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    

    
    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }

    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }
    
}




// Обработка переходов и событий внутри WebView.
extension WebViewViewController: WKNavigationDelegate {
    
    // Вызывается при каждом переходе внутри WebView.
    // Если в URL появился code, забираем его и прекращаем переход.
    // Иначе разрешаем WebView открыть страницу.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Проверяем, не пришёл ли код авторизации.
        if let code = code(from: navigationAction) {
            // Передаём код авторизации делегату.
            delegate?.webViewViewController(self, didAuthenticateWithCode: code) // сообщаем наверх: код получен
            // Останавливаем переход, код уже получен.
            decisionHandler(.cancel) // НЕ открываем эту страницу дальше
        } else {
            // Разрешаем обычный переход.
            decisionHandler(.allow) // продолжай открывать страницу как обычно
        }
    }
    
    // Извлекаем code из redirect URL после успешной авторизации.
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            return presenter?.code(from: url)
        }
        return nil
    }
    
}
