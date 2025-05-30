//
//  UITableView+Extensions.swift
//  PIC2BIM
//
//  Created by apple on 29/05/24.
//

import UIKit

extension UITableView {
    func register<T: UITableViewCell>(cell cellClass: T.Type) {
        let nib = UINib.init(nibName: T.cellID, bundle: Bundle.main)
        register(nib, forCellReuseIdentifier: T.cellID)
    }
    
    func dequeue<T: UITableViewCell>(withClass cellClass: T.Type, for indexPath: IndexPath) -> T? {
        return dequeueReusableCell(withIdentifier: T.cellID, for: indexPath) as? T
    }
    
    func register<T: UITableViewHeaderFooterView>(header headerClass: T.Type) {
        let nib = UINib.init(nibName: T.classAsString, bundle: Bundle.main)
        register(nib, forHeaderFooterViewReuseIdentifier: T.classAsString)
    }
    
    func dequeue<T: UITableViewHeaderFooterView>(withHeaderClass headerClass: T.Type) -> T? {
        return dequeueReusableHeaderFooterView(withIdentifier: T.classAsString) as? T
    }
    
    func disableStickyHeader(headerHeight: CGFloat) {
        self.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: headerHeight))
        self.contentInset = UIEdgeInsets(top: -headerHeight, left: 0, bottom: 0, right: 0)
    }
    
}

extension UICollectionViewCell {
    static var cellID: String {
        return "\(self)"
    }
}


extension UITableViewCell {
    static var cellID: String {
        return "\(self)"
    }
    
    @objc
    func shrinkOnTap(_ isHighlighted: Bool) {
        UIView.animate(withDuration: 0.1) {
            if self.isHighlighted {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } else {
                self.transform = .identity
            }
        }
    }
}

extension NSObject {
    
    static var classAsString : String {
        return String(describing: self)
    }
    
    public var className: String {
        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
    }
}
