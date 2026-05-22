import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    
    private static var window: UIWindow? {
        UIApplication.shared.windows.first
    }
    
    static func show() {
        window?.isUserInteractionEnabled = false

        ProgressHUD.colorHUD = .clear
        ProgressHUD.colorBackground = UIColor.black.withAlphaComponent(0.3)
        ProgressHUD.colorAnimation = .white

        ProgressHUD.animate()
    }
    
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
