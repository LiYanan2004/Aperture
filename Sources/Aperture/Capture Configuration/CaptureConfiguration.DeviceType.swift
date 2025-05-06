//
//  CaptureConfiguration.DeviceType.swift
//  Aperture
//
//  Created by Yanan Li on 2025/5/6.
//

import AVFoundation

extension CaptureConfiguration {
    public enum DeviceType: Sendable, Hashable {
        /// A compositing device that fuses all available cameras (e.g., `.builtInTripleCamera`).
        case all
        /// A specific lens type to use for capture.
        case specific(LensType)
        
        var deviceTypes: [AVCaptureDevice.DeviceType] {
            switch self {
            case .all:
                #if os(macOS)
                [.builtInWideAngleCamera, .continuityCamera]
                #else
                [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera, .continuityCamera]
                #endif
            case .specific(let lensType):
                [lensType.rawValue]
            }
        }
        
        public enum LensType: Sendable, Hashable, RawRepresentable {
            #if os(iOS)
            public init?(rawValue: AVCaptureDevice.DeviceType) {
                switch rawValue {
                case .builtInUltraWideCamera:
                    self = .ultraWideAngle
                case .builtInWideAngleCamera:
                    self = .wideAngle
                case .builtInTelephotoCamera:
                    self = .telephoto
                case .continuityCamera:
                    self = .continuity
                default:
                    return nil
                }
            }
            
            public var rawValue: AVCaptureDevice.DeviceType {
                switch self {
                case .wideAngle: .builtInWideAngleCamera
                case .ultraWideAngle: .builtInUltraWideCamera
                case .telephoto: .builtInTelephotoCamera
                case .continuity: .continuityCamera
                }
            }
            #elseif os(macOS)
            public init?(rawValue: AVCaptureDevice.DeviceType) {
                switch rawValue {
                case .builtInWideAngleCamera:
                    self = .wideAngle
                case .continuityCamera:
                    self = .continuity
                default:
                    return nil
                }
            }
            
            public var rawValue: AVCaptureDevice.DeviceType {
                switch self {
                case .wideAngle: .builtInWideAngleCamera
                case .continuity: .continuityCamera
                default: fatalError("Unsupported Lens Type.")
                }
            }
            #endif
            
            case wideAngle
            @available(macOS, unavailable)
            case ultraWideAngle
            @available(macOS, unavailable)
            case telephoto
            case continuity
        }
    }
}
