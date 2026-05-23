import UIKit
import ProgressHUD

/* Делегат, через который AuthViewController сообщает наружу: авторизация прошла или отменена. */
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

// Экран авторизации с WKWebView. Загружает страницу Unsplash OAuth
final class AuthViewController: UIViewController {
    
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    weak var delegate: AuthViewControllerDelegate?
    
    // Выполняет первоначальную настройку экрана авторизации
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    // prepare = хук перед переходом между экранами
    // вызывается автоматические перед переходом на другой экран, что бы передать другому экрану данные
    // Передает delegate в WebViewViewController перед переходом
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // Настраивает кастомную кнопку Back в Navigation Bar
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(resource: .navBackButton)
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(resource: .navBackButton)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(resource: .ypBlack)
    }
    
}

extension AuthViewController: WebViewViewControllerDelegate {
    // Получает code авторизации из WebView и запрашивает OAuth token
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true) { [weak self] in
            UIBlockingProgressHUD.show()
            
            OAuth2Service.shared.fetchOAuthToken(code: code) { result in
                defer {
                    UIBlockingProgressHUD.dismiss()
                }
                
                switch result {
                case .success:
                    guard let self else { return }
                    self.delegate?.didAuthenticate(self)
                    
                case .failure(let error):
                    print("[AuthViewController.webViewViewController]: \(error)")
                    self?.showAuthErrorAlert()
                }
            }
        }
    }
    
    // Закрывает WebView при отмене авторизации
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
    
    // Показывает alert при ошибке авторизации
    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: "Ок", style: .default)
        alert.addAction(action)
        
        present(alert, animated: true)
    }
    
}
