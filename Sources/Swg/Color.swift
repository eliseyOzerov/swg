import Foundation

/// An RGBA color used by parsed SVG paint, gradients, filters, and overrides.
public struct Color: Equatable, Hashable, Sendable {
	public var red: Double
	public var green: Double
	public var blue: Double
	public var alpha: Double

	public init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) {
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}

	public func withAlpha(_ alpha: Double) -> Color {
		Color(red, green, blue, alpha)
	}

	public static let black = Color(0, 0, 0)
	public static let white = Color(1, 1, 1)
	public static let clear = Color(0, 0, 0, 0)
	public static let red = Color(1, 0, 0)
	public static let green = Color(0, 1, 0)
	public static let blue = Color(0, 0, 1)
	public static let gray = Color(0.5, 0.5, 0.5)
}
