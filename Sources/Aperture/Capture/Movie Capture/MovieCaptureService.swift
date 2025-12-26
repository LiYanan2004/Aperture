//
//  MovieCaptureService.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/21.
//

import AVFoundation

public struct MovieCaptureService: OutputService {
    var configuraton: MovieCaptureConfiguration
    
    @_spi(Internal)
    public init(configuration: MovieCaptureConfiguration = .init()) {
        self.configuraton = configuration
    }
    
    public func makeOutput(context: Context) -> AVCaptureMovieFileOutput {
        return AVCaptureMovieFileOutput()
    }
    
    public func updateOutput(output: AVCaptureMovieFileOutput, context: Context) {
        //
    }
}
