//
//  TabBarController.swift
//  PIC2BIM
//
//  Created by Mayur Shrivas on 28/05/24.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        adjustTabBarSize()
    }
    
    override func viewWillLayoutSubviews() {
        adjustTabBarSize()
    }
    
    
    private func adjustTabBarSize() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            /// Adjust the tab bar height for iPad
            var tabFrame = tabBar.frame
            tabFrame.size.height = 100 /// Set the desired height for iPad
            tabFrame.origin.y = view.frame.size.height - tabFrame.size.height
            tabBar.frame = tabFrame
            /// Adjust the safe area inset at the bottom if needed
            additionalSafeAreaInsets.bottom = tabBar.frame.height - 70
        }
    }
}


extension TabBarController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let selectedIndex = tabBarController.tabBar.items?.firstIndex(where: { $0 == viewController.tabBarItem }) else {
            return false
        }
        
        if selectedIndex == 2 {
            if let topVC = UIApplication.getTopViewController() {
                let sb = UIStoryboard(name: "Camera", bundle: nil)
                
                let manageObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                
                guard let vc = sb.instantiateViewController(identifier: "CameraViewController") as? CameraViewController else { return false }
                vc.isPresented = true
                vc.manageObjectContext = manageObjectContext
                if let navController = sb.instantiateViewController(identifier: "CameraNavigationController") as? UINavigationController {
                    navController.setViewControllers([vc], animated: true)
                    navController.modalPresentationStyle = .fullScreen
                    topVC.present(navController, animated: true)
                }
                return false
            }
        } else if selectedIndex == 3 {
            guard let navigationController = viewController as? UINavigationController else { return false }
            for vc in navigationController.viewControllers {
                if let mapVC = vc as? MapViewController {
                    mapVC.isForRecord = true
                }
            }
            return true
        }
        return true
    }
}


extension UINavigationController {
    func hideVisualEffectBackdropView() {
        if let navigationBar = self.navigationBar as? UINavigationBar {
            for view in navigationBar.subviews {
                if view.isKind(of: NSClassFromString("_UIVisualEffectBackdropView")!) {
                    view.isHidden = true
                }
            }
        }
    }
}
