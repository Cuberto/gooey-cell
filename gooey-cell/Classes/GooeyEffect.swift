//
//  GooeyEffect.swift
//  gooey-cell
//
//  Created by Прегер Глеб on 22/01/2019.
//  Copyright © 2019 Cuberto. All rights reserved.
//

import UIKit
import pop

public class GooeyEffect {
    public enum Direction {
        case toRight, toLeft
    }
    
    public struct Config {
        let color: UIColor?
        let image: UIImage?
        
        public init(color: UIColor?, image: UIImage?) {
            self.color = color
            self.image = image
        }
    }
    
    private struct SnapshotLayerInfo {
        let position: CGPoint
        let opacity: Float
    }

    private struct CircleLayerInfo {
        let centerPoint: CGPoint
        let radius: CGFloat
        let leftPoint: CGPoint
        let rightPoint: CGPoint
        let path: CGPath?
    }
    
    private struct EdgeLayerInfo {
        let topPoint: CGPoint
        let topControlPoint: CGPoint
        let bottomPoint: CGPoint
        let bottomControlPoint: CGPoint
        let rightControlPoint: CGPoint
        let path: CGPath?
    }
    
    private struct JointLayerInfo {
        let path: CGPath?
    }
    
    private struct ImageLayerInfo {
        let position: CGPoint
        let opacity: Float
        let transform: CATransform3D
    }
    
    let direction: Direction
    let effectMaxWidth: CGFloat = 170
    let gapProgressValue: Float = 0.7
    
    private let edgeShapeWidthRate: CGFloat = 0.35
    private let effectMaxHeight: CGFloat = 150
    private let circleShapeRadius: CGFloat = 20
    private let jointShapeConstringencyRate: Float = 2
    private let fullAnimationDuration: CFTimeInterval = 0.35
    private let color: UIColor
    private let buttonImage: UIImage?

    private weak var container: UIView?
    private let effectCenterY: CGFloat
    private let effectHeight: CGFloat
    
    private let maskLayer = CALayer()
    private let snapshotLayer = CALayer()
    private let circleLayer = CAShapeLayer()
    private let edgeLayer = CAShapeLayer()
    private let jointLayer = CAShapeLayer()
    private let imageLayer = CALayer()

    private var currentProgress: Float = 0
    
    public init(to container: UIView, verticalPosition: Float, direction: Direction, config: Config? = nil) {
        
        var effectCenterY = container.bounds.height * CGFloat(verticalPosition)
        effectCenterY = max(circleShapeRadius, min(effectCenterY, (container.bounds.height - circleShapeRadius)))
        
        self.container = container
        self.direction = direction
        self.effectCenterY = effectCenterY
        self.effectHeight = min(min(effectCenterY, (container.bounds.height - effectCenterY)) * 2, effectMaxHeight)
        self.buttonImage = config?.image
        self.color = config?.color ?? .clear
        
        let snapShot = UIImage(view: container)
        
        var superView: UIView? = container
        var maskColor: UIColor? = nil
        
        repeat {
            if let color = superView?.backgroundColor,
                color != .clear {
                maskColor = color
            } else {
                superView = superView?.superview
            }
        } while maskColor == nil && superView != nil
        
        maskLayer.backgroundColor = (maskColor ?? .white).cgColor
        maskLayer.frame = container.layer.bounds
        container.layer.addSublayer(maskLayer)
        
        snapshotLayer.contents = snapShot.cgImage
        snapshotLayer.frame = container.layer.bounds
        snapshotLayer.actions = ["position": NSNull(), "opacity": NSNull()]
        container.layer.addSublayer(snapshotLayer)
        
        circleLayer.fillColor = color.cgColor
        circleLayer.frame = container.layer.bounds
        container.layer.addSublayer(circleLayer)

        edgeLayer.fillColor = color.cgColor
        edgeLayer.frame = container.layer.bounds
        container.layer.addSublayer(edgeLayer)
        
        jointLayer.fillColor = color.cgColor
        jointLayer.frame = container.layer.bounds
        container.layer.addSublayer(jointLayer)
        
        imageLayer.contents = buttonImage?.cgImage
        imageLayer.bounds.size = buttonImage?.size ?? .zero
        imageLayer.actions = ["position": NSNull(), "opacity": NSNull(), "transform": NSNull()]
        container.layer.addSublayer(imageLayer)
        
        if direction == .toLeft {
            container.layer.sublayerTransform = CATransform3DMakeScale(-1, 1, 1)
            snapshotLayer.transform = CATransform3DMakeScale(-1, 1, 1)
        }
        
        updateProgress(progress: 0)
    }
    
