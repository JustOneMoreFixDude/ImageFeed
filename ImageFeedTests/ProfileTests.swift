@testable import ImageFeed
import XCTest

// Spy для ProfileViewControllerProtocol.
// Это не настоящий экран, а фальшивый объект для тестов.
// Он просто запоминает, какие методы вызвал Presenter.
final class ProfileViewControllerSpy: ProfileViewControllerProtocol {

    // Presenter вызвал обновление данных профиля.
    var updateProfileDetailsCalled = false

    // Presenter попросил показать alert подтверждения logout.
    var showLogoutAlertCalled = false

    // Presenter попросил перейти на Splash после logout.
    var switchToSplashViewControllerCalled = false

    // Сохраняем профиль, который Presenter передал во View.
    // Так можно проверить не только факт вызова, но и сами данные.
    var receivedProfile: Profile?

    func updateProfileDetails(profile: Profile) {
        updateProfileDetailsCalled = true
        receivedProfile = profile
    }

    func showLogoutAlert() {
        showLogoutAlertCalled = true
    }

    func switchToSplashViewController() {
        switchToSplashViewControllerCalled = true
    }
}

// Stub для ProfileServiceProtocol.
// В отличие от настоящего ProfileService, тут мы сами задаём,
// есть профиль или нет. Так тесты не зависят от реального состояния приложения.
final class ProfileServiceStub: ProfileServiceProtocol {
    var profile: Profile?

    init(profile: Profile?) {
        self.profile = profile
    }
}

final class ProfileTests: XCTestCase {

    // MARK: Test 1
    // Проверяем, что ProfilePresenter вызывает updateProfileDetails(profile:),
    // если в ProfileService уже есть профиль пользователя.
    func testPresenterCallsUpdateProfileDetailsWhenProfileExists() {

        // Создаём тестовый профиль.
        let profile = Profile(
            username: "Test User",
            name: "Test Name",
            loginName: "@test",
            bio: "Test Bio"
        )

        // Создаём фальшивый экран, который запомнит вызовы Presenter.
        let viewController = ProfileViewControllerSpy()

        // Создаём фальшивый сервис профиля и кладём в него тестовый профиль.
        let profileService = ProfileServiceStub(profile: profile)

        // Создаём настоящий Presenter, но передаём ему фальшивый сервис.
        let presenter = ProfilePresenter(profileService: profileService)

        // Соединяем Presenter с фальшивым экраном.
        presenter.view = viewController

        // Сообщаем Presenter, что экран загрузился.
        presenter.viewDidLoad()

        // Проверяем, что Presenter попросил экран обновить данные профиля.
        XCTAssertTrue(viewController.updateProfileDetailsCalled)

        // Проверяем, что Presenter передал во View именно тот профиль,
        // который лежал в ProfileServiceStub.
        XCTAssertEqual(viewController.receivedProfile?.username, profile.username)
        XCTAssertEqual(viewController.receivedProfile?.name, profile.name)
        XCTAssertEqual(viewController.receivedProfile?.loginName, profile.loginName)
        XCTAssertEqual(viewController.receivedProfile?.bio, profile.bio)
    }

    // MARK: Test 2
    // Проверяем, что ProfilePresenter НЕ вызывает updateProfileDetails(profile:),
    // если профиля в ProfileService нет.
    func testPresenterDoesNotCallUpdateProfileDetailsWhenProfileIsNil() {

        // Создаём фальшивый экран, который запомнит вызовы Presenter.
        let viewController = ProfileViewControllerSpy()

        // Создаём фальшивый сервис профиля без профиля.
        let profileService = ProfileServiceStub(profile: nil)

        // Создаём настоящий Presenter, но передаём ему фальшивый сервис.
        let presenter = ProfilePresenter(profileService: profileService)

        // Соединяем Presenter с фальшивым экраном.
        presenter.view = viewController

        // Сообщаем Presenter, что экран загрузился.
        presenter.viewDidLoad()

        // Проверяем, что Presenter не стал обновлять экран,
        // потому что данных профиля нет.
        XCTAssertFalse(viewController.updateProfileDetailsCalled)
    }

    // MARK: Test 3
    // Проверяем, что при нажатии на logout Presenter просит View показать alert.
    func testPresenterCallsShowLogoutAlertWhenLogoutButtonTapped() {

        // Создаём фальшивый экран, который запомнит вызовы Presenter.
        let viewController = ProfileViewControllerSpy()

        // Для этого теста профиль не важен, поэтому передаём nil.
        let profileService = ProfileServiceStub(profile: nil)

        // Создаём настоящий Presenter.
        let presenter = ProfilePresenter(profileService: profileService)

        // Соединяем Presenter с фальшивым экраном.
        presenter.view = viewController

        // Имитируем нажатие на кнопку logout.
        presenter.didTapLogoutButton()

        // Проверяем, что Presenter попросил View показать alert подтверждения выхода.
        XCTAssertTrue(viewController.showLogoutAlertCalled)
    }

    // MARK: Test 4
    // Проверяем, что после подтверждения logout Presenter просит View перейти на Splash.
    func testPresenterCallsSwitchToSplashViewControllerWhenLogoutConfirmed() {

        // Создаём фальшивый экран, который запомнит вызовы Presenter.
        let viewController = ProfileViewControllerSpy()

        // Для этого теста профиль не важен, поэтому передаём nil.
        let profileService = ProfileServiceStub(profile: nil)

        // Создаём настоящий Presenter.
        let presenter = ProfilePresenter(profileService: profileService)

        // Соединяем Presenter с фальшивым экраном.
        presenter.view = viewController

        // Имитируем подтверждение выхода в alert.
        presenter.logoutConfirmed()

        // Проверяем, что Presenter попросил View переключить приложение на Splash.
        XCTAssertTrue(viewController.switchToSplashViewControllerCalled)
    }
}
