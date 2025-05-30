//
//  CircleView.swift
//  EGNSS4CAP
//
//  Created by Gabriele Amendola on 01/06/22.
//

import UIKit

class CircleView: UIView {
    
    override func draw(_ rect: CGRect) {
        for i in 0..<9 {
            let circle = UIBezierPath(arcCenter: CGPoint(x: bounds.width/2, y: bounds.height/2), radius: CGFloat(i) * 19, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            circle.lineWidth = 1
            circle.stroke()
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(2.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: CGPoint(x: bounds.width - 65 , y: bounds.height - 65 ))
        context?.addLine(to: CGPoint(x: 65, y: 65))
        
        
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: CGPoint(x: bounds.width - 65, y: 65))
        context?.addLine(to: CGPoint(x: 65, y: bounds.height - 65))
        context?.strokePath()
        
        
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: CGPoint(x: bounds.width/2, y: 13))
        context?.addLine(to: CGPoint(x: bounds.width/2, y: bounds.height - 13))
        context?.strokePath()
        
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: CGPoint(x: 13, y: bounds.height/2))
        context?.addLine(to: CGPoint(x: bounds.width - 13, y: bounds.height/2))
        context?.strokePath()
        
        
        let nord = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        nord.center = CGPoint(x: bounds.width/2, y: 4)
        nord.textAlignment = .center
        nord.text = "N"
        self.addSubview(nord)
        
        let nordOvest = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        nordOvest.center = CGPoint(x: 56, y: 56)
        nordOvest.textAlignment = .center
        nordOvest.text = "NW"
        self.addSubview(nordOvest)
        
        let nordEst = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        nordEst.center = CGPoint(x: bounds.width - 56, y: 56)
        nordEst.textAlignment = .center
        nordEst.text = "NE"
        self.addSubview(nordEst)
        
        let sud = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        sud.center = CGPoint(x: bounds.width/2, y: bounds.height - 4)
        sud.textAlignment = .center
        sud.text = "S"
        self.addSubview(sud)
        
        let sudOvest = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        sudOvest.center = CGPoint(x: 56, y: bounds.height - 56)
        sudOvest.textAlignment = .center
        sudOvest.text = "SW"
        self.addSubview(sudOvest)
        
        let sudEst = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        sudEst.center = CGPoint(x: bounds.width - 56, y: bounds.height - 56)
        sudEst.textAlignment = .center
        sudEst.text = "SE"
        self.addSubview(sudEst)
        
        
        let ovest = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        ovest.center = CGPoint(x: 4, y: bounds.height/2)
        ovest.textAlignment = .center
        ovest.text = "W"
        self.addSubview(ovest)
        
        let est = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        est.center = CGPoint(x: bounds.width - 4, y: bounds.height/2)
        est.textAlignment = .center
        est.text = "E"
        self.addSubview(est)
    }
    
}
