//
//  MovieCapture.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/21.
//

import AVFoundation

open class MovieCapture: CaptureOutput {
    public let output = AVCaptureMovieFileOutput()
    
    public func updateOutput(_ camera: Camera) throws {
       
    }
}
