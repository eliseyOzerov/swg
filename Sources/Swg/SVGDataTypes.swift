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

/// Parses reusable SVG primitive data types such as scalar angle values.
enum SVGAngleParser {
	private static let units: [(suffix: String, multiplier: Double)] = [
		("turn", 2 * .pi),
		("grad", .pi / 200),
		("deg", .pi / 180),
		("rad", 1)
	]

	static func parse(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		for unit in units where trimmed.hasSuffix(unit.suffix) {
			let numberText = String(trimmed.dropLast(unit.suffix.count))
			guard let number = SVGNumberParser.parse(numberText) else { return nil }
			return number * unit.multiplier
		}
		return SVGNumberParser.parse(trimmed).map { $0 * .pi / 180 }
	}
}

/// Parses reusable SVG animation clock values into seconds.
enum SVGClockValueParser {
	private static let fullClockPattern = #"^([0-9]+):([0-9]{2}):([0-9]{2})(?:\.([0-9]+))?$"#
	private static let partialClockPattern = #"^([0-9]{2}):([0-9]{2})(?:\.([0-9]+))?$"#
	private static let timecountPattern = #"^([0-9]+)(?:\.([0-9]+))?(h|min|s|ms)?$"#

	static func parse(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if let components = match(trimmed, pattern: fullClockPattern) {
			return parseFullClock(components)
		}
		if let components = match(trimmed, pattern: partialClockPattern) {
			return parsePartialClock(components)
		}
		if let components = match(trimmed, pattern: timecountPattern) {
			return parseTimecount(components)
		}
		return nil
	}

	private static func parseFullClock(_ components: [String?]) -> Double? {
		guard let hoursText = components[0], let minutesText = components[1], let secondsText = components[2] else { return nil }
		guard let hours = Double(hoursText), let minutes = parseClockComponent(minutesText), let seconds = parseClockComponent(secondsText) else { return nil }
		guard let secondValue = parseFractionalClockComponent(seconds, fraction: components[3]) else { return nil }
		return hours * 3600 + Double(minutes) * 60 + secondValue
	}

	private static func parsePartialClock(_ components: [String?]) -> Double? {
		guard let minutesText = components[0], let secondsText = components[1] else { return nil }
		guard let minutes = parseClockComponent(minutesText), let seconds = parseClockComponent(secondsText) else { return nil }
		guard let secondValue = parseFractionalClockComponent(seconds, fraction: components[2]) else { return nil }
		return Double(minutes) * 60 + secondValue
	}

	private static func parseTimecount(_ components: [String?]) -> Double? {
		guard let wholeText = components[0] else { return nil }
		let fractionText = components[1].map { ".\($0)" } ?? ""
		guard let value = Double("\(wholeText)\(fractionText)") else { return nil }
		switch components[2] {
		case "h":
			return value * 3600
		case "min":
			return value * 60
		case "ms":
			return value / 1000
		case "s", nil:
			return value
		default:
			return nil
		}
	}

	private static func parseClockComponent(_ value: String) -> Int? {
		guard let component = Int(value), (0...59).contains(component) else { return nil }
		return component
	}

	private static func parseFractionalClockComponent(_ seconds: Int, fraction: String?) -> Double? {
		let fractionText = fraction.map { ".\($0)" } ?? ""
		return Double("\(seconds)\(fractionText)")
	}

	private static func match(_ value: String, pattern: String) -> [String?]? {
		guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
		let range = NSRange(location: 0, length: (value as NSString).length)
		guard let match = regex.firstMatch(in: value, range: range), match.range == range else { return nil }
		let nsValue = value as NSString
		return (1..<match.numberOfRanges).map { index in
			let range = match.range(at: index)
			guard range.location != NSNotFound else { return nil }
			return nsValue.substring(with: range)
		}
	}
}

/// Parses reusable SVG frequency values into hertz.
enum SVGFrequencyParser {
	private static let units: [(suffix: String, multiplier: Double)] = [
		("khz", 1000),
		("hz", 1)
	]

	static func parse(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		let lowercased = trimmed.lowercased()
		for unit in units where lowercased.hasSuffix(unit.suffix) {
			let numberText = String(trimmed.dropLast(unit.suffix.count))
			guard numberText == numberText.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
			guard let number = SVGNumberParser.parse(numberText), number >= 0 else { return nil }
			return number * unit.multiplier
		}
		return nil
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
