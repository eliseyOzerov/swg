import CoreGraphics
import Foundation
import ImageIO
import Swg
import UniformTypeIdentifiers

struct FeatureExample {
	let slug: String
	let width: Int
	let height: Int
}

let featureExamples = [
	FeatureExample(slug: "shapes-basic", width: 720, height: 480),
	FeatureExample(slug: "shapes-rounded-polygons", width: 720, height: 480),
	FeatureExample(slug: "path-lines-curves", width: 720, height: 480),
	FeatureExample(slug: "path-arcs-fillrule", width: 720, height: 480),
	FeatureExample(slug: "paint-fill-opacity", width: 720, height: 480),
	FeatureExample(slug: "paint-strokes", width: 720, height: 480),
	FeatureExample(slug: "transforms-groups", width: 720, height: 480),
	FeatureExample(slug: "transforms-style", width: 720, height: 480),
]

let explicitPackageRoot = CommandLine.arguments.dropFirst().first.map { URL(fileURLWithPath: $0) }
let inferredPackageRoot = URL(fileURLWithPath: #filePath)
	.deletingLastPathComponent()
	.deletingLastPathComponent()
	.deletingLastPathComponent()
let packageRoot = explicitPackageRoot ?? inferredPackageRoot

try FeatureGalleryRenderer.renderAll(examples: featureExamples, packageRoot: packageRoot)

enum FeatureGalleryRenderer {
	static func renderAll(examples: [FeatureExample], packageRoot: URL) throws {
		let svgDirectory = packageRoot.appendingPathComponent("docs/feature-gallery/svg", isDirectory: true)
		let pngDirectory = packageRoot.appendingPathComponent("docs/feature-gallery/png", isDirectory: true)
		try FileManager.default.createDirectory(at: pngDirectory, withIntermediateDirectories: true)

		for example in examples {
			let svgURL = svgDirectory.appendingPathComponent("\(example.slug).svg")
			let pngURL = pngDirectory.appendingPathComponent("\(example.slug).png")
			let svg = try String(contentsOf: svgURL, encoding: .utf8)
			guard let document = SVGParser().parse(svg) else {
				throw FeatureGalleryError.invalidSVG(example.slug)
			}
			let image = try SVGGalleryRasterizer.render(document, width: example.width, height: example.height)
			try image.writePNG(to: pngURL)
			print("Rendered \(pngURL.path)")
		}
	}
}

enum FeatureGalleryError: Error {
	case invalidSVG(String)
	case missingContext
	case missingImage
	case missingDestination(URL)
	case imageWriteFailed(URL)
}

struct SVGGalleryRasterizer {
	static func render(_ document: SVGDocument, width: Int, height: Int) throws -> CGImage {
		guard let context = CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: width * 4,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		) else {
			throw FeatureGalleryError.missingContext
		}

		context.setShouldAntialias(true)
		context.setAllowsAntialiasing(true)
		context.interpolationQuality = .high
		context.concatenate(document.viewBoxToImageTransform(width: width, height: height))

		for element in document.elements {
			render(element, opacity: 1, in: context)
		}

		guard let image = context.makeImage() else {
			throw FeatureGalleryError.missingImage
		}
		return image
	}

	private static func render(_ element: SVGElement, opacity: Double, in context: CGContext) {
		switch element {
		case .path(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, in: context)
		case .rect(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, in: context)
		case .circle(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, in: context)
		case .ellipse(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, in: context)
		case .line(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, forceStroke: true, in: context)
		case .polygon(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, in: context)
		case .polyline(let data):
			render(path: data.path.cgPath, attributes: data.attributes, opacity: opacity, forceStroke: true, in: context)
		case .group(let data):
			render(children: data.children, attributes: data.attributes, opacity: opacity, in: context)
		case .switch(let data):
			render(children: data.children, attributes: data.attributes, opacity: opacity, in: context)
		case .link(let data):
			render(children: data.children, attributes: data.attributes, opacity: opacity, in: context)
		case .svg(let data):
			render(children: data.children, attributes: data.attributes, opacity: opacity, in: context)
		case .foreignObject(let data):
			render(children: data.children, attributes: data.attributes, opacity: opacity, in: context)
		case .unknown(let data):
			render(children: data.children, attributes: data.attributes, opacity: opacity, in: context)
		case .use, .image, .text:
			break
		}
	}

	private static func render(children: [SVGElement], attributes: SVGPaintAttributes, opacity: Double, in context: CGContext) {
		guard attributes.display != .none, attributes.visibility == .visible, attributes.opacity > 0 else { return }
		context.saveGState()
		context.concatenate(attributes.transform.cgAffineTransform)
		let childOpacity = opacity * attributes.opacity
		for child in children {
			render(child, opacity: childOpacity, in: context)
		}
		context.restoreGState()
	}

	private static func render(path: CGPath, attributes: SVGPaintAttributes, opacity: Double, forceStroke: Bool = false, in context: CGContext) {
		guard attributes.display != .none, attributes.visibility == .visible, attributes.opacity > 0 else { return }
		context.saveGState()
		context.concatenate(attributes.transform.cgAffineTransform)
		let resolvedOpacity = opacity * attributes.opacity

		for operation in attributes.paintOrder.resolvedOperations {
			switch operation {
			case .fill where !forceStroke:
				fill(path: path, attributes: attributes, opacity: resolvedOpacity, in: context)
			case .stroke:
				stroke(path: path, attributes: attributes, opacity: resolvedOpacity, in: context)
			case .markers, .fill:
				break
			}
		}

		context.restoreGState()
	}

	private static func fill(path: CGPath, attributes: SVGPaintAttributes, opacity: Double, in context: CGContext) {
		guard case .color(let color) = attributes.fill else { return }
		context.addPath(path)
		context.setFillColor(color.cgColor(alpha: attributes.fillOpacity * opacity))
		context.fillPath(using: attributes.fillRule == .evenOdd ? .evenOdd : .winding)
	}

	private static func stroke(path: CGPath, attributes: SVGPaintAttributes, opacity: Double, in context: CGContext) {
		guard case .color(let color) = attributes.stroke, attributes.strokeWidth > 0 else { return }
		context.addPath(path)
		context.setLineWidth(attributes.strokeWidth)
		context.setLineCap(attributes.strokeLineCap.cgLineCap)
		context.setLineJoin(attributes.strokeLineJoin.cgLineJoin)
		context.setMiterLimit(attributes.strokeMiterLimit)
		context.setLineDash(phase: CGFloat(attributes.strokeDashOffset), lengths: attributes.strokeDashArray.map { CGFloat($0) })
		context.setStrokeColor(color.cgColor(alpha: attributes.strokeOpacity * opacity))
		context.strokePath()
	}
}

