//
//  GooeyEffectTableViewCell.swift
//  gooey-cell
//
//  Created by Прегер Глеб on 22/01/2019.
//  Copyright © 2019 Cuberto. All rights reserved.
//

import UIKit

public protocol GooeyCellDelegate: class {
    func gooeyCellActionConfig(for cell: UITableViewCell, direction: GooeyEffect.Direction) -> GooeyEffectTableViewCell.ActionConfig?
    func gooeyCellActionTriggered(for cell: UITableViewCell, direction: GooeyEffect.Direction)
}

open class GooeyEffectTableViewCell: UITableViewCell {
    
    public struct ActionConfig {
        let effectConfig: GooeyEffect.Config
        let isCellDeletingAction: Bool

        public init(effectConfig: GooeyEffect.Config, isCellDeletingAction: Bool) {
            self.effectConfig = effectConfig
            self.isCellDeletingAction = isCellDeletingAction
        }
    }
        
    private var effect: GooeyEffect?
    private var actionConfig: ActionConfig?
    private var gesture: UIPanGestureRecognizer!
    
    open weak var gooeyCellDelegate: GooeyCellDelegate?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addGesture()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGesture()
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        effect = nil
        actionConfig = nil
        gesture.isEnabled = true
    }
    
    private func addGesture() {
        gesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized))
        gesture.delegate = self
        self.addGestureRecognizer(gesture)
    }
    
    @objc private func panGestureRecognized(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            
            let direction: GooeyEffect.Direction = gesture.velocity(in: self).x > 0 ? .toRight : .toLeft

            guard self.effect == nil,
                let actionConfig = gooeyCellDelegate?.gooeyCellActionConfig(for: self, direction: direction) else {
                    
                gesture.isEnabled = false
                gesture.isEnabled = true
                return
            }
            
            self.actionConfig = actionConfig
            
            let verticalPosition = Float(gesture.location(in: self).y / self.bounds.height)
            
            effect = GooeyEffect(to: self,
                                 verticalPosition: verticalPosition,
                                 direction: direction,
                                 config: actionConfig.effectConfig)
            
        case .changed:
            
            guard let effect = effect else { return }
            
            var progress = Float(gesture.translation(in: self).x / effect.effectMaxWidth)
            
            if isProgressInCorrectDirection(progress) {
                progress = abs(progress)
            } else {
                progress = 0
            }
            
            let nonlinearProgressLength: Float = 0.15
            let nonlinearProgressStart: Float = effect.gapProgressValue - nonlinearProgressLength

            let effectProgress: Float
            
            if progress > nonlinearProgressStart {
                
                let localProgress = (progress - (nonlinearProgressStart)) / nonlinearProgressLength
                let rate = Float(log10(Double(1 + localProgress)))
                
                if rate > 1 {
                    effectProgress = effect.gapProgressValue
                } else {
                    effectProgress = nonlinearProgressStart + nonlinearProgressLength * rate
                }
                
            } else {
                effectProgress = progress
            }
        
            effect.updateProgress(progress: effectProgress)

        case .cancelled, .ended, .failed:
            
            guard let effect = effect else { return }
          
            gesture.isEnabled = false
            
            let progress = Float(gesture.translation(in: self).x / effect.effectMaxWidth)

            let finalEffectProgress: Float
            
            if isProgressInCorrectDirection(progress), gesture.state == .ended {
                finalEffectProgress = abs(progress) < effect.gapProgressValue ? 0 : 1
            } else {
                finalEffectProgress = 0
            }

            effect.animateToProgress(finalEffectProgress) { [weak self] in
                guard let self = self else { return }
                
                if finalEffectProgress == 1 {
                    
                    self.gooeyCellDelegate?.gooeyCellActionTriggered(for: self, direction: effect.direction)
                    
                    let saveFinalEffectState = self.actionConfig?.isCellDeletingAction == true
                    
                    if !saveFinalEffectState {
                        self.effect?.removeEffect(animated: true) { [weak self] in
                            self?.effect = nil
                        }
                    }
                } else {
                    self.effect = nil
                }
                
                gesture.isEnabled = true
            }
            
        case .possible:
            break
        }
    }
    
    private func isProgressInCorrectDirection(_ progress: Float) -> Bool {
        guard let effect = effect else { return false }

        if progress < 0 && effect.direction == .toRight ||
            progress > 0 && effect.direction == .toLeft {
            
            return false
        } else {
            return true
        }
    }
    
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == gesture,
            abs(gesture.translation(in: self).y) > 0 {
            return false
        }
        return true
    }
}
