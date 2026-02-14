//
//  PlatformImage.swift
//  ImageProcessing
//
//  Platform abstraction for image types across macOS, iOS, and visionOS.
//

import Foundation

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#else
import UIKit
public typealias PlatformImage = UIImage
#endif
