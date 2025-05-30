//
//  UIViewController+Extensions.swift
//  PIC2BIM
//
//  Created by apple on 30/05/24.
//

import UIKit
import SideMenuSwift

extension UIViewController {
    
    func addMenuButton() {
        let image = UIImage(named: "menuIcon")   
        let backBarButton = UIBarButtonItem(image: image, style: .plain, target: self, action:  #selector(didTapOnBackButton))
        backBarButton.tintColor = .white
        navigationItem.rightBarButtonItem = backBarButton
    }
    
    @objc
    func didTapOnBackButton(sender: UIBarButtonItem) {
        sideMenuController?.revealMenu()
    }
}
