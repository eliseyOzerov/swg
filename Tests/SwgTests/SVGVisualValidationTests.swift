#if canImport(CoreGraphics)
import CoreGraphics
import Foundation
import Testing
@testable import Swg

@Test func svgVisualValidationRendersBasicPaintFixture() throws {
	try assertVisualFixture("basic-paint")
}

@Test func svgVisualValidationRendersTransformFixture() throws {
	try assertVisualFixture("transforms")
}

private func assertVisualFixture(_ name: String) throws {
	let svgURL = try #require(visualFixtureURL(for: name, extension: "svg"))
	let goldenURL = try #require(visualFixtureURL(for: name, extension: "golden.txt"))
	let svg = try String(contentsOf: svgURL, encoding: .utf8)
	let golden = try String(contentsOf: goldenURL, encoding: .utf8)
		.split(whereSeparator: \.isNewline)
		.map(String.init)

	let document = try #require(SVGParser().parse(svg))
	let raster = try SVGVisualRasterizer.render(document, width: golden.first?.count ?? 0, height: golden.count)
	#expect(raster.symbolRows == golden)
}

private func visualFixtureURL(for name: String, extension fileExtension: String) -> URL? {
	Bundle.module.url(forResource: name, withExtension: fileExtension, subdirectory: "VisualFixtures")
		?? Bundle.module.url(forResource: name, withExtension: fileExtension)
}

private struct SVGVisualRasterizer {
	static func render(_ document: SVGDocument, width: Int, height: Int) throws -> SVGVisualRaster {
		#expect(width > 0)
		#expect(height > 0)
		var pixels = [UInt8](repeating: 0, count: width * height * 4)
		try pixels.withUnsafeMutableBytes { rawPixels in
			let colorSpace = CGColorSpaceCreateDeviceRGB()
			let context = try #require(CGContext(
				data: rawPixels.baseAddress,
				width: width,
				height: height,
				bitsPerComponent: 8,
				bytesPerRow: width * 4,
				space: colorSpace,
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
			))
			context.setShouldAntialias(false)
			context.setAllowsAntialiasing(false)
			context.concatenate(document.viewBoxToPixelTransform(width: width, height: height))
			for element in document.elements {
				render(element, in: context)
			}
			context.flush()
		}
		return SVGVisualRaster(width: width, height: height, pixels: pixels)
	}

	private static func render(_ element: SVGElement, in context: CGContext) {
		switch element {
		case .path(let data):
			render(path: data.path.cgPath, attributes: data.attributes, in: context)
		case .rect(let data):
			render(path: data.path.cgPath, attributes: data.attributes, in: context)
		case .circle(let data):
			render(path: data.path.cgPath, attributes: data.attributes, in: context)
		case .ellipse(let data):
			render(path: data.path.cgPath, attributes: data.attributes, in: context)
		case .line(let data):
			render(path: data.path.cgPath, attributes: data.attributes, forceStroke: true, in: context)
		case .polygon(let data):
			render(path: data.path.cgPath, attributes: data.attributes, in: context)
		case .polyline(let data):
			render(path: data.path.cgPath, attributes: data.attributes, forceStroke: true, in: context)
		case .group(let data):
			render(children: data.children, attributes: data.attributes, in: context)
		case .switch(let data):
			render(children: data.children, attributes: data.attributes, in: context)
		case .link(let data):
			render(children: data.children, attributes: data.attributes, in: context)
		case .svg(let data):
			render(children: data.children, attributes: data.attributes, in: context)
		case .foreignObject(let data):
			render(children: data.children, attributes: data.attributes, in: context)
		case .unknown(let data):
			render(children: data.children, attributes: data.attributes, in: context)
		case .use, .image, .text:
			break
		}
	}

	private static func render(children: [SVGElement], attributes: SVGPaintAttributes, in context: CGContext) {
		guard attributes.display != .none, attributes.visibility == .visible, attributes.opacity > 0 else { return }
		context.saveGState()
		context.concatenate(attributes.transform.cgAffineTransform)
		for child in children {
			render(child, in: context)
		}
		context.restoreGState()
	}

	private static func render(path: CGPath, attributes: SVGPaintAttributes, forceStroke: Bool = false, in context: CGContext) {
		guard attributes.display != .none, attributes.visibility == .visible, attributes.opacity > 0 else { return }
		context.saveGState()
		context.concatenate(attributes.transform.cgAffineTransform)

		if !forceStroke, case .color(let color) = attributes.fill {
			context.addPath(path)
			context.setFillColor(color.cgColor(alpha: attributes.fillOpacity * attributes.opacity))
			context.fillPath(using: attributes.fillRule == .evenOdd ? .evenOdd : .winding)
		}

		if case .color(let color) = attributes.stroke, attributes.strokeWidth > 0 {
			context.addPath(path)
			context.setLineWidth(attributes.strokeWidth)
			context.setLineCap(attributes.strokeLineCap.cgLineCap)
			context.setLineJoin(attributes.strokeLineJoin.cgLineJoin)
			context.setStrokeColor(color.cgColor(alpha: attributes.strokeOpacity * attributes.opacity))
			context.strokePath()
		}

		context.restoreGState()
	}
}

private struct SVGVisualRaster {
	let width: Int
	let height: Int
	let pixels: [UInt8]

	var symbolRows: [String] {
		stride(from: height - 1, through: 0, by: -1).map { y in
			String((0..<width).map { symbol(atX: $0, y: y) })
		}
	}

	private func symbol(atX x: Int, y: Int) -> Character {
		let index = (y * width + x) * 4
		let red = pixels[index]
		let green = pixels[index + 1]
		let blue = pixels[index + 2]
		let alpha = pixels[index + 3]
		if alpha < 16 { return "." }
		if red > 240, green > 240, blue > 240 { return "W" }
		if red > 200, green < 80, blue < 80 { return "R" }
		if red < 80, green > 200, blue < 80 { return "G" }
		if red < 80, green < 80, blue > 200 { return "B" }
		return "?"
	}
}

private extension SVGDocument {
	func viewBoxToPixelTransform(width: Int, height: Int) -> CGAffineTransform {
		CGAffineTransform(
			a: CGFloat(Double(width) / viewBox.width),
			b: 0,
			c: 0,
			d: CGFloat(Double(height) / viewBox.height),
			tx: CGFloat(-viewBox.x * Double(width) / viewBox.width),
			ty: CGFloat(-viewBox.y * Double(height) / viewBox.height)
		)
	}
}

private extension Path {
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

private extension Point {
	var cgPoint: CGPoint {
		CGPoint(x: x, y: y)
	}
}

private extension Rect {
	var cgRect: CGRect {
		CGRect(x: x, y: y, width: width, height: height)
	}
}

private extension Transform {
	var cgAffineTransform: CGAffineTransform {
		CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
	}
}

private extension Color {
	func cgColor(alpha: Double) -> CGColor {
		CGColor(red: red, green: green, blue: blue, alpha: self.alpha * alpha)
	}
}

private extension LineCap {
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

private extension LineJoin {
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
#endif
