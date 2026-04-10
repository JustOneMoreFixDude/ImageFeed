import Foundation
import UIKit

// Комментарий для ревьюера: брат/сестра, я намеренно написал подробные комменты, без них я плаваю
// ну и в целом это учебный проект. Уверен, что когда я стану таким же мощным, как ты
// я от этой привычки избавлюсь


// Контроллер для показа одной картинки с возможностью зума и шаринга
class SingleImageViewController: UIViewController {
    
    // ScrollView используется для зума и скролла картинки
    @IBOutlet weak var scrollView: UIScrollView!
    
    // UIImageView, в котором отображается картинка (private, чтобы не трогали снаружи)
    @IBOutlet private var imageView: UIImageView! // private, ибо вызов imageView.image извне = падение
    
    
    // Картинка, которую передаёт предыдущий экран
    var image: UIImage? {
        didSet {
            // Если view ещё не загружена — не трогаем UI (imageView ещё nil)
            guard isViewLoaded else { return } // пиздец коненку: аутлет ещё не инициализирован
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настраиваем границы зума
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1.25
        
        guard let image else { return }
        
        imageView.image = image // Устанавливаем картинку в imageView
        imageView.frame.size = image.size // Задаём реальный размер imageView равный размеру картинки
        rescaleAndCenterImageInScrollView(image: image) // Масштабируем и центрируем картинку под размер экрана
        
        let doubleTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        
        scrollView.addGestureRecognizer(doubleTapGesture)
    }
    
    // Закрываем экран (так как он показан модально)
    @IBAction func didTapBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // Открываем системное окно шеринга (AirDrop, Messages и т.д.)
    @IBAction func didTapShareButton(_ sender: Any) {
        // Проверяем, что image совпадает с тем, что отображается
        guard image == imageView.image else { return }
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil)
        
        present(activityViewController, animated: true)
    }
    
    // Обрабатывает двойной тап по экрану и переключает зум
    @objc private func didDoubleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: imageView)
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let zoomRect = zoomRectForScale(
                scale: scrollView.maximumZoomScale,
                center: point
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    // Считает какой кусок картинки нужно показать, чтобы получить нужный zoom
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect()
        zoomRect.size.height = scrollView.bounds.size.height / scale
        zoomRect.size.width = scrollView.bounds.size.width / scale
        zoomRect.origin.x = center.x - zoomRect.size.width / 2
        zoomRect.origin.y = center.y - zoomRect.size.height / 2
        return zoomRect
    }
    
    /*
     rescaleAndCenterImageInScrollView изменяет скейл у scrollView так,
     чтобы картинка занимала по возможности весь экран,
     а её центр совпадал с центром экрана.
     */
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        
        // текущие ограничения зума
        let minZoomScale = scrollView.minimumZoomScale // минимально разрешённый зум (0.1)
        let maxZoomScale = scrollView.maximumZoomScale // максимально разрешённый зум (1.25)
        
        // Обновляем layout, чтобы получить актуальные размеры scrollView
        view.layoutIfNeeded()
        
        // Размер области, которую видит пользователь
        let visibleRectSize = scrollView.bounds.size
        
        // Исходный размер картинки
        let imageSize = image.size // реальный размер картинки
        
        // Масштаб, при котором картинка влезет по ширине
        let hScale = visibleRectSize.width / imageSize.width
        
        // Масштаб, при котором картинка влезет по высоте
        let vScale = visibleRectSize.height / imageSize.height
        
        // Масштаб реальный
        let scaleToFit = min(hScale, vScale)
        
        // Выбираем масштаб, чтобы картинка полностью поместилась,
        // но не выходила за допустимые границы zoom
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        // Не даём уменьшить картинку меньше, чем она помещается на экран
        scrollView.minimumZoomScale = scaleToFit
        
        // Применяем начальный масштаб
        scrollView.setZoomScale(scale, animated: false)
        
        // Обновляем layout после изменения масштаба
        scrollView.layoutIfNeeded()
        
        // Размер контента после масштабирования
        let newContentSize = scrollView.contentSize
        
        // Смещение по X, чтобы центр картинки совпал с центром экрана
        let x = (newContentSize.width - visibleRectSize.width) / 2
        
        // Смещение по Y
        let y = (newContentSize.height - visibleRectSize.height) / 2
        
        // Применяем смещение — центрируем картинку
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}


extension SingleImageViewController: UIScrollViewDelegate {
    // Указываем, какую view нужно зумить (в нашем случае imageView)
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Центрируем картинку после каждого изменения масштаба
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        /*
         Cчитаем, сколько свободного места осталось по вертикали:
         высота видимой области минус текущая высота картинки
         делим на 2, чтобы распределить отступы сверху и снизу
         max(..., 0) нужен, чтобы не получить отрицательные значения,
         если картинка больше экрана (в этом случае inset = 0)
         */
        let verticalInset = max((scrollView.bounds.height - imageView.frame.height) / 2, 0)
        
        // то же самое по горизонтали: считаем свободное место слева и справа
        let horizontalInset = max((scrollView.bounds.width - imageView.frame.width) / 2, 0)
        
        /*
         задаём внутренние отступы контента scrollView
         таким образом создаём "пустое пространство" вокруг картинки,
         чтобы она визуально оказалась по центру
         */
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,      // отступ сверху
            left: horizontalInset,   // отступ слева
            bottom: verticalInset,   // отступ снизу (тот же, чтобы центр был симметричный)
            right: horizontalInset   // отступ справа
        )
    }
}
