import Foundation

/// A two-dimensional point used by SVG geometry and path commands.
public struct Point: Equatable, Hashable, Sendable {
	public var x: Double
	public var y: Double

	public init(_ x: Double, _ y: Double) {
		self.x = x
		self.y = y
	}

	public static let zero = Point(0, 0)

	public func distance(to other: Point) -> Double {
		hypot(other.x - x, other.y - y)
	}

	public func applying(_ transform: Transform) -> Point {
		Point(
			x * transform.a + y * transform.c + transform.tx,
			x * transform.b + y * transform.d + transform.ty
		)
	}

	public static func + (lhs: Point, rhs: Point) -> Point {
		Point(lhs.x + rhs.x, lhs.y + rhs.y)
	}

	public static func - (lhs: Point, rhs: Point) -> Point {
		Point(lhs.x - rhs.x, lhs.y - rhs.y)
	}

	public static func * (lhs: Point, rhs: Double) -> Point {
		Point(lhs.x * rhs, lhs.y * rhs)
	}

	public static func * (lhs: Double, rhs: Point) -> Point {
		Point(lhs * rhs.x, lhs * rhs.y)
	}
}

/// An axis-aligned rectangle used for SVG view boxes and path bounds.
public struct Rect: Equatable, Hashable, Sendable {
	public var x: Double
	public var y: Double
	public var width: Double
	public var height: Double

	public init(x: Double, y: Double, width: Double, height: Double) {
		self.x = x
		self.y = y
		self.width = width
		self.height = height
	}

	public static let zero = Rect(x: 0, y: 0, width: 0, height: 0)

	public var left: Double { x }
	public var right: Double { x + width }
	public var top: Double { y }
	public var bottom: Double { y + height }
	public var midX: Double { x + width / 2 }
	public var midY: Double { y + height / 2 }
	public var center: Point { Point(midX, midY) }
	public var topLeft: Point { Point(left, top) }
	public var topRight: Point { Point(right, top) }
	public var bottomRight: Point { Point(right, bottom) }
	public var bottomLeft: Point { Point(left, bottom) }
	public var isZero: Bool { x == 0 && y == 0 && width == 0 && height == 0 }

	public static func fromCircle(center: Point, radius: Double) -> Rect {
		Rect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
	}

	public static func fromPoints(_ points: [Point]) -> Rect {
		guard let first = points.first else { return .zero }
		var minX = first.x
		var minY = first.y
		var maxX = first.x
		var maxY = first.y
		for point in points.dropFirst() {
			minX = min(minX, point.x)
			minY = min(minY, point.y)
			maxX = max(maxX, point.x)
			maxY = max(maxY, point.y)
		}
		return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
	}
}

/// A 2D affine transform matching SVG's six-value matrix model.
public struct Transform: Equatable, Hashable, Sendable {
	public var a: Double
	public var b: Double
	public var c: Double
	public var d: Double
	public var tx: Double
	public var ty: Double

	public init(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double) {
		self.a = a
		self.b = b
		self.c = c
		self.d = d
		self.tx = tx
		self.ty = ty
	}

	public static let identity = Transform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

	public func translatedBy(x: Double, y: Double) -> Transform {
		concatenating(Transform(a: 1, b: 0, c: 0, d: 1, tx: x, ty: y))
	}

	public func scaledBy(x: Double, y: Double) -> Transform {
		concatenating(Transform(a: x, b: 0, c: 0, d: y, tx: 0, ty: 0))
	}

	public func rotated(by angle: Double) -> Transform {
		let cosine = cos(angle)
		let sine = sin(angle)
		return concatenating(Transform(a: cosine, b: sine, c: -sine, d: cosine, tx: 0, ty: 0))
	}

	public func rotated(by angle: Double, center: Point) -> Transform {
		translatedBy(x: center.x, y: center.y)
			.rotated(by: angle)
			.translatedBy(x: -center.x, y: -center.y)
	}

	public func concatenating(_ other: Transform) -> Transform {
		Transform(
			a: a * other.a + c * other.b,
			b: b * other.a + d * other.b,
			c: a * other.c + c * other.d,
			d: b * other.c + d * other.d,
			tx: a * other.tx + c * other.ty + tx,
			ty: b * other.tx + d * other.ty + ty
		)
	}
}
