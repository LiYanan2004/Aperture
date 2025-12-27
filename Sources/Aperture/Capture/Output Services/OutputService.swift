//
//  OutputService.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import Foundation
import AVFoundation

public protocol OutputService: Equatable, Sendable {
    associatedtype Output: AVCaptureOutput
    associatedtype Coordinator = Void
    typealias Context = OutputServiceContext<Self>
    
    func makeCoordinator() -> Coordinator
    func makeOutput(context: Context) -> Output
    func updateOutput(output: Output, context: Context)
}

extension OutputService where Coordinator == Void {
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

// MARK: - Context

public struct OutputServiceContext<Service: OutputService> {    
    public var coordinator: Service.Coordinator
    public var session: AVCaptureSession
    public var input: AVCaptureDeviceInput
    
    public var inputDevice: AVCaptureDevice {
        input.device
    }
}

// MARK: - Builder

@resultBuilder
public enum OutputServiceBuilder {
    public static func buildExpression(_ expression: any OutputService) -> [any OutputService] {
        [expression]
    }

    public static func buildExpression(_ expression: [any OutputService]) -> [any OutputService] {
        expression
    }

    public static func buildBlock(_ components: [any OutputService]...) -> [any OutputService] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any OutputService]?) -> [any OutputService] {
        component ?? []
    }

    public static func buildEither(first component: [any OutputService]) -> [any OutputService] {
        component
    }

    public static func buildEither(second component: [any OutputService]) -> [any OutputService] {
        component
    }

    public static func buildArray(_ components: [[any OutputService]]) -> [any OutputService] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [any OutputService]) -> [any OutputService] {
        component
    }
}

