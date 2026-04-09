import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let loginNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let labelsStackView = UIStackView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileView()
    }
    
    // MARK: - Setup
    
    func setupProfileView() {
        setupViews()
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupViews() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        let avatarImage = UIImage(named: "Userpics") ?? UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.image = avatarImage
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 35
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .boldSystemFont(ofSize: 23)
        nameLabel.textColor = .ypWhite
        nameLabel.text = "Екатерина Новикова"
        
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.font = .systemFont(ofSize: 13)
        loginNameLabel.textColor = .ypGray
        loginNameLabel.text = "@ekaterina_nov"
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.text = "Hello, world!"
        
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonImage = UIImage(named: "logout_button")
        logoutButton.setImage(buttonImage, for: .normal)
        logoutButton.tintColor = .ypRed
        logoutButton.contentMode = .scaleAspectFit
        logoutButton.addTarget(
            self,
            action: #selector(didTapLogoutButton),
            for: .touchUpInside
        )
        logoutButton.imageView?.contentMode = .scaleAspectFit
        logoutButton.contentMode = .scaleAspectFit
        
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 8
        labelsStackView.alignment = .leading
        
        view.backgroundColor = .ypBlack
        
    }
    
    private func setupHierarchy() {
        view.addSubview(avatarImageView)
        view.addSubview(logoutButton)
        view.addSubview(labelsStackView)
        
        labelsStackView.addArrangedSubview(nameLabel)
        labelsStackView.addArrangedSubview(loginNameLabel)
        labelsStackView.addArrangedSubview(descriptionLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            
            labelsStackView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            labelsStackView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
        ])
    }
    
    @objc private func didTapLogoutButton() {
        print("logout tapped")
    }
}
