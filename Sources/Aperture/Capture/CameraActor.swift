//
//  CameraActor.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/20.
//

import Foundation

/// A singleton actor whose executor is equivalent to a dispatch serial queue.
@globalActor
public final actor CameraActor {
    public static var shared = CameraActor()
    
    private let sessionQueue = DispatchSerialQueue(
        label: "liyanan2004.Aperture.CameraActor",
        qos: .userInitiated
    )
    
    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
}
