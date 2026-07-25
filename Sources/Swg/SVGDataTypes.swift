import Foundation

/// Parses reusable SVG primitive data types such as the generic integer grammar.
enum SVGIntegerParser {
	private static let pattern = #"^[+-]?[0-9]+$"#

	static func parse(_ value: String) -> Int? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.range(of: pattern, options: .regularExpression) != nil else { return nil }
		return Int(trimmed)
	}
}
