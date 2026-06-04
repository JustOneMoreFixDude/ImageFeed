import Foundation
import UIKit
import Kingfisher

// Ячейка ленты фотографий.
// Показывает картинку, дату и кнопку лайка.
final class ImagesListCell: UITableViewCell {
    
    // Identifier ячейки из Storyboard.
    static let reuseIdentifier = "ImagesListCell"
    // Анимированная заглушка во время загрузки картинки.
    private var gradientView: GradientView?
    
    // Картинка фотографии.
    @IBOutlet var cellImage: UIImageView!
    // Кнопка лайка.
    @IBOutlet var likeButton: UIButton!
    // Дата создания фотографии.
    @IBOutlet var dateLabel: UILabel!
    
    // Вызывается перед переиспользованием ячейки.
    // Отменяет старую загрузку картинки, чтобы фото не путались при скролле.
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        gradientView?.removeFromSuperview()
        gradientView = nil
    }
    
    
    // кто хочет быть делегатом ячейки, должен уметь обработать нажатие лайка
    protocol ImagesListCellDelegate: AnyObject {
        func imageListCellDidTapLike(_ cell: ImagesListCell)
    }
    
    // ссылка на того, кто будет слушать ячейку. Слушатель ImagesListViewController
    weak var delegate: ImagesListCellDelegate?
    
    
    @IBAction private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
    
    // метод для смены картинки сердечка
    func setIsLiked(_ isLiked: Bool) {
        let image = isLiked
            ? UIImage(named: "like_button_on")
            : UIImage(named: "like_button_off")
        likeButton.setImage(image, for: .normal)
    }
    
    // Показывает анимированную заглушку поверх изображения.
    func showGradient() {
        guard gradientView == nil else { return }

        let gradient = GradientView(frame: cellImage.bounds)
        gradient.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        cellImage.addSubview(gradient)
        gradientView = gradient
    }

    // Убирает заглушку после загрузки картинки.
    func hideGradient() {
        gradientView?.removeFromSuperview()
        gradientView = nil
    }
}
