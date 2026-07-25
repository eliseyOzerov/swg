import Foundation

/// Parses and serializes SVG path `d` attributes.
public enum SVGPathDataParser {
	public static func parse(_ data: String) -> Path {
		Path(commands: parseCommands(data))
	}

	public static func parseCommands(_ data: String) -> [PathCommand] {
		var builder = PathCommandBuilder()
		let tokens = tokenize(data)
		var index = 0
		var current = Point.zero
		var lastCubicControlPoint: Point?
		var lastQuadraticControlPoint: Point?
		var lastCommand: Character = " "
		var subpathStart = Point.zero

		func nextNumber() -> Double? {
			guard index < tokens.count, case .number(let value) = tokens[index] else { return nil }
			index += 1
			return value
		}

		func nextPoint() -> Point? {
			guard let x = nextNumber(), let y = nextNumber() else { return nil }
			return Point(x, y)
		}

		while index < tokens.count {
			let command: Character
			if case .command(let value) = tokens[index] {
				command = value
				index += 1
			} else {
				command = lastCommand
			}

			let isRelative = command.isLowercase
			let absoluteCommand = Character(String(command).uppercased())

			switch absoluteCommand {
			case "M":
				guard let point = nextPoint() else { break }
				let target = isRelative ? current + point : point
				builder.move(to: target)
				current = target
				subpathStart = target
				lastCubicControlPoint = nil
				lastQuadraticControlPoint = nil
				lastCommand = isRelative ? "l" : "L"
				continue

			case "L":
				guard let point = nextPoint() else { break }
				let target = isRelative ? current + point : point
				builder.line(to: target)
				current = target
				lastCubicControlPoint = nil
				lastQuadraticControlPoint = nil

			case "H":
				guard let x = nextNumber() else { break }
				let target = Point(isRelative ? current.x + x : x, current.y)
				builder.line(to: target)
				current = target
				lastCubicControlPoint = nil
				lastQuadraticControlPoint = nil

			case "V":
				guard let y = nextNumber() else { break }
				let target = Point(current.x, isRelative ? current.y + y : y)
				builder.line(to: target)
				current = target
				lastCubicControlPoint = nil
				lastQuadraticControlPoint = nil

			case "C":
				guard let control1 = nextPoint(), let control2 = nextPoint(), let end = nextPoint() else { break }
				let absoluteControl1 = isRelative ? current + control1 : control1
				let absoluteControl2 = isRelative ? current + control2 : control2
				let absoluteEnd = isRelative ? current + end : end
				builder.cubic(to: absoluteEnd, control1: absoluteControl1, control2: absoluteControl2)
				lastCubicControlPoint = absoluteControl2
				lastQuadraticControlPoint = nil
				current = absoluteEnd

			case "S":
				guard let control2 = nextPoint(), let end = nextPoint() else { break }
				let absoluteControl1 = lastCubicControlPoint.map { current * 2 - $0 } ?? current
				let absoluteControl2 = isRelative ? current + control2 : control2
				let absoluteEnd = isRelative ? current + end : end
				builder.cubic(to: absoluteEnd, control1: absoluteControl1, control2: absoluteControl2)
				lastCubicControlPoint = absoluteControl2
				lastQuadraticControlPoint = nil
				current = absoluteEnd

			case "Q":
				guard let control = nextPoint(), let end = nextPoint() else { break }
				let absoluteControl = isRelative ? current + control : control
				let absoluteEnd = isRelative ? current + end : end
				builder.quad(to: absoluteEnd, control: absoluteControl)
				lastQuadraticControlPoint = absoluteControl
				lastCubicControlPoint = nil
				current = absoluteEnd

			case "T":
				guard let end = nextPoint() else { break }
				let absoluteControl = lastQuadraticControlPoint.map { current * 2 - $0 } ?? current
				let absoluteEnd = isRelative ? current + end : end
				builder.quad(to: absoluteEnd, control: absoluteControl)
				lastQuadraticControlPoint = absoluteControl
				lastCubicControlPoint = nil
				current = absoluteEnd

			case "A":
				guard let rx = nextNumber(), let ry = nextNumber(), let rotation = nextNumber(),
					  let largeArc = nextNumber(), let sweep = nextNumber(), let end = nextPoint() else { break }
				let absoluteEnd = isRelative ? current + end : end
				addArc(
					to: &builder,
					from: current,
					to: absoluteEnd,
					rx: abs(rx),
					ry: abs(ry),
					xRotation: rotation,
					largeArc: largeArc != 0,
					sweep: sweep != 0
				)
				current = absoluteEnd
				lastCubicControlPoint = nil
				lastQuadraticControlPoint = nil

			case "Z":
				builder.close()
				current = subpathStart
				lastCubicControlPoint = nil
				lastQuadraticControlPoint = nil

			default:
				break
			}

			lastCommand = command
		}

		return builder.commands
	}

