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
	FeatureExample(slug: "viewports-containers", width: 720, height: 480),
	FeatureExample(slug: "transforms-style", width: 720, height: 480),
	FeatureExample(slug: "paint-fill-opacity", width: 720, height: 480),
	FeatureExample(slug: "paint-strokes", width: 720, height: 480),
	FeatureExample(slug: "gradients-patterns", width: 720, height: 480),
	FeatureExample(slug: "clip-mask-composite", width: 720, height: 480),
	FeatureExample(slug: "filters", width: 720, height: 480),
	FeatureExample(slug: "text", width: 720, height: 480),
	FeatureExample(slug: "reuse-markers", width: 720, height: 480),
	FeatureExample(slug: "embedded-animation", width: 720, height: 480),
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
		let scratchDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
			.appendingPathComponent("swg-feature-gallery-\(UUID().uuidString)", isDirectory: true)
		try FileManager.default.createDirectory(at: pngDirectory, withIntermediateDirectories: true)
		try FileManager.default.createDirectory(at: scratchDirectory, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: scratchDirectory) }

		for example in examples {
			let svgURL = svgDirectory.appendingPathComponent("\(example.slug).svg")
			let pngURL = pngDirectory.appendingPathComponent("\(example.slug).png")
			try assertSwgParses(svgURL)
			try renderSVGWithQuickLook(svgURL, pngURL: pngURL, scratchDirectory: scratchDirectory, width: example.width, height: example.height)
			print("Rendered \(pngURL.path)")
		}
	}

	private static func assertSwgParses(_ svgURL: URL) throws {
		let svg = try String(contentsOf: svgURL, encoding: .utf8)
		guard SVGParser().parse(svg) != nil else {
			throw FeatureGalleryError.invalidSVG(svgURL.lastPathComponent)
		}
	}

	private static func renderSVGWithQuickLook(_ svgURL: URL, pngURL: URL, scratchDirectory: URL, width: Int, height: Int) throws {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
		process.arguments = ["-t", "-s", "\(width)", "-o", scratchDirectory.path, svgURL.path]

		let output = Pipe()
		process.standardOutput = output
		process.standardError = output
		try process.run()
		process.waitUntilExit()

		guard process.terminationStatus == 0 else {
			let data = output.fileHandleForReading.readDataToEndOfFile()
			let message = String(decoding: data, as: UTF8.self)
			throw FeatureGalleryError.quickLookFailed(svgURL.lastPathComponent, message)
		}

		let renderedURL = scratchDirectory.appendingPathComponent("\(svgURL.lastPathComponent).png")
		guard FileManager.default.fileExists(atPath: renderedURL.path) else {
			throw FeatureGalleryError.missingRenderedPNG(renderedURL)
		}

		if FileManager.default.fileExists(atPath: pngURL.path) {
			try FileManager.default.removeItem(at: pngURL)
		}
		try FileManager.default.moveItem(at: renderedURL, to: pngURL)
		try cropPNG(at: pngURL, width: width, height: height)
	}

	private static func cropPNG(at url: URL, width targetWidth: Int, height targetHeight: Int) throws {
		guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
			let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
		else {
			throw FeatureGalleryError.invalidRenderedPNG(url)
		}

		let cropWidth = min(image.width, targetWidth)
		let cropHeight = min(image.height, targetHeight)
		let cropRect = CGRect(
			x: (image.width - cropWidth) / 2,
			y: (image.height - cropHeight) / 2,
			width: cropWidth,
			height: cropHeight
		)
		guard let cropped = image.cropping(to: cropRect) else {
			throw FeatureGalleryError.invalidRenderedPNG(url)
		}

		guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
			throw FeatureGalleryError.invalidRenderedPNG(url)
		}
		CGImageDestinationAddImage(destination, cropped, nil)
		guard CGImageDestinationFinalize(destination) else {
			throw FeatureGalleryError.invalidRenderedPNG(url)
		}
	}
}

enum FeatureGalleryError: Error {
	case invalidSVG(String)
	case quickLookFailed(String, String)
	case missingRenderedPNG(URL)
	case invalidRenderedPNG(URL)
}
