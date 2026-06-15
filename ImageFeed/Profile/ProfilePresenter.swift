
import Foundation

// Протокол сервиса профиля.
// Нужен, чтобы Presenter зависел не от конкретного ProfileService.shared,
// а от договора. В тестах сюда можно будет подставить Stub.
protocol ProfileServiceProtocol {
    var profile: Profile? { get }
}

extension ProfileService: ProfileServiceProtocol { }

protocol ProfileViewControllerProtocol: AnyObject {
    func updateProfileDetails(profile: Profile)
    func showLogoutAlert()
    func switchToSplashViewController()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
    func logoutConfirmed()
}

final class ProfilePresenter: ProfilePresenterProtocol {

    weak var view: ProfileViewControllerProtocol?
    
    // Сервис, из которого Presenter берёт данные профиля.
    private let profileService: ProfileServiceProtocol
    
    // В приложении используется настоящий ProfileService.shared.
    // В тестах можно будет передать фейковый сервис.
    init(profileService: ProfileServiceProtocol = ProfileService.shared) {
        self.profileService = profileService
    }

    func viewDidLoad() {
        guard let profile = profileService.profile else { return }
        view?.updateProfileDetails(profile: profile)
    }
    
    func didTapLogoutButton() {
        view?.showLogoutAlert()
    }
    
    func logoutConfirmed() {
        ProfileLogoutService.shared.logout()
        view?.switchToSplashViewController()
    }
}
