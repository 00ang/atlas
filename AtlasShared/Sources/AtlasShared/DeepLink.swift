import Foundation

public enum DeepLink: Equatable {
    case session(id: UUID)

    public static let scheme = "atlas"

    public init?(url: URL) {
        guard url.scheme == DeepLink.scheme else { return nil }
        let host = url.host ?? ""
        let path = url.pathComponents.filter { $0 != "/" }
        switch host {
        case "session":
            guard let raw = path.first, let id = UUID(uuidString: raw) else { return nil }
            self = .session(id: id)
        default:
            return nil
        }
    }

    public var url: URL {
        switch self {
        case .session(let id):
            return URL(string: "\(DeepLink.scheme)://session/\(id.uuidString)")!
        }
    }
}
