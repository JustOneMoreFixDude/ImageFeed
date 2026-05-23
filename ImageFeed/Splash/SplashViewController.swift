import UIKit

/*
 Первый экран. Проверяет: есть токен или нет.
 Если токена нет — открывает авторизацию.
 Если есть — пускает в приложение.
 
 Flow:
 1.SplashViewController
 2.есть token
 3.fetchProfile(token)
 4.ProfileService.shared.profile сохраняется
 5.fetch avatar URL
 6.открываем TabBar
 7.ProfileViewController показывает уже готовый Profile
 */

final class SplashViewController: UIViewController {
    
    // Хранилище токена
    private let storage = OAuth2TokenStorage.shared
    private var isFetchingProfile = false
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "splash_screen_logo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if DEBUG
        /* Как юзать DEBUG:
        1. Поставить didResetToken == false
        2. Запустил приложение
        3. Splash один раз стирает token
        4. Появилась кнопка “Войти”
        5. поменял обратно на: didResetToken == true
        6. После логина токен уже не сотрется повторно
        */
        if UserDefaults.standard.bool(forKey: "didResetToken") == false {
            storage.token = nil
            UserDefaults.standard.set(true, forKey: "didResetToken")
        }
#endif// DEBUG Чтобы один раз сбросить token и заново пройти авторизацию, поставь didResetToken = false
        
        // проверим есть ли токен (авторизация)
        if let token = storage.token {
            // если есть - сначала загружаем профиль, потом идем в основное приложение
            fetchProfile(token: token)
        } else {
            // если нет - открываем окно авторизации
            showAuthController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
    }
    
    private func showAuthController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        guard let authViewController = storyboard.instantiateViewController(
            withIdentifier: "AuthViewController"
        ) as? AuthViewController else {
            assertionFailure("Failed to instantiate AuthViewController")
            return
        }
        
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        
        present(authViewController, animated: true)
    }
    
    private func setupViews() {
        view.backgroundColor = .ypBlack
        view.addSubview(logoImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func fetchProfile(token: String) {
        guard !isFetchingProfile else {
            return
        }
        isFetchingProfile = true
        UIBlockingProgressHUD.show()
        
        ProfileService.shared.fetchProfile(token: token) { [weak self] result in
            guard let self else { return }
            
            defer {
                self.isFetchingProfile = false
                UIBlockingProgressHUD.dismiss()
            }
            
            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { [weak self] result in
                    if case .failure(let error) = result {
                        print("[SplashViewController.fetchProfileImageURL]: \(error)")
                    }
                    self?.switchToTabBarController()
                }
                
                
            case .failure(let error):
                print("[SplashViewController.fetchProfile]: \(error)")
                // Если Unsplash вернул ошибку, всё равно открываем приложение,
                // чтобы пользователь не оставался на Splash-экране
                self.switchToTabBarController()
            }
        }
    }
    
    // Переключает приложение на TabBar (основной экран)
    private func switchToTabBarController() {
        guard let window = view.window else {
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
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            guard let token = self.storage.token else {
                return
            }
            self.fetchProfile(token: token)
        }
    }
    
}
