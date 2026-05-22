import UIKit

final class TabBarController: UITabBarController {
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        // Create ImagesListViewController
        let imageListViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController")
        
        // Create ProfileViewController
        //let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        self.viewControllers = [
            imageListViewController,
            profileViewController
        ]
    }
}
