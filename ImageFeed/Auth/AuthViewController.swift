import UIKit
import ProgressHUD

// Делегат AuthViewController.
// Через него этот экран сообщает наружу: пользователь успешно авторизовался.
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

// Первый экран авторизации.
// Сам WebView тут не живёт — этот контроллер только открывает WebViewViewController
final class AuthViewController: UIViewController {
    
    // Identifier segue из Storyboard.
    // По нему понимаем, что сейчас будет переход на WebViewViewController.
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    // Делегат, которому сообщаем, что авторизация полностью завершилась.
    // Обычно это SplashViewController или другой родительский экран.
    weak var delegate: AuthViewControllerDelegate?
    
    // Выполняет первоначальную настройку экрана авторизации
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    // prepare вызывается системой прямо перед переходом по segue.
    // Здесь мы настраиваем следующий экран до того, как он появится.
    // В нашем случае создаём Presenter + AuthHelper для WebViewViewController
    // и соединяем их между собой.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            // AuthHelper умеет собирать OAuth-запрос и доставать code из redirect URL.
            let authHelper = AuthHelper()
            // Presenter — мозг WebViewViewController: он решает, какой request загрузить
            // и как реагировать на изменение прогресса.
            let webViewPresenter = WebViewPresenter(authHelper: authHelper)
            // Даём экрану его Presenter.
            webViewViewController.presenter = webViewPresenter
            // Даём Presenter ссылку на экран, чтобы он мог командовать UI через протокол.
            webViewPresenter.view = webViewViewController
            
            // Назначаем себя делегатом, чтобы получить code после авторизации.
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // Настраивает внешний вид системной кнопки Back в Navigation Bar.
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(resource: .navBackButton)
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(resource: .navBackButton)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(resource: .ypBlack)
    }
    
}

// MARK: - WebViewViewControllerDelegate
// Получаем события от WebViewViewController: успешный code или отмену авторизации.
extension AuthViewController: WebViewViewControllerDelegate {
    // WebViewViewController нашёл authorization code в redirect URL.
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        // Закрываем WebView и начинаем обмен authorization code на OAuth token.
        vc.dismiss(animated: true) { [weak self] in
            UIBlockingProgressHUD.show()
            
            // Отправляем authorization code на Unsplash и получаем access token.
            // После этого приложение сможет ходить в API от имени пользователя.
            OAuth2Service.shared.fetchOAuthToken(code: code) { result in
                defer {
                    UIBlockingProgressHUD.dismiss()
                }
                
                switch result {
                case .success:
                    guard let self else { return }
                    // Сообщаем родительскому экрану, что авторизация завершилась успешно.
                    self.delegate?.didAuthenticate(self)
                    
                case .failure(let error):
                    print("[AuthViewController.webViewViewController]: \(error)")
                    self?.showAuthErrorAlert()
                }
            }
        }
    }
    
    // Пользователь нажал Back на WebViewViewController.
    // Просто закрываем WebView и возвращаемся назад.
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
    
    // Показывает пользователю сообщение об ошибке авторизации.
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
