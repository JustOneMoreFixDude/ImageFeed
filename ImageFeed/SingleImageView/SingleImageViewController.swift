import Foundation
import UIKit

class SingleImageViewController: UIViewController {
    
    var image: UIImage? {
        didSet {
            // проверяем загружено ли view
            guard isViewLoaded else { return } // пиздец коненку: аутлет ещё не инициализирован
            imageView.image = image
        }
    }
    
    
    @IBOutlet private var imageView: UIImageView! // private, ибо вызов imageView.image извне = падение
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image // инициализируем image, что бы не упало
    }
}