	public static func serialize(_ path: Path, precision: Int = 3) -> String {
		serialize(path.commands, precision: precision)
	}

	public static func serialize(_ commands: [PathCommand], precision: Int = 3) -> String {
		var parts: [String] = []
		var current: Point?

		for command in commands {
			switch command {
			case .move(let point):
				parts.append("M \(format(point, precision: precision))")
				current = point
			case .line(let point):
				parts.append("L \(format(point, precision: precision))")
				current = point
			case .cubic(let point, let control1, let control2):
				parts.append("C \(format(control1, precision: precision)) \(format(control2, precision: precision)) \(format(point, precision: precision))")
				current = point
			case .quad(let point, let control):
				parts.append("Q \(format(control, precision: precision)) \(format(point, precision: precision))")
				current = point
			case .arc(let center, let radius, let startAngle, let endAngle, let clockwise):
				let start = Point(center.x + cos(startAngle) * radius, center.y + sin(startAngle) * radius)
				let end = Point(center.x + cos(endAngle) * radius, center.y + sin(endAngle) * radius)
				if current?.distance(to: start) ?? .infinity > 0.000001 {
					parts.append("L \(format(start, precision: precision))")
				}
				let delta = normalizedArcDelta(from: startAngle, to: endAngle, clockwise: clockwise)
				let largeArc = abs(delta) > .pi ? 1 : 0
				let sweep = clockwise ? 1 : 0
				parts.append("A \(format(radius, precision: precision)) \(format(radius, precision: precision)) 0 \(largeArc) \(sweep) \(format(end, precision: precision))")
				current = end
			case .ellipticalArc(let center, let radiusX, let radiusY, let startAngle, let endAngle, let clockwise):
				let start = Point(center.x + cos(startAngle) * radiusX, center.y + sin(startAngle) * radiusY)
				let end = Point(center.x + cos(endAngle) * radiusX, center.y + sin(endAngle) * radiusY)
				if current?.distance(to: start) ?? .infinity > 0.000001 {
					parts.append("L \(format(start, precision: precision))")
				}
				let delta = normalizedArcDelta(from: startAngle, to: endAngle, clockwise: clockwise)
				let largeArc = abs(delta) > .pi ? 1 : 0
				let sweep = clockwise ? 1 : 0
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 \(largeArc) \(sweep) \(format(end, precision: precision))")
				current = end
			case .close:
				parts.append("Z")
			case .rect(let rect):
				let points = [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]
				guard let first = points.first else { break }
				parts.append("M \(format(first, precision: precision))")
				for point in points.dropFirst() {
					parts.append("L \(format(point, precision: precision))")
				}
				parts.append("Z")
				current = first
			case .ellipse(let rect):
				let radiusX = rect.width / 2
				let radiusY = rect.height / 2
				let left = Point(rect.left, rect.midY)
				let right = Point(rect.right, rect.midY)
				parts.append("M \(format(left, precision: precision))")
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 1 1 \(format(right, precision: precision))")
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 1 1 \(format(left, precision: precision))")
				parts.append("Z")
				current = left
			case .roundedRect(let rect, let cornerWidth, let cornerHeight):
				let radiusX = min(cornerWidth, rect.width / 2)
				let radiusY = min(cornerHeight, rect.height / 2)
				let topLeft = Point(rect.left + radiusX, rect.top)
				parts.append("M \(format(topLeft, precision: precision))")
				parts.append("L \(format(Point(rect.right - radiusX, rect.top), precision: precision))")
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 0 1 \(format(Point(rect.right, rect.top + radiusY), precision: precision))")
				parts.append("L \(format(Point(rect.right, rect.bottom - radiusY), precision: precision))")
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 0 1 \(format(Point(rect.right - radiusX, rect.bottom), precision: precision))")
				parts.append("L \(format(Point(rect.left + radiusX, rect.bottom), precision: precision))")
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 0 1 \(format(Point(rect.left, rect.bottom - radiusY), precision: precision))")
				parts.append("L \(format(Point(rect.left, rect.top + radiusY), precision: precision))")
				parts.append("A \(format(radiusX, precision: precision)) \(format(radiusY, precision: precision)) 0 0 1 \(format(topLeft, precision: precision))")
				parts.append("Z")
				current = topLeft
			}
		}

		return parts.joined(separator: " ")
	}

