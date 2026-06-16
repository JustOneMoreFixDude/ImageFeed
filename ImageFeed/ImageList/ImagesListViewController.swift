import UIKit
import Kingfisher

// Экран ленты фотографий.
final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
        
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var photos: [Photo] = []
    
    private var presenter: ImagesListPresenterProtocol!
    
    // Связывает ViewController и Presenter.
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if presenter == nil {
            configure(ImagesListPresenter())
        }
        
        tableView.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: 12,
            right: 0
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        presenter.viewDidLoad()
    }
    
    // Передаёт URL выбранной фотографии на экран просмотра.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            let photo = photos[indexPath.row]
            
            guard let url = URL(string: photo.largeImageURL) else {
                return
            }
            
            viewController.imageURL = url
        } else {
            super.prepare(for: segue, sender: sender)
        }
        
    }
    
    @objc private func updateTableViewAnimated() {
        presenter.didReceivePhotosUpdate()
    }
    
    func updatePhotos(_ photos: [Photo]) {
        self.photos = photos
    }
    
    func insertRows(at indexPaths: [IndexPath]) {
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    func showBlockingProgressHUD() {
        UIBlockingProgressHUD.show()
    }
    
    func dismissBlockingProgressHUD() {
        UIBlockingProgressHUD.dismiss()
    }
    
    func updateLike(isLiked: Bool, at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell else { return }
        cell.setIsLiked(isLiked)
    }
    
    func showLikeError(_ error: Error) {
        print("[ImagesListViewController.changeLike]: \(error)")
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        imageListCell.delegate = self
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

// MARK: - Cell configuration

extension ImagesListViewController {
    // Настраивает ячейку для фотографии.
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
   
        let photo = photos[indexPath.row]
        
        guard let url = URL(string: photo.thumbImageURL) else {
            return
        }

        cell.cellImage.kf.indicatorType = .activity
        
        cell.showGradient()
        
        cell.cellImage.kf.setImage(with: url) { [weak self] _ in
            cell.hideGradient()
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }
        
        let likeImage = photo.isLiked
            ? UIImage(named: "like_button_on")
            : UIImage(named: "like_button_off")
        
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}


// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]

        let imageViewInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageViewInsets.left - imageViewInsets.right

        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + imageViewInsets.top + imageViewInsets.bottom
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        presenter.willDisplayPhoto(at: indexPath.row)
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCell.ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        presenter.didTapLike(at: indexPath.row)
    }
}
