import UIKit

final class GradientView: UIView {

    // Слой с анимированным градиентом
    private let gradientLayer = CAGradientLayer()

    // Создание View программно
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    // Создание View из Storyboard/XIB
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // Обновляем размер градиента при изменении размеров View
    override func layoutSubviews() {
        super.layoutSubviews()
        // Градиент должен занимать всю область View.
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }

    // Запускаем анимацию, когда View появилась на экране.
    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            startAnimation()
        } else {
            gradientLayer.removeAnimation(forKey: "locationsChange")
        }
    }

    // Настраивает внешний вид градиента
    private func setupGradient() {
        // Цвета градиента из макета.
        gradientLayer.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
        ]

        // Начальные позиции цветов внутри градиента
        gradientLayer.locations = [0, 0.1, 0.3]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        // Добавляем градиент на экран
        layer.addSublayer(gradientLayer)
    }

    // Создаёт shimmer-анимацию для градиента
    private func startAnimation() {
        gradientLayer.removeAnimation(forKey: "locationsChange")
        // Анимируем положение цветов внутри градиента
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0, 0.1, 0.3]
        animation.toValue = [0, 0.8, 1]
        animation.duration = 1
        animation.repeatCount = .infinity

        // Добавляем анимацию к слою
        gradientLayer.add(animation, forKey: "locationsChange")
    }
}