	private static func addArc(
		to builder: inout PathCommandBuilder,
		from p1: Point,
		to p2: Point,
		rx: Double,
		ry: Double,
		xRotation: Double,
		largeArc: Bool,
		sweep: Bool
	) {
		guard rx > 0, ry > 0, p1 != p2 else {
			if p1 != p2 {
				builder.line(to: p2)
			}
			return
		}

		let phi = xRotation * .pi / 180
		let cosPhi = cos(phi)
		let sinPhi = sin(phi)
		let dx = (p1.x - p2.x) / 2
		let dy = (p1.y - p2.y) / 2
		let x1p = cosPhi * dx + sinPhi * dy
		let y1p = -sinPhi * dx + cosPhi * dy
		var rxSquared = rx * rx
		var rySquared = ry * ry
		let x1pSquared = x1p * x1p
		let y1pSquared = y1p * y1p
		let lambda = x1pSquared / rxSquared + y1pSquared / rySquared
		var correctedRX = rx
		var correctedRY = ry

		if lambda > 1 {
			let scale = sqrt(lambda)
			correctedRX = scale * rx
			correctedRY = scale * ry
			rxSquared = correctedRX * correctedRX
			rySquared = correctedRY * correctedRY
		}

		let numerator = max(0, rxSquared * rySquared - rxSquared * y1pSquared - rySquared * x1pSquared)
		let denominator = rxSquared * y1pSquared + rySquared * x1pSquared
		var root = denominator > 0 ? sqrt(numerator / denominator) : 0
		if largeArc == sweep {
			root = -root
		}

		let cxp = root * correctedRX * y1p / correctedRY
		let cyp = -root * correctedRY * x1p / correctedRX
		let midpointX = (p1.x + p2.x) / 2
		let midpointY = (p1.y + p2.y) / 2
		let centerX = cosPhi * cxp - sinPhi * cyp + midpointX
		let centerY = sinPhi * cxp + cosPhi * cyp + midpointY

		func angle(ux: Double, uy: Double, vx: Double, vy: Double) -> Double {
			let dot = ux * vx + uy * vy
			let length = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
			var value = length > 0 ? acos(max(-1, min(1, dot / length))) : 0
			if ux * vy - uy * vx < 0 {
				value = -value
			}
			return value
		}

		let theta1 = angle(
			ux: 1,
			uy: 0,
			vx: (x1p - cxp) / correctedRX,
			vy: (y1p - cyp) / correctedRY
		)
		var deltaTheta = angle(
			ux: (x1p - cxp) / correctedRX,
			uy: (y1p - cyp) / correctedRY,
			vx: (-x1p - cxp) / correctedRX,
			vy: (-y1p - cyp) / correctedRY
		)

		if !sweep && deltaTheta > 0 {
			deltaTheta -= 2 * .pi
		} else if sweep && deltaTheta < 0 {
			deltaTheta += 2 * .pi
		}

		let segmentCount = max(1, Int(ceil(abs(deltaTheta) / (.pi / 2))))
		let segmentAngle = deltaTheta / Double(segmentCount)

		for segment in 0..<segmentCount {
			let angle1 = theta1 + Double(segment) * segmentAngle
			let angle2 = angle1 + segmentAngle
			let alpha = sin(segmentAngle) * (sqrt(4 + 3 * pow(tan(segmentAngle / 2), 2)) - 1) / 3
			let cos1 = cos(angle1)
			let sin1 = sin(angle1)
			let cos2 = cos(angle2)
			let sin2 = sin(angle2)

			func transform(_ x: Double, _ y: Double) -> Point {
				Point(cosPhi * x - sinPhi * y + centerX, sinPhi * x + cosPhi * y + centerY)
			}

			let control1 = transform(correctedRX * (cos1 - alpha * sin1), correctedRY * (sin1 + alpha * cos1))
			let control2 = transform(correctedRX * (cos2 + alpha * sin2), correctedRY * (sin2 - alpha * cos2))
			let end = transform(correctedRX * cos2, correctedRY * sin2)
			builder.cubic(to: end, control1: control1, control2: control2)
		}
	}

