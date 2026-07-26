import CoreGraphics
import Foundation
import SwiftUI

/// Controls how `SVGView` maps a parsed document into SwiftUI layout and drawing.
public struct SVGRenderOptions {
	public var contentMode: ContentMode
	public var preserveAspectRatio: SVGPreserveAspectRatio?
	public var opacity: Double

	public init(contentMode: ContentMode = .fit, preserveAspectRatio: SVGPreserveAspectRatio? = nil, opacity: Double = 1) {
		self.contentMode = contentMode
		self.preserveAspectRatio = preserveAspectRatio
		self.opacity = opacity
	}
}

/// A SwiftUI view that renders an `SVGDocument` with the package's native path renderer.
public struct SVGView: View {
	public var document: SVGDocument
	public var options: SVGRenderOptions

	public init(_ document: SVGDocument, options: SVGRenderOptions = SVGRenderOptions()) {
		self.document = document
		self.options = options
	}

	public init?(svg source: String, parser: SVGParser = SVGParser(), options: SVGRenderOptions = SVGRenderOptions()) {
		guard let document = parser.parse(source) else { return nil }
		self.init(document, options: options)
	}

	public var body: some View {
		Canvas { context, size in
			let renderer = SVGCanvasRenderer(document: document, size: size, options: options)
			renderer.render(in: &context)
		}
		.aspectRatio(document.viewBox.aspectRatio, contentMode: options.contentMode)
	}
}

public typealias SWGView = SVGView

private struct SVGCanvasRenderer {
	var document: SVGDocument
	var size: CGSize
	var options: SVGRenderOptions

	func render(in context: inout GraphicsContext) {
		guard size.width > 0, size.height > 0 else { return }
		guard let transform = (options.preserveAspectRatio ?? document.preserveAspectRatio).viewBoxTransform(
			from: document.viewBox,
			to: Rect(x: 0, y: 0, width: size.width, height: size.height)
		) else { return }

		context.drawLayer { layer in
			layer.concatenate(transform.cgAffineTransform)
			for element in document.elements {
				render(element, opacity: options.opacity, in: &layer)
			}
		}
	}

	private func render(_ element: SVGElement, opacity: Double, in context: inout GraphicsContext) {
		switch element {
		case .path(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .rect(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .circle(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .ellipse(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .line(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: true, in: &context)
		case .polygon(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .polyline(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: true, in: &context)
		case .group(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .switch(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .link(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .svg(let data):
			render(viewport: data, inheritedOpacity: opacity, in: &context)
		case .unknown(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .foreignObject(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .use(let data):
			render(use: data, inheritedOpacity: opacity, in: &context)
		case .image, .text:
			break
		}
	}

	private func render(children: [SVGElement], attributes: SVGPaintAttributes, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(attributes.transform.cgAffineTransform)
			let opacity = inheritedOpacity * attributes.opacity
			for child in children {
				render(child, opacity: opacity, in: &layer)
			}
		}
	}

	private func render(viewport data: SVGViewportData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.cgAffineTransform)
			if let viewBox = data.viewBox, let transform = data.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			) {
				layer.concatenate(transform.cgAffineTransform)
			} else {
				layer.concatenate(Transform.identity.translatedBy(x: data.x, y: data.y).cgAffineTransform)
			}
			let opacity = inheritedOpacity * data.attributes.opacity
			for child in data.children {
				render(child, opacity: opacity, in: &layer)
			}
		}
	}

	private func render(use data: SVGUseData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.translatedBy(x: data.x, y: data.y).cgAffineTransform)
			let opacity = inheritedOpacity * data.attributes.opacity
			if let elements = document.defs.reusableElements[referenceID] {
				for element in elements {
					render(element, opacity: opacity, in: &layer)
				}
			} else if let symbol = document.defs.symbols[referenceID] {
				render(symbol: symbol, use: data, opacity: opacity, in: &layer)
			}
		}
	}

	private func render(symbol: SVGSymbolData, use data: SVGUseData, opacity: Double, in context: inout GraphicsContext) {
		let width = data.width ?? symbol.width
		let height = data.height ?? symbol.height
		if let viewBox = symbol.viewBox, let transform = symbol.preserveAspectRatio.viewBoxTransform(
			from: viewBox,
			to: Rect(x: symbol.x, y: symbol.y, width: width, height: height)
		) {
			context.concatenate(transform.cgAffineTransform)
		}
		for child in symbol.children {
			render(child, opacity: opacity * symbol.attributes.opacity, in: &context)
		}
	}

	private func render(path cgPath: CGPath, attributes: SVGPaintAttributes, inheritedOpacity: Double, forceStroke: Bool, in context: inout GraphicsContext) {
		guard attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(attributes.transform.cgAffineTransform)
			let path = SwiftUI.Path(cgPath)
			let opacity = inheritedOpacity * attributes.opacity
			for operation in attributes.paintOrder.resolvedOperations {
				switch operation {
				case .fill:
					if !forceStroke, let color = swiftUIColor(from: attributes.fill, currentColor: attributes.color, opacity: opacity * attributes.fillOpacity) {
						layer.fill(path, with: .color(color), style: FillStyle(eoFill: attributes.fillRule == .evenOdd))
					}
				case .stroke:
					if let color = swiftUIColor(from: attributes.stroke, currentColor: attributes.color, opacity: opacity * attributes.strokeOpacity), attributes.strokeWidth > 0 {
						layer.stroke(path, with: .color(color), style: StrokeStyle(
							lineWidth: CGFloat(attributes.strokeWidth),
							lineCap: attributes.strokeLineCap.cgLineCap,
							lineJoin: attributes.strokeLineJoin.cgLineJoin,
							miterLimit: CGFloat(attributes.strokeMiterLimit),
							dash: attributes.strokeDashArray.map { CGFloat($0) },
							dashPhase: CGFloat(attributes.strokeDashOffset)
						))
					}
				case .markers:
					break
				}
			}
		}
	}

	private func swiftUIColor(from paint: SVGPaint, currentColor: Color, opacity: Double) -> SwiftUI.Color? {
		switch paint {
		case .none, .url, .contextFill, .contextStroke:
			return nil
		case .color(let color):
			return SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha * opacity)
		case .currentColor:
			return SwiftUI.Color(red: currentColor.red, green: currentColor.green, blue: currentColor.blue, opacity: currentColor.alpha * opacity)
		case .urlWithFallback(_, let fallback):
			return swiftUIColor(from: fallback, currentColor: currentColor, opacity: opacity)
		}
	}
}

private extension Rect {
	var aspectRatio: CGFloat? {
		guard width > 0, height > 0 else { return nil }
		return CGFloat(width / height)
	}
}

private extension SVGPaintAttributes {
	var canRender: Bool {
		display != .none && visibility == .visible && opacity > 0
	}
}
