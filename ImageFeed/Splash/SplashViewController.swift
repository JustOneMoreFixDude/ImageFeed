import UIKit

final class SplashViewController: UIViewController {

    // Хранилище токена
    private let storage = OAuth2TokenStorage.shared

    // Идентификатор segue в storyboard
    private let showAuthSegueIdentifier = "ShowAuthenticationScreen"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // проверим есть ли токен (авторизация)
        if storage.token != nil {
            // если есть - сразу идем в основное приложение
            switchToTabBarController()
        } else {
            // если нет - открываем окно авторизации
            print("открываем окно авторизации")
            performSegue(withIdentifier: showAuthSegueIdentifier, sender: nil)
        }
    }
    
    // Системный метод — вызывается перед переходом (segue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthSegueIdentifier {
            
            // Достаём AuthViewController из UINavigationController
            guard
                let navController = segue.destination as? UINavigationController,
                let authVC = navController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for segue")
                return
            }
            
            // Назначаем делегат, чтобы получить результат авторизации
            authVC.delegate = self
            
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // Переключает приложение на TabBar (основной экран)
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window")
            return
        }
        
        // Создаём TabBarController из storyboard
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        // Меняем корневой контроллер приложения
        window.rootViewController = tabBarController
        
    }
    
}

extension SplashViewController: AuthViewControllerDelegate {
    
    // Вызывается после успешной авторизации
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) // Закрываем экран авторизации
        switchToTabBarController() // Переходим в основное приложение
    }
    
}
