import UIKit
import Kingfisher

// Экран ленты фотографий.
// Показывает список фото, загружает новые страницы и открывает выбранную картинку.
final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    // Identifier перехода на экран большой картинки из Storyboard.
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    // Таблица, в которой отображается лента фотографий.
    @IBOutlet private var tableView: UITableView!
        
    // Форматирует дату фотографии для показа в ячейке.
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Фотографии, которые сейчас показывает таблица.
    // После загрузки новых данных массив обновляется из ImagesListService.
    private var photos: [Photo] = []
    
    // Presenter — мозг экрана ленты.
    // ViewController показывает таблицу, Presenter решает, когда грузить данные.
    private var presenter: ImagesListPresenterProtocol!
    
    // configure нужен для связи ViewController и Presenter.
    // В обычном приложении сюда передаём настоящий ImagesListPresenter.
    // В тестах сюда можно будет передать ImagesListPresenterSpy.
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }
    
    // Вызывается один раз после загрузки экрана.
    // Здесь настраиваем таблицу, подписываемся на обновления и запускаем первую загрузку фото.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Если Presenter ещё не передали снаружи, создаём настоящий Presenter.
        // Это нужно для обычного запуска приложения.
        if presenter == nil {
            configure(ImagesListPresenter())
        }
        
        // Добавляем отступы сверху и снизу у таблицы.
        tableView.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: 12,
            right: 0
        )
        
        // Подписываемся на уведомление о загрузке новых фотографий.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        // Сообщаем Presenter, что экран загрузился.
        // Presenter сам запустит первую загрузку фотографий.
        presenter.viewDidLoad()
    }
    
    // Вызывается перед переходом на экран большой картинки.
    // Здесь находим выбранное фото и загружаем его большую версию.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Проверяем, что это нужный segue.
        if segue.identifier == showSingleImageSegueIdentifier {
            // Получаем экран назначения и индекс выбранной ячейки.
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            // Берём выбранную фотографию.
            let photo = photos[indexPath.row]
            
            // Получаем URL большой картинки.
            guard let url = URL(string: photo.largeImageURL) else {
                return
            }
            
            // Передаём URL, а SingleImageViewController сам загрузит картинку
            viewController.imageURL = url
        } else {
            super.prepare(for: segue, sender: sender)
        }
        
    }
    
    // Вызывается, когда ImagesListService сообщил о новых фотографиях.
    // Добавляет новые строки в таблицу с анимацией.
    @objc private func updateTableViewAnimated() {
        // Сервис сообщил, что фотографии обновились.
        // Дальше Presenter решит, какие строки нужно вставить.
        presenter.didReceivePhotosUpdate()
    }
    
    // Метод из ImagesListViewControllerProtocol.
    // Presenter передаёт сюда новый массив фотографий.
    func updatePhotos(_ photos: [Photo]) {
        self.photos = photos
    }
    
    // Метод из ImagesListViewControllerProtocol.
    // Presenter уже посчитал indexPath новых строк, а ViewController только обновляет UI.
    func insertRows(at indexPaths: [IndexPath]) {
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    // Метод из ImagesListViewControllerProtocol.
    // Presenter просит заблокировать интерфейс на время сетевого запроса.
    func showBlockingProgressHUD() {
        UIBlockingProgressHUD.show()
    }
    
    // Метод из ImagesListViewControllerProtocol.
    // Presenter просит разблокировать интерфейс после завершения сетевого запроса.
    func dismissBlockingProgressHUD() {
        UIBlockingProgressHUD.dismiss()
    }
    
    // Метод из ImagesListViewControllerProtocol.
    // Presenter сообщает, что лайк у конкретной фотографии изменился.
    func updateLike(isLiked: Bool, at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell else { return }
        cell.setIsLiked(isLiked)
    }
    
    // Метод из ImagesListViewControllerProtocol.
    // Presenter сообщает, что изменение лайка завершилось ошибкой.
    func showLikeError(_ error: Error) {
        print("[ImagesListViewController.changeLike]: \(error)")
    }
}

// MARK: - UITableViewDataSource

// DataSource говорит таблице, сколько строк показать и какие ячейки использовать.
extension ImagesListViewController: UITableViewDataSource {
    // Количество строк равно количеству загруженных фотографий.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    // Создаёт и настраивает ячейку для конкретной строки.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
        // Берём переиспользуемую ячейку из Storyboard.
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        // Проверяем, что это наша кастомная ячейка.
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        // Будем получать события от кнопки лайка внутри ячейки.
        imageListCell.delegate = self
        
        // Настраиваем содержимое ячейки.
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

// MARK: - Cell configuration

// Вспомогательные методы для настройки ячеек.
extension ImagesListViewController {
    // Заполняет ячейку данными конкретной фотографии.
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
   
        // Берём фотографию для этой строки.
        let photo = photos[indexPath.row]
        
        // Получаем URL маленькой картинки для ленты.
        guard let url = URL(string: photo.thumbImageURL) else {
            return
        }

        // Показываем индикатор, пока картинка загружается.
        cell.cellImage.kf.indicatorType = .activity
        
        // Показываем анимированную заглушку, пока картинка загружается
        cell.showGradient()
        
        // Загружаем картинку и обновляем высоту ячейки после загрузки.
        cell.cellImage.kf.setImage(with: url) { [weak self] _ in
            cell.hideGradient()
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        // Показываем дату создания фотографии
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }
        
        // Показываем состояние лайка
        let likeImage = photo.isLiked
            ? UIImage(named: "like_button_on")
            : UIImage(named: "like_button_off")
        
        // Устанавливаем иконку лайка на кнопку.
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}


// MARK: - UITableViewDelegate

// Delegate отвечает за действия пользователя, высоту ячеек и подгрузку новых страниц.
extension ImagesListViewController: UITableViewDelegate {
    
    // Вызывается при нажатии на ячейку.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Передаём индекс выбранной фотографии на следующий экран.
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    // Считает высоту ячейки по пропорциям фотографии.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Берём фото для текущей строки.
        let photo = photos[indexPath.row]

        // Отступы картинки внутри ячейки.
        let imageViewInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        // Доступная ширина для картинки.
        let imageViewWidth = tableView.bounds.width - imageViewInsets.left - imageViewInsets.right

        // Масштаб, который сохраняет пропорции фотографии.
        let scale = imageViewWidth / photo.size.width
        // Итоговая высота ячейки: высота картинки + вертикальные отступы.
        return photo.size.height * scale + imageViewInsets.top + imageViewInsets.bottom
    }
    
    // Вызывается перед показом ячейки.
    // Если это последняя строка, просим сервис загрузить следующую страницу.
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // Сообщаем Presenter, какая строка скоро появится на экране.
        // Presenter сам решит, надо ли загружать следующую страницу.
        presenter.willDisplayPhoto(at: indexPath.row)
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCell.ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        // Определяем, в какой строке нажали кнопку лайка.
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        // Сообщаем Presenter, что пользователь нажал лайк у конкретной фотографии.
        // Presenter сам решит, какой запрос отправить и что обновить после ответа.
        presenter.didTapLike(at: indexPath.row)
    }
}
