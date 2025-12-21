//
//  CaptureOutput.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/21.
//

import Foundation
import AVFoundation

public protocol CaptureOutput {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    
    @CameraActor
    func updateOutput(_ camera: Camera) throws
    
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension CaptureOutput {
    public func setVideoRotationAngle(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }
}
