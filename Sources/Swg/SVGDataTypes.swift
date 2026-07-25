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

/// Context used to resolve SVG relative length units into user units.
struct SVGLengthContext: Equatable, Sendable {
	var fontSize: Double
	var rootFontSize: Double
	var viewportWidth: Double
	var viewportHeight: Double
	var xHeight: Double?
	var zeroAdvance: Double?
	var isUprightText: Bool

	static let `default` = SVGLengthContext(fontSize: 16, rootFontSize: 16, viewportWidth: 100, viewportHeight: 100)

	init(fontSize: Double = 16, rootFontSize: Double = 16, viewportWidth: Double = 100, viewportHeight: Double = 100, xHeight: Double? = nil, zeroAdvance: Double? = nil, isUprightText: Bool = false) {
		self.fontSize = fontSize
		self.rootFontSize = rootFontSize
		self.viewportWidth = viewportWidth
		self.viewportHeight = viewportHeight
		self.xHeight = xHeight
		self.zeroAdvance = zeroAdvance
		self.isUprightText = isUprightText
	}

	var resolvedXHeight: Double {
		xHeight ?? fontSize * 0.5
	}

	var resolvedZeroAdvance: Double {
		zeroAdvance ?? (isUprightText ? fontSize : fontSize * 0.5)
	}

	var resolvedViewportMinimum: Double {
		min(viewportWidth, viewportHeight)
	}

	var resolvedViewportMaximum: Double {
		max(viewportWidth, viewportHeight)
	}

	var resolvedViewportNormalizedDiagonal: Double {
		sqrt((viewportWidth * viewportWidth) + (viewportHeight * viewportHeight)) / sqrt(2)
	}
}

/// Reference distance used to resolve an SVG percentage length into user units.
enum SVGLengthPercentageBasis: Equatable, Sendable {
	case horizontal
	case vertical
	case normalizedDiagonal
	case custom(Double)

	func referenceDistance(in context: SVGLengthContext) -> Double {
		switch self {
		case .horizontal:
			context.viewportWidth
		case .vertical:
			context.viewportHeight
		case .normalizedDiagonal:
			context.resolvedViewportNormalizedDiagonal
		case .custom(let distance):
			distance
		}
	}
}

/// Parses reusable SVG primitive data types such as unitless and scalar lengths.
enum SVGLengthParser {
	private static let fontRelativeUnits: [(suffix: String, resolve: @Sendable (SVGLengthContext) -> Double)] = [
		("rem", { $0.rootFontSize }),
		("em", { $0.fontSize }),
		("ex", { $0.resolvedXHeight }),
		("ch", { $0.resolvedZeroAdvance })
	]
	private static let viewportRelativeUnits: [(suffix: String, resolve: @Sendable (SVGLengthContext) -> Double)] = [
		("vmin", { $0.resolvedViewportMinimum / 100 }),
		("vmax", { $0.resolvedViewportMaximum / 100 }),
		("vw", { $0.viewportWidth / 100 }),
		("vh", { $0.viewportHeight / 100 })
	]
	private static let absoluteUnits: [(suffix: String, multiplier: Double)] = [
		("px", 1),
		("in", 96),
		("pt", 96 / 72),
		("pc", 16),
		("cm", 96 / 2.54),
		("mm", 96 / 25.4)
	]

	static func parse(_ value: String, context: SVGLengthContext = .default, percentageBasis: SVGLengthPercentageBasis = .normalizedDiagonal) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.hasSuffix("%") {
			let numberText = String(trimmed.dropLast())
			guard let number = SVGNumberParser.parse(numberText) else { return nil }
			return number * percentageBasis.referenceDistance(in: context) / 100
		}
		for unit in fontRelativeUnits where trimmed.hasSuffix(unit.suffix) {
			let numberText = String(trimmed.dropLast(unit.suffix.count))
			guard let number = SVGNumberParser.parse(numberText) else { return nil }
			return number * unit.resolve(context)
		}
		for unit in viewportRelativeUnits where trimmed.hasSuffix(unit.suffix) {
			let numberText = String(trimmed.dropLast(unit.suffix.count))
			guard let number = SVGNumberParser.parse(numberText) else { return nil }
			return number * unit.resolve(context)
		}
		for unit in absoluteUnits where trimmed.hasSuffix(unit.suffix) {
			let numberText = String(trimmed.dropLast(unit.suffix.count))
			guard let number = SVGNumberParser.parse(numberText) else { return nil }
			return number * unit.multiplier
		}
		return parseUnitless(trimmed)
	}

	static func parseUnitless(_ value: String) -> Double? {
		SVGNumberParser.parse(value)
	}
}
