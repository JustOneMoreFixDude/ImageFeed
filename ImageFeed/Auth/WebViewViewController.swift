import UIKit
import WebKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) // vc - тот кто вызывает
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

final class WebViewViewController: UIViewController {
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!
    
    // Делегат получает результат авторизации.
    weak var delegate: WebViewViewControllerDelegate?
    
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    // Помогает проверить, что контроллер освобождается из памяти.
    deinit {
        print("\(String(describing: type(of: self))) помер")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Будем получать события переходов внутри WebView.
        webView.navigationDelegate = self
        // Открываем страницу авторизации Unsplash.
        loadAuthView()
        
        // Следим за прогрессом загрузки страницы.
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
             options: [.new]
        ) { [weak self] _, _ in
            self?.updateProgress()
        }
    }
    
    @IBAction private func didTapBackButton(_ sender: Any?) {
        // Сообщаем делегату, что пользователь отменил авторизацию.
        delegate?.webViewViewControllerDidCancel(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Обновляем индикатор прогресса.
        updateProgress()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    

    
    private func updateProgress() {
        // Передаём прогресс загрузки в progressView.
        progressView.progress = Float(webView.estimatedProgress)
        // Когда страница загружена полностью, скрываем индикатор.
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    private func loadAuthView() {
        // Собираем URL страницы авторизации.
        guard var urlComponents = URLComponents(string: Constants.API.unsplashAuthorizeURLString) else {
            return
        }
        // Добавляем параметры OAuth авторизации.
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            return
        }
        
        // Создаём и открываем запрос в WebView.
        let request = URLRequest(url: url)
        webView.load(request)
        //print("<!!!2> request == \(request)")
    }
}




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
            delegate?.webViewViewController(self, didAuthenticateWithCode: code) // сообщаем наверх: под получен
            //print("!!! Произошел cancel\n")
            // Останавливаем переход, код уже получен.
            decisionHandler(.cancel) // НЕ открываем эту страницу дальше
        } else {
            //print("!!! Произошел allow\n")
            // Разрешаем обычный переход.
            decisionHandler(.allow) // продолжай открывать страницу как обычно
        }
    }
    
    // Ищет code в URL после успешной авторизации.
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if
            let url = navigationAction.request.url,
            let urlComponents = URLComponents(string: url.absoluteString),
            urlComponents.path == "/oauth/authorize/native",
            let items = urlComponents.queryItems,
            let codeItem = items.first(where: {$0.name == "code"})
        {
            // Нашли код авторизации.
            return codeItem.value
        } else {
            return nil
        }
    }
    
}
