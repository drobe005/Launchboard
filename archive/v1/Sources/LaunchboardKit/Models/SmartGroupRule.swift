/// SwiftData model for a single predicate rule within a smart group, plus its supporting enums.
import Foundation
import SwiftData

public enum RuleField: String, Codable, CaseIterable {
    case lastOpened, fileSize, source, category, name
}

public enum RuleOperator: String, Codable, CaseIterable {
    case equals, notEquals, greaterThan, lessThan, contains, startsWith
}

@Model
public final class SmartGroupRule {
    public var field: RuleField
    public var op: RuleOperator
    public var value: String

    public init(field: RuleField, op: RuleOperator, value: String) {
        self.field = field
        self.op = op
        self.value = value
    }
}
