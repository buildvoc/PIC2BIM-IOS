//
//  MenuViewController.swift
//  PIC2BIM
//
//  Created by apple on 29/05/24.
//

import UIKit
import SideMenuSwift

class MenuViewController: UIViewController {

    // MARK: - IBOutlet -
    
    @IBOutlet weak var tableViewMenu: UITableView!
    
    // MARK: - Properties -
    
    var arrayMenuText: [String] = ["Photos", "Paths", "Skymaps", "Settings", "About", "Logout"]
    
    // MARK: - ViewLifeCycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        tableViewMenu.register(cell: MenuTableViewCell.self)
        
        let storyboard = UIStoryboard(name: "Photo", bundle: nil)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mapStoryboard = UIStoryboard(name: "Map", bundle: nil)
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        
        
        sideMenuController?.cache(viewControllerGenerator: {
            storyboard.instantiateViewController(withIdentifier: "PhotoNavigationController")
        }, with: "0")

        
        sideMenuController?.cache(viewControllerGenerator: {
            mapStoryboard.instantiateViewController(withIdentifier: "MapNavigationController")
        }, with: "1")
        
        
        sideMenuController?.cache(viewControllerGenerator: {
            mainStoryboard.instantiateViewController(withIdentifier: "SkyMapNavigationController")
        }, with: "2")
        
        sideMenuController?.cache(viewControllerGenerator: {
            mainStoryboard.instantiateViewController(withIdentifier: "SettingNavigationController")
        }, with: "3")
        
        sideMenuController?.cache(viewControllerGenerator: {
            mainStoryboard.instantiateViewController(withIdentifier: "AboutNavigationController")
        }, with: "4")
        
        sideMenuController?.cache(viewControllerGenerator: {
            homeStoryboard.instantiateViewController(withIdentifier: "HomeNavigationController")
        }, with: "5")
        
                
        sideMenuController?.delegate = self
    }
    
}

extension MenuViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayMenuText.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeue(withClass: MenuTableViewCell.self, for: indexPath) else {return UITableViewCell()}
        
        cell.labelMenu.text = arrayMenuText[indexPath.row]
        return cell
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sideMenuController?.setContentViewController(with: "\(indexPath.row)", animated: false)
        sideMenuController?.hideMenu()
        
        if let identifier = sideMenuController?.currentCacheIdentifier() {
            print("[Example] View Controller Cache Identifier: \(identifier)")
        }
        switch indexPath.row {
        case 0:
           if let vc = UIStoryboard(name: "Photo", bundle: nil).instantiateViewController(identifier: "PhotosTableViewController") as? PhotosTableViewController  {
               self.navigationController?.pushViewController(vc, animated: true)
           }
        case 1:
            if let vc = UIStoryboard(name: "Map", bundle: nil).instantiateViewController(identifier: "PathTrackTableViewController") as? PathTrackTableViewController {
                vc.loadPaths()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 2:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SkyViewVC") as? SkyViewVC {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 3:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SettingViewController") as? SettingViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 4:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AboutViewController") as? AboutViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 5:
            UserStorage.removeObject(key: UserStorage.Key.userID)
            UserStorage.removeObject(key: UserStorage.Key.login)
            UserStorage.removeObject(key: UserStorage.Key.userName)
            UserStorage.removeObject(key: UserStorage.Key.userSurname)
            let isLogged = UserStorage.exists(key: UserStorage.Key.userID)
            if isLogged != true {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let loginNavCon = storyboard.instantiateViewController(withIdentifier: "LoginNavigationController") as? UINavigationController {
                    loginNavCon.modalPresentationStyle = .fullScreen
                    present(loginNavCon, animated: true)
                }
            }
        default:
            print(indexPath.row)
        }
    }
}

extension MenuViewController: SideMenuControllerDelegate {
    func sideMenuController(_ sideMenuController: SideMenuController,
                            animationControllerFrom fromVC: UIViewController,
                            to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BasicTransitionAnimator(options: .transitionFlipFromLeft, duration: 0.6)
    }
    
    func sideMenuController(_ sideMenuController: SideMenuController, willShow viewController: UIViewController, animated: Bool) {
        print("[Example] View controller will show [\(viewController)]")
    }
    
    func sideMenuController(_ sideMenuController: SideMenuController, didShow viewController: UIViewController, animated: Bool) {
        print("[Example] View controller did show [\(viewController)]")
    }
    
    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        tabBarController?.tabBar.isHidden = false
    }
    
    func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {
        print("[Example] Menu did hide.")
    }
    
    func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        print("[Example] Menu will reveal.")
    }
    
    func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
        print("[Example] Menu did reveal.")
    }
}
