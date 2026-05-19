//
//  NetworkReachability.swift
//  UginsVault — Data layer / Local
//
//  Thin `NWPathMonitor` wrapper. Exposes whether the device is on
//  Wi-Fi right now (the sync use case gates downloads on this).
//  Concrete + protocol so tests can inject a stub.
//

import Foundation
import Network

@MainActor
public protocol NetworkReachability: AnyObject, Sendable {
    /// Snapshot — `true` only when the active path is unrestricted
    /// Wi-Fi. Cellular returns `false` even when connected.
    var isOnWiFi: Bool { get }
}

@MainActor
public final class NWPathReachability: NetworkReachability {

    /// Defaults to `true` on the simulator (its network is bridged
    /// through the host Mac as `.wiredEthernet`, never `.wifi`, so a
    /// strict Wi-Fi gate would lock dev/test builds out forever). On
    /// real devices the path-monitor's first callback lands the real
    /// value milliseconds after init — we also default `true` there so
    /// a slow first event doesn't block legit first-launch sync.
    public private(set) var isOnWiFi: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "uv.network.reachability")

    public init() {
        #if targetEnvironment(simulator)
        // Always-Wi-Fi on the simulator. Real-device users still get
        // the gate.
        return
        #else
        monitor.pathUpdateHandler = { [weak self] path in
            let isUp = path.status == .satisfied && path.usesInterfaceType(.wifi)
            Task { @MainActor in
                self?.isOnWiFi = isUp
            }
        }
        monitor.start(queue: queue)
        #endif
    }

    deinit {
        #if !targetEnvironment(simulator)
        monitor.cancel()
        #endif
    }
}
