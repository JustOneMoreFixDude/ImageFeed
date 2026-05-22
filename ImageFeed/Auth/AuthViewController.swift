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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    // prepare = хук перед переходом между экранами
    // вызывается автоматические перед переходом на другой экран, что бы передать другому экрану данные
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
    
    //кастомная кнопка назад в Navigation Bar
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(resource: .navBackButton)
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(resource: .navBackButton)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(resource: .ypBlack)
    }
    
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        
        UIBlockingProgressHUD.show()
        
        OAuth2Service.shared.fetchOAuthToken(code: code) { [weak self] result in
            defer {
                UIBlockingProgressHUD.dismiss()
            }
            
            switch result {
            case .success:
                vc.dismiss(animated: true)
                guard let self else { return }
                self.delegate?.didAuthenticate(self)
            case .failure(let error):
                print("[AuthViewController.webViewViewController]: \(error)")
                self?.showAuthErrorAlert()
            }
            
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
    
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
