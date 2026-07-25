import Foundation

/// The fill rule used when interpreting SVG path interiors.
public enum FillRule: Sendable, Equatable, Hashable {
	case winding
	case evenOdd
}

/// The stroke line cap used by SVG stroke rendering.
public enum LineCap: Sendable, Equatable, Hashable {
	case butt
	case round
	case square
}

/// The stroke line join used by SVG stroke rendering.
public enum LineJoin: Sendable, Equatable, Hashable {
	case miter
	case round
	case bevel
}

/// An inspectable SVG-compatible path instruction.
public enum PathCommand: Equatable, Hashable, Sendable {
	case move(to: Point)
	case line(to: Point)
	case cubic(to: Point, control1: Point, control2: Point)
	case quad(to: Point, control: Point)
	case arc(center: Point, radius: Double, startAngle: Double, endAngle: Double, clockwise: Bool)
	case ellipticalArc(center: Point, radiusX: Double, radiusY: Double, startAngle: Double, endAngle: Double, clockwise: Bool)
	case close
	case rect(Rect)
	case ellipse(Rect)
	case roundedRect(Rect, cornerWidth: Double, cornerHeight: Double)
}

/// An editable vector path represented by SVG-compatible commands.
public struct Path: Equatable, Hashable, Sendable {
	public var commands: [PathCommand]

	public init(commands: [PathCommand] = []) {
		self.commands = commands
	}

	public mutating func move(to point: Point) {
		commands.append(.move(to: point))
	}

	public mutating func line(to point: Point) {
		commands.append(.line(to: point))
	}

	public mutating func curve(to point: Point, control1: Point, control2: Point) {
		commands.append(.cubic(to: point, control1: control1, control2: control2))
	}

	public mutating func quadCurve(to point: Point, control: Point) {
		commands.append(.quad(to: point, control: control))
	}

	public mutating func arc(center: Point, radius: Double, startAngle: Double, endAngle: Double, clockwise: Bool) {
		commands.append(.arc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise))
	}

	public mutating func ellipticalArc(center: Point, radiusX: Double, radiusY: Double, startAngle: Double, endAngle: Double, clockwise: Bool) {
		commands.append(.ellipticalArc(center: center, radiusX: radiusX, radiusY: radiusY, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise))
	}

	public mutating func close() {
		commands.append(.close)
	}

	public mutating func addPath(_ other: Path) {
		commands.append(contentsOf: other.commands)
	}

	public static func line(from: Point, to: Point) -> Path {
		var path = Path()
		path.move(to: from)
		path.line(to: to)
		return path
	}

	public static func polyline(_ points: [Point]) -> Path {
		var path = Path()
		guard let first = points.first else { return path }
		path.move(to: first)
		for point in points.dropFirst() {
			path.line(to: point)
		}
		return path
	}

	public static func polygon(_ points: [Point]) -> Path {
		var path = polyline(points)
		path.close()
		return path
	}
}
