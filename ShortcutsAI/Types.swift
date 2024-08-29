
import Foundation

public struct SelectOption: Identifiable, Codable {
    public let id: UUID
    public let value: String
    public let label: String

    public init(id: UUID = UUID(), value: String, label: String) {
        self.id = id
        self.value = value
        self.label = label
    }
}
