//
//  UIImage.swift
//  AppKit
//
//  Created by Nicholas Bosak on 8/22/16.
//

import UIKit
import CoreGraphics

extension UIImage {

    /// Reference: http://stackoverflow.com/a/24545102
    /// Reconstructs an image with a specific tint color
    /// Used to set the unselected item appearance for UITabBar
    func withColor(_ color: UIColor) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        guard let context = UIGraphicsGetCurrentContext() as CGContext!,
            let cgi = self.cgImage else { return nil }

        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)

        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: cgi)
        context.fill(rect)

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage! else { return nil }
        UIGraphicsEndImageContext()

        return newImage
    }
}