	private static func format(_ point: Point, precision: Int) -> String {
		"\(format(point.x, precision: precision)) \(format(point.y, precision: precision))"
	}

	private static func format(_ value: Double, precision: Int) -> String {
		let multiplier = pow(10, Double(max(0, precision)))
		let rounded = (value * multiplier).rounded() / multiplier
		if rounded == 0 {
			return "0"
		}

		var string = String(format: "%.\(max(0, precision))f", rounded)
		while string.contains(".") && string.last == "0" {
			string.removeLast()
		}
		if string.last == "." {
			string.removeLast()
		}
		return string
	}

	private static func normalizedArcDelta(from start: Double, to end: Double, clockwise: Bool) -> Double {
		var delta = end - start
		if clockwise {
			while delta < 0 {
				delta += 2 * .pi
			}
		} else {
			while delta > 0 {
				delta -= 2 * .pi
			}
		}
		return delta
	}

	private enum Token {
		case command(Character)
		case number(Double)
	}

	private static func tokenize(_ data: String) -> [Token] {
		var tokens: [Token] = []
		let characters = Array(data)
		var index = 0

		while index < characters.count {
			let character = characters[index]

			if character.isWhitespace || character == "," {
				index += 1
				continue
			}

			if "MmLlHhVvCcSsQqTtAaZz".contains(character) {
				tokens.append(.command(character))
				index += 1
				continue
			}

			if character == "-" || character == "+" || character == "." || character.isNumber {
				var number = ""
				var hasDot = false

				if character == "-" || character == "+" {
					number.append(character)
					index += 1
				}

				while index < characters.count {
					let current = characters[index]
					if current.isNumber {
						number.append(current)
						index += 1
					} else if current == "." && !hasDot {
						hasDot = true
						number.append(current)
						index += 1
					} else {
						break
					}
				}

				if index < characters.count && (characters[index] == "e" || characters[index] == "E") {
					number.append(characters[index])
					index += 1

					if index < characters.count && (characters[index] == "+" || characters[index] == "-") {
						number.append(characters[index])
						index += 1
					}

					while index < characters.count && characters[index].isNumber {
						number.append(characters[index])
						index += 1
					}
				}

				if let value = Double(number) {
					tokens.append(.number(value))
				}
				continue
			}

			index += 1
		}

		return tokens
	}
}

public extension Path {
	init(svgPathData: String) {
		self = SVGPathDataParser.parse(svgPathData)
	}

	func svgPathData(precision: Int = 3) -> String {
		SVGPathDataParser.serialize(self, precision: precision)
	}
}

public extension SVGPathData {
	var path: Path {
		SVGPathDataParser.parse(d)
	}

