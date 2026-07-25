import Foundation

/// Parses reusable SVG primitive data types such as the generic number grammar.
enum SVGNumberParser {
	private static let pattern = #"^[+-]?(?:(?:[0-9]+(?:[Ee][+-]?[0-9]+)?)|(?:[0-9]*\.[0-9]+(?:[Ee][+-]?[0-9]+)?))$"#

	static func parse(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.range(of: pattern, options: .regularExpression) != nil else { return nil }
		guard let number = Double(trimmed), number.isFinite else { return nil }
		return number
	}
}

/// Parses reusable SVG primitive data types such as the generic integer grammar.
enum SVGIntegerParser {
	private static let pattern = #"^[+-]?[0-9]+$"#

	static func parse(_ value: String) -> Int? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.range(of: pattern, options: .regularExpression) != nil else { return nil }
		return Int(trimmed)
	}
}

/// Parses reusable SVG primitive data types such as unitless lengths.
enum SVGLengthParser {
	static func parseUnitless(_ value: String) -> Double? {
		SVGNumberParser.parse(value)
	}
}
