//
//  ViewController.swift
//  gooey-cell
//
//  Created by Прегер Глеб on 17/01/2019.
//  Copyright © 2019 Cuberto. All rights reserved.
//

import UIKit
import gooey_cell

class ViewController: UIViewController {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var horizontalSlider: UISlider!
    @IBOutlet private weak var lblProgress: UILabel!
    
    private var effect: GooeyEffect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = GooeyEffect.Config(color: UIColor.red, image: #imageLiteral(resourceName: "imgCross"))
        effect = GooeyEffect(to: containerView, verticalPosition: 0.2, direction: .toRight, config: config)
        updateEffect()
    }
    
    @IBAction private func sliderValueChanged(_ slider: UISlider) {
        updateEffect()
    }
    
    private func updateEffect() {
        lblProgress.text = "\(horizontalSlider.value)"
        effect?.updateProgress(progress: horizontalSlider.value)
    }
}
