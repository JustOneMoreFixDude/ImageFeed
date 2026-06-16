import UIKit
import Kingfisher

final class ImagesListCell: UITableViewCell {
    
    static let reuseIdentifier = "ImagesListCell"
    private var gradientView: GradientView?
    
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var dateLabel: UILabel!
    
    // Сбрасывает состояние ячейки перед переиспользованием.
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        gradientView?.removeFromSuperview()
        gradientView = nil
    }
    
    protocol ImagesListCellDelegate: AnyObject {
        func imageListCellDidTapLike(_ cell: ImagesListCell)
    }
    
    weak var delegate: ImagesListCellDelegate?
    
    @IBAction private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let image = isLiked
            ? UIImage(named: "like_button_on")
            : UIImage(named: "like_button_off")
        likeButton.setImage(image, for: .normal)
    }
    
    func showGradient() {
        guard gradientView == nil else { return }

        let gradient = GradientView(frame: cellImage.bounds)
        gradient.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        cellImage.addSubview(gradient)
        gradientView = gradient
    }

    func hideGradient() {
        gradientView?.removeFromSuperview()
        gradientView = nil
    }
}
