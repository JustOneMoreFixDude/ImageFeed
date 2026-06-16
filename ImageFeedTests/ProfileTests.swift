@testable import ImageFeed
import XCTest

// Spy для ProfileViewControllerProtocol.
// Запоминает, какие методы вызвал Presenter.
final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var updateProfileDetailsCalled = false
    var showLogoutAlertCalled = false
    var switchToSplashViewControllerCalled = false
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
// Позволяет самому задать, есть профиль пользователя или нет.
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
        // Given
        let profile = Profile(
            username: "Test User",
            name: "Test Name",
            loginName: "@test",
            bio: "Test Bio"
        )
        let viewController = ProfileViewControllerSpy()
        let profileService = ProfileServiceStub(profile: profile)
        let presenter = ProfilePresenter(profileService: profileService)
        presenter.view = viewController

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertTrue(viewController.updateProfileDetailsCalled)
        XCTAssertEqual(viewController.receivedProfile?.username, profile.username)
        XCTAssertEqual(viewController.receivedProfile?.name, profile.name)
        XCTAssertEqual(viewController.receivedProfile?.loginName, profile.loginName)
        XCTAssertEqual(viewController.receivedProfile?.bio, profile.bio)
    }

    // MARK: Test 2
    // Проверяем, что ProfilePresenter НЕ вызывает updateProfileDetails(profile:),
    // если профиля в ProfileService нет.
    func testPresenterDoesNotCallUpdateProfileDetailsWhenProfileIsNil() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let profileService = ProfileServiceStub(profile: nil)
        let presenter = ProfilePresenter(profileService: profileService)
        presenter.view = viewController

        // When
        presenter.viewDidLoad()

        // Then
        XCTAssertFalse(viewController.updateProfileDetailsCalled)
    }

    // MARK: Test 3
    // Проверяем, что при нажатии на logout Presenter просит View показать alert.
    func testPresenterCallsShowLogoutAlertWhenLogoutButtonTapped() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let profileService = ProfileServiceStub(profile: nil)
        let presenter = ProfilePresenter(profileService: profileService)
        presenter.view = viewController

        // When
        presenter.didTapLogoutButton()

        // Then
        XCTAssertTrue(viewController.showLogoutAlertCalled)
    }

    // MARK: Test 4
    // Проверяем, что после подтверждения logout Presenter просит View перейти на Splash.
    func testPresenterCallsSwitchToSplashViewControllerWhenLogoutConfirmed() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let profileService = ProfileServiceStub(profile: nil)
        let presenter = ProfilePresenter(profileService: profileService)
        presenter.view = viewController

        // When
        presenter.logoutConfirmed()

        // Then
        XCTAssertTrue(viewController.switchToSplashViewControllerCalled)
    }
}