    deinit {
        removeEffect(animated: false)
    }
    
    public func animateToProgress(_ finalProgress: Float, completion: (()->Void)? = nil) {
        
        let animationStartTime = CACurrentMediaTime()
        let startProgress = currentProgress
        let progressLength = startProgress - finalProgress
        let duration: CFTimeInterval = fullAnimationDuration * CFTimeInterval(abs(progressLength))
        
        let animation = POPCustomAnimation { [weak self] (target, animation) -> Bool in
            
            guard let self = self,
                let animation = animation else {
                    return false
            }
            
            let currentTime = animation.currentTime - animationStartTime
            let animationProgress = Float(currentTime / duration)
            let progress = startProgress - progressLength * animationProgress
            
            if progress >= 0 && progress <= 1 {
                self.updateProgress(progress: progress)
                return true
            } else {
                self.updateProgress(progress: finalProgress)
                return false
            }
        }
        
        animation?.completionBlock = {(animation, isFinished) in
            completion?()
        }
        
        container?.pop_add(animation, forKey: "animation")
    }
    
    public func removeEffect(animated: Bool, completion: (()->Void)? = nil) {

        snapshotLayer.removeFromSuperlayer()
        circleLayer.removeFromSuperlayer()
        edgeLayer.removeFromSuperlayer()
        jointLayer.removeFromSuperlayer()
        imageLayer.removeFromSuperlayer()
        
        if direction == .toLeft {
            container?.layer.sublayerTransform = CATransform3DIdentity
        }
        
        if animated {
            CATransaction.begin()
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            animation.toValue = 0
            animation.duration = fullAnimationDuration
            CATransaction.setCompletionBlock { [weak self] in
                self?.maskLayer.removeFromSuperlayer()
                completion?()
            }
            maskLayer.add(animation, forKey: "opacity")
            CATransaction.commit()
        } else {
            maskLayer.removeFromSuperlayer()
        }
    }
    
    public func updateProgress(progress: Float) {
        guard let _ = container else { return }
        
        currentProgress = progress
        
        let circleLayerInfo = getCircleLayerInfo(with: progress)
        let edgeLayerInfo = getEdgeLayerInfo(with: progress, circleLayerInfo: circleLayerInfo)
        let jointLayerInfo = getJointLayerInfo(with: progress, circleLayerInfo: circleLayerInfo, edgeLayerInfo: edgeLayerInfo)
        let imageLayerInfo = getImageLayerInfo(with: progress, circleLayerInfo: circleLayerInfo)
        let snapshotLayerInfo = getSnapshotLayerInfo(with: progress, circleLayerInfo: circleLayerInfo)
        
        circleLayer.path = circleLayerInfo.path
        edgeLayer.path = edgeLayerInfo.path
        jointLayer.path = jointLayerInfo.path
        
        snapshotLayer.position = snapshotLayerInfo.position
        snapshotLayer.opacity = snapshotLayerInfo.opacity
        
        imageLayer.position = imageLayerInfo.position
        imageLayer.opacity = imageLayerInfo.opacity
        imageLayer.transform = imageLayerInfo.transform
    }
    
    private func getCircleLayerInfo(with progress: Float) -> CircleLayerInfo {
        
        let radius: CGFloat
        
        if progress <= gapProgressValue {
            radius =  circleShapeRadius
        } else {
            radius = circleShapeRadius * CGFloat(1 - (progress - gapProgressValue) / (1 - gapProgressValue))
        }
        
        let locationY = effectCenterY
        let locationX = effectMaxWidth * CGFloat(progress) - radius
        
        let rect = CGRect(x: locationX - radius, y: locationY - radius, width: 2 * radius, height: 2 * radius)
        let bezierPath = UIBezierPath(ovalIn: rect)
        
        let centerPoint = CGPoint(x: locationX, y: locationY)
        let leftPoint = CGPoint(x: locationX - radius, y: locationY)
        let rightPoint = CGPoint(x: locationX + radius, y: locationY)
        
        return CircleLayerInfo(centerPoint: centerPoint, radius: radius, leftPoint: leftPoint, rightPoint: rightPoint, path: bezierPath.cgPath)
    }
    
