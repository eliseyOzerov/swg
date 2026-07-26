import CoreGraphics
import Foundation
import SwiftUI

/// A SwiftUI view that renders an `SVGDocument` with the package's native path renderer.
public struct SVG: View {
	@Binding private var boundDocument: SVGDocument?
	@State private var loadedDocument: SVGDocument?
	@State private var loadedSourceID: String?

	private var initialDocument: SVGDocument?
	private var usesBoundDocument: Bool
	private var loadSource: SVGLoadSource?

	/// Rendering and layout options applied to the document.
	public var options: SVGRenderOptions

	/// The parsed SVG document this view renders when one is available.
	public var document: SVGDocument? {
		usesBoundDocument ? boundDocument : initialDocument
	}

	/// Creates a SwiftUI SVG view from a parsed document.
	///
	/// - Parameters:
	///   - document: The parsed SVG document to display.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: SVGDocument, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: document, boundDocument: nil, loadSource: nil, options: options)
	}

	/// Creates a SwiftUI SVG view backed by a mutable optional document binding.
	///
	/// Use this initializer when the document may be loaded later, or when callers want to modify the parsed document after the view appears.
	///
	/// - Parameters:
	///   - document: A binding to the document the view should render.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: Binding<SVGDocument?>, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: nil, options: options)
	}

	/// Creates a SwiftUI SVG view backed by a mutable document binding.
	///
	/// - Parameters:
	///   - document: A binding to the document the view should render.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: Binding<SVGDocument>, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(Binding<SVGDocument?>(
			get: { document.wrappedValue },
			set: { newValue in
				if let newValue {
					document.wrappedValue = newValue
				}
			}
		), options: options)
	}

	/// Parses SVG source and creates a SwiftUI SVG view when parsing succeeds.
	///
	/// - Parameters:
	///   - source: The SVG XML source string to parse.
	///   - parser: The parser configuration to use.
	///   - options: Rendering and layout options for the root drawing pass.
	public init?(source: String, parser: SVGParser = SVGParser(), options: SVGRenderOptions = SVGRenderOptions()) {
		guard let document = parser.parse(source) else { return nil }
		self.init(document, options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a bundled resource path.
	///
	/// This mirrors SwiftUI's `Image` initializer for the common bundled-asset case. Pass `"checkmark"` for `checkmark.svg`, or a relative path such as `"Icons/checkmark.svg"` for a resource in a bundle subdirectory.
	///
	/// - Parameters:
	///   - assetPath: The bundled SVG resource name or relative path.
	///   - bundle: The bundle that contains the SVG resource.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ assetPath: String, bundle: Bundle = .main, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		let url = SVGBundleResource.url(for: assetPath, in: bundle)
		self.init(initialDocument: nil, boundDocument: document, loadSource: url.map(SVGLoadSource.file), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a network URL.
	///
	/// - Parameters:
	///   - url: The remote URL to load with `URLSession`.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(url: URL, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: .url(url), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a bundled resource.
	///
	/// - Parameters:
	///   - name: The resource name in `bundle`.
	///   - bundle: The bundle that contains the SVG resource.
	///   - fileExtension: The resource extension, usually `"svg"`.
	///   - subdirectory: An optional bundle subdirectory.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(asset name: String, bundle: Bundle = .main, fileExtension: String? = "svg", subdirectory: String? = nil, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		let url = bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
			?? bundle.url(forResource: name, withExtension: fileExtension)
		self.init(initialDocument: nil, boundDocument: document, loadSource: url.map(SVGLoadSource.file), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a file URL.
	///
	/// - Parameters:
	///   - url: The file URL for an SVG stored in the app's filesystem.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(file url: URL, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: .file(url), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a filesystem path.
	///
	/// - Parameters:
	///   - path: The path for an SVG stored in the app's filesystem.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(file path: String, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(file: URL(fileURLWithPath: path), document: document, options: options)
	}

	/// The SwiftUI body that renders the document into a `Canvas`.
	public var body: some View {
		Group {
			if let renderDocument {
				render(renderDocument)
			} else {
				SwiftUI.Color.clear
			}
		}
		.task(id: loadTaskID) {
			await loadSourceIfNeeded()
		}
	}

	private init(initialDocument: SVGDocument?, boundDocument: Binding<SVGDocument?>?, loadSource: SVGLoadSource?, options: SVGRenderOptions) {
		if let boundDocument {
			_boundDocument = boundDocument
			usesBoundDocument = true
		} else {
			_boundDocument = .constant(nil)
			usesBoundDocument = false
		}
		_loadedDocument = State(initialValue: initialDocument)
		_loadedSourceID = State(initialValue: nil)
		self.initialDocument = initialDocument
		self.loadSource = loadSource
		self.options = options
	}

	private var loadTaskID: String {
		"\(loadSource?.id ?? "none"):\(renderDocument == nil)"
	}

	private var renderDocument: SVGDocument? {
		usesBoundDocument ? boundDocument : loadedDocument ?? initialDocument
	}

	@ViewBuilder private func render(_ document: SVGDocument) -> some View {
		Canvas { context, size in
			let renderer = SVGCanvasRenderer(document: document, size: size, options: options)
			renderer.render(in: &context)
		}
		.aspectRatio(document.viewBox.aspectRatio, contentMode: options.contentMode)
	}

	@MainActor private func loadSourceIfNeeded() async {
		guard let loadSource else { return }
		guard renderDocument == nil || loadedSourceID != loadSource.id else { return }
		guard let document = try? await SVGDocumentLoader.load(from: loadSource) else { return }
		if usesBoundDocument {
			boundDocument = document
		} else {
			loadedDocument = document
		}
		loadedSourceID = loadSource.id
	}
}

/// Controls how `SVG` maps a parsed document into SwiftUI layout and drawing.
public struct SVGRenderOptions {
	/// The SwiftUI content mode used when the view proposes the document aspect ratio.
	public var contentMode: ContentMode
	/// An optional override for the root document's `preserveAspectRatio` mapping.
	public var preserveAspectRatio: SVGPreserveAspectRatio?
	/// A root opacity multiplier applied to all rendered content.
	public var opacity: Double

	/// Creates rendering options for `SVG`.
	///
	/// - Parameters:
	///   - contentMode: The SwiftUI content mode used for aspect-ratio layout.
	///   - preserveAspectRatio: A root `preserveAspectRatio` override, or `nil` to use the parsed document value.
	///   - opacity: A root opacity multiplier applied to rendered content.
	public init(contentMode: ContentMode = .fit, preserveAspectRatio: SVGPreserveAspectRatio? = nil, opacity: Double = 1) {
		self.contentMode = contentMode
		self.preserveAspectRatio = preserveAspectRatio
		self.opacity = opacity
	}
}

enum SVGLoadSource: Equatable {
	case url(URL)
	case file(URL)

	var id: String {
		switch self {
		case .url(let url):
			return "url:\(url.absoluteString)"
		case .file(let url):
			return "file:\(url.path)"
		}
	}
}

enum SVGDocumentLoader {
	static func load(from source: SVGLoadSource) async throws -> SVGDocument? {
		let data: Data
		switch source {
		case .url(let url):
			let response: URLResponse
			(data, response) = try await URLSession.shared.data(from: url)
			if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
				return nil
			}
		case .file(let url):
			data = try Data(contentsOf: url)
		}
		return SVGParser().parse(data)
	}
}

enum SVGBundleResource {
	static func url(for path: String, in bundle: Bundle) -> URL? {
		let filePath = path as NSString
		let fileExtension = filePath.pathExtension.isEmpty ? "svg" : filePath.pathExtension
		let pathWithoutExtension = filePath.pathExtension.isEmpty ? path : filePath.deletingPathExtension
		let resourcePath = pathWithoutExtension as NSString
		let name = resourcePath.lastPathComponent
		let directory = resourcePath.deletingLastPathComponent
		let subdirectory = directory.isEmpty || directory == "." ? nil : directory

		return bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
			?? bundle.url(forResource: pathWithoutExtension, withExtension: fileExtension)
			?? bundle.url(forResource: name, withExtension: fileExtension)
			?? bundle.url(forResource: path, withExtension: nil)
	}
}

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
