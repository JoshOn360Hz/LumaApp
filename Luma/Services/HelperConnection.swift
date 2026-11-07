import Foundation

enum HelperError: LocalizedError, Sendable {
    case unavailable
    case incompatible
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable: "The Luma helper is unavailable. Try repairing it."
        case .incompatible: "The Luma helper needs to be repaired."
        case .operationFailed(let message): message
        }
    }
}

// NSXPC invokes replies on its own queues. This gate resolves each request
// once, then delivers the result to the main actor that owns the UI state.
private final class PendingRequest<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var didFinish = false
    private let connection: NSXPCConnection
    private let completion: @MainActor (Result<Value, HelperError>) -> Void

    init(connection: NSXPCConnection, completion: @escaping @MainActor (Result<Value, HelperError>) -> Void) {
        self.connection = connection
        self.completion = completion
    }

    func finish(_ result: Result<Value, HelperError>) {
        lock.lock()
        guard !didFinish else {
            lock.unlock()
            return
        }
        didFinish = true
        lock.unlock()
        connection.invalidate()
        Task { @MainActor in completion(result) }
    }

    func startTimeout() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 6) { [self] in
            finish(.failure(.unavailable))
        }
    }
}

nonisolated final class HelperConnection {
    private func makeConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(
            machServiceName: LumaConstants.helperLabel,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: LumaHelperProtocol.self)
        connection.setCodeSigningRequirement(
            "anchor apple generic and certificate leaf[subject.OU] = \"\(LumaConstants.teamID)\" and identifier \"\(LumaConstants.helperLabel)\""
        )
        connection.resume()
        return connection
    }

    func version(_ completion: @escaping @MainActor (Result<Int, HelperError>) -> Void) {
        let connection = makeConnection()
        let request = PendingRequest(connection: connection, completion: completion)
        request.startTimeout()
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ _ in
            request.finish(.failure(.unavailable))
        }) as? LumaHelperProtocol else {
            request.finish(.failure(.unavailable))
            return
        }
        proxy.getProtocolVersion { value in request.finish(.success(value)) }
    }

    func read(_ completion: @escaping @MainActor (Result<(IlluminationState, String?), HelperError>) -> Void) {
        let connection = makeConnection()
        let request = PendingRequest(connection: connection, completion: completion)
        request.startTimeout()
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ _ in
            request.finish(.failure(.unavailable))
        }) as? LumaHelperProtocol else {
            request.finish(.failure(.unavailable))
            return
        }
        proxy.getIlluminationState { rawState, message in
            request.finish(.success((IlluminationState(rawValue: rawState) ?? .unknown, message)))
        }
    }

    func write(_ enabled: Bool, completion: @escaping @MainActor (Result<IlluminationState, HelperError>) -> Void) {
        let connection = makeConnection()
        let request = PendingRequest(connection: connection, completion: completion)
        request.startTimeout()
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ _ in
            request.finish(.failure(.unavailable))
        }) as? LumaHelperProtocol else {
            request.finish(.failure(.unavailable))
            return
        }
        proxy.setIlluminationEnabled(enabled) { rawState, message in
            if let message {
                request.finish(.failure(.operationFailed(message)))
            } else {
                request.finish(.success(IlluminationState(rawValue: rawState) ?? .unknown))
            }
        }
    }
}
