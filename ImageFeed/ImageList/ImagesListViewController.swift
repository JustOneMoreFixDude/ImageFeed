import UIKit

class ImagesListViewController: UIViewController {
    
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
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImagesListCell", for: indexPath)
        
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
        
        cell.cellImage.image = image // вставляем картинку
        cell.dateLabel.text = dateFormatter.string(from: Date()) // форматируем дату
        
        /*Для каждой ячейки с чётным индексом установите включённый лайк.
         Для ячеек с нечётным индексом лайк должен быть выключен. */
        let likeImage = indexPath.row % 2 == 0 ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}


extension ImagesListViewController: UITableViewDelegate {
    
    // метод отвечает за действия, которые будут выполнены при тапе по ячейке таблицы.
    // адрес ячейки, который содержится в indexPath, передаётся в качестве аргумента
    // высота = (оригинальная высота * масштаб) + отступы
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        let imageViewInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        
        /*ширина = экран - (left + right)
         высота = пересчитанная + (top + bottom)*/
        let width = tableView.bounds.width - (imageViewInsets.left + imageViewInsets.right)
        let scale = width / image.size.width
        return image.size.height * scale + (imageViewInsets.top + imageViewInsets.bottom)
        
    }
}


