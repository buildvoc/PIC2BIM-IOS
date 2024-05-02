//
//  PDFCreator.swift
//  Atlhas
//
//

import UIKit
import PDFKit
import ImageIO


let pdfMargin = 40.0

class PDFCreator: NSObject {
    let title: String
    let image: UIImage
    let map: UIImage
    let latitude: Double
    let longitude: Double
    let shotDate: String
    let note: String
    let send: Bool
    let validated: Bool
  
    init(title: String, image: UIImage, map: UIImage, latitude: Double, longitude: Double, shotDate: String, note: String, send: Bool, validated: Bool) {
        self.title = title
        self.image = image
        self.map = map
        self.latitude = latitude
        self.longitude = longitude
        self.shotDate = shotDate
        self.note = note
        self.send = send
        self.validated = validated
  }
    static var unameMachine: String {
        var utsnameInstance = utsname()
        uname(&utsnameInstance)
        let optionalString: String? = withUnsafePointer(to: &utsnameInstance.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return optionalString ?? "N/A"
    }
  
    func createPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "EGNSS4ALL",
            kCGPDFContextAuthor: "EUSPA",
            kCGPDFContextTitle: title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            
            context.beginPage()
            
            //Extract Device Name
            let device = UIDevice.current
            let modelName = "\(PDFCreator.unameMachine)"+" (\(device.systemName) \(device.systemVersion))"

            
           
            let image = addImage(image: image, pageRect: pageRect, imageTop: 0, imageX: pageRect.width/4, maxHeight: pageRect.height/2+150, maxWidth: pageRect.width/2+150)
            let imageMap = addImage(image: map, pageRect: pageRect, imageTop: image, imageX: 0, maxHeight: 245, maxWidth: 300)
            
            let userPoint = addImage(image: UIImage(named: "pin_map")!, pageRect: pageRect, imageTop: image+122-12, imageX: 150-12, maxHeight: 24, maxWidth: 24)
            
            let titlePropAttribute: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let propAttribute: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor(named: "Primary")!
            ]
            
            let distanceFromImage = 320.0
            let separator = 10.0
            let title1 = addText(text: "Latitude", pageRect: pageRect, textTop: image+20, textX: distanceFromImage, textAttributes: titlePropAttribute)
            let title2 = addText(text: "Longitude", pageRect: pageRect, textTop: title1+separator, textX: distanceFromImage, textAttributes: titlePropAttribute)
            let title3 = addText(text: "Created", pageRect: pageRect, textTop: title2+separator, textX: distanceFromImage, textAttributes: titlePropAttribute)
            let title4 = addText(text: "Sent", pageRect: pageRect, textTop: title3+separator, textX: distanceFromImage, textAttributes: titlePropAttribute)
            let title5 = addText(text: "Note", pageRect: pageRect, textTop: title4+separator, textX: distanceFromImage, textAttributes: titlePropAttribute)
            let title6 = addText(text: "OSNMA Validated", pageRect: pageRect, textTop: title5+separator, textX: distanceFromImage, textAttributes: titlePropAttribute)
            
            let title1Prop = addTextRight(text: String(latitude), pageRect: pageRect, textTop: image+20, textX: pageRect.width-40, textAttributes: propAttribute)
            let title2Prop = addTextRight(text: String(longitude), pageRect: pageRect, textTop: title1Prop+separator, textX: pageRect.width-40, textAttributes: propAttribute)
            let title3Prop = addTextRight(text: String(shotDate), pageRect: pageRect, textTop: title2Prop+separator, textX: pageRect.width-40, textAttributes: propAttribute)
            let title4Prop = addTextRight(text: String(send), pageRect: pageRect, textTop: title3Prop+separator, textX: pageRect.width-40, textAttributes: propAttribute)
            let title5Prop = addTextRight(text: String(note), pageRect: pageRect, textTop: title4Prop+separator, textX: pageRect.width-40, textAttributes: propAttribute)
            var sendTxt = ""
            if send {
                sendTxt = "yes"
            } else {
                sendTxt = "no"
            }
            
            var validTxt = ""
            if validated {
                validTxt = "yes"
            } else {
                validTxt = "no"
            }
            
            let title6Prop = addTextRight(text: validTxt, pageRect: pageRect, textTop: title5Prop+separator, textX: pageRect.width-40, textAttributes: propAttribute)
            
            
            
           
        }
        return data
    
  }
    
    func addImage(image: UIImage, pageRect: CGRect, imageTop: CGFloat, imageX: CGFloat, maxHeight: CGFloat, maxWidth: CGFloat) -> CGFloat {
        
        
      // 2
      let aspectWidth = maxWidth / image.size.width
      let aspectHeight = maxHeight / image.size.height
      let aspectRatio = min(aspectWidth, aspectHeight)
      // 3
      let scaledWidth = image.size.width * aspectRatio
      let scaledHeight = image.size.height * aspectRatio
      // 4
      let imageX = imageX
      let imageRect = CGRect(x: imageX, y: imageTop,
                             width: scaledWidth, height: scaledHeight)
      // 5
        image.draw(in: imageRect)
      return imageRect.origin.y + imageRect.size.height
    }
    
    func addText(text: String, pageRect: CGRect, textTop: CGFloat, textX: CGFloat, textAttributes: [NSAttributedString.Key: Any]) -> CGFloat {
      // 1
     
      let attributedText = NSAttributedString(string: text, attributes: textAttributes)
      // 3
      let textStringSize = attributedText.size()
      // 4
      let textStringRect = CGRect(x: textX,
                                   y: textTop, width: textStringSize.width,
                                   height: textStringSize.height)
      // 5
      attributedText.draw(in: textStringRect)
      // 6
      return textStringRect.origin.y + textStringRect.size.height
    }
    
    func addTextRight(text: String, pageRect: CGRect, textTop: CGFloat, textX: CGFloat, textAttributes: [NSAttributedString.Key: Any]) -> CGFloat {
      // 1
     
      let attributedText = NSAttributedString(string: text, attributes: textAttributes)
      // 3
      let textStringSize = attributedText.size()
      // 4
        let textStringRect = CGRect(x: textX-textStringSize.width,
                                   y: textTop, width: textStringSize.width,
                                   height: textStringSize.height)
      // 5
      attributedText.draw(in: textStringRect)
      // 6
      return textStringRect.origin.y + textStringRect.size.height
    }
  
    
    func formatDateToCustomString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE MMMM dd, yyyy, 'at' h:mm a zzz"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Imposta la lingua della formattazione
        //dateFormatter.timeZone = TimeZone(identifier: "Europe/Rome") // Imposta la zona oraria

        return dateFormatter.string(from: date)
    }
    
   
}
