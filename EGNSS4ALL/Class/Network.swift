import Network

class NetworkManager {
    static let shared = NetworkManager()
    
    private let monitor: NWPathMonitor
    private var isReachable: Bool = false
    private let queue = DispatchQueue.global(qos: .background)

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachable = (path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    func isNetworkAvailable() -> Bool {
        return isReachable
    }
}


