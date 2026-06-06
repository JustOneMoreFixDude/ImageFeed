import UIKit
import Kingfisher


// Экран просмотра одной фотографии.
// Позволяет приблизить картинку двойным тапом и поделиться ей.
final class SingleImageViewController: UIViewController {
    
    // ScrollView нужен для зума и перемещения картинки.
    @IBOutlet weak var scrollView: UIScrollView!
    
    // ImageView показывает выбранную фотографию.
    @IBOutlet private var imageView: UIImageView!
    
    // URL полноразмерной картинки.
    // Передаётся из экрана ленты через prepare.
    var imageURL: URL?
    
    // Вызывается после загрузки экрана.
    // Настраивает zoom, двойной тап и показывает картинку, если она уже есть.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настраиваем минимальный и максимальный zoom.
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1.25

        // Добавляем двойной тап для приближения и отдаления картинки.
        let doubleTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)

        loadImage()
        
    }
    
    // Загружает полноразмерную картинку по URL.
    // Показывает лоадер и обрабатывает ошибки загрузки.
    private func loadImage() {
        // Без URL загружать нечего.
        guard let imageURL else { return }
        

        // Показываем индикатор загрузки.
        UIBlockingProgressHUD.show()

        // Kingfisher скачивает картинку и помещает её в imageView.
        imageView.kf.setImage(with: imageURL) { [weak self] result in
            // Загрузка завершилась — скрываем индикатор.
            UIBlockingProgressHUD.dismiss()

            guard let self else { return }

            switch result {
            // Картинка успешно загружена.
            case .success(let imageResult):
                // Обновляем размер imageView под реальный размер картинки.
                self.imageView.frame.size = imageResult.image.size
                // Подбираем масштаб и центрируем изображение.
                self.rescaleAndCenterImageInScrollView(image: imageResult.image)

            // Не удалось загрузить картинку.
            case .failure:
                print("Failed to load full image")
                // Предлагаем пользователю повторить загрузку.
                self.showError()
            }
        }
    }
    
    // Показывает сообщение об ошибке загрузки картинки.
    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: "Не надо",
            style: .cancel
        )

        // Повторяем попытку загрузки.
        let retryAction = UIAlertAction(
            title: "Повторить",
            style: .default
        ) { [weak self] _ in
            // Повторно запускаем загрузку картинки.
            self?.loadImage()
        }

        alert.addAction(cancelAction)
        alert.addAction(retryAction)

        present(alert, animated: true)
    }
    
    // Закрывает экран просмотра картинки.
    @IBAction func didTapBackButton(_ sender: UIButton) {
        // Возвращаемся к экрану ленты.
        dismiss(animated: true, completion: nil)
    }
    
    // Открывает системное меню «Поделиться».
    @IBAction func didTapShareButton(_ sender: Any) {
        // Проверяем, что картинка уже загружена.
        guard let image = imageView.image else { return }

        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        // Показываем системное меню «Поделиться».
        present(activityViewController, animated: true)
    }
    
    // Обрабатывает двойной тап: приближает или возвращает исходный масштаб.
    @objc private func didDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Точка, по которой пользователь тапнул.
        let point = gesture.location(in: imageView)
        
        // Если картинка уже приближена — уменьшаем её обратно.
        // Иначе приближаем к месту двойного тапа.
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // Вычисляем область, к которой нужно приблизиться.
            let zoomRect = zoomRectForScale(
                scale: scrollView.maximumZoomScale,
                center: point
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    // Считает область, к которой нужно приблизить картинку.
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        // Создаём прямоугольник zoom-области.
        var zoomRect = CGRect()
        zoomRect.size.height = scrollView.bounds.size.height / scale
        zoomRect.size.width = scrollView.bounds.size.width / scale
        zoomRect.origin.x = center.x - zoomRect.size.width / 2
        zoomRect.origin.y = center.y - zoomRect.size.height / 2
        return zoomRect
    }
    
    // Подбирает масштаб так, чтобы картинка поместилась на экран,
    // и центрирует её внутри scrollView.
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        
        // Текущие ограничения zoom.
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        
        // Обновляем layout, чтобы получить актуальный размер scrollView.
        view.layoutIfNeeded()
        
        // Размер видимой области.
        let visibleRectSize = scrollView.bounds.size
        
        // Реальный размер картинки.
        let imageSize = image.size
        
        // Масштаб, при котором картинка помещается по ширине.
        let hScale = visibleRectSize.width / imageSize.width
        
        // Масштаб, при котором картинка помещается по высоте.
        let vScale = visibleRectSize.height / imageSize.height
        
        // Берём меньший масштаб, чтобы картинка целиком поместилась на экран.
        let scaleToFit = min(hScale, vScale)
        
        // Ограничиваем масштаб разрешёнными значениями scrollView.
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        // Минимальный zoom делаем равным масштабу, при котором картинка помещается на экран.
        scrollView.minimumZoomScale = scaleToFit
        
        // Применяем стартовый масштаб.
        scrollView.setZoomScale(scale, animated: false)
        
        // Обновляем layout после изменения zoom.
        scrollView.layoutIfNeeded()
        
        // Размер контента после масштабирования.
        let newContentSize = scrollView.contentSize
        
        // Смещение по X для центрирования картинки.
        let x = (newContentSize.width - visibleRectSize.width) / 2
        
        // Смещение по Y для центрирования картинки.
        let y = (newContentSize.height - visibleRectSize.height) / 2
        
        // Применяем смещение.
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}


// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    // Сообщает scrollView, какую view нужно зумить.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Центрирует картинку после изменения zoom.
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Считаем свободное место сверху и снизу.
        // max(..., 0) защищает от отрицательных отступов.
        let verticalInset = max((scrollView.bounds.height - imageView.frame.height) / 2, 0)
        
        // Считаем свободное место слева и справа.
        let horizontalInset = max((scrollView.bounds.width - imageView.frame.width) / 2, 0)
        
        // Добавляем отступы, чтобы картинка оставалась по центру.
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
}