    private func getEdgeLayerInfo(with progress: Float, circleLayerInfo: CircleLayerInfo) -> EdgeLayerInfo {
        
        let maxEdgeShapeWidth = effectMaxWidth * CGFloat(gapProgressValue) * edgeShapeWidthRate

        var width: CGFloat

        if progress <= gapProgressValue {
            width = min(circleLayerInfo.leftPoint.x - circleLayerInfo.radius / 2, maxEdgeShapeWidth * CGFloat(progress / gapProgressValue))
        } else {
            width = maxEdgeShapeWidth * CGFloat(1 - (progress - gapProgressValue) / (1 - gapProgressValue))
        }
        
        let locationX: CGFloat = 0
        let locationY = circleLayerInfo.centerPoint.y
        let height = effectHeight
        
        let minY: CGFloat = locationY - effectHeight / 2
        let maxY: CGFloat = minY + height
        
        let topPartHeight = locationY - minY
        let bottomPartHeight = maxY - locationY
        
        let verticalRate2: CGFloat = 0.44
        let verticaRate1: CGFloat = 0.71
        
        let horizontalRate1: CGFloat = 0.64
        let horizontalRateCenter: CGFloat = 1.36
        
        let top3Point = CGPoint(x: locationX, y: minY)
        let top2Point = CGPoint(x: locationX, y: minY + topPartHeight * verticalRate2)
        let top1Point = CGPoint(x: locationX + width * horizontalRate1, y: minY + topPartHeight * verticaRate1)
        let centerPoint = CGPoint(x: locationX + width * horizontalRateCenter, y: locationY)
        let bottom1Point = CGPoint(x: locationX + width * horizontalRate1, y: maxY - bottomPartHeight * verticaRate1)
        let bottom2Point = CGPoint(x: locationX, y: maxY - (bottomPartHeight * verticalRate2))
        let bottom3Point = CGPoint(x: locationX, y: maxY)
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: top3Point)
        bezierPath.addCurve(to: top1Point, controlPoint1: top3Point, controlPoint2: top2Point)
        bezierPath.addCurve(to: bottom1Point, controlPoint1: centerPoint, controlPoint2: bottom1Point)
        bezierPath.addCurve(to: bottom3Point, controlPoint1: bottom1Point, controlPoint2: bottom2Point)
        bezierPath.close()
        
        let percentage = CGFloat(progress * jointShapeConstringencyRate)
        let topControlPoint = pointInLine(p1: top1Point, p2: centerPoint, percentage: percentage)
        let bottomControlPoint = pointInLine(p1: bottom1Point, p2: centerPoint, percentage: percentage)
        
