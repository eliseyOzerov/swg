import CoreGraphics
import Foundation

public extension Point {
	/// Returns this SVG point as a CoreGraphics point.
	var cgPoint: CGPoint {
		CGPoint(x: x, y: y)
	}
}

public extension Rect {
	/// Returns this SVG rectangle as a CoreGraphics rectangle.
	var cgRect: CGRect {
		CGRect(x: x, y: y, width: width, height: height)
	}
}

public extension Transform {
	/// Returns this SVG affine matrix as a CoreGraphics affine transform.
	var cgAffineTransform: CGAffineTransform {
		CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
	}
}

public extension Color {
	/// Returns this SVG color as a CoreGraphics color after multiplying its alpha.
	///
	/// - Parameter alphaMultiplier: A multiplier applied to the color's stored alpha.
	func cgColor(alphaMultiplier: Double = 1) -> CGColor {
		CGColor(red: red, green: green, blue: blue, alpha: alpha * alphaMultiplier)
	}
}

public extension LineCap {
	/// Returns the matching CoreGraphics line-cap value.
	var cgLineCap: CGLineCap {
		switch self {
		case .butt:
			return .butt
		case .round:
			return .round
		case .square:
			return .square
		}
	}
}

public extension LineJoin {
	/// Returns the matching CoreGraphics line-join value.
	var cgLineJoin: CGLineJoin {
		switch self {
		case .miter:
			return .miter
		case .round:
			return .round
		case .bevel:
			return .bevel
		}
	}
}

public extension Path {
	/// Converts this editable SVG path model into a `CGPath`.
	var cgPath: CGPath {
		let path = CGMutablePath()
		for command in commands {
			switch command {
			case .move(let point):
				path.move(to: point.cgPoint)
			case .line(let point):
				path.addLine(to: point.cgPoint)
			case .cubic(let point, let control1, let control2):
				path.addCurve(to: point.cgPoint, control1: control1.cgPoint, control2: control2.cgPoint)
			case .quad(let point, let control):
				path.addQuadCurve(to: point.cgPoint, control: control.cgPoint)
			case .arc(let center, let radius, let startAngle, let endAngle, let clockwise):
				path.addArc(center: center.cgPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
			case .ellipticalArc(let center, let radiusX, let radiusY, let startAngle, let endAngle, let clockwise):
				path.addEllipticalArc(center: center, radiusX: radiusX, radiusY: radiusY, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
			case .close:
				path.closeSubpath()
			case .rect(let rect):
				path.addRect(rect.cgRect)
			case .ellipse(let rect):
				path.addEllipse(in: rect.cgRect)
			case .roundedRect(let rect, let cornerWidth, let cornerHeight):
				path.addRoundedRect(in: rect.cgRect, cornerWidth: cornerWidth, cornerHeight: cornerHeight)
			}
		}
		return path
	}
}

private extension CGMutablePath {
	func addEllipticalArc(center: Point, radiusX: Double, radiusY: Double, startAngle: Double, endAngle: Double, clockwise: Bool) {
		let delta = clockwise ? endAngle - startAngle : startAngle - endAngle
		let segments = max(1, Int(ceil(abs(delta) / (.pi / 16))))
		for index in 1...segments {
			let progress = Double(index) / Double(segments)
			let angle = clockwise ? startAngle + delta * progress : startAngle - delta * progress
			addLine(to: CGPoint(x: center.x + cos(angle) * radiusX, y: center.y + sin(angle) * radiusY))
		}
	}
}
