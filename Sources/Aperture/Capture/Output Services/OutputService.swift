//
//  OutputService.swift
//  Aperture
//
//  Created by Yanan Li on 2025/12/26.
//

import Foundation
import AVFoundation

/// A type that provides media output destinations for a capture session.
public protocol OutputService: Equatable, Sendable {
    /// The underlying output class.
    associatedtype Output: AVCaptureOutput
    /// The service's associated coordinator.
    associatedtype Coordinator = Void
    typealias Context = OutputServiceContext<Self>
    
    /// Creates a custom coordinator to communicate with other data types.
    func makeCoordinator() -> Coordinator
    /// Creates the output object and configure its initial state.
    func makeOutput(context: Context) -> Output
    /// Update the output object with the information from context.
    func updateOutput(output: Output, context: Context)
}

extension OutputService where Coordinator == Void {
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

// MARK: - Context

/// Contextual information of the camera session and associated device input.
public struct OutputServiceContext<Service: OutputService> {
    /// The service associated coordinator.
    public var coordinator: Service.Coordinator
    /// The capture session.
    public var session: AVCaptureSession
    /// The device input that is associated to the session.
    public var input: AVCaptureDeviceInput
    
    /// The connected capture device.
    public var inputDevice: AVCaptureDevice {
        input.device
    }
}

// MARK: - Builder

/// A result builder that combines multiple ``OutputService`` into an array.
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