        return EdgeLayerInfo(topPoint: top1Point, topControlPoint: topControlPoint, bottomPoint: bottom1Point, bottomControlPoint: bottomControlPoint, rightControlPoint: centerPoint, path: bezierPath.cgPath)
    }
    
    private func getJointLayerInfo(with progress: Float, circleLayerInfo: CircleLayerInfo, edgeLayerInfo: EdgeLayerInfo) -> JointLayerInfo {
        
        guard progress <= gapProgressValue else {
            
            let radius: CGFloat = circleLayerInfo.radius / 2.5 * CGFloat(1 - progress)
            let rect = CGRect(x: edgeLayerInfo.rightControlPoint.x - radius, y: edgeLayerInfo.rightControlPoint.y - radius, width: 2 * radius, height: 2 * radius)
            let bezierPath = UIBezierPath(ovalIn: rect)
            
            return JointLayerInfo(path: bezierPath.cgPath)
        }
        
        let circleTopControlPoint = CGPoint(x: circleLayerInfo.leftPoint.x - 10, y: edgeLayerInfo.topControlPoint.y)
        let circleTopPoint = calculateJointShapePoints(cp: circleTopControlPoint, circleShapeCenter: circleLayerInfo.centerPoint, circleShapeRadius: circleLayerInfo.radius).1
        
        let circleBottomControlPoint = CGPoint(x: circleLayerInfo.leftPoint.x - 10, y: edgeLayerInfo.bottomControlPoint.y)
        let circleBottomPoint = calculateJointShapePoints(cp: circleBottomControlPoint, circleShapeCenter: circleLayerInfo.centerPoint, circleShapeRadius: circleLayerInfo.radius).0
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: edgeLayerInfo.topPoint)
        bezierPath.addCurve(to: circleTopPoint, controlPoint1: edgeLayerInfo.topControlPoint, controlPoint2: circleTopPoint)
        bezierPath.addLine(to: circleBottomPoint)
        bezierPath.addCurve(to: edgeLayerInfo.bottomPoint, controlPoint1: circleBottomPoint, controlPoint2: edgeLayerInfo.bottomControlPoint)
        bezierPath.close()
        
        return JointLayerInfo(path: bezierPath.cgPath)
    }
    
    private func getSnapshotLayerInfo(with progress: Float, circleLayerInfo: CircleLayerInfo) -> SnapshotLayerInfo {
        let position = CGPoint(x: circleLayerInfo.rightPoint.x + snapshotLayer.bounds.width / 2, y: snapshotLayer.position.y)
        let opacity = 1 - progress / gapProgressValue
        return SnapshotLayerInfo(position: position, opacity: opacity)
    }

    private func getImageLayerInfo(with progress: Float, circleLayerInfo: CircleLayerInfo) -> ImageLayerInfo {
        
        let afterGapProgress = max(0, (progress - gapProgressValue) / (1 - gapProgressValue))
        let position = circleLayerInfo.centerPoint
        let opacity = 1 - afterGapProgress
        let scale = CGFloat(1 - afterGapProgress * 1.2)
        let transform = CATransform3DMakeScale(scale, scale, 1)
        
        return ImageLayerInfo(position: position, opacity: opacity, transform: transform)
    }

    private func pointInLine(p1: CGPoint, p2: CGPoint, percentage: CGFloat) -> CGPoint {
        return CGPoint(x: p1.x + percentage * (p2.x - p1.x), y: p1.y + percentage * (p2.y - p1.y))
    }

    private func calculateJointShapePoints(cp: CGPoint, circleShapeCenter: CGPoint, circleShapeRadius: CGFloat) -> (CGPoint, CGPoint) {
        let x = (circleShapeCenter.x + cp.x) / 2
        let y = (circleShapeCenter.y + cp.y) / 2
        let c1 = circleShapeCenter
        let c1r = circleShapeRadius
        let c2 = CGPoint(x: x, y: y)
        let (p1, p2) = findIntersections(centerCircle1: c1, radiusCircle1: c1r, centerCircle2: c2)
        
        return (p1, p2)
    }
    
    private func findIntersections(centerCircle1 c1: CGPoint, radiusCircle1 c1r: CGFloat, centerCircle2 c2: CGPoint) -> (CGPoint, CGPoint) {
        //        The solution is to find tangents by calculation of intersection of two circles
        //         https://www.mathsisfun.com/geometry/construct-circletangent.html
        //
        //        Intersection of two circles
        //        Discussion http://stackoverflow.com/questions/3349125/circle-circle-intersection-points
        //        Description http://paulbourke.net/geometry/circlesphere/
        
        //Calculate distance between centres of circle
        
        let c1c2 = CGPoint(x: c1.x - c2.x, y: c1.y - c2.y)
        let d = sqrt(c1c2.x * c1c2.x + c1c2.y * c1c2.y)
        
        let c2r = d //in our case
        let m = c1r + c2r
        var n = c1r - c2r
        
        if (n < 0) {
            n = n * -1
        }
        
        //No solns
        if (d > m) {
            return (CGPoint.zero, CGPoint.zero)
        }
        //Circle are contained within each other
        if (d < n) {
            return (CGPoint.zero, CGPoint.zero)
        }
        //Circles are the same
        if (d == 0 && c1r == c2r) {
            return (CGPoint.zero, CGPoint.zero)
        }
        
        let a = (c1r * c1r - c2r * c2r + d * d) / (2 * d)
        
        let h = sqrt(c1r * c1r - a * a)
        
        //Calculate point p, where the line through the circle intersection points crosses the line between the circle centers.
        
        var x = c1.x + (a / d) * (c2.x - c1.x)
        var y = c1.y + (a / d) * (c2.y - c1.y)
        let p = CGPoint(x: x, y: y)
        
        //1 Intersection , circles are touching
        if (d == c1r + c2r) {
            return (p, CGPoint.zero)
        }
        
        //2 Intersections
        //Intersection 1
        x = p.x + (h / d) * (c2.y - c1.y)
        y = p.y - (h / d) * (c2.x - c1.x)
        let p1 = CGPoint(x: x, y: y)
        
        //Intersection 2
        x = p.x - (h / d) * (c2.y - c1.y)
        y = p.y + (h / d) * (c2.x - c1.x)
        let p2 = CGPoint(x: x, y: y)
        
        return (p1, p2)
    }
}

extension UIImage {
    convenience init(view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!, scale: UIScreen.main.scale, orientation: .up)
    }
}
