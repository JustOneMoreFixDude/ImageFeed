import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let loginNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let labelsStackView = UIStackView()
    
    private var animationViews: [GradientView] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupProfileView()
        showProfileGradients()
        setupProfile()
        setupAvatar()
        setupObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    // Общая настройка экрана профиля
    private func setupProfileView() {
        setupViews()
        setupHierarchy()
        setupConstraints()
    }

    // Заполняет лейблы данными профиля
    private func setupProfile() {
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
            removeAnimationViews()
        }
    }

    // Загружает уже сохранённую аватарку пользователя
    private func setupAvatar() {
        guard
            let avatarURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: avatarURL)
        else {
            return
        }

        avatarImageView.kf.setImage(with: url) { [weak self] _ in
            self?.removeAnimationViews()
        }
    }

    // Подписывается на обновление аватарки через NotificationCenter
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAvatar),
            name: ProfileImageService.didChangeNotification,
            object: nil
        )
    }
    
    // Обновляет текстовые данные профиля на экране
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }
    
    // Обновляет аватарку после получения уведомления
    @objc private func updateAvatar(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let avatarURL = userInfo["URL"] as? String,
            let url = URL(string: avatarURL)
        else {
            return
        }
        
        avatarImageView.kf.setImage(with: url) { [weak self] _ in
            self?.removeAnimationViews()
        }
    }
    
    
    // Настраивает внешний вид UI элементов
    private func setupViews() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        let avatarImage = UIImage(named: "Userpics") ?? UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.image = avatarImage
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 35
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .boldSystemFont(ofSize: 23)
        nameLabel.textColor = .ypWhite
        nameLabel.text = "Екатерина Новикова"
        
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.font = .systemFont(ofSize: 13)
        loginNameLabel.textColor = .ypGray
        loginNameLabel.text = "@ekaterina_nov"
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.text = "Hello, world!"
        
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonImage = UIImage(named: "logout_button")
        logoutButton.setImage(buttonImage, for: .normal)
        logoutButton.tintColor = .ypRed
        logoutButton.contentMode = .scaleAspectFit
        logoutButton.addTarget(
            self,
            action: #selector(didTapLogoutButton),
            for: .touchUpInside
        )
        logoutButton.imageView?.contentMode = .scaleAspectFit
        logoutButton.contentMode = .scaleAspectFit
        
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 8
        labelsStackView.alignment = .leading
        
        view.backgroundColor = .ypBlack
        
    }
    
    // Добавляет элементы в иерархию View
    private func setupHierarchy() {
        view.addSubview(avatarImageView)
        view.addSubview(logoutButton)
        view.addSubview(labelsStackView)
        
        labelsStackView.addArrangedSubview(nameLabel)
        labelsStackView.addArrangedSubview(loginNameLabel)
        labelsStackView.addArrangedSubview(descriptionLabel)
    }
    
    // Настраивает Auto Layout констрейнты
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            
            labelsStackView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            labelsStackView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
        ])
    }
    
    // Показывает shimmer-заглушки на аватарке и текстах профиля.
    private func showProfileGradients() {
        view.layoutIfNeeded()

        nameLabel.textColor = .clear
        loginNameLabel.textColor = .clear
        descriptionLabel.textColor = .clear

        addGradient(
            over: avatarImageView,
            frame: avatarImageView.bounds,
            cornerRadius: 35
        )
        addGradient(
            over: nameLabel,
            frame: CGRect(x: 0, y: 0, width: 223, height: 18),
            cornerRadius: 9
        )
        addGradient(
            over: loginNameLabel,
            frame: CGRect(x: 0, y: 0, width: 89, height: 18),
            cornerRadius: 9
        )
        addGradient(
            over: descriptionLabel,
            frame: CGRect(x: 0, y: 0, width: 67, height: 18),
            cornerRadius: 9
        )
    }

    // Создаёт shimmer-заглушку поверх конкретной View.
    private func addGradient(over view: UIView, frame: CGRect, cornerRadius: CGFloat) {
        let gradientView = GradientView(frame: frame)
        gradientView.layer.cornerRadius = cornerRadius
        gradientView.clipsToBounds = true
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(gradientView)
        animationViews.append(gradientView)
    }

    private func removeAnimationViews() {
        animationViews.forEach { $0.removeFromSuperview() }
        animationViews.removeAll()

        nameLabel.textColor = .ypWhite
        loginNameLabel.textColor = .ypGray
        descriptionLabel.textColor = .ypWhite
    }
    
    // Обрабатывает нажатие на кнопку выхода.
    // Сначала спрашивает подтверждение, затем очищает данные пользователя.
    @objc private func didTapLogoutButton() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: "Нет",
            style: .cancel
        )

        let logoutAction = UIAlertAction(
            title: "Да",
            style: .destructive
        ) { _ in
            ProfileLogoutService.shared.logout()
            self.switchToSplashViewController()
        }

        alert.addAction(cancelAction)
        alert.addAction(logoutAction)

        present(alert, animated: true)
    }
    
    // Возвращает приложение на стартовый экран после logout.
    private func switchToSplashViewController() {
        guard let window = UIApplication.shared.windows.first else { return }
        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()
    }
}