	init(id: String, path: Path, attributes: SVGPaintAttributes = .defaults, precision: Int = 3) {
		self.init(id: id, d: path.svgPathData(precision: precision), attributes: attributes)
	}
}

public extension SVGRectData {
	/// The equivalent path for this rectangle.
	var path: Path {
		guard width > 0, height > 0 else { return Path() }
		let radii = usedCornerRadii
		let rect = Rect(x: x, y: y, width: width, height: height)
		guard radii.x > 0, radii.y > 0 else {
			return Path(commands: [.rect(rect)])
		}
		return Path(commands: [.roundedRect(rect, cornerWidth: radii.x, cornerHeight: radii.y)])
	}

	/// The used rounded-corner radii after resolving auto values and clamping.
	var usedCornerRadii: (x: Double, y: Double) {
		let hasRX = !rxIsAuto && rx >= 0
		let hasRY = !ryIsAuto && ry >= 0
		guard hasRX || hasRY else { return (0, 0) }

		let resolvedRX: Double
		let resolvedRY: Double
		if hasRX, hasRY {
			resolvedRX = rx
			resolvedRY = ry
		} else if hasRX {
			resolvedRX = rx
			resolvedRY = rx
		} else {
			resolvedRX = ry
			resolvedRY = ry
		}

		guard resolvedRX > 0, resolvedRY > 0 else { return (0, 0) }
		return (min(resolvedRX, width / 2), min(resolvedRY, height / 2))
	}
}

public extension SVGCircleData {
	/// The equivalent path for this circle.
	var path: Path {
		guard r > 0 else { return Path() }
		let center = Point(cx, cy)
		return Path(commands: [
			.move(to: Point(cx + r, cy)),
			.arc(center: center, radius: r, startAngle: 0, endAngle: .pi / 2, clockwise: true),
			.arc(center: center, radius: r, startAngle: .pi / 2, endAngle: .pi, clockwise: true),
			.arc(center: center, radius: r, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true),
			.arc(center: center, radius: r, startAngle: .pi * 3 / 2, endAngle: .pi * 2, clockwise: true),
			.close,
		])
	}
}

public extension SVGEllipseData {
	/// The equivalent path for this ellipse.
	var path: Path {
		let radii = usedRadii
		guard radii.x > 0, radii.y > 0 else { return Path() }
		let center = Point(cx, cy)
		return Path(commands: [
			.move(to: Point(cx + radii.x, cy)),
			.ellipticalArc(center: center, radiusX: radii.x, radiusY: radii.y, startAngle: 0, endAngle: .pi / 2, clockwise: true),
			.ellipticalArc(center: center, radiusX: radii.x, radiusY: radii.y, startAngle: .pi / 2, endAngle: .pi, clockwise: true),
			.ellipticalArc(center: center, radiusX: radii.x, radiusY: radii.y, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true),
			.ellipticalArc(center: center, radiusX: radii.x, radiusY: radii.y, startAngle: .pi * 3 / 2, endAngle: .pi * 2, clockwise: true),
			.close,
		])
	}

	/// The used ellipse radii after resolving auto values.
	var usedRadii: (x: Double, y: Double) {
		let hasRX = !rxIsAuto && rx >= 0
		let hasRY = !ryIsAuto && ry >= 0
		guard hasRX || hasRY else { return (0, 0) }

		if hasRX, hasRY {
			return (rx, ry)
		} else if hasRX {
			return (rx, rx)
		} else {
			return (ry, ry)
		}
	}
}

private struct PathCommandBuilder {
	var commands: [PathCommand] = []

	mutating func move(to point: Point) {
		commands.append(.move(to: point))
	}

	mutating func line(to point: Point) {
		commands.append(.line(to: point))
	}

	mutating func cubic(to point: Point, control1: Point, control2: Point) {
		commands.append(.cubic(to: point, control1: control1, control2: control2))
	}

	mutating func quad(to point: Point, control: Point) {
		commands.append(.quad(to: point, control: control))
	}

	mutating func close() {
		commands.append(.close)
	}
}