extension SVGDocument {
	func viewBoxToImageTransform(width: Int, height: Int) -> CGAffineTransform {
		let scaleX = Double(width) / viewBox.width
		let scaleY = Double(height) / viewBox.height
		return CGAffineTransform(translationX: 0, y: CGFloat(height))
			.scaledBy(x: CGFloat(scaleX), y: CGFloat(-scaleY))
			.translatedBy(x: CGFloat(-viewBox.x), y: CGFloat(-viewBox.y))
	}
}

extension Path {
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

extension CGMutablePath {
	func addEllipticalArc(center: Point, radiusX: Double, radiusY: Double, startAngle: Double, endAngle: Double, clockwise: Bool) {
		let delta = clockwise ? endAngle - startAngle : startAngle - endAngle
		let segments = max(1, Int(ceil(abs(delta) / (.pi / 24))))
		for index in 1...segments {
			let progress = Double(index) / Double(segments)
			let angle = clockwise ? startAngle + delta * progress : startAngle - delta * progress
			addLine(to: CGPoint(x: center.x + cos(angle) * radiusX, y: center.y + sin(angle) * radiusY))
		}
	}
}

extension CGImage {
	func writePNG(to url: URL) throws {
		guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
			throw FeatureGalleryError.missingDestination(url)
		}
		CGImageDestinationAddImage(destination, self, nil)
		guard CGImageDestinationFinalize(destination) else {
			throw FeatureGalleryError.imageWriteFailed(url)
		}
	}
}

extension Point {
	var cgPoint: CGPoint {
		CGPoint(x: x, y: y)
	}
}

extension Rect {
	var cgRect: CGRect {
		CGRect(x: x, y: y, width: width, height: height)
	}
}

extension Transform {
	var cgAffineTransform: CGAffineTransform {
		CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
	}
}

extension Color {
	func cgColor(alpha: Double) -> CGColor {
		CGColor(red: red, green: green, blue: blue, alpha: self.alpha * alpha)
	}
}

extension LineCap {
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

extension LineJoin {
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
