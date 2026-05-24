import UIKit

// Контроллер экрана со списком фотографий.
// Он отвечает за:
// - показ таблицы с фотографиями;
// - настройку каждой ячейки таблицы;
// - обработку тапа по фото;
// - переход на экран просмотра одной большой картинки.
final class ImagesListViewController: UIViewController {
    
    // Identifier segue из Storyboard.
    // По нему мы понимаем, какой переход нужно выполнить.
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    // Таблица на экране, в которой показываются фотографии.
    // IBOutlet связывает этот код с Table View в Storyboard.
    @IBOutlet private var tableView: UITableView!
    
    // Временный массив с названиями картинок из Assets.
    // Сейчас фото берутся не из интернета, а из локальных ресурсов приложения.
    private let photosName: [String] = Array(0..<20).map{"\($0)"}
    
    // Форматтер даты для красивого текста в ячейке.
    // lazy значит: он создастся только тогда, когда впервые понадобится.
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Вызывается один раз, когда экран загрузился в память.
    // Здесь обычно делают первичную настройку UI.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Добавляем отступы сверху и снизу у таблицы,
        // чтобы первая и последняя ячейка не прилипали к краям экрана.
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
    }
    
    
    // Вызывается перед переходом на другой экран через segue.
    // Здесь мы передаём данные из списка фотографий на экран одной картинки.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Проверяем, что это именно переход на экран SingleImageViewController.
        if segue.identifier == showSingleImageSegueIdentifier {
            // Достаём экран назначения и indexPath выбранной ячейки.
            // Если что-то пошло не так — дальше идти нельзя.
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            // Берём картинку из Assets по номеру выбранной строки.
            let image = UIImage(named: photosName[indexPath.row])
            
            /*
             Важно:
             UIViewController загружает view лениво.
             Пока view не загружена:
             - IBOutlet = nil
             - UI элементы недоступны

             Поэтому перед работой с UI нужно убедиться, что view инициализирована.

             Варианты:

             1. Принудительно загрузить view:
                _ = viewController.view
                // или (предпочтительно)
                viewController.loadViewIfNeeded()

             2. Научить SingleViewController показывать картинки,
                не инициируя загрузку view
                Воспользоваться isViewLoaded
             */
            
            // Передаём выбранную картинку на следующий экран.
            viewController.image = image
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - UITableViewDataSource

// DataSource отвечает на вопрос: "что показывать в таблице?"
// Здесь мы говорим таблице:
// - сколько будет строк;
// - какую ячейку показать для каждой строки.
extension ImagesListViewController: UITableViewDataSource {
    // Возвращает количество строк в таблице.
    // У нас строк столько же, сколько картинок в массиве photosName.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photosName.count
    }
    
    // Создаёт и настраивает ячейку для конкретной строки таблицы.
    // indexPath.row — это номер строки.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Переиспользуем готовую ячейку из Storyboard по её reuseIdentifier.
        // Так таблица работает быстрее и не создаёт новые ячейки бесконечно.
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        // Проверяем, что получили именно нашу кастомную ячейку ImagesListCell.
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        // Передаём ячейку в отдельную функцию настройки.
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

// MARK: - Cell configuration

// Отдельный extension для вспомогательных методов настройки ячеек.
extension ImagesListViewController {
    // Настраивает конкретную ячейку:
    // - ставит картинку;
    // - ставит дату;
    // - ставит иконку лайка.
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        // Пытаемся найти картинку в Assets.
        // Если картинки нет — просто выходим из функции.
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return
        }
        
        // Показываем картинку внутри ячейки.
        cell.cellImage.image = image
        // Показываем текущую дату в label ячейки.
        cell.dateLabel.text = dateFormatter.string(from: Date())
        
        // Для тренировки: у чётных строк показываем активный лайк,
        // у нечётных — неактивный.
        let likeImage = indexPath.row % 2 == 0 ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        // Ставим нужную картинку на кнопку лайка.
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}


// MARK: - UITableViewDelegate

// Delegate отвечает на вопрос: "что делать, когда пользователь взаимодействует с таблицей?"
// Здесь мы обрабатываем тап по ячейке и задаём высоту ячеек.
extension ImagesListViewController: UITableViewDelegate {
    
    // Вызывается, когда пользователь нажал на ячейку таблицы.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Запускаем segue на экран большой картинки.
        // В sender передаём indexPath, чтобы prepare(for:) понял, какую картинку открыть.
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    // Возвращает высоту ячейки для конкретной строки.
    // Высота считается по пропорциям картинки, чтобы фото не растягивалось криво.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Берём картинку, чтобы узнать её реальный размер.
        // Если картинки нет — высота будет 0.
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        // Отступы картинки внутри ячейки.
        let imageViewInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        
        // ширина = экран - (left + right)
        // высота = пересчитанная + (top + bottom)
        let width = tableView.bounds.width - (imageViewInsets.left + imageViewInsets.right)
        
        // Защита от деления на ноль.
        guard image.size.width != 0 else {
            return 0
        }
        // Считаем масштаб по ширине, чтобы сохранить пропорции картинки.
        let scale = width / image.size.width
        // Итоговая высота = высота картинки после масштабирования + вертикальные отступы.
        return image.size.height * scale + (imageViewInsets.top + imageViewInsets.bottom)
        
    }
}


extension  ImagesListViewController {
    
    // Метод вызывается прямо перед тем, как ячейка таблицы будет показана на экране
    // willDisplay может вызываться много раз, поэтому сервис обязан уметь защищаться от повторных запросов.
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        //        if indexPath.row + 1 == photos.count {
        //            // TO DO: тут вызываем fetchPhotosNextPage()
        //        }
            
            
            
            
            
        // Для проверки:
        // когда появляется первая ячейка — запускаем загрузку фото
        // и печатаем результат в консоль.
//        if indexPath.row == 0 {
//            ImagesListService.shared.fetchPhotosNextPage(token: OAuth2TokenStorage.shared.token ?? "") { result in
//                print(result)
//            }
//        }
        
        
    }
}
