//
//  MustacheAdjustment.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 19/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import Foundation
import Photos

let MustacheAdjustmentDataFormatIdentifier = "com.elpassion.SwiftMustaches.MustacheAnnotator"
let MustacheAdjustmentDataFormatVersion = "0.1"

class MustacheAdjustment {
    
    let mustacheImage: UIImage = UIImage(named: "mustache")
    let mustachePositions: [MustachePosition]
    
    // MARK: - Initialization
    
    init(adjustmentData: PHAdjustmentData) {
        if let mustachePositions = NSKeyedUnarchiver.unarchiveObjectWithData(adjustmentData.data) as? [MustachePosition] {
            self.mustachePositions = mustachePositions
        }
        else {
            mustachePositions = []
        }
    }
    
    init(image: UIImage) {
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [
                CIDetectorAccuracy: CIDetectorAccuracyHigh,
                CIDetectorTracking: false,
                CIDetectorMinFeatureSize: NSNumber(float: 0.1)
            ])
        
        let ciImage = CIImage(CGImage: image.CGImage)
        let features = detector.featuresInImage(
            ciImage,
            options: [
                CIDetectorImageOrientation: UIImage.orientationPropertyValueFromImageOrientation(.Up),
                CIDetectorEyeBlink: false,
                CIDetectorSmile: false
            ])
        
        var mustachePositions: [MustachePosition] = []
        
        for faceFeature in features as [CIFaceFeature] {
            if let mustachePosition = MustacheAdjustment.mustachePosition(imageSize: image.size, faceFeature: faceFeature) {
                mustachePositions.append(mustachePosition)
                NSLog("Mustache position found")
            }
            else {
                NSLog("Mustache position not found")
            }
        }
        
        self.mustachePositions = mustachePositions
    }
    
    // MARK: -
    
    func adjustmentData() -> PHAdjustmentData {
        let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.mustachePositions)
        return PHAdjustmentData(
            formatIdentifier: MustacheAdjustmentDataFormatIdentifier,
            formatVersion: MustacheAdjustmentDataFormatVersion,
            data: data)
    }
    
    func applyAdjustment(inputImage: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(inputImage.size, true, inputImage.scale)
        let context = UIGraphicsGetCurrentContext()!
        inputImage.drawAtPoint(CGPointZero)
        
        for mustachePosition in mustachePositions {
            let mustacheImage = self.mustacheImage.rotatedImage(mustachePosition.angle)
            mustacheImage.drawInRect(mustachePosition.rect)
            NSLog("Mustache drawed")
        }
        
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return outputImage
    }
    
    // MARK: - Helper methods
    
    class func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        if let adjustmentData = adjustmentData {
            return  adjustmentData.formatIdentifier == MustacheAdjustmentDataFormatIdentifier &&
                    adjustmentData.formatVersion == MustacheAdjustmentDataFormatVersion
        }
        return false
    }
    
    class private func mustachePosition(#imageSize: CGSize, faceFeature: CIFaceFeature) -> MustachePosition? {
        if !faceFeature.hasMouthPosition { return nil }
        
        let mustacheSize = CGSize(
            width: faceFeature.bounds.width / 1.5,
            height: faceFeature.bounds.height / 5)
        
        let mustacheRect = CGRect(
            x: faceFeature.mouthPosition.x - (mustacheSize.width / 2),
            y: imageSize.height - faceFeature.mouthPosition.y - mustacheSize.height,
            width: mustacheSize.width,
            height: mustacheSize.height)
        
        var mustacheAngle: CGFloat
        if faceFeature.hasFaceAngle {
            mustacheAngle = CGFloat(faceFeature.faceAngle) * CGFloat(3.14) / CGFloat(180.0)
        }
        else {
            mustacheAngle = CGFloat(0)
            NSLog("Mustache angle not found, using \(mustacheAngle)")
        }
        
        return MustachePosition(rect: mustacheRect, angle: mustacheAngle)
    }
    
}