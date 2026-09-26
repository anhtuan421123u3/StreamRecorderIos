import Foundation
import SwiftUI
import LiveVaultCommon

public enum DeepLinkDestination: Equatable, Sendable {
    case recording(id: String)
    case storageSettings
    case paywall
}

@Observable
public final class DeepLinkManager {
    public static let shared = DeepLinkManager()
    public var activeDestination: DeepLinkDestination? = nil
    
    public init() {}
    
    @discardableResult
    public func handleURL(_ url: URL) -> Bool {
        // 1. Custom URL Scheme: livevault://recording/{id}
        if url.scheme == LiveVaultConstants.customScheme {
            let host = url.host
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            
            if host == "recording" || pathComponents.first == "recording" {
                if let recId = url.pathComponents.last ?? url.host, recId != "recording" {
                    self.activeDestination = .recording(id: recId)
                    return true
                }
            } else if host == "storage" || host == "settings" {
                self.activeDestination = .storageSettings
                return true
            } else if host == "paywall" || host == "upgrade" {
                self.activeDestination = .paywall
                return true
            }
        }
        
        // 2. Universal Links: https://livevault.app/recording/{id}
        if url.host == LiveVaultConstants.universalLinkHost {
            let components = url.pathComponents.filter { $0 != "/" }
            if components.first == "recording", components.count >= 2 {
                let recId = components[1]
                self.activeDestination = .recording(id: recId)
                return true
            } else if components.first == "paywall" {
                self.activeDestination = .paywall
                return true
            }
        }
        
        return false
    }
}
