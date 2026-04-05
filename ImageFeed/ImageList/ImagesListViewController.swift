import UIKit

final class ImagesListViewController: UIViewController {
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    // создаем и заполняем массив с названиями фоток
    private let photosName: [String] = Array(0..<20).map{"\($0)"}
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            let image = UIImage(named: photosName[indexPath.row])
            
            /*
             ⚠️ Важно:
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
            
            viewController.image = image
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

extension ImagesListViewController {
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return
        }
        
        cell.cellImage.image = image
        cell.dateLabel.text = dateFormatter.string(from: Date())
        
        // чётная ячейка — лайк включён, нечётная — выключен
        let likeImage = indexPath.row % 2 == 0 ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}


extension ImagesListViewController: UITableViewDelegate {
    
    // вызывается при тапе по ячейке
    // TODO: открыть экран с картинкой
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // осуществление перехода к экране
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        let imageViewInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        
        // ширина = экран - (left + right)
        // высота = пересчитанная + (top + bottom)
        let width = tableView.bounds.width - (imageViewInsets.left + imageViewInsets.right)
        
        guard image.size.width != 0 else {
            return 0
        }
        // масштаб по ширине, чтобы сохранить пропорции картинки
        let scale = width / image.size.width
        return image.size.height * scale + (imageViewInsets.top + imageViewInsets.bottom)
        
    }
}


