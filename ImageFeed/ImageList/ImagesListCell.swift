import Foundation
import UIKit
import Kingfisher

// Ячейка ленты фотографий.
// Показывает картинку, дату и кнопку лайка.
final class ImagesListCell: UITableViewCell {
    
    // Identifier ячейки из Storyboard.
    static let reuseIdentifier = "ImagesListCell"
    
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
    }
    
}
