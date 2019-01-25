//
//  TableViewCell.swift
//  gooey-cell
//
//  Created by Прегер Глеб on 24/01/2019.
//  Copyright © 2019 Cuberto. All rights reserved.
//

import UIKit
import gooey_cell

class TableViewCell: GooeyEffectTableViewCell {
    @IBOutlet var backgroundFrameView: UIView! {
        didSet {
            backgroundFrameView.layer.shadowColor = UIColor.black.cgColor
            backgroundFrameView.layer.shadowRadius = 5
            backgroundFrameView.layer.shadowOpacity = 0.08
        }
    }
    @IBOutlet var imgIcon: UIImageView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblDescription: UILabel!
    @IBOutlet var lblTime: UILabel!
}

private extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   randomCGFloat(),
                       green: randomCGFloat(),
                       blue:  randomCGFloat(),
                       alpha: 1.0)
    }
    
    private static func randomCGFloat() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
