import XCTest

// Локальные данные для запуска UI-теста авторизации.
// Вставьте свои данные для запуска этой волшебной рулетки удачи
private enum UITestCredentials {
    static let login = ""
    static let password = ""
}

final class ImageFeedUITests: XCTestCase {
    
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        // Если один шаг теста упал, дальше тест не продолжаем.
        continueAfterFailure = false
        // Запускаем приложение перед каждым UI-тестом.
        app.launch()
    }
      
    // MARK: Test 1
    // Сценарий авторизации.
    func testAuth() throws {
        // Без реальных логина и пароля тест авторизации запускать нельзя.
        guard !UITestCredentials.login.isEmpty,
              !UITestCredentials.password.isEmpty else {
            throw XCTSkip("UI-тест авторизации пропущен: логин и пароль не заданы")
        }
        
        // Нажать кнопку авторизации.
        app.buttons["Authenticate"].tap()
        
        // Подождать, пока экран авторизации открывается и загружается.
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
        
        // Ввести данные в форму.
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        loginTextField.tap()
        loginTextField.typeText(UITestCredentials.login)
        
        app.buttons["Next"].firstMatch.tap()
        sleep(1)
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        passwordTextField.typeText(UITestCredentials.password)
        
        // Нажать кнопку логина.
        app.buttons["Done"].firstMatch.tap()
        sleep(1)
        app.buttons["Login"].firstMatch.tap()
        
        // Подождать, пока открывается экран ленты.
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
    }
    
    // MARK: Test 2
    // Сценарий работы с лентой.
    func testFeed() throws {
        // Подождать, пока открывается и загружается экран ленты.
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
        
        // Сделать жест «смахивания» вверх по экрану для его скролла.
        cell.swipeUp()
        sleep(2)
        
        // Поставить лайк в ячейке верхней картинки.
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        XCTAssertTrue(cellToLike.waitForExistence(timeout: 5))
        cellToLike.buttons["like button off"].tap()
        sleep(1)
        
        // Отменить лайк в ячейке верхней картинки.
        cellToLike.buttons["like button on"].tap()
        sleep(1)
        
        // Нажать на верхнюю ячейку.
        cellToLike.tap()
        sleep(2)
        
        // Подождать, пока картинка открывается на весь экран.
        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 20))
        
        // Ищу кнопку назад
        print(app.debugDescription)
        
        // Увеличить картинку.
        image.pinch(withScale: 3, velocity: 1)
        
        // Уменьшить картинку.
        image.pinch(withScale: 0.5, velocity: -1)
        
        // Вернуться на экран ленты.
        app.buttons["singleImageBackButton"].tap()
    }
    
    // MARK: Test 3
    // Сценарий работы с профилем.
    func testProfile() throws {
        // Подождать, пока открывается и загружается экран ленты.
        let firstCell = app.tables.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        
        // Перейти на экран профиля.
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(2)
        
        // Проверить, что на нём отображаются ваши персональные данные.
        // Конкретные имя и username зависят от аккаунта Unsplash,
        // поэтому проверяем наличие кнопки logout как признак открытого профиля.
        XCTAssertTrue(app.buttons["logout button"].waitForExistence(timeout: 5))
        
        // Нажать кнопку логаута.
        app.buttons["logout button"].tap()
        
        // Проверить, что открылся экран авторизации.
        app.alerts["Пока, пока!"].scrollViews.otherElements.buttons["Да"].tap()
        XCTAssertTrue(app.buttons["Authenticate"].waitForExistence(timeout: 5))
    }
}
