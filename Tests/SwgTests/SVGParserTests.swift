import Testing
@testable import Swg

@Test func svgParserBuildsDocumentFromFoundationXMLParser() throws {
	let svg = """
	<svg width="24" height="24" viewBox="0 0 24 24">
		<style>.accent { fill: #336699; stroke-width: 2; }</style>
		<defs>
			<linearGradient id="fade" x1="0%" y1="0%" x2="100%" y2="0%">
				<stop offset="0%" stop-color="red"/>
				<stop offset="100%" stop-color="blue" stop-opacity="0.5"/>
			</linearGradient>
		</defs>
		<g id="icon" transform="translate(2,3)">
			<path id="mark" class="accent" d="M0 0 L10 0 Z"/>
			<circle id="dot" cx="12" cy="12" r="4" fill="url(#fade)"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 24, height: 24))
	#expect(document.elementIDs == ["icon", "mark", "dot"])
	#expect(document.defs.linearGradients["fade"]?.stops.count == 2)

	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected root element to be a group")
		return
	}
	#expect(group.attributes.transform == Transform.identity.translatedBy(x: 2, y: 3))

	guard case .path(let path) = group.children.first else {
		Issue.record("Expected first child to be a path")
		return
	}
	#expect(path.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(path.attributes.strokeWidth == 2)
}

@Test func svgParserStoresFilterDefinitionsWithoutRenderingTheFilterElement() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="shadow" display="none">
			<feGaussianBlur stdDeviation="2"/>
			<feDropShadow dx="1" dy="2" stdDeviation="3" flood-color="#336699" flood-opacity="0.5"/>
		</filter>
		<rect id="painted" width="20" height="20"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let filter = try #require(document.defs.filters["shadow"])

	#expect(filter.id == "shadow")
	#expect(document.elementIDs == ["painted"])
	#expect(filter.primitives.count == 2)
	guard case .gaussianBlur(let stdDeviationX, let stdDeviationY, let edgeMode) = filter.primitives[0] else {
		Issue.record("Expected first filter primitive to be feGaussianBlur")
		return
	}
	#expect(stdDeviationX == 2)
	#expect(stdDeviationY == 2)
	#expect(edgeMode == .none)
	guard case .dropShadow(let dx, let dy, let shadowDeviationX, let shadowDeviationY, let color) = filter.primitives[1] else {
		Issue.record("Expected second filter primitive to be feDropShadow")
		return
	}
	#expect(dx == 1)
	#expect(dy == 2)
	#expect(shadowDeviationX == 3)
	#expect(shadowDeviationY == 3)
	#expect(color == Color(0.2, 0.4, 0.6).withAlpha(0.5))
}

@Test func svgParserPreservesFilterUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="defaultUnits"/>
		<filter id="objectBox" filterUnits="objectBoundingBox"/>
		<filter id="userSpace" filterUnits="userSpaceOnUse"/>
		<filter id="invalidUnits" filterUnits="definitelyNotUnits"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.filters["defaultUnits"]?.filterUnits == .objectBoundingBox)
	#expect(document.defs.filters["objectBox"]?.filterUnits == .objectBoundingBox)
	#expect(document.defs.filters["userSpace"]?.filterUnits == .userSpaceOnUse)
	#expect(document.defs.filters["invalidUnits"]?.filterUnits == .objectBoundingBox)
}

@Test func svgParserPreservesPrimitiveUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="defaultUnits"/>
		<filter id="userSpace" primitiveUnits="userSpaceOnUse"/>
		<filter id="objectBox" primitiveUnits="objectBoundingBox"/>
		<filter id="invalidUnits" primitiveUnits="definitelyNotUnits"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.filters["defaultUnits"]?.primitiveUnits == .userSpaceOnUse)
	#expect(document.defs.filters["userSpace"]?.primitiveUnits == .userSpaceOnUse)
	#expect(document.defs.filters["objectBox"]?.primitiveUnits == .objectBoundingBox)
	#expect(document.defs.filters["invalidUnits"]?.primitiveUnits == .userSpaceOnUse)
}

@Test func svgParserPreservesGaussianBlurPrimitiveAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="blur">
			<feGaussianBlur stdDeviation="2" edgeMode="none"/>
			<feGaussianBlur stdDeviation="3 4" edgeMode="duplicate"/>
			<feGaussianBlur stdDeviation="5,6" edgeMode="wrap"/>
			<feGaussianBlur/>
			<feGaussianBlur stdDeviation="bad" edgeMode="unknown"/>
		</filter>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let filter = try #require(document.defs.filters["blur"])
	#expect(filter.primitives.count == 5)
	guard
		case .gaussianBlur(2, 2, .none) = filter.primitives[0],
		case .gaussianBlur(3, 4, .duplicate) = filter.primitives[1],
		case .gaussianBlur(5, 6, .wrap) = filter.primitives[2],
		case .gaussianBlur(0, 0, .none) = filter.primitives[3],
		case .gaussianBlur(0, 0, .none) = filter.primitives[4]
	else {
		Issue.record("Expected parsed feGaussianBlur stdDeviation and edgeMode attributes")
		return
	}
}

@Test func svgParserPreservesDropShadowPrimitiveAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="shadow">
			<feDropShadow/>
			<feDropShadow dx="3" dy="4" stdDeviation="5" flood-color="#336699" flood-opacity="50%"/>
			<feDropShadow dx="6" dy="7" stdDeviation="8 9" flood-color="rgba(51,102,153,0.5)" flood-opacity="0.5"/>
			<feDropShadow dx="bad" dy="bad" stdDeviation="bad" flood-color="bogus" flood-opacity="2"/>
		</filter>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let filter = try #require(document.defs.filters["shadow"])
	#expect(filter.primitives.count == 4)

	func expectDropShadow(_ primitive: SVGFilterPrimitive, dx expectedDX: Double, dy expectedDY: Double, stdDeviationX expectedStdDeviationX: Double, stdDeviationY expectedStdDeviationY: Double, color expectedColor: Color) {
		guard case .dropShadow(let dx, let dy, let stdDeviationX, let stdDeviationY, let color) = primitive else {
			Issue.record("Expected parsed feDropShadow primitive")
			return
		}
		#expect(dx == expectedDX)
		#expect(dy == expectedDY)
		#expect(stdDeviationX == expectedStdDeviationX)
		#expect(stdDeviationY == expectedStdDeviationY)
		#expect(color == expectedColor)
	}

	expectDropShadow(filter.primitives[0], dx: 2, dy: 2, stdDeviationX: 2, stdDeviationY: 2, color: .black)
	expectDropShadow(filter.primitives[1], dx: 3, dy: 4, stdDeviationX: 5, stdDeviationY: 5, color: Color(0.2, 0.4, 0.6, 0.5))
	expectDropShadow(filter.primitives[2], dx: 6, dy: 7, stdDeviationX: 8, stdDeviationY: 9, color: Color(0.2, 0.4, 0.6, 0.25))
	expectDropShadow(filter.primitives[3], dx: 2, dy: 2, stdDeviationX: 2, stdDeviationY: 2, color: .black)
}

@Test func svgParserPreservesBlendPrimitiveAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="blend">
			<feBlend/>
			<feBlend in="SourceGraphic" in2="BackgroundImage" mode="multiply" no-composite="no-composite"/>
			<feBlend mode="normal"/>
			<feBlend mode="darken"/>
			<feBlend mode="color-burn"/>
			<feBlend mode="lighten"/>
			<feBlend mode="screen"/>
			<feBlend mode="color-dodge"/>
			<feBlend mode="overlay"/>
			<feBlend mode="soft-light"/>
			<feBlend mode="hard-light"/>
			<feBlend mode="difference"/>
			<feBlend mode="exclusion"/>
			<feBlend mode="hue"/>
			<feBlend mode="saturation"/>
			<feBlend mode="color"/>
			<feBlend mode="luminosity"/>
			<feBlend mode="unsupported"/>
		</filter>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let filter = try #require(document.defs.filters["blend"])
	#expect(filter.primitives.count == 18)
	guard case .blend(nil, nil, .normal, false) = filter.primitives[0] else {
		Issue.record("Expected default feBlend primitive")
		return
	}
	guard case .blend("SourceGraphic", "BackgroundImage", .multiply, true) = filter.primitives[1] else {
		Issue.record("Expected feBlend input, in2, mode, and no-composite attributes")
		return
	}
	let modes = filter.primitives.dropFirst(2).map { primitive -> SVGBlendMode? in
		guard case .blend(_, _, let mode, _) = primitive else { return nil }
		return mode
	}
	#expect(modes == [
		.normal,
		.darken,
		.colorBurn,
		.lighten,
		.screen,
		.colorDodge,
		.overlay,
		.softLight,
		.hardLight,
		.difference,
		.exclusion,
		.hue,
		.saturation,
		.color,
		.luminosity,
		.normal,
	])
}

@Test func svgParserPreservesColorMatrixPrimitiveAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="colors">
			<feColorMatrix/>
			<feColorMatrix in="SourceGraphic" type="matrix" values="1 0 0 0 0, 0 1 0 0 0, 0 0 1 0 0, 0 0 0 1 0"/>
			<feColorMatrix type="saturate" values="0.4"/>
			<feColorMatrix type="hueRotate" values="90"/>
			<feColorMatrix type="luminanceToAlpha"/>
			<feColorMatrix type="saturate"/>
			<feColorMatrix type="hueRotate"/>
			<feColorMatrix type="unsupported"/>
			<feColorMatrix type="matrix" values="1 0"/>
			<feColorMatrix type="saturate" values="1 0"/>
			<feColorMatrix type="hueRotate" values="bad"/>
		</filter>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let filter = try #require(document.defs.filters["colors"])
	#expect(filter.primitives.count == 11)

	let identity = [
		1.0, 0, 0, 0, 0,
		0, 1, 0, 0, 0,
		0, 0, 1, 0, 0,
		0, 0, 0, 1, 0,
	]

	func expectColorMatrix(_ primitive: SVGFilterPrimitive, input expectedInput: String?, type expectedType: SVGColorMatrixType, values expectedValues: [Double], isPassThrough expectedIsPassThrough: Bool = false) {
		guard case .colorMatrix(let input, let type, let values, let isPassThrough) = primitive else {
			Issue.record("Expected parsed feColorMatrix primitive")
			return
		}
		#expect(input == expectedInput)
		#expect(type == expectedType)
		#expect(values == expectedValues)
		#expect(isPassThrough == expectedIsPassThrough)
	}

	expectColorMatrix(filter.primitives[0], input: nil, type: .matrix, values: identity)
	expectColorMatrix(filter.primitives[1], input: "SourceGraphic", type: .matrix, values: identity)
	expectColorMatrix(filter.primitives[2], input: nil, type: .saturate, values: [0.4])
	expectColorMatrix(filter.primitives[3], input: nil, type: .hueRotate, values: [90])
	expectColorMatrix(filter.primitives[4], input: nil, type: .luminanceToAlpha, values: [])
	expectColorMatrix(filter.primitives[5], input: nil, type: .saturate, values: [1])
	expectColorMatrix(filter.primitives[6], input: nil, type: .hueRotate, values: [0])
	expectColorMatrix(filter.primitives[7], input: nil, type: .matrix, values: identity)
	expectColorMatrix(filter.primitives[8], input: nil, type: .matrix, values: [1, 0], isPassThrough: true)
	expectColorMatrix(filter.primitives[9], input: nil, type: .saturate, values: [1, 0], isPassThrough: true)
	expectColorMatrix(filter.primitives[10], input: nil, type: .hueRotate, values: [], isPassThrough: true)
}

@Test func svgParserPreservesComponentTransferPrimitiveAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<filter id="component">
			<feComponentTransfer/>
			<feComponentTransfer in="SourceGraphic"/>
		</filter>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let filter = try #require(document.defs.filters["component"])
	#expect(document.elements.isEmpty)
	#expect(filter.primitives.count == 2)
	guard
		case .componentTransfer(nil) = filter.primitives[0],
		case .componentTransfer("SourceGraphic") = filter.primitives[1]
	else {
		Issue.record("Expected parsed feComponentTransfer input attributes")
		return
	}
}

@Test func svgParserPreservesRadialGradientGeometryAndStops() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<radialGradient id="default">
				<stop offset="0%" stop-color="red"/>
				<stop offset="100%" stop-color="blue"/>
			</radialGradient>
			<radialGradient id="focus" cx="25%" cy="75%" r="40%" fx="10%" fy="20%" fr="5%">
				<stop offset="0" stop-color="#ffffff"/>
				<stop offset="0.5" stop-color="#808080" stop-opacity="0.25"/>
				<stop offset="1" stop-color="#000000"/>
			</radialGradient>
			<radialGradient id="invalid" r="-10%" fr="-1">
				<stop offset="0%" stop-color="red"/>
				<stop offset="100%" stop-color="blue"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let defaults = try #require(document.defs.radialGradients["default"])
	let focus = try #require(document.defs.radialGradients["focus"])
	let invalid = try #require(document.defs.radialGradients["invalid"])

	#expect(defaults.cx == 0.5)
	#expect(defaults.cy == 0.5)
	#expect(defaults.r == 0.5)
	#expect(defaults.fx == nil)
	#expect(defaults.fy == nil)
	#expect(defaults.fr == 0)
	#expect(defaults.stops.map(\.offset) == [0, 1])
	#expect(defaults.stops.map(\.color) == [.red, .blue])

	#expect(focus.cx == 0.25)
	#expect(focus.cy == 0.75)
	#expect(focus.r == 0.4)
	#expect(focus.fx == 0.1)
	#expect(focus.fy == 0.2)
	#expect(focus.fr == 0.05)
	#expect(focus.stops.map(\.offset) == [0, 0.5, 1])
	#expect(focus.stops[1].color == Color(128 / 255, 128 / 255, 128 / 255))
	#expect(focus.stops[1].opacity == 0.25)

	#expect(invalid.r == 0.5)
	#expect(invalid.fr == 0)
	#expect(invalid.stops.count == 2)
}

@Test func svgParserPreservesObjectBoundingBoxGradientUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<linearGradient id="linearExplicit" gradientUnits="objectBoundingBox" x1="25%" y1=".1" x2=".75" y2="90%">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<linearGradient id="linearDefault" x1=".2" y1="30%" x2=".8" y2="70%">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<radialGradient id="radialExplicit" gradientUnits="objectBoundingBox" cx="20%" cy=".3" r="40%" fx=".5" fy="60%" fr=".1">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
			<radialGradient id="radialInvalid" gradientUnits="definitelyNotUnits" cx=".4" cy=".6" r=".2">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let linearExplicit = try #require(document.defs.linearGradients["linearExplicit"])
	let linearDefault = try #require(document.defs.linearGradients["linearDefault"])
	let radialExplicit = try #require(document.defs.radialGradients["radialExplicit"])
	let radialInvalid = try #require(document.defs.radialGradients["radialInvalid"])

	#expect(linearExplicit.gradientUnits == .objectBoundingBox)
	#expect(linearExplicit.x1 == 0.25)
	#expect(linearExplicit.y1 == 0.1)
	#expect(linearExplicit.x2 == 0.75)
	#expect(linearExplicit.y2 == 0.9)

	#expect(linearDefault.gradientUnits == .objectBoundingBox)
	#expect(linearDefault.x1 == 0.2)
	#expect(linearDefault.y1 == 0.3)
	#expect(linearDefault.x2 == 0.8)
	#expect(linearDefault.y2 == 0.7)

	#expect(radialExplicit.gradientUnits == .objectBoundingBox)
	#expect(radialExplicit.cx == 0.2)
	#expect(radialExplicit.cy == 0.3)
	#expect(radialExplicit.r == 0.4)
	#expect(radialExplicit.fx == 0.5)
	#expect(radialExplicit.fy == 0.6)
	#expect(radialExplicit.fr == 0.1)

	#expect(radialInvalid.gradientUnits == .objectBoundingBox)
	#expect(radialInvalid.cx == 0.4)
	#expect(radialInvalid.cy == 0.6)
	#expect(radialInvalid.r == 0.2)
}

@Test func svgParserResolvesUserSpaceOnUseGradientUnitsAgainstViewport() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" viewBox="0 0 200 100">
		<defs>
			<linearGradient id="linearDefault" gradientUnits="userSpaceOnUse">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<linearGradient id="linearExplicit" gradientUnits="userSpaceOnUse" x1="25%" y1="50%" x2="1in" y2="30">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<radialGradient id="radialDefault" gradientUnits="userSpaceOnUse">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
			<radialGradient id="radialExplicit" gradientUnits="userSpaceOnUse" cx="50%" cy="25%" r="10%" fx="75%" fy="80%" fr="5%">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let linearDefault = try #require(document.defs.linearGradients["linearDefault"])
	let linearExplicit = try #require(document.defs.linearGradients["linearExplicit"])
	let radialDefault = try #require(document.defs.radialGradients["radialDefault"])
	let radialExplicit = try #require(document.defs.radialGradients["radialExplicit"])

	#expect(linearDefault.gradientUnits == .userSpaceOnUse)
	#expect(linearDefault.x1 == 0)
	#expect(linearDefault.y1 == 0)
	#expect(linearDefault.x2 == 200)
	#expect(linearDefault.y2 == 0)

	#expect(linearExplicit.gradientUnits == .userSpaceOnUse)
	#expect(linearExplicit.x1 == 50)
	#expect(linearExplicit.y1 == 50)
	#expect(linearExplicit.x2 == 96)
	#expect(linearExplicit.y2 == 30)

	#expect(radialDefault.gradientUnits == .userSpaceOnUse)
	#expect(radialDefault.cx == 100)
	#expect(radialDefault.cy == 50)
	#expect(abs(radialDefault.r - 79.05694150420949) < 0.000001)
	#expect(radialDefault.fx == nil)
	#expect(radialDefault.fy == nil)
	#expect(radialDefault.fr == 0)

	#expect(radialExplicit.gradientUnits == .userSpaceOnUse)
	#expect(radialExplicit.cx == 100)
	#expect(radialExplicit.cy == 25)
	#expect(abs(radialExplicit.r - 15.811388300841898) < 0.000001)
	#expect(radialExplicit.fx == 150)
	#expect(radialExplicit.fy == 80)
	#expect(abs(radialExplicit.fr - 7.905694150420949) < 0.000001)
}

@Test func svgParserPreservesGradientTransformLists() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<linearGradient id="linearDefault">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<linearGradient id="linearTransformed" gradientTransform="translate(10 20) scale(2)">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<radialGradient id="radialDefault">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
			<radialGradient id="radialTransformed" gradientTransform="matrix(1 2 3 4 5 6)">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let linearDefault = try #require(document.defs.linearGradients["linearDefault"])
	let linearTransformed = try #require(document.defs.linearGradients["linearTransformed"])
	let radialDefault = try #require(document.defs.radialGradients["radialDefault"])
	let radialTransformed = try #require(document.defs.radialGradients["radialTransformed"])

	#expect(linearDefault.gradientTransform == .identity)
	#expect(radialDefault.gradientTransform == .identity)
	#expect(linearTransformed.gradientTransform == Transform(a: 2, b: 0, c: 0, d: 2, tx: 10, ty: 20))
	#expect(radialTransformed.gradientTransform == Transform(a: 1, b: 2, c: 3, d: 4, tx: 5, ty: 6))
}

@Test func svgParserPreservesPadGradientSpreadMethod() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<linearGradient id="linearDefault">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<linearGradient id="linearPad" spreadMethod="pad">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<linearGradient id="linearInvalid" spreadMethod="definitelyNotSpread">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<radialGradient id="radialDefault">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
			<radialGradient id="radialPad" spreadMethod="pad">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
			<radialGradient id="radialInvalid" spreadMethod="definitelyNotSpread">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.linearGradients["linearDefault"]?.spreadMethod == .pad)
	#expect(document.defs.linearGradients["linearPad"]?.spreadMethod == .pad)
	#expect(document.defs.linearGradients["linearInvalid"]?.spreadMethod == .pad)
	#expect(document.defs.radialGradients["radialDefault"]?.spreadMethod == .pad)
	#expect(document.defs.radialGradients["radialPad"]?.spreadMethod == .pad)
	#expect(document.defs.radialGradients["radialInvalid"]?.spreadMethod == .pad)
}

@Test func svgParserPreservesReflectGradientSpreadMethod() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<linearGradient id="linear" spreadMethod="reflect">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<radialGradient id="radial" spreadMethod="reflect">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.linearGradients["linear"]?.spreadMethod == .reflect)
	#expect(document.defs.radialGradients["radial"]?.spreadMethod == .reflect)
}

@Test func svgParserPreservesRepeatGradientSpreadMethod() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<linearGradient id="linear" spreadMethod="repeat">
				<stop offset="0" stop-color="red"/>
				<stop offset="1" stop-color="blue"/>
			</linearGradient>
			<radialGradient id="radial" spreadMethod="repeat">
				<stop offset="0" stop-color="white"/>
				<stop offset="1" stop-color="black"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.linearGradients["linear"]?.spreadMethod == .repeat)
	#expect(document.defs.radialGradients["radial"]?.spreadMethod == .repeat)
}

@Test func svgParserPreservesPatternDefinitions() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" viewBox="0 0 200 100">
		<defs>
			<pattern id="tile" patternUnits="userSpaceOnUse" x="10%" y="5" width="25%" height="20" patternTransform="translate(1 2) scale(3)" viewBox="0 0 10 10" preserveAspectRatio="xMaxYMax slice" href="#template">
				<rect id="background" width="10" height="10" fill="white"/>
				<path id="mark" d="M0 0 L10 10" stroke="black"/>
			</pattern>
			<pattern id="defaults"/>
		</defs>
		<rect id="painted" width="100" height="50" fill="url(#tile)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let tile = try #require(document.defs.patterns["tile"])
	let defaults = try #require(document.defs.patterns["defaults"])

	#expect(document.elements.count == 1)
	#expect(tile.x == 20)
	#expect(tile.y == 5)
	#expect(tile.width == 50)
	#expect(tile.height == 20)
	#expect(tile.patternUnits == .userSpaceOnUse)
	#expect(tile.patternTransform == Transform.identity.translatedBy(x: 1, y: 2).scaledBy(x: 3, y: 3))
	#expect(tile.viewBox == Rect(x: 0, y: 0, width: 10, height: 10))
	#expect(tile.preserveAspectRatio.align == .xMaxYMax)
	#expect(tile.preserveAspectRatio.meetOrSlice == .slice)
	#expect(tile.href == "template")
	#expect(tile.children.count == 2)
	#expect(tile.children.flatMap { $0.collectIDs() } == ["background", "mark"])

	#expect(defaults.x == 0)
	#expect(defaults.y == 0)
	#expect(defaults.width == 0)
	#expect(defaults.height == 0)
	#expect(defaults.patternUnits == .objectBoundingBox)
	#expect(defaults.patternTransform == .identity)
	#expect(defaults.viewBox == nil)
	#expect(defaults.preserveAspectRatio == .default)
	#expect(defaults.href == nil)
	#expect(defaults.children.isEmpty)
}

@Test func svgParserPreservesPatternContentUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
		<defs>
			<pattern id="defaultContentUnits"/>
			<pattern id="userSpaceContent" patternContentUnits="userSpaceOnUse"/>
			<pattern id="objectContent" patternContentUnits="objectBoundingBox"/>
			<pattern id="invalidContent" patternContentUnits="definitelyNotUnits"/>
			<pattern id="withViewBox" patternContentUnits="objectBoundingBox" viewBox="0 0 10 10"/>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.patterns["defaultContentUnits"]?.patternContentUnits == .userSpaceOnUse)
	#expect(document.defs.patterns["userSpaceContent"]?.patternContentUnits == .userSpaceOnUse)
	#expect(document.defs.patterns["objectContent"]?.patternContentUnits == .objectBoundingBox)
	#expect(document.defs.patterns["invalidContent"]?.patternContentUnits == .userSpaceOnUse)
	#expect(document.defs.patterns["withViewBox"]?.patternContentUnits == .objectBoundingBox)
	#expect(document.defs.patterns["withViewBox"]?.viewBox == Rect(x: 0, y: 0, width: 10, height: 10))
}

@Test func svgParserStoresClipPathDefinitionsOutsideRenderableElements() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<clipPath id="clip">
			<rect id="clipRect" x="1" y="2" width="3" height="4"/>
			<circle id="clipCircle" cx="10" cy="10" r="5"/>
			<path id="clipPathShape" d="M0 0 L20 0 L20 20 Z"/>
		</clipPath>
		<rect id="painted" width="20" height="20"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let clipChildren = try #require(document.defs.clipPaths["clip"])

	#expect(document.elementIDs == ["painted"])
	#expect(clipChildren.flatMap { $0.collectIDs() } == ["clipRect", "clipCircle", "clipPathShape"])

	guard case .rect(let rect) = clipChildren[0] else {
		Issue.record("Expected clip rect")
		return
	}
	#expect(rect.x == 1)
	#expect(rect.y == 2)
	#expect(rect.width == 3)
	#expect(rect.height == 4)

	guard case .circle(let circle) = clipChildren[1] else {
		Issue.record("Expected clip circle")
		return
	}
	#expect(circle.cx == 10)
	#expect(circle.cy == 10)
	#expect(circle.r == 5)

	guard case .path(let path) = clipChildren[2] else {
		Issue.record("Expected clip path geometry")
		return
	}
	#expect(path.d == "M0 0 L20 0 L20 20 Z")
}

@Test func svgParserParsesClipPathPropertyValues() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.basic { clip-path: circle(40% at 50% 50%) fill-box; }
			.box { clip-path: stroke-box; }
			.invalid { clip-path: url(#a) url(#b); }
		</style>
		<g id="parent" clip-path="url(#clip)">
			<path id="inherited" d="M0 0 L1 1" clip-path="inherit"/>
			<path id="none" d="M0 0 L1 1" clip-path="none"/>
			<path id="basic" class="basic" d="M0 0 L1 1"/>
			<path id="box" class="box" d="M0 0 L1 1"/>
			<path id="invalid" class="invalid" d="M0 0 L1 1"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected parent group")
		return
	}

	var paths: [String: SVGPathData] = [:]
	for child in group.children {
		if case .path(let path) = child {
			paths[path.id] = path
		}
	}

	#expect(group.attributes.clipPath == .url("clip"))
	#expect(group.attributes.clipPathID == "clip")
	#expect(paths["inherited"]?.attributes.clipPath == .url("clip"))
	#expect(paths["inherited"]?.attributes.clipPathID == "clip")
	#expect(paths["none"]?.attributes.clipPath == SVGClipPathValue.none)
	#expect(paths["none"]?.attributes.clipPathID == nil)
	#expect(paths["basic"]?.attributes.clipPath == .basicShape("circle(40% at 50% 50%)", geometryBox: .fillBox))
	#expect(paths["basic"]?.attributes.clipPathID == nil)
	#expect(paths["box"]?.attributes.clipPath == .geometryBox(.strokeBox))
	#expect(paths["invalid"]?.attributes.clipPath == SVGClipPathValue.none)
	#expect(paths["invalid"]?.attributes.clipPathID == nil)
}

@Test func svgParserParsesClipRuleForClipPathGeometry() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" clip-rule="evenodd">
		<style>
			.clipRoot { clip-rule: evenodd; }
			.invalidRule { clip-rule: sideways; }
		</style>
		<clipPath id="ancestorClip">
			<path id="ancestorInherited" d="M0 0 L10 0 L10 10 Z"/>
		</clipPath>
		<clipPath id="classClip" class="clipRoot">
			<path id="classInherited" d="M0 0 L10 0 L10 10 Z"/>
			<path id="attributeOverride" d="M0 0 L10 0 L10 10 Z" clip-rule="nonzero"/>
			<path id="inlineOverride" d="M0 0 L10 0 L10 10 Z" style="clip-rule: nonzero"/>
			<path id="invalid" class="invalidRule" d="M0 0 L10 0 L10 10 Z"/>
		</clipPath>
		<path id="referencer" d="M0 0 L10 0 L10 10 Z" clip-path="url(#classClip)" clip-rule="nonzero" fill-rule="evenodd"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let ancestorClip = try #require(document.defs.clipPaths["ancestorClip"])
	let classClip = try #require(document.defs.clipPaths["classClip"])
	guard case .path(let referencer) = document.elements[0] else {
		Issue.record("Expected referencing path")
		return
	}
	let defaultDocument = try #require(SVGParser().parse(#"<svg xmlns="http://www.w3.org/2000/svg"><path id="initial" d="M0 0 L10 0 L10 10 Z"/></svg>"#))
	guard case .path(let initial) = defaultDocument.elements[0] else {
		Issue.record("Expected default path")
		return
	}

	guard case .path(let ancestorInherited) = ancestorClip[0],
		case .path(let classInherited) = classClip[0],
		case .path(let attributeOverride) = classClip[1],
		case .path(let inlineOverride) = classClip[2],
		case .path(let invalid) = classClip[3] else {
		Issue.record("Expected clip path geometry")
		return
	}

	#expect(ancestorInherited.attributes.clipRule == .evenOdd)
	#expect(classInherited.attributes.clipRule == .evenOdd)
	#expect(attributeOverride.attributes.clipRule == .winding)
	#expect(inlineOverride.attributes.clipRule == .winding)
	#expect(invalid.attributes.clipRule == .evenOdd)
	#expect(referencer.attributes.clipRule == .winding)
	#expect(referencer.attributes.fillRule == .evenOdd)
	#expect(initial.attributes.clipRule == .winding)
}

@Test func svgParserPreservesClipPathUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<clipPath id="defaultUnits">
			<path id="defaultChild" d="M0 0 L10 0 L10 10 Z"/>
		</clipPath>
		<clipPath id="userSpace" clipPathUnits="userSpaceOnUse"/>
		<clipPath id="objectBox" clipPathUnits="objectBoundingBox">
			<path id="objectChild" d="M0 0 L1 0 L1 1 Z"/>
		</clipPath>
		<clipPath id="invalidUnits" clipPathUnits="definitelyNotUnits"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.clipPathDefinitions["defaultUnits"]?.units == .userSpaceOnUse)
	#expect(document.defs.clipPathDefinitions["userSpace"]?.units == .userSpaceOnUse)
	#expect(document.defs.clipPathDefinitions["objectBox"]?.units == .objectBoundingBox)
	#expect(document.defs.clipPathDefinitions["invalidUnits"]?.units == .userSpaceOnUse)
	#expect(document.defs.clipPathDefinitions["defaultUnits"]?.children.flatMap { $0.collectIDs() } == ["defaultChild"])
	#expect(document.defs.clipPathDefinitions["objectBox"]?.children.flatMap { $0.collectIDs() } == ["objectChild"])
	#expect(document.defs.clipPaths["objectBox"]?.flatMap { $0.collectIDs() } == ["objectChild"])
}

@Test func svgParserStoresMaskDefinitionsOutsideRenderableElements() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<mask id="mask" display="none">
			<rect id="maskRect" x="1" y="2" width="3" height="4" fill="white"/>
			<circle id="maskCircle" cx="10" cy="10" r="5" fill="black"/>
			<path id="maskPath" d="M0 0 L20 0 L20 20 Z" opacity="0.5"/>
		</mask>
		<rect id="painted" width="20" height="20"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let mask = try #require(document.defs.masks["mask"])

	#expect(mask.id == "mask")
	#expect(document.elementIDs == ["painted"])
	#expect(mask.children.flatMap { $0.collectIDs() } == ["maskRect", "maskCircle", "maskPath"])

	guard case .rect(let rect) = mask.children[0] else {
		Issue.record("Expected mask rect")
		return
	}
	#expect(rect.x == 1)
	#expect(rect.y == 2)
	#expect(rect.width == 3)
	#expect(rect.height == 4)
	#expect(rect.attributes.fill == .color(.white))

	guard case .circle(let circle) = mask.children[1] else {
		Issue.record("Expected mask circle")
		return
	}
	#expect(circle.cx == 10)
	#expect(circle.cy == 10)
	#expect(circle.r == 5)
	#expect(circle.attributes.fill == .color(.black))

	guard case .path(let path) = mask.children[2] else {
		Issue.record("Expected mask path geometry")
		return
	}
	#expect(path.d == "M0 0 L20 0 L20 20 Z")
	#expect(path.attributes.opacity == 0.5)
}

@Test func svgParserParsesMaskPropertyLocalReferences() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.classMask { mask: url( '#classMask' ); }
			.noneMask { mask: none; }
			.invalidMask { mask: url(#a) url(#b); }
		</style>
		<g id="parent" mask="url(#parentMask)">
			<path id="notInherited" d="M0 0 L1 1"/>
			<path id="explicitInherit" d="M0 0 L1 1" style="mask: inherit"/>
		</g>
		<path id="attributeMask" d="M0 0 L1 1" mask="url(#attributeMask)"/>
		<path id="classMask" class="classMask" d="M0 0 L1 1"/>
		<path id="noneMask" class="noneMask" d="M0 0 L1 1" mask="url(#ignored)"/>
		<path id="invalidMask" class="invalidMask" d="M0 0 L1 1"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let parent) = document.elements[0] else {
		Issue.record("Expected parent group")
		return
	}

	var paths: [String: SVGPathData] = [:]
	for child in parent.children {
		if case .path(let path) = child {
			paths[path.id] = path
		}
	}
	for element in document.elements.dropFirst() {
		if case .path(let path) = element {
			paths[path.id] = path
		}
	}

	#expect(parent.attributes.maskID == "parentMask")
	#expect(paths["notInherited"]?.attributes.maskID == nil)
	#expect(paths["explicitInherit"]?.attributes.maskID == "parentMask")
	#expect(paths["attributeMask"]?.attributes.maskID == "attributeMask")
	#expect(paths["classMask"]?.attributes.maskID == "classMask")
	#expect(paths["noneMask"]?.attributes.maskID == nil)
	#expect(paths["invalidMask"]?.attributes.maskID == nil)
}

@Test func svgParserPreservesMaskUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<mask id="defaultUnits">
			<path id="defaultChild" d="M0 0 L10 0 L10 10 Z"/>
		</mask>
		<mask id="objectBox" maskUnits="objectBoundingBox"/>
		<mask id="userSpace" maskUnits="userSpaceOnUse">
			<path id="userSpaceChild" d="M0 0 L10 0 L10 10 Z"/>
		</mask>
		<mask id="invalidUnits" maskUnits="definitelyNotUnits"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.masks["defaultUnits"]?.maskUnits == .objectBoundingBox)
	#expect(document.defs.masks["objectBox"]?.maskUnits == .objectBoundingBox)
	#expect(document.defs.masks["userSpace"]?.maskUnits == .userSpaceOnUse)
	#expect(document.defs.masks["invalidUnits"]?.maskUnits == .objectBoundingBox)
	#expect(document.defs.masks["defaultUnits"]?.children.flatMap { $0.collectIDs() } == ["defaultChild"])
	#expect(document.defs.masks["userSpace"]?.children.flatMap { $0.collectIDs() } == ["userSpaceChild"])
}

@Test func svgParserPreservesMaskContentUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<mask id="defaultContent">
			<path id="defaultChild" d="M0 0 L10 0 L10 10 Z"/>
		</mask>
		<mask id="userSpaceContent" maskContentUnits="userSpaceOnUse"/>
		<mask id="objectContent" maskContentUnits="objectBoundingBox">
			<path id="objectChild" d="M0 0 L1 0 L1 1 Z"/>
		</mask>
		<mask id="invalidContent" maskContentUnits="definitelyNotUnits"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.defs.masks["defaultContent"]?.maskContentUnits == .userSpaceOnUse)
	#expect(document.defs.masks["userSpaceContent"]?.maskContentUnits == .userSpaceOnUse)
	#expect(document.defs.masks["objectContent"]?.maskContentUnits == .objectBoundingBox)
	#expect(document.defs.masks["invalidContent"]?.maskContentUnits == .userSpaceOnUse)
	#expect(document.defs.masks["defaultContent"]?.children.flatMap { $0.collectIDs() } == ["defaultChild"])
	#expect(document.defs.masks["objectContent"]?.children.flatMap { $0.collectIDs() } == ["objectChild"])
}

@Test func svgParserNormalizesGradientStopOffsets() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<linearGradient id="linear">
				<stop stop-color="red"/>
				<stop offset="-25%" stop-color="red"/>
				<stop offset="0.5" stop-color="green"/>
				<stop offset="25%" stop-color="blue"/>
				<stop offset="150%" stop-color="black"/>
			</linearGradient>
			<radialGradient id="radial">
				<stop offset=".25" stop-color="red"/>
				<stop offset="75%" stop-color="blue"/>
			</radialGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let linear = try #require(document.defs.linearGradients["linear"])
	let radial = try #require(document.defs.radialGradients["radial"])

	#expect(linear.stops.map(\.offset) == [0, 0, 0.5, 0.5, 1])
	#expect(radial.stops.map(\.offset) == [0.25, 0.75])
}

@Test func svgParserAppliesGradientStopColorCascadeAndSpecialValues() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.classed { stop-color: #808080; }
			.invalid { stop-color: definitely-not-a-color; }
		</style>
		<defs>
			<linearGradient id="colors">
				<stop offset="0"/>
				<stop offset=".15" stop-color="red"/>
				<stop offset=".3" class="classed" stop-color="blue"/>
				<stop offset=".45" class="classed" style="stop-color: #00ff00"/>
				<stop offset=".6" style="color: #336699; stop-color: currentColor"/>
				<stop offset=".75" stop-color="transparent"/>
				<stop offset=".9" class="invalid"/>
			</linearGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let stops = try #require(document.defs.linearGradients["colors"]?.stops)

	#expect(stops.map(\.stopColor) == [
		.color(.black),
		.color(.red),
		.color(Color(128 / 255, 128 / 255, 128 / 255)),
		.color(Color(0, 1, 0)),
		.currentColor,
		.color(.black),
		.color(.black)
	])
	#expect(stops[4].color == Color(0.2, 0.4, 0.6))
	#expect(stops[5].opacity == 0)
}

@Test func svgParserAppliesGradientStopOpacityCascadePercentagesAndClamping() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.classed { stop-opacity: 25%; }
			.invalid { stop-opacity: definitely-not-opacity; }
		</style>
		<defs>
			<linearGradient id="opacity" stop-opacity="0.2">
				<stop offset="0"/>
				<stop offset=".15" stop-opacity="0.5"/>
				<stop offset=".3" class="classed" stop-opacity="0.75"/>
				<stop offset=".45" class="classed" style="stop-opacity: 60%"/>
				<stop offset=".6" stop-opacity="-10%"/>
				<stop offset=".75" stop-opacity="2"/>
				<stop offset=".9" class="invalid"/>
			</linearGradient>
		</defs>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let stops = try #require(document.defs.linearGradients["opacity"]?.stops)

	#expect(stops.map(\.opacity) == [
		1,
		0.5,
		0.25,
		0.6,
		0,
		1,
		1
	])
}

@Test func svgParserMultipliesTransformListsFromLeftToRight() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="translateThenScale" transform="translate(10,0) scale(2)"/>
		<g id="scaleThenTranslate" transform="scale(2) translate(10,0)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let translateThenScale) = document.elements.first else {
		Issue.record("Expected first group")
		return
	}
	guard case .group(let scaleThenTranslate) = document.elements.dropFirst().first else {
		Issue.record("Expected second group")
		return
	}

	#expect(translateThenScale.attributes.transform == Transform(a: 2, b: 0, c: 0, d: 2, tx: 10, ty: 0))
	#expect(Point(1, 0).applying(translateThenScale.attributes.transform) == Point(12, 0))
	#expect(scaleThenTranslate.attributes.transform == Transform(a: 2, b: 0, c: 0, d: 2, tx: 20, ty: 0))
	#expect(Point(1, 0).applying(scaleThenTranslate.attributes.transform) == Point(22, 0))
}

@Test func svgParserParsesMatrixTransformFunction() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="matrix" transform="matrix(1 2 3 4 5 6)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected matrix group")
		return
	}

	#expect(group.attributes.transform == Transform(a: 1, b: 2, c: 3, d: 4, tx: 5, ty: 6))
	#expect(Point(7, 8).applying(group.attributes.transform) == Point(36, 52))
}

@Test func svgParserParsesScaleTransformFunction() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="uniform" transform="scale(2)"/>
		<g id="nonuniform" transform="scale(2 3)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let uniform) = document.elements.first else {
		Issue.record("Expected uniform scale group")
		return
	}
	guard case .group(let nonuniform) = document.elements.dropFirst().first else {
		Issue.record("Expected non-uniform scale group")
		return
	}

	#expect(uniform.attributes.transform == Transform(a: 2, b: 0, c: 0, d: 2, tx: 0, ty: 0))
	#expect(Point(4, 5).applying(uniform.attributes.transform) == Point(8, 10))
	#expect(nonuniform.attributes.transform == Transform(a: 2, b: 0, c: 0, d: 3, tx: 0, ty: 0))
	#expect(Point(4, 5).applying(nonuniform.attributes.transform) == Point(8, 15))
}

@Test func svgParserParsesSingleAngleRotateTransformFunction() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="rotated" transform="rotate(90)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected rotated group")
		return
	}

	expectTransformApproximately(group.attributes.transform, Transform(a: 0, b: 1, c: -1, d: 0, tx: 0, ty: 0))
	let point = Point(2, 3).applying(group.attributes.transform)
	#expect(abs(point.x + 3) < 0.000001)
	#expect(abs(point.y - 2) < 0.000001)
}

@Test func svgParserParsesCenteredRotateTransformFunction() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">
		<g id="rotated" transform="rotate(90 10 20)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected centered rotate group")
		return
	}

	expectTransformApproximately(group.attributes.transform, Transform(a: 0, b: 1, c: -1, d: 0, tx: 30, ty: 10))
	let center = Point(10, 20).applying(group.attributes.transform)
	#expect(abs(center.x - 10) < 0.000001)
	#expect(abs(center.y - 20) < 0.000001)
	let rotated = Point(12, 20).applying(group.attributes.transform)
	#expect(abs(rotated.x - 10) < 0.000001)
	#expect(abs(rotated.y - 22) < 0.000001)
}

@Test func svgParserParsesSkewXTransformFunction() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="skewed" transform="skewX(45)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected skewX group")
		return
	}

	expectTransformApproximately(group.attributes.transform, Transform(a: 1, b: 0, c: 1, d: 1, tx: 0, ty: 0))
	let point = Point(2, 3).applying(group.attributes.transform)
	#expect(abs(point.x - 5) < 0.000001)
	#expect(abs(point.y - 3) < 0.000001)
}

@Test func svgParserParsesSkewYTransformFunction() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="skewed" transform="skewY(45)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected skewY group")
		return
	}

	expectTransformApproximately(group.attributes.transform, Transform(a: 1, b: 1, c: 0, d: 1, tx: 0, ty: 0))
	let point = Point(2, 3).applying(group.attributes.transform)
	#expect(abs(point.x - 2) < 0.000001)
	#expect(abs(point.y - 5) < 0.000001)
}

@Test func svgParserParsesVectorEffectPropertyWithoutInheritance() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>.screen-fixed { vector-effect: non-scaling-size non-rotation fixed-position screen; }</style>
		<g id="parent" vector-effect="non-scaling-stroke">
			<path id="child" d="M0 0 L10 10"/>
		</g>
		<path id="stroke" vector-effect="non-scaling-stroke" d="M0 0 L10 10"/>
		<path id="none" vector-effect="none" d="M0 0 L10 10"/>
		<path id="screen" class="screen-fixed" d="M0 0 L10 10"/>
		<path id="invalid" vector-effect="none non-scaling-stroke" d="M0 0 L10 10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let paths = Dictionary(uniqueKeysWithValues: document.elements.flatMap { element -> [(String, SVGPathData)] in
		switch element {
		case .group(let group):
			return group.children.compactMap {
				if case .path(let path) = $0 { return (path.id, path) }
				return nil
			}
		case .path(let path):
			return [(path.id, path)]
		default:
			return []
		}
	})

	guard case .group(let parent) = document.elements.first else {
		Issue.record("Expected vector-effect parent group")
		return
	}
	#expect(parent.attributes.vectorEffect == .effects([.nonScalingStroke], coordinateSpace: .viewport))
	#expect(paths["child"]?.attributes.vectorEffect == SVGVectorEffect.none)
	#expect(paths["stroke"]?.attributes.vectorEffect == .effects([.nonScalingStroke], coordinateSpace: .viewport))
	#expect(paths["none"]?.attributes.vectorEffect == SVGVectorEffect.none)
	#expect(paths["screen"]?.attributes.vectorEffect == .effects([.nonScalingSize, .nonRotation, .fixedPosition], coordinateSpace: .screen))
	#expect(paths["invalid"]?.attributes.vectorEffect == SVGVectorEffect.none)
	#expect(paths["stroke"]?.unknownAttributes["vector-effect"] == nil)
}

@Test func svgParserAppliesPresentationAttributesWithCascadeSpecificity() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="red" stroke-width="1">
		<style>.accent { fill: #336699; stroke-width: 7; }</style>
		<path id="presented" d="M0 0 L10 10" fill="blue" stroke-width="2" stroke-linecap="round" data-note="kept"/>
		<path id="styled" class="accent" d="M0 0 L10 10" fill="blue" stroke-width="2" style="opacity: 0.5"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let paths = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGPathData)? in
		if case .path(let path) = element { return (path.id, path) }
		return nil
	})
	let presented = try #require(paths["presented"])
	let styled = try #require(paths["styled"])

	#expect(presented.attributes.fill == .color(.blue))
	#expect(presented.attributes.strokeWidth == 2)
	#expect(presented.attributes.strokeLineCap == .round)
	#expect(presented.unknownAttributes == ["data-note": "kept"])
	#expect(styled.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(styled.attributes.strokeWidth == 7)
	#expect(styled.attributes.opacity == 0.5)
	#expect(styled.unknownAttributes["fill"] == nil)
	#expect(styled.unknownAttributes["stroke-width"] == nil)
}

@Test func svgParserAppliesOpacityInitialCascadeInheritanceAndClamping() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.classed { opacity: 0.25; }
			.high { opacity: 2; }
			.low { opacity: -1; }
			.invalid { opacity: definitely-not-opacity; }
		</style>
		<g id="parent" opacity="0.5">
			<path id="notInherited" d="M0 0 L1 1"/>
			<path id="explicitInherit" d="M0 0 L1 1" style="opacity: inherit"/>
		</g>
		<path id="initial" d="M0 0 L1 1"/>
		<path id="attribute" d="M0 0 L1 1" opacity="0.6"/>
		<path id="classed" class="classed" d="M0 0 L1 1"/>
		<path id="inline" class="classed" d="M0 0 L1 1" style="opacity: 0.75"/>
		<path id="high" class="high" d="M0 0 L1 1"/>
		<path id="low" class="low" d="M0 0 L1 1"/>
		<path id="invalid" class="invalid" d="M0 0 L1 1"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let parent) = document.elements[0] else {
		Issue.record("Expected parent group")
		return
	}

	var paths: [String: SVGPathData] = [:]
	for child in parent.children {
		if case .path(let path) = child {
			paths[path.id] = path
		}
	}
	for element in document.elements.dropFirst() {
		if case .path(let path) = element {
			paths[path.id] = path
		}
	}

	#expect(parent.attributes.opacity == 0.5)
	#expect(paths["notInherited"]?.attributes.opacity == 1)
	#expect(paths["explicitInherit"]?.attributes.opacity == 0.5)
	#expect(paths["initial"]?.attributes.opacity == 1)
	#expect(paths["attribute"]?.attributes.opacity == 0.6)
	#expect(paths["classed"]?.attributes.opacity == 0.25)
	#expect(paths["inline"]?.attributes.opacity == 0.75)
	#expect(paths["high"]?.attributes.opacity == 1)
	#expect(paths["low"]?.attributes.opacity == 0)
	#expect(paths["invalid"]?.attributes.opacity == 1)
}

@Test func svgParserAppliesInlineStyleAttributeAsDeclarationList() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="black" stroke-width="1">
		<style>.accent { fill: red; stroke-width: 3; opacity: 0.25; stroke-linecap: butt; }</style>
		<path
			id="styled"
			class="accent"
			d="M0 0 L10 10"
			fill="blue"
			stroke-width="2"
			style=" fill: blue; stroke-width: 9; opacity: 0.75; stroke-linecap: square; ignored ; fill: #336699; "
		/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .path(let path) = document.elements.first else {
		Issue.record("Expected styled path")
		return
	}

	#expect(path.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(path.attributes.strokeWidth == 9)
	#expect(path.attributes.opacity == 0.75)
	#expect(path.attributes.strokeLineCap == .square)
	#expect(path.unknownAttributes["style"] == nil)
}

@Test func svgParserAppliesStyleElementsOnlyForMatchingMedia() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>.base { stroke-width: 2; }</style>
		<style media="screen">.media { fill: #336699; }</style>
		<style media="print">.media { fill: red; stroke-width: 9; }</style>
		<style media="print, screen">.listed { stroke: blue; }</style>
		<style media="all">.all { opacity: 0.5; }</style>
		<path id="styled" class="base media listed all" d="M0 0 L10 10" fill="black"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .path(let path) = document.elements.first else {
		Issue.record("Expected styled path")
		return
	}

	#expect(path.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(path.attributes.strokeWidth == 2)
	#expect(path.attributes.stroke == .color(.blue))
	#expect(path.attributes.opacity == 0.5)
}

@Test func svgParserAppliesFillPaintInitialInheritanceAndCascade() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>.accent { fill: #336699; }</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" fill="red">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="none" d="M0 0 L10 10" fill="none"/>
			<path id="classed" class="accent" d="M0 0 L10 10"/>
			<path id="inline" class="accent" d="M0 0 L10 10" style="fill: blue"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.fill == .color(.black))
	#expect(paths["inherited"]?.attributes.fill == .color(.red))
	#expect(paths["none"]?.attributes.fill == SVGPaint.none)
	#expect(paths["classed"]?.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(paths["inline"]?.attributes.fill == .color(.blue))
}

@Test func svgParserAppliesStrokePaintInitialInheritanceAndCascade() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.outline { stroke: #336699; }
			.none { stroke: none; }
			.context { stroke: context-stroke; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" stroke="red">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="classed" class="outline" d="M0 0 L10 10"/>
			<path id="none" class="none" d="M0 0 L10 10"/>
			<path id="url" d="M0 0 L10 10" stroke="url(#paint) blue"/>
			<path id="current" d="M0 0 L10 10" color="#336699" stroke="currentColor"/>
			<path id="context" class="context" d="M0 0 L10 10"/>
			<path id="inline" class="outline" d="M0 0 L10 10" style="stroke: green"/>
			<path id="invalid" d="M0 0 L10 10" stroke="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.stroke == SVGPaint.none)
	#expect(paths["inherited"]?.attributes.stroke == .color(.red))
	#expect(paths["classed"]?.attributes.stroke == .color(Color(0.2, 0.4, 0.6)))
	#expect(paths["none"]?.attributes.stroke == SVGPaint.none)
	#expect(paths["url"]?.attributes.stroke == .urlWithFallback("paint", .color(.blue)))
	#expect(paths["current"]?.attributes.stroke == .currentColor)
	#expect(paths["context"]?.attributes.stroke == .contextStroke)
	#expect(paths["inline"]?.attributes.stroke == .color(Color(0, 128 / 255, 0)))
	#expect(paths["invalid"]?.attributes.stroke == .color(.red))
}

@Test func svgParserAppliesStrokeOpacityInitialInheritancePercentagesAndClamping() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.soft { stroke-opacity: 50%; }
			.high { stroke-opacity: 2; }
			.low { stroke-opacity: -25%; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" stroke-opacity="0.25">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="percentage" class="soft" d="M0 0 L10 10"/>
			<path id="high" class="high" d="M0 0 L10 10"/>
			<path id="low" class="low" d="M0 0 L10 10"/>
			<path id="inline" class="soft" d="M0 0 L10 10" style="stroke-opacity: 75%"/>
			<path id="invalid" d="M0 0 L10 10" stroke-opacity="bad"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeOpacity == 1)
	#expect(paths["inherited"]?.attributes.strokeOpacity == 0.25)
	#expect(paths["percentage"]?.attributes.strokeOpacity == 0.5)
	#expect(paths["high"]?.attributes.strokeOpacity == 1)
	#expect(paths["low"]?.attributes.strokeOpacity == 0)
	#expect(paths["inline"]?.attributes.strokeOpacity == 0.75)
	#expect(paths["invalid"]?.attributes.strokeOpacity == 0.25)
}

@Test func svgParserAppliesButtStrokeLineCapInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.flat { stroke-linecap: butt; }
			.other { stroke-linecap: square; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="butt-parent" stroke-linecap="butt">
			<path id="inherited" d="M0 0 L10 10"/>
		</g>
		<g id="round-parent" stroke-linecap="round">
			<path id="attribute" d="M0 0 L10 10" stroke-linecap="butt"/>
			<path id="class-rule" class="flat" d="M0 0 L10 10"/>
			<path id="inline" class="other" d="M0 0 L10 10" style="stroke-linecap: butt"/>
			<path id="invalid" d="M0 0 L10 10" stroke-linecap="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeLineCap == .butt)
	#expect(paths["inherited"]?.attributes.strokeLineCap == .butt)
	#expect(paths["attribute"]?.attributes.strokeLineCap == .butt)
	#expect(paths["class-rule"]?.attributes.strokeLineCap == .butt)
	#expect(paths["inline"]?.attributes.strokeLineCap == .butt)
	#expect(paths["invalid"]?.attributes.strokeLineCap == .round)
}

@Test func svgParserAppliesRoundStrokeLineCapInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.rounding { stroke-linecap: round; }
			.other { stroke-linecap: butt; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="round-parent" stroke-linecap="round">
			<path id="inherited" d="M0 0 L10 10"/>
		</g>
		<g id="square-parent" stroke-linecap="square">
			<path id="attribute" d="M0 0 L10 10" stroke-linecap="round"/>
			<path id="class-rule" class="rounding" d="M0 0 L10 10"/>
			<path id="inline" class="other" d="M0 0 L10 10" style="stroke-linecap: round"/>
			<path id="invalid" d="M0 0 L10 10" stroke-linecap="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeLineCap == .butt)
	#expect(paths["inherited"]?.attributes.strokeLineCap == .round)
	#expect(paths["attribute"]?.attributes.strokeLineCap == .round)
	#expect(paths["class-rule"]?.attributes.strokeLineCap == .round)
	#expect(paths["inline"]?.attributes.strokeLineCap == .round)
	#expect(paths["invalid"]?.attributes.strokeLineCap == .square)
}

@Test func svgParserAppliesSquareStrokeLineCapInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.blocky { stroke-linecap: square; }
			.other { stroke-linecap: round; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="square-parent" stroke-linecap="square">
			<path id="inherited" d="M0 0 L10 10"/>
		</g>
		<g id="round-parent" stroke-linecap="round">
			<path id="attribute" d="M0 0 L10 10" stroke-linecap="square"/>
			<path id="class-rule" class="blocky" d="M0 0 L10 10"/>
			<path id="inline" class="other" d="M0 0 L10 10" style="stroke-linecap: square"/>
			<path id="invalid" d="M0 0 L10 10" stroke-linecap="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeLineCap == .butt)
	#expect(paths["inherited"]?.attributes.strokeLineCap == .square)
	#expect(paths["attribute"]?.attributes.strokeLineCap == .square)
	#expect(paths["class-rule"]?.attributes.strokeLineCap == .square)
	#expect(paths["inline"]?.attributes.strokeLineCap == .square)
	#expect(paths["invalid"]?.attributes.strokeLineCap == .round)
}

@Test func svgParserAppliesMiterStrokeLineJoinInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.sharp { stroke-linejoin: miter; }
			.other { stroke-linejoin: round; }
		</style>
		<path id="initial" d="M0 0 L10 10 L10 0"/>
		<g id="miter-parent" stroke-linejoin="miter">
			<path id="inherited" d="M0 0 L10 10 L10 0"/>
		</g>
		<g id="bevel-parent" stroke-linejoin="bevel">
			<path id="attribute" d="M0 0 L10 10 L10 0" stroke-linejoin="miter"/>
			<path id="class-rule" class="sharp" d="M0 0 L10 10 L10 0"/>
			<path id="inline" class="other" d="M0 0 L10 10 L10 0" style="stroke-linejoin: miter"/>
			<path id="invalid" d="M0 0 L10 10 L10 0" stroke-linejoin="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["inherited"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["attribute"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["class-rule"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["inline"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["invalid"]?.attributes.strokeLineJoin == .bevel)
}

@Test func svgParserAppliesRoundStrokeLineJoinInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.soft { stroke-linejoin: round; }
			.other { stroke-linejoin: miter; }
		</style>
		<path id="initial" d="M0 0 L10 10 L10 0"/>
		<g id="round-parent" stroke-linejoin="round">
			<path id="inherited" d="M0 0 L10 10 L10 0"/>
		</g>
		<g id="bevel-parent" stroke-linejoin="bevel">
			<path id="attribute" d="M0 0 L10 10 L10 0" stroke-linejoin="round"/>
			<path id="class-rule" class="soft" d="M0 0 L10 10 L10 0"/>
			<path id="inline" class="other" d="M0 0 L10 10 L10 0" style="stroke-linejoin: round"/>
			<path id="invalid" d="M0 0 L10 10 L10 0" stroke-linejoin="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["inherited"]?.attributes.strokeLineJoin == .round)
	#expect(paths["attribute"]?.attributes.strokeLineJoin == .round)
	#expect(paths["class-rule"]?.attributes.strokeLineJoin == .round)
	#expect(paths["inline"]?.attributes.strokeLineJoin == .round)
	#expect(paths["invalid"]?.attributes.strokeLineJoin == .bevel)
}

@Test func svgParserAppliesBevelStrokeLineJoinInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.chamfer { stroke-linejoin: bevel; }
			.other { stroke-linejoin: miter; }
		</style>
		<path id="initial" d="M0 0 L10 10 L10 0"/>
		<g id="bevel-parent" stroke-linejoin="bevel">
			<path id="inherited" d="M0 0 L10 10 L10 0"/>
		</g>
		<g id="round-parent" stroke-linejoin="round">
			<path id="attribute" d="M0 0 L10 10 L10 0" stroke-linejoin="bevel"/>
			<path id="class-rule" class="chamfer" d="M0 0 L10 10 L10 0"/>
			<path id="inline" class="other" d="M0 0 L10 10 L10 0" style="stroke-linejoin: bevel"/>
			<path id="invalid" d="M0 0 L10 10 L10 0" stroke-linejoin="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeLineJoin == .miter)
	#expect(paths["inherited"]?.attributes.strokeLineJoin == .bevel)
	#expect(paths["attribute"]?.attributes.strokeLineJoin == .bevel)
	#expect(paths["class-rule"]?.attributes.strokeLineJoin == .bevel)
	#expect(paths["inline"]?.attributes.strokeLineJoin == .bevel)
	#expect(paths["invalid"]?.attributes.strokeLineJoin == .round)
}

@Test func svgParserAppliesStrokeMiterLimitInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.tight { stroke-miterlimit: 0.5; }
			.negative { stroke-miterlimit: -1; }
		</style>
		<path id="initial" d="M0 0 L10 10 L10 0"/>
		<g id="parent" stroke-miterlimit="7">
			<path id="inherited" d="M0 0 L10 10 L10 0"/>
			<path id="attribute" d="M0 0 L10 10 L10 0" stroke-miterlimit="9"/>
			<path id="class-rule" class="tight" d="M0 0 L10 10 L10 0"/>
			<path id="inline" class="tight" d="M0 0 L10 10 L10 0" style="stroke-miterlimit: 3"/>
			<path id="negative-attribute" d="M0 0 L10 10 L10 0" stroke-miterlimit="-2"/>
			<path id="negative-class" class="negative" d="M0 0 L10 10 L10 0"/>
			<path id="invalid" d="M0 0 L10 10 L10 0" stroke-miterlimit="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeMiterLimit == 4)
	#expect(paths["inherited"]?.attributes.strokeMiterLimit == 7)
	#expect(paths["attribute"]?.attributes.strokeMiterLimit == 9)
	#expect(paths["class-rule"]?.attributes.strokeMiterLimit == 0.5)
	#expect(paths["inline"]?.attributes.strokeMiterLimit == 3)
	#expect(paths["negative-attribute"]?.attributes.strokeMiterLimit == 7)
	#expect(paths["negative-class"]?.attributes.strokeMiterLimit == 7)
	#expect(paths["invalid"]?.attributes.strokeMiterLimit == 7)
}

@Test func svgParserAppliesStrokeDashArrayInitialInheritanceCascadeNoneAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.dashed { stroke-dasharray: 2, 3 4; }
			.negative { stroke-dasharray: -1 2; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" stroke-dasharray="8 4">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="attribute" d="M0 0 L10 10" stroke-dasharray="5 1 2"/>
			<path id="length-percentage" d="M0 0 L10 10" stroke-dasharray="12px 50%"/>
			<path id="class-rule" class="dashed" d="M0 0 L10 10"/>
			<path id="inline" class="dashed" d="M0 0 L10 10" style="stroke-dasharray: 6, 2"/>
			<path id="none" d="M0 0 L10 10" stroke-dasharray="none"/>
			<path id="negative-attribute" d="M0 0 L10 10" stroke-dasharray="3 -2"/>
			<path id="negative-class" class="negative" d="M0 0 L10 10"/>
			<path id="invalid" d="M0 0 L10 10" stroke-dasharray="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeDashArray == [])
	#expect(paths["inherited"]?.attributes.strokeDashArray == [8, 4])
	#expect(paths["attribute"]?.attributes.strokeDashArray == [5, 1, 2])
	#expect(paths["length-percentage"]?.attributes.strokeDashArray == [12, 50])
	#expect(paths["class-rule"]?.attributes.strokeDashArray == [2, 3, 4])
	#expect(paths["inline"]?.attributes.strokeDashArray == [6, 2])
	#expect(paths["none"]?.attributes.strokeDashArray == [])
	#expect(paths["negative-attribute"]?.attributes.strokeDashArray == [8, 4])
	#expect(paths["negative-class"]?.attributes.strokeDashArray == [8, 4])
	#expect(paths["invalid"]?.attributes.strokeDashArray == [8, 4])
}

@Test func svgParserAppliesStrokeDashOffsetInitialInheritanceCascadeLengthsAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.offset { stroke-dashoffset: 50%; }
			.negative { stroke-dashoffset: -3px; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" stroke-dashoffset="7">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="attribute" d="M0 0 L10 10" stroke-dashoffset="12px"/>
			<path id="class-rule" class="offset" d="M0 0 L10 10"/>
			<path id="inline" class="offset" d="M0 0 L10 10" style="stroke-dashoffset: -2"/>
			<path id="negative-class" class="negative" d="M0 0 L10 10"/>
			<path id="invalid" d="M0 0 L10 10" stroke-dashoffset="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.strokeDashOffset == 0)
	#expect(paths["inherited"]?.attributes.strokeDashOffset == 7)
	#expect(paths["attribute"]?.attributes.strokeDashOffset == 12)
	#expect(abs((paths["class-rule"]?.attributes.strokeDashOffset ?? 0) - 50) < 0.000001)
	#expect(paths["inline"]?.attributes.strokeDashOffset == -2)
	#expect(paths["negative-class"]?.attributes.strokeDashOffset == -3)
	#expect(paths["invalid"]?.attributes.strokeDashOffset == 7)
}

@Test func svgParserAppliesPaintOrderInitialInheritanceCascadeResolutionAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.stroke-first { paint-order: stroke; }
			.markers-first { paint-order: markers fill; }
			.duplicate { paint-order: stroke stroke; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" paint-order="stroke fill">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="attribute" d="M0 0 L10 10" paint-order="markers stroke"/>
			<path id="class-rule" class="stroke-first" d="M0 0 L10 10"/>
			<path id="inline" class="markers-first" d="M0 0 L10 10" style="paint-order: normal"/>
			<path id="invalid" d="M0 0 L10 10" paint-order="bogus"/>
			<path id="duplicate" class="duplicate" d="M0 0 L10 10"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.paintOrder == .normal)
	#expect(paths["initial"]?.attributes.paintOrder.resolvedOperations == [.fill, .stroke, .markers])
	#expect(paths["inherited"]?.attributes.paintOrder == .specified([.stroke, .fill]))
	#expect(paths["inherited"]?.attributes.paintOrder.resolvedOperations == [.stroke, .fill, .markers])
	#expect(paths["attribute"]?.attributes.paintOrder == .specified([.markers, .stroke]))
	#expect(paths["attribute"]?.attributes.paintOrder.resolvedOperations == [.markers, .stroke, .fill])
	#expect(paths["class-rule"]?.attributes.paintOrder == .specified([.stroke]))
	#expect(paths["class-rule"]?.attributes.paintOrder.resolvedOperations == [.stroke, .fill, .markers])
	#expect(paths["inline"]?.attributes.paintOrder == .normal)
	#expect(paths["invalid"]?.attributes.paintOrder == .specified([.stroke, .fill]))
	#expect(paths["duplicate"]?.attributes.paintOrder == .specified([.stroke, .fill]))
}

@Test func svgParserAppliesFillOpacityInitialInheritancePercentagesAndClamping() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.soft { fill-opacity: 50%; }
			.high { fill-opacity: 2; }
			.low { fill-opacity: -25%; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" fill-opacity="0.25">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="percentage" class="soft" d="M0 0 L10 10"/>
			<path id="high" class="high" d="M0 0 L10 10"/>
			<path id="low" class="low" d="M0 0 L10 10"/>
			<path id="inline" class="soft" d="M0 0 L10 10" style="fill-opacity: 75%"/>
			<path id="invalid" d="M0 0 L10 10" fill-opacity="bad"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.fillOpacity == 1)
	#expect(paths["inherited"]?.attributes.fillOpacity == 0.25)
	#expect(paths["percentage"]?.attributes.fillOpacity == 0.5)
	#expect(paths["high"]?.attributes.fillOpacity == 1)
	#expect(paths["low"]?.attributes.fillOpacity == 0)
	#expect(paths["inline"]?.attributes.fillOpacity == 0.75)
	#expect(paths["invalid"]?.attributes.fillOpacity == 0.25)
}

@Test func svgParserAppliesNonzeroFillRuleInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.winding { fill-rule: nonzero; }
			.other { fill-rule: evenodd; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="nonzero-parent" fill-rule="nonzero">
			<path id="inherited" d="M0 0 L10 10"/>
		</g>
		<g id="evenodd-parent" fill-rule="evenodd">
			<path id="attribute" d="M0 0 L10 10" fill-rule="nonzero"/>
			<path id="class-rule" class="winding" d="M0 0 L10 10"/>
			<path id="inline" class="other" d="M0 0 L10 10" style="fill-rule: nonzero"/>
			<path id="invalid" d="M0 0 L10 10" fill-rule="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.fillRule == .winding)
	#expect(paths["inherited"]?.attributes.fillRule == .winding)
	#expect(paths["attribute"]?.attributes.fillRule == .winding)
	#expect(paths["class-rule"]?.attributes.fillRule == .winding)
	#expect(paths["inline"]?.attributes.fillRule == .winding)
	#expect(paths["invalid"]?.attributes.fillRule == .evenOdd)
}

@Test func svgParserAppliesEvenOddFillRuleInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.alternate { fill-rule: evenodd; }
			.other { fill-rule: nonzero; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="evenodd-parent" fill-rule="evenodd">
			<path id="inherited" d="M0 0 L10 10"/>
		</g>
		<g id="nonzero-parent" fill-rule="nonzero">
			<path id="attribute" d="M0 0 L10 10" fill-rule="evenodd"/>
			<path id="class-rule" class="alternate" d="M0 0 L10 10"/>
			<path id="inline" class="other" d="M0 0 L10 10" style="fill-rule: evenodd"/>
			<path id="invalid" d="M0 0 L10 10" fill-rule="bogus"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.fillRule == .winding)
	#expect(paths["inherited"]?.attributes.fillRule == .evenOdd)
	#expect(paths["attribute"]?.attributes.fillRule == .evenOdd)
	#expect(paths["class-rule"]?.attributes.fillRule == .evenOdd)
	#expect(paths["inline"]?.attributes.fillRule == .evenOdd)
	#expect(paths["invalid"]?.attributes.fillRule == .winding)
}

@Test func svgParserInheritsOnlyInheritedPresentationProperties() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g
			id="parent"
			fill="red"
			fill-opacity="0.5"
			fill-rule="evenodd"
			stroke="blue"
			stroke-width="4"
			stroke-linecap="round"
			stroke-linejoin="bevel"
			stroke-miterlimit="9"
			stroke-dasharray="2 3"
			stroke-dashoffset="1"
			stroke-opacity="0.25"
			paint-order="stroke fill"
			visibility="hidden"
			opacity="0.4"
			display="none"
			clip-path="url(#clip)"
			filter="url(#filter)"
			mask="url(#mask)"
			transform="translate(5 6)"
			vector-effect="non-scaling-stroke"
		>
			<path id="child" d="M0 0 L10 10"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let parent) = document.elements.first else {
		Issue.record("Expected parent group")
		return
	}
	guard case .path(let child) = parent.children.first else {
		Issue.record("Expected child path")
		return
	}

	#expect(child.attributes.fill == .color(.red))
	#expect(child.attributes.fillOpacity == 0.5)
	#expect(child.attributes.fillRule == .evenOdd)
	#expect(child.attributes.stroke == .color(.blue))
	#expect(child.attributes.strokeWidth == 4)
	#expect(child.attributes.strokeLineCap == .round)
	#expect(child.attributes.strokeLineJoin == .bevel)
	#expect(child.attributes.strokeMiterLimit == 9)
	#expect(child.attributes.strokeDashArray == [2, 3])
	#expect(child.attributes.strokeDashOffset == 1)
	#expect(child.attributes.strokeOpacity == 0.25)
	#expect(child.attributes.paintOrder == .specified([.stroke, .fill]))
	#expect(child.attributes.visibility == .hidden)
	#expect(child.attributes.opacity == 1)
	#expect(child.attributes.display == .inline)
	#expect(child.attributes.clipPathID == nil)
	#expect(child.attributes.filterID == nil)
	#expect(child.attributes.maskID == nil)
	#expect(child.attributes.transform == .identity)
	#expect(child.attributes.vectorEffect == SVGVectorEffect.none)
}

@Test func svgParserAppliesExplicitInheritKeywordForSupportedProperties() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>.override { fill: blue; opacity: 0.2; display: inline; clip-path: url(#other); transform: scale(2); vector-effect: none; }</style>
		<g
			id="parent"
			fill="red"
			stroke-width="4"
			opacity="0.4"
			display="none"
			clip-path="url(#clip)"
			filter="url(#filter)"
			mask="url(#mask)"
			transform="translate(5 6)"
			vector-effect="non-scaling-stroke"
		>
			<path
				id="child"
				class="override"
				d="M0 0 L10 10"
				style="fill: inherit; stroke-width: inherit; opacity: inherit; display: inherit; clip-path: inherit; filter: inherit; mask: inherit; transform: inherit; vector-effect: inherit"
			/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let parent) = document.elements.first else {
		Issue.record("Expected parent group")
		return
	}
	guard case .path(let child) = parent.children.first else {
		Issue.record("Expected child path")
		return
	}

	#expect(child.attributes.fill == .color(.red))
	#expect(child.attributes.strokeWidth == 4)
	#expect(child.attributes.opacity == 0.4)
	#expect(child.attributes.display == .none)
	#expect(child.attributes.clipPathID == "clip")
	#expect(child.attributes.filterID == "filter")
	#expect(child.attributes.maskID == "mask")
	#expect(child.attributes.transform == Transform.identity.translatedBy(x: 5, y: 6))
	#expect(child.attributes.vectorEffect == .effects([.nonScalingStroke], coordinateSpace: .viewport))
}

@Test func svgParserAppliesCurrentColorFromInheritedColorProperty() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" color="red">
		<style>.accent { color: #336699; fill: currentColor; stroke: currentColor; }</style>
		<g id="parent" color="blue">
			<path id="classed" class="accent" d="M0 0 L10 10"/>
			<path id="inlineInherit" class="accent" d="M0 0 L10 10" style="color: currentColor; stroke: url(#missing) currentColor"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let parent) = document.elements.first else {
		Issue.record("Expected parent group")
		return
	}
	let paths = Dictionary(uniqueKeysWithValues: parent.children.compactMap { element -> (String, SVGPathData)? in
		if case .path(let path) = element { return (path.id, path) }
		return nil
	})
	let classed = try #require(paths["classed"])
	let inlineInherit = try #require(paths["inlineInherit"])

	#expect(parent.attributes.color == .blue)
	#expect(classed.attributes.color == Color(0.2, 0.4, 0.6))
	#expect(classed.attributes.fill == .currentColor)
	#expect(classed.attributes.stroke == .currentColor)
	#expect(inlineInherit.attributes.color == .blue)
	#expect(inlineInherit.attributes.fill == .currentColor)
	#expect(inlineInherit.attributes.stroke == .urlWithFallback("missing", .currentColor))
}

@Test func svgParserAppliesColorPropertyWithCSSColorSyntaxesInheritanceAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.rgb-percent { color: rgb(100%, 50%, 0%); }
			.rgba { color: rgba(0, 0, 255, 0.25); }
			.hsl { color: hsl(120, 100%, 25%); }
			.hsla { color: hsla(240, 100%, 50%, 0.5); }
			.current { color: currentColor; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" color="blue">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="rgb" d="M0 0 L10 10" color="rgb(255, 128, 0)"/>
			<path id="rgb-percent" class="rgb-percent" d="M0 0 L10 10"/>
			<path id="rgba" class="rgba" d="M0 0 L10 10"/>
			<path id="hsl" class="hsl" d="M0 0 L10 10"/>
			<path id="hsla" class="hsla" d="M0 0 L10 10"/>
			<path id="extended-name" d="M0 0 L10 10" color="aliceblue"/>
			<path id="transparent" d="M0 0 L10 10" color="transparent"/>
			<path id="inline" class="rgba" d="M0 0 L10 10" style="color: #336699"/>
			<path id="current" class="current" d="M0 0 L10 10"/>
			<path id="invalid" d="M0 0 L10 10" color="not-a-color"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	expectColorApproximately(paths["initial"]?.attributes.color, .black)
	expectColorApproximately(paths["inherited"]?.attributes.color, .blue)
	expectColorApproximately(paths["rgb"]?.attributes.color, Color(1, 128 / 255, 0))
	expectColorApproximately(paths["rgb-percent"]?.attributes.color, Color(1, 0.5, 0))
	expectColorApproximately(paths["rgba"]?.attributes.color, Color(0, 0, 1, 0.25))
	expectColorApproximately(paths["hsl"]?.attributes.color, Color(0, 0.5, 0))
	expectColorApproximately(paths["hsla"]?.attributes.color, Color(0, 0, 1, 0.5))
	expectColorApproximately(paths["extended-name"]?.attributes.color, Color(240 / 255, 248 / 255, 1))
	expectColorApproximately(paths["transparent"]?.attributes.color, .clear)
	expectColorApproximately(paths["inline"]?.attributes.color, Color(0.2, 0.4, 0.6))
	expectColorApproximately(paths["current"]?.attributes.color, .blue)
	expectColorApproximately(paths["invalid"]?.attributes.color, .blue)
}

@Test func svgParserAppliesColorInterpolationInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.auto { color-interpolation: auto; }
			.invalid { color-interpolation: lab; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" color-interpolation="linearRGB">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="auto" class="auto" d="M0 0 L10 10"/>
			<path id="srgb" d="M0 0 L10 10" color-interpolation="sRGB"/>
			<path id="inline" class="auto" d="M0 0 L10 10" style="color-interpolation: linearRGB"/>
			<path id="invalid" class="invalid" d="M0 0 L10 10"/>
			<path id="inherit" class="auto" d="M0 0 L10 10" style="color-interpolation: inherit"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.colorInterpolation == .sRGB)
	#expect(paths["inherited"]?.attributes.colorInterpolation == .linearRGB)
	#expect(paths["auto"]?.attributes.colorInterpolation == .auto)
	#expect(paths["srgb"]?.attributes.colorInterpolation == .sRGB)
	#expect(paths["inline"]?.attributes.colorInterpolation == .linearRGB)
	#expect(paths["invalid"]?.attributes.colorInterpolation == .linearRGB)
	#expect(paths["inherit"]?.attributes.colorInterpolation == .linearRGB)
}

@Test func svgParserAppliesColorRenderingInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.speed { color-rendering: optimizeSpeed; }
			.invalid { color-rendering: geometricPrecision; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" color-rendering="optimizeQuality">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="speed" class="speed" d="M0 0 L10 10"/>
			<path id="auto" d="M0 0 L10 10" color-rendering="auto"/>
			<path id="inline" class="speed" d="M0 0 L10 10" style="color-rendering: optimizeQuality"/>
			<path id="invalid" class="invalid" d="M0 0 L10 10"/>
			<path id="inherit" class="speed" d="M0 0 L10 10" style="color-rendering: inherit"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.colorRendering == .auto)
	#expect(paths["inherited"]?.attributes.colorRendering == .optimizeQuality)
	#expect(paths["speed"]?.attributes.colorRendering == .optimizeSpeed)
	#expect(paths["auto"]?.attributes.colorRendering == .auto)
	#expect(paths["inline"]?.attributes.colorRendering == .optimizeQuality)
	#expect(paths["invalid"]?.attributes.colorRendering == .optimizeQuality)
	#expect(paths["inherit"]?.attributes.colorRendering == .optimizeQuality)
}

@Test func svgParserAppliesShapeRenderingInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.crisp { shape-rendering: crispEdges; }
			.invalid { shape-rendering: optimizeQuality; }
		</style>
		<path id="initial" d="M0 0 L10 10"/>
		<g id="parent" shape-rendering="geometricPrecision">
			<path id="inherited" d="M0 0 L10 10"/>
			<path id="crisp" class="crisp" d="M0 0 L10 10"/>
			<path id="speed" d="M0 0 L10 10" shape-rendering="optimizeSpeed"/>
			<path id="auto" d="M0 0 L10 10" shape-rendering="auto"/>
			<path id="inline" class="crisp" d="M0 0 L10 10" style="shape-rendering: geometricPrecision"/>
			<path id="invalid" class="invalid" d="M0 0 L10 10"/>
			<path id="inherit" class="crisp" d="M0 0 L10 10" style="shape-rendering: inherit"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var paths: [String: SVGPathData] = [:]
	for element in document.elements {
		switch element {
		case .path(let path):
			paths[path.id] = path
		case .group(let group):
			for child in group.children {
				if case .path(let path) = child {
					paths[path.id] = path
				}
			}
		default:
			break
		}
	}

	#expect(paths["initial"]?.attributes.shapeRendering == .auto)
	#expect(paths["inherited"]?.attributes.shapeRendering == .geometricPrecision)
	#expect(paths["crisp"]?.attributes.shapeRendering == .crispEdges)
	#expect(paths["speed"]?.attributes.shapeRendering == .optimizeSpeed)
	#expect(paths["auto"]?.attributes.shapeRendering == .auto)
	#expect(paths["inline"]?.attributes.shapeRendering == .geometricPrecision)
	#expect(paths["invalid"]?.attributes.shapeRendering == .geometricPrecision)
	#expect(paths["inherit"]?.attributes.shapeRendering == .geometricPrecision)
}

@Test func svgParserAppliesTextRenderingInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.legible { text-rendering: optimizeLegibility; }
			.invalid { text-rendering: crispEdges; }
		</style>
		<text id="initial" x="0" y="1">Initial</text>
		<g id="parent" text-rendering="geometricPrecision">
			<text id="inherited" x="0" y="2">Inherited</text>
			<text id="legible" class="legible" x="0" y="3">Legible</text>
			<text id="speed" x="0" y="4" text-rendering="optimizeSpeed">Speed</text>
			<text id="auto" x="0" y="5" text-rendering="auto">Auto</text>
			<text id="inline" class="legible" x="0" y="6" style="text-rendering: geometricPrecision">Inline</text>
			<text id="invalid" class="invalid" x="0" y="7">Invalid</text>
			<text id="inherit" class="legible" x="0" y="8" style="text-rendering: inherit">Inherit</text>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var texts: [String: SVGTextData] = [:]
	for element in document.elements {
		switch element {
		case .text(let text):
			texts[text.id] = text
		case .group(let group):
			for child in group.children {
				if case .text(let text) = child {
					texts[text.id] = text
				}
			}
		default:
			break
		}
	}

	#expect(texts["initial"]?.attributes.textRendering == .auto)
	#expect(texts["inherited"]?.attributes.textRendering == .geometricPrecision)
	#expect(texts["legible"]?.attributes.textRendering == .optimizeLegibility)
	#expect(texts["speed"]?.attributes.textRendering == .optimizeSpeed)
	#expect(texts["auto"]?.attributes.textRendering == .auto)
	#expect(texts["inline"]?.attributes.textRendering == .geometricPrecision)
	#expect(texts["invalid"]?.attributes.textRendering == .geometricPrecision)
	#expect(texts["inherit"]?.attributes.textRendering == .geometricPrecision)
}

@Test func svgParserAppliesImageRenderingInitialInheritanceCascadeAndInvalidFallback() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<style>
			.speed { image-rendering: optimizeSpeed; }
			.invalid { image-rendering: crispEdges; }
		</style>
		<image id="initial" href="initial.png" x="0" y="0" width="1" height="1"/>
		<g id="parent" image-rendering="optimizeQuality">
			<image id="inherited" href="inherited.png" x="0" y="1" width="1" height="1"/>
			<image id="speed" class="speed" href="speed.png" x="0" y="2" width="1" height="1"/>
			<image id="auto" href="auto.png" x="0" y="3" width="1" height="1" image-rendering="auto"/>
			<image id="inline" class="speed" href="inline.png" x="0" y="4" width="1" height="1" style="image-rendering: optimizeQuality"/>
			<image id="invalid" class="invalid" href="invalid.png" x="0" y="5" width="1" height="1"/>
			<image id="inherit" class="speed" href="inherit.png" x="0" y="6" width="1" height="1" style="image-rendering: inherit"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	var images: [String: SVGImageData] = [:]
	for element in document.elements {
		switch element {
		case .image(let image):
			images[image.id] = image
		case .group(let group):
			for child in group.children {
				if case .image(let image) = child {
					images[image.id] = image
				}
			}
		default:
			break
		}
	}

	#expect(images["initial"]?.attributes.imageRendering == .auto)
	#expect(images["inherited"]?.attributes.imageRendering == .optimizeQuality)
	#expect(images["speed"]?.attributes.imageRendering == .optimizeSpeed)
	#expect(images["auto"]?.attributes.imageRendering == .auto)
	#expect(images["inline"]?.attributes.imageRendering == .optimizeQuality)
	#expect(images["invalid"]?.attributes.imageRendering == .optimizeQuality)
	#expect(images["inherit"]?.attributes.imageRendering == .optimizeQuality)
}

@Test func svgParserPreservesInitialUserCoordinateSystem() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="300" height="100">
		<line id="diagonal" x1="0" y1="0" x2="300" y2="100"/>
		<rect id="lower-left" x="0" y="97" width="3" height="3"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 300, height: 100))

	guard case .line(let diagonal) = document.elements.first else {
		Issue.record("Expected first child to be a line")
		return
	}
	#expect(diagonal.x1 == 0)
	#expect(diagonal.y1 == 0)
	#expect(diagonal.x2 == 300)
	#expect(diagonal.y2 == 100)

	guard case .rect(let lowerLeft) = document.elements.dropFirst().first else {
		Issue.record("Expected second child to be a rect")
		return
	}
	#expect(lowerLeft.path.commands == [
		.rect(Rect(x: 0, y: 97, width: 3, height: 3)),
	])
}

@Test func svgParserResolvesViewportCoordinatesFromViewportDimensions() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" viewBox="0 0 20 10">
		<svg id="nested" x="50%" y="25%" width="25%" height="50%" viewBox="0 0 5 5"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 20, height: 10))
	guard case .svg(let nested) = document.elements.first else {
		Issue.record("Expected nested svg child")
		return
	}

	#expect(nested.x == 100)
	#expect(nested.y == 25)
	#expect(nested.width == 50)
	#expect(nested.height == 50)
	#expect(nested.viewBox == Rect(x: 0, y: 0, width: 5, height: 5))
}

@Test func svgPreserveAspectRatioComputesViewBoxToViewportTransform() throws {
	let transform = try #require(SVGPreserveAspectRatio.default.viewBoxTransform(
		from: Rect(x: 10, y: 20, width: 100, height: 50),
		to: Rect(x: 5, y: 7, width: 200, height: 100)
	))

	#expect(transform == Transform(a: 2, b: 0, c: 0, d: 2, tx: -15, ty: -33))
	#expect(Point(10, 20).applying(transform) == Point(5, 7))
	#expect(Point(110, 70).applying(transform) == Point(205, 107))
}

@Test func svgPreserveAspectRatioNoneUsesNonUniformViewBoxScale() throws {
	let transform = try #require(SVGPreserveAspectRatio(align: .none, meetOrSlice: .slice).viewBoxTransform(
		from: Rect(x: 0, y: 0, width: 100, height: 50),
		to: Rect(x: 0, y: 0, width: 300, height: 100)
	))

	#expect(transform == Transform(a: 3, b: 0, c: 0, d: 2, tx: 0, ty: 0))
	#expect(Point(100, 50).applying(transform) == Point(300, 100))
}

@Test func svgPreserveAspectRatioMeetUsesUniformContainedScale() throws {
	let centered = try #require(SVGPreserveAspectRatio(align: .xMidYMid, meetOrSlice: .meet).viewBoxTransform(
		from: Rect(x: 0, y: 0, width: 100, height: 50),
		to: Rect(x: 0, y: 0, width: 300, height: 300)
	))
	let maxAligned = try #require(SVGPreserveAspectRatio(align: .xMaxYMax, meetOrSlice: .meet).viewBoxTransform(
		from: Rect(x: 0, y: 0, width: 100, height: 50),
		to: Rect(x: 0, y: 0, width: 300, height: 300)
	))

	#expect(centered == Transform(a: 3, b: 0, c: 0, d: 3, tx: 0, ty: 75))
	#expect(Point(100, 50).applying(centered) == Point(300, 225))
	#expect(maxAligned == Transform(a: 3, b: 0, c: 0, d: 3, tx: 0, ty: 150))
	#expect(Point(100, 50).applying(maxAligned) == Point(300, 300))
}

@Test func svgPreserveAspectRatioSliceUsesUniformCoveringScale() throws {
	let centered = try #require(SVGPreserveAspectRatio(align: .xMidYMid, meetOrSlice: .slice).viewBoxTransform(
		from: Rect(x: 0, y: 0, width: 100, height: 50),
		to: Rect(x: 0, y: 0, width: 300, height: 300)
	))
	let minAligned = try #require(SVGPreserveAspectRatio(align: .xMinYMin, meetOrSlice: .slice).viewBoxTransform(
		from: Rect(x: 0, y: 0, width: 100, height: 50),
		to: Rect(x: 0, y: 0, width: 300, height: 300)
	))

	#expect(centered == Transform(a: 6, b: 0, c: 0, d: 6, tx: -150, ty: 0))
	#expect(Point(0, 0).applying(centered) == Point(-150, 0))
	#expect(Point(100, 50).applying(centered) == Point(450, 300))
	#expect(minAligned == Transform(a: 6, b: 0, c: 0, d: 6, tx: 0, ty: 0))
	#expect(Point(100, 50).applying(minAligned) == Point(600, 300))
}

@Test func svgParserParsesPaintValuesAndFallbacks() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="inherited" fill="red">
			<path id="none" d="M0 0 L1 1" fill="none" stroke="currentColor"/>
			<path id="fallbackColor" d="M0 0 L1 1" fill="url(#missing) #336699"/>
			<path id="fallbackNone" d="M0 0 L1 1" fill="url(#missing) none"/>
			<path id="fallbackCurrent" d="M0 0 L1 1" stroke="url(#missing) currentColor"/>
			<path id="context" d="M0 0 L1 1" fill="context-fill" stroke="context-stroke"/>
			<path id="invalid" d="M0 0 L1 1" fill="url(#first) url(#second)"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected root element to be a group")
		return
	}
	let paths = Dictionary(uniqueKeysWithValues: group.children.compactMap { element -> (String, SVGPathData)? in
		if case .path(let path) = element {
			return (path.id, path)
		}
		return nil
	})
	let none = try #require(paths["none"])
	let fallbackColor = try #require(paths["fallbackColor"])
	let fallbackNone = try #require(paths["fallbackNone"])
	let fallbackCurrent = try #require(paths["fallbackCurrent"])
	let context = try #require(paths["context"])
	let invalid = try #require(paths["invalid"])

	#expect(none.attributes.fill == .none)
	#expect(none.attributes.stroke == .currentColor)
	#expect(fallbackColor.attributes.fill == .urlWithFallback("missing", .color(Color(0.2, 0.4, 0.6))))
	#expect(fallbackNone.attributes.fill == .urlWithFallback("missing", .none))
	#expect(fallbackCurrent.attributes.stroke == .urlWithFallback("missing", .currentColor))
	#expect(context.attributes.fill == .contextFill)
	#expect(context.attributes.stroke == .contextStroke)
	#expect(invalid.attributes.fill == .color(.red))
}

@Test func svgParserPreservesNestedSVGViewportAsContainer() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="red">
		<svg id="nested" x="10" y="20" width="30" height="40" viewBox="0 0 3 4" fill="#336699">
			<path id="child" d="M0 0 L1 1"/>
		</svg>
		<path id="sibling" d="M0 0 L1 1"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 100, height: 100))
	#expect(document.elementIDs == ["nested", "child", "sibling"])

	guard case .svg(let nested) = document.elements.first else {
		Issue.record("Expected first root child to be nested svg")
		return
	}
	#expect(nested.id == "nested")
	#expect(nested.x == 10)
	#expect(nested.y == 20)
	#expect(nested.width == 30)
	#expect(nested.height == 40)
	#expect(nested.viewBox == Rect(x: 0, y: 0, width: 3, height: 4))
	#expect(nested.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let child) = nested.children.first else {
		Issue.record("Expected nested svg child to be a path")
		return
	}
	#expect(child.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let sibling) = document.elements.dropFirst().first else {
		Issue.record("Expected root sibling to remain outside nested svg")
		return
	}
	#expect(sibling.attributes.fill == .color(.red))
}

@Test func svgParserResolvesSVGGeometryAttributesAgainstCurrentViewport() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="200" height="80" viewBox="0 0 400 160">
		<svg id="percent" x="10%" y="25%" width="50%" height="75%"/>
		<svg id="auto" x="5" y="6" width="auto" height="auto"/>
		<svg id="omitted"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let viewports = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGViewportData)? in
		if case .svg(let viewport) = element {
			return (viewport.id, viewport)
		}
		return nil
	})
	let percent = try #require(viewports["percent"])
	let auto = try #require(viewports["auto"])
	let omitted = try #require(viewports["omitted"])

	#expect(percent.x == 20)
	#expect(percent.y == 20)
	#expect(percent.width == 100)
	#expect(percent.height == 60)
	#expect(auto.x == 5)
	#expect(auto.y == 6)
	#expect(auto.width == 200)
	#expect(auto.height == 80)
	#expect(omitted.x == 0)
	#expect(omitted.y == 0)
	#expect(omitted.width == 200)
	#expect(omitted.height == 80)
}

@Test func svgParserParsesSVGPreserveAspectRatioValues() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50" preserveAspectRatio="none slice">
		<svg id="slice" width="40" height="20" viewBox="0 0 10 10" preserveAspectRatio="xMaxYMin slice"/>
		<svg id="defaulted" width="40" height="20" viewBox="0 0 10 10"/>
		<svg id="invalid" width="40" height="20" viewBox="0 0 10 10" preserveAspectRatio="xMiddleYMiddle crop"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	#expect(document.preserveAspectRatio == SVGPreserveAspectRatio(align: .none, meetOrSlice: nil))

	let viewports = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGViewportData)? in
		if case .svg(let viewport) = element {
			return (viewport.id, viewport)
		}
		return nil
	})
	let slice = try #require(viewports["slice"])
	let defaulted = try #require(viewports["defaulted"])
	let invalid = try #require(viewports["invalid"])

	#expect(slice.preserveAspectRatio == SVGPreserveAspectRatio(align: .xMaxYMin, meetOrSlice: .slice))
	#expect(defaulted.preserveAspectRatio == .default)
	#expect(invalid.preserveAspectRatio == .default)
}

@Test func svgParserStoresDefsContentOutsideRenderableElements() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<defs>
			<g id="glyph" fill="#336699">
				<path id="glyph-path" d="M0 0 L1 1"/>
			</g>
			<path id="loose" d="M2 2 L3 3"/>
		</defs>
		<path id="visible" d="M4 4 L5 5"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["visible"])
	#expect(document.defs.reusableElements.keys.sorted() == ["glyph", "loose"])

	guard case .group(let glyph) = try #require(document.defs.reusableElements["glyph"]?.first) else {
		Issue.record("Expected defs glyph to be preserved as a group")
		return
	}
	#expect(glyph.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let glyphPath) = glyph.children.first else {
		Issue.record("Expected defs group child to be a path")
		return
	}
	#expect(glyphPath.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let loose) = try #require(document.defs.reusableElements["loose"]?.first) else {
		Issue.record("Expected loose defs child to be preserved as a path")
		return
	}
	#expect(loose.id == "loose")
}

@Test func svgParserStoresSymbolTemplatesOutsideRenderableElements() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
		<symbol id="pin" x="10%" y="20%" width="50%" height="40%" viewBox="0 0 10 20" preserveAspectRatio="xMaxYMin slice" refX="center" refY="18" fill="#336699">
			<path id="pin-shape" d="M0 0 L10 20"/>
		</symbol>
		<path id="visible" d="M1 1 L2 2"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["visible"])
	#expect(document.defs.symbols.keys.sorted() == ["pin"])

	let symbol = try #require(document.defs.symbols["pin"])
	#expect(symbol.id == "pin")
	#expect(symbol.x == 20)
	#expect(symbol.y == 20)
	#expect(symbol.width == 100)
	#expect(symbol.height == 40)
	#expect(symbol.viewBox == Rect(x: 0, y: 0, width: 10, height: 20))
	#expect(symbol.preserveAspectRatio == SVGPreserveAspectRatio(align: .xMaxYMin, meetOrSlice: .slice))
	#expect(symbol.refX == "center")
	#expect(symbol.refY == "18")
	#expect(symbol.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let child) = symbol.children.first else {
		Issue.record("Expected symbol child to be a path")
		return
	}
	#expect(child.id == "pin-shape")
	#expect(child.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
}

@Test func svgParserUsesFunctionalURLParserForLocalResourceReferences() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<path id="styled" d="M0 0 L1 1" clip-path="url( '#clip' )" filter='url("#filter")' mask="url(#mask)" fill='url("#paint")'/>
		<path id="invalid" d="M0 0 L1 1" clip-path="url(#first) url(#second)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let paths = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGPathData)? in
		if case .path(let path) = element {
			return (path.id, path)
		}
		return nil
	})
	let styled = try #require(paths["styled"])
	let invalid = try #require(paths["invalid"])

	#expect(styled.attributes.clipPathID == "clip")
	#expect(styled.attributes.filterID == "filter")
	#expect(styled.attributes.maskID == "mask")
	#expect(styled.attributes.fill == .url("paint"))
	#expect(invalid.attributes.clipPathID == nil)
}

@Test func svgParserUsesAngleUnitsForRotateTransforms() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<g id="degrees" transform="rotate(90deg)"/>
		<g id="gradians" transform="rotate(100grad)"/>
		<g id="radians" transform="rotate(1.5707963267948966rad)"/>
		<g id="turns" transform="rotate(0.25turn)"/>
		<g id="unitless" transform="rotate(90)"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let groups = document.elements.compactMap { element -> SVGGroupData? in
		if case .group(let group) = element {
			group
		} else {
			nil
		}
	}

	#expect(groups.map(\.id) == ["degrees", "gradians", "radians", "turns", "unitless"])
	for group in groups {
		expectTransformApproximately(group.attributes.transform, Transform.identity.rotated(by: .pi / 2))
	}
}

@Test func svgParserHandlesDefaultNamespaceAndXLinkHref() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 10 10">
		<defs>
			<path id="symbolPath" d="M0 0 L1 1"/>
		</defs>
		<use id="copy" xlink:href="#symbolPath" x="2" y="3"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 10, height: 10))
	#expect(document.defs.reusableElements["symbolPath"]?.count == 1)

	guard case .use(let use) = document.elements.first else {
		Issue.record("Expected root element to be a use element")
		return
	}
	#expect(use.id == "copy")
	#expect(use.href == "symbolPath")
	#expect(use.x == 2)
	#expect(use.y == 3)
}

@Test func svgParserHandlesPrefixedSVGNamespaceAndHrefPrecedence() throws {
	let svg = """
	<svg:svg xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 16 16">
		<svg:defs>
			<svg:path id="preferred" d="M0 0 L2 2"/>
			<svg:path id="legacy" d="M1 1 L3 3"/>
		</svg:defs>
		<custom:path xmlns:custom="https://example.com/custom" id="foreign" d="M0 0 L9 9"/>
		<svg:use id="copy" href="#preferred" xlink:href="#legacy"/>
	</svg:svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 16, height: 16))
	#expect(document.defs.reusableElements["preferred"]?.count == 1)
	#expect(document.defs.reusableElements["legacy"]?.count == 1)
	#expect(document.elementIDs.contains("foreign") == false)

	guard case .use(let use) = document.elements.first else {
		Issue.record("Expected root element to be a use element")
		return
	}
	#expect(use.href == "preferred")
}

@Test func svgParserPreservesUseGeometryAndReferenceOverrides() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="200" height="100">
		<use id="copy" href="#pin" xlink:href="#fallback" x="10%" y="20%" width="50%" height="40%"/>
		<use id="auto" href="#pin" width="auto" height="auto"/>
		<use id="illegal" href="#pin" width="-1" height="-2"/>
		<use id="external" href="sprite.svg"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let uses = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGUseData)? in
		if case .use(let use) = element {
			return (use.id, use)
		}
		return nil
	})
	let copy = try #require(uses["copy"])
	let auto = try #require(uses["auto"])
	let illegal = try #require(uses["illegal"])
	let external = try #require(uses["external"])

	#expect(copy.href == "pin")
	#expect(copy.x == 20)
	#expect(copy.y == 20)
	#expect(copy.width == 100)
	#expect(copy.height == 40)
	#expect(auto.width == nil)
	#expect(auto.height == nil)
	#expect(illegal.width == nil)
	#expect(illegal.height == nil)
	#expect(external.href == "sprite.svg")
}

@Test func svgParserSelectsFirstPassingSwitchChild() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<switch id="choice" fill="#336699">
			<path id="empty-extension" requiredExtensions="" d="M0 0 L1 1"/>
			<path id="unsupported-extension" requiredExtensions="https://example.com/unsupported" d="M1 1 L2 2"/>
			<g id="french" systemLanguage="fr" display="inline">
				<path id="french-child" d="M2 2 L3 3"/>
			</g>
			<g id="english" systemLanguage="en" display="none">
				<path id="english-child" d="M3 3 L4 4"/>
			</g>
			<path id="fallback" d="M4 4 L5 5"/>
		</switch>
	</svg>
	"""

	let document = try #require(SVGParser(languagePreferences: ["en"]).parse(svg))

	#expect(document.elementIDs == ["choice", "english", "english-child"])

	guard case .switch(let choice) = document.elements.first else {
		Issue.record("Expected root element to be a switch")
		return
	}
	#expect(choice.id == "choice")
	#expect(choice.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(choice.children.count == 1)

	guard case .group(let english) = choice.children.first else {
		Issue.record("Expected selected switch child to be a group")
		return
	}
	#expect(english.id == "english")
	#expect(english.attributes.display == .none)
	#expect(english.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let englishChild) = english.children.first else {
		Issue.record("Expected selected switch group child to be a path")
		return
	}
	#expect(englishChild.id == "english-child")
	#expect(englishChild.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
}

@Test func svgParserStoresPredefinedViewsOutsideRenderableElements() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" lang="en">
		<view id="closeup" viewBox="10 20 30 40" preserveAspectRatio="xMaxYMin slice" zoomAndPan="disable" data-note="kept"/>
		<view id="plain" data-empty="yes"/>
		<path id="visible" d="M0 0 L1 1"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["visible"])
	#expect(document.defs.views.keys.sorted() == ["closeup", "plain"])

	let closeup = try #require(document.defs.views["closeup"])
	#expect(closeup.id == "closeup")
	#expect(closeup.viewBox == Rect(x: 10, y: 20, width: 30, height: 40))
	#expect(closeup.preserveAspectRatio == SVGPreserveAspectRatio(align: .xMaxYMin, meetOrSlice: .slice))
	#expect(closeup.zoomAndPan == .disable)
	#expect(closeup.language == "en")
	#expect(closeup.unknownAttributes == ["data-note": "kept"])

	let plain = try #require(document.defs.views["plain"])
	#expect(plain.viewBox == nil)
	#expect(plain.preserveAspectRatio == nil)
	#expect(plain.zoomAndPan == nil)
	#expect(plain.unknownAttributes == ["data-empty": "yes"])
}

@Test func svgParserPreservesAnchorLinksAsRenderableContainers() throws {
	let svg = #"""
	<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 20 20" lang="en">
		<a id="docs" href="icons.svg?name=A&amp;mode=1#icon" xlink:href="#fallback" target="_blank" download="icon.svg" ping="https://example.com/ping" rel="external help" hreflang="en" type="image/svg+xml" referrerpolicy="no-referrer" xlink:title="Docs" fill="#336699" data-note="kept">
			<path id="linked-path" d="M0 0 L1 1"/>
			<a id="nested" href="https://example.com/nested">
				<path id="nested-path" d="M1 1 L2 2"/>
			</a>
		</a>
		<a id="legacy" xlink:href="#legacy-target">
			<path id="legacy-path" d="M2 2 L3 3"/>
		</a>
		<a id="placeholder">
			<path id="placeholder-path" d="M3 3 L4 4"/>
		</a>
	</svg>
	"""#

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["docs", "linked-path", "nested", "nested-path", "legacy", "legacy-path", "placeholder", "placeholder-path"])

	guard case .link(let docs) = document.elements.first else {
		Issue.record("Expected first root element to be an anchor link")
		return
	}
	#expect(docs.id == "docs")
	#expect(docs.href == "icons.svg?name=A&mode=1#icon")
	#expect(docs.target == "_blank")
	#expect(docs.download == "icon.svg")
	#expect(docs.ping == "https://example.com/ping")
	#expect(docs.rel == "external help")
	#expect(docs.hreflang == "en")
	#expect(docs.type == "image/svg+xml")
	#expect(docs.referrerPolicy == "no-referrer")
	#expect(docs.xlinkTitle == "Docs")
	#expect(docs.language == "en")
	#expect(docs.unknownAttributes == ["data-note": "kept"])
	#expect(docs.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(docs.children.count == 2)

	guard case .path(let linkedPath) = docs.children.first else {
		Issue.record("Expected anchor child to be a path")
		return
	}
	#expect(linkedPath.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .link(let nested) = docs.children.dropFirst().first else {
		Issue.record("Expected nested anchor to be preserved as a link container")
		return
	}
	#expect(nested.id == "nested")
	#expect(nested.href == nil)
	#expect(nested.target == "_self")
	#expect(nested.children.count == 1)

	guard case .link(let legacy) = document.elements.dropFirst().first else {
		Issue.record("Expected second root element to be a legacy xlink anchor")
		return
	}
	#expect(legacy.href == "#legacy-target")

	guard case .link(let placeholder) = document.elements.dropFirst(2).first else {
		Issue.record("Expected third root element to be an inactive anchor")
		return
	}
	#expect(placeholder.href == nil)
	#expect(placeholder.target == "_self")
	#expect(placeholder.children.count == 1)
}

@Test func svgParserPreservesTitleElementsAsNonRenderedMetadata() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" lang="en">
		<title id="root-title">Root English</title>
		<title id="root-nl" lang="nl">Wortel Nederlands</title>
		<g id="icon">
			<title id="icon-gb" lang="en-gb">Favourite</title>
			<title id="icon-us" lang="en-US">Favorite</title>
			<path id="mark" d="M0 0 L1 1">
				<title id="mark-symbol" lang="">★</title>
			</path>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser(languagePreferences: ["en-US"]).parse(svg))

	#expect(document.elementIDs == ["icon", "mark"])
	#expect(document.rootTitles.map(\.id) == ["root-title", "root-nl"])
	#expect(document.rootTitles.map(\.text) == ["Root English", "Wortel Nederlands"])
	#expect(document.rootTitles.map(\.language) == ["en", "nl"])
	#expect(document.selectedTitle?.text == "Root English")

	let iconTitles = try #require(document.elementTitles["icon"])
	#expect(iconTitles.map(\.id) == ["icon-gb", "icon-us"])
	#expect(iconTitles.map(\.language) == ["en-gb", "en-US"])
	#expect(document.selectedElementTitles["icon"]?.text == "Favorite")

	let markTitles = try #require(document.elementTitles["mark"])
	#expect(markTitles.map(\.text) == ["★"])
	#expect(markTitles.map(\.language) == [""])
	#expect(document.selectedElementTitles["mark"]?.text == "★")
}

@Test func svgParserPreservesDescElementsAsNonRenderedMetadata() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" lang="en">
		<desc id="root-desc">Root description</desc>
		<desc id="root-empty-lang" lang="">No-language fallback</desc>
		<g id="chart">
			<desc id="chart-fr" lang="fr">Graphique detaille</desc>
			<desc id="chart-en" lang="en-US">Detailed chart description</desc>
			<path id="bar" d="M0 0 L1 1">
				<desc id="bar-desc">Bar shape description</desc>
			</path>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser(languagePreferences: ["en-US"]).parse(svg))

	#expect(document.elementIDs == ["chart", "bar"])
	#expect(document.rootDescriptions.map(\.id) == ["root-desc", "root-empty-lang"])
	#expect(document.rootDescriptions.map(\.text) == ["Root description", "No-language fallback"])
	#expect(document.rootDescriptions.map(\.language) == ["en", ""])
	#expect(document.selectedDescription?.text == "Root description")

	let chartDescriptions = try #require(document.elementDescriptions["chart"])
	#expect(chartDescriptions.map(\.id) == ["chart-fr", "chart-en"])
	#expect(chartDescriptions.map(\.language) == ["fr", "en-US"])
	#expect(document.selectedElementDescriptions["chart"]?.text == "Detailed chart description")

	let barDescriptions = try #require(document.elementDescriptions["bar"])
	#expect(barDescriptions.map(\.text) == ["Bar shape description"])
	#expect(barDescriptions.map(\.language) == ["en"])
	#expect(document.selectedElementDescriptions["bar"]?.text == "Bar shape description")
}

@Test func svgParserPreservesMetadataElementsAsNonRenderedMetadata() throws {
	let svg = #"""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" lang="en">
		<metadata id="root-metadata" data-origin="root">
			<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/">
				<rdf:Description rdf:about="">
					<dc:title>Root dataset</dc:title>
				</rdf:Description>
			</rdf:RDF>
		</metadata>
		<g id="icon">
			<metadata id="icon-metadata" xml:lang="fr">
				<custom:entry xmlns:custom="https://example.com/custom" custom:key="usage">Decorative</custom:entry>
			</metadata>
			<path id="mark" d="M0 0 L1 1"/>
		</g>
	</svg>
	"""#

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["icon", "mark"])
	#expect(document.rootMetadata.count == 1)

	let rootMetadata = try #require(document.rootMetadata.first)
	#expect(rootMetadata.id == "root-metadata")
	#expect(rootMetadata.language == "en")
	#expect(rootMetadata.unknownAttributes == ["data-origin": "root"])

	let rdf = try #require(rootMetadata.children.compactMap(\.element).first)
	#expect(rdf.name == "rdf:RDF")
	#expect(rdf.localName == "RDF")
	#expect(rdf.namespaceURI == "http://www.w3.org/1999/02/22-rdf-syntax-ns#")

	let description = try #require(rdf.children.compactMap(\.element).first)
	#expect(description.name == "rdf:Description")
	#expect(description.attributes["rdf:about"] == "")

	let title = try #require(description.children.compactMap(\.element).first)
	#expect(title.name == "dc:title")
	#expect(title.namespaceURI == "http://purl.org/dc/elements/1.1/")
	#expect(title.children.compactMap(\.text) == ["Root dataset"])

	let iconMetadata = try #require(document.elementMetadata["icon"]?.first)
	#expect(iconMetadata.id == "icon-metadata")
	#expect(iconMetadata.language == "fr")

	let entry = try #require(iconMetadata.children.compactMap(\.element).first)
	#expect(entry.name == "custom:entry")
	#expect(entry.localName == "entry")
	#expect(entry.namespaceURI == "https://example.com/custom")
	#expect(entry.attributes["custom:key"] == "usage")
	#expect(entry.children.compactMap(\.text) == ["Decorative"])
}

@Test func svgParserPreservesRectElementsAndEquivalentSquareCornerPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" lang="en" fill="red">
		<rect id="box" x="2" y="3" width="10" height="6" fill="#336699" data-note="kept"/>
		<rect id="defaulted" width="4" height="5"/>
		<rect id="zero-width" x="1" y="1" width="0" height="5"/>
		<rect id="negative-width" x="1" y="1" width="-3" height="5"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let rects = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGRectData)? in
		if case .rect(let rect) = element {
			return (rect.id, rect)
		}
		return nil
	})

	#expect(document.elementIDs == ["box", "defaulted", "zero-width", "negative-width"])

	let box = try #require(rects["box"])
	#expect(box.x == 2)
	#expect(box.y == 3)
	#expect(box.width == 10)
	#expect(box.height == 6)
	#expect(box.language == "en")
	#expect(box.unknownAttributes == ["data-note": "kept"])
	#expect(box.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(box.path.commands == [.rect(Rect(x: 2, y: 3, width: 10, height: 6))])
	#expect(box.path.svgPathData(precision: 0) == "M 2 3 L 12 3 L 12 9 L 2 9 Z")

	let defaulted = try #require(rects["defaulted"])
	#expect(defaulted.x == 0)
	#expect(defaulted.y == 0)
	#expect(defaulted.width == 4)
	#expect(defaulted.height == 5)
	#expect(defaulted.attributes.fill == .color(.red))
	#expect(defaulted.path.commands == [.rect(Rect(x: 0, y: 0, width: 4, height: 5))])

	#expect(rects["zero-width"]?.path.commands == [])
	#expect(rects["negative-width"]?.width == 0)
	#expect(rects["negative-width"]?.path.commands == [])
}

@Test func svgParserUsesRectRXForRoundedCornerEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30 20">
		<rect id="rounded" x="2" y="3" width="20" height="10" rx="4"/>
		<rect id="clamped" x="0" y="0" width="6" height="4" rx="10"/>
		<rect id="negative-rx" x="1" y="1" width="8" height="4" rx="-2"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let rects = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGRectData)? in
		if case .rect(let rect) = element {
			return (rect.id, rect)
		}
		return nil
	})

	let rounded = try #require(rects["rounded"])
	#expect(rounded.rx == 4)
	#expect(rounded.ry == 0)
	#expect(rounded.path.commands == [.roundedRect(Rect(x: 2, y: 3, width: 20, height: 10), cornerWidth: 4, cornerHeight: 4)])
	#expect(rounded.path.svgPathData(precision: 0) == "M 6 3 L 18 3 A 4 4 0 0 1 22 7 L 22 9 A 4 4 0 0 1 18 13 L 6 13 A 4 4 0 0 1 2 9 L 2 7 A 4 4 0 0 1 6 3 Z")

	let clamped = try #require(rects["clamped"])
	#expect(clamped.rx == 10)
	#expect(clamped.path.commands == [.roundedRect(Rect(x: 0, y: 0, width: 6, height: 4), cornerWidth: 3, cornerHeight: 2)])

	let negativeRX = try #require(rects["negative-rx"])
	#expect(negativeRX.rx == 0)
	#expect(negativeRX.path.commands == [.rect(Rect(x: 1, y: 1, width: 8, height: 4))])
}

@Test func svgParserUsesRectRYForRoundedCornerEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30 20">
		<rect id="rounded" x="2" y="3" width="20" height="10" ry="3"/>
		<rect id="clamped" x="0" y="0" width="6" height="4" ry="10"/>
		<rect id="negative-ry" x="1" y="1" width="8" height="4" ry="-2"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let rects = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGRectData)? in
		if case .rect(let rect) = element {
			return (rect.id, rect)
		}
		return nil
	})

	let rounded = try #require(rects["rounded"])
	#expect(rounded.rx == 0)
	#expect(rounded.ry == 3)
	#expect(rounded.path.commands == [.roundedRect(Rect(x: 2, y: 3, width: 20, height: 10), cornerWidth: 3, cornerHeight: 3)])
	#expect(rounded.path.svgPathData(precision: 0) == "M 5 3 L 19 3 A 3 3 0 0 1 22 6 L 22 10 A 3 3 0 0 1 19 13 L 5 13 A 3 3 0 0 1 2 10 L 2 6 A 3 3 0 0 1 5 3 Z")

	let clamped = try #require(rects["clamped"])
	#expect(clamped.ry == 10)
	#expect(clamped.path.commands == [.roundedRect(Rect(x: 0, y: 0, width: 6, height: 4), cornerWidth: 3, cornerHeight: 2)])

	let negativeRY = try #require(rects["negative-ry"])
	#expect(negativeRY.ry == 0)
	#expect(negativeRY.path.commands == [.rect(Rect(x: 1, y: 1, width: 8, height: 4))])
}

@Test func svgParserPreservesCircleElementsAndEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 30 30">
		<circle id="dot" cx="10" cy="20" r="5" fill="#336699" data-note="kept"/>
		<circle id="defaulted"/>
		<circle id="negative-radius" cx="1" cy="2" r="-3"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let circles = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGCircleData)? in
		if case .circle(let circle) = element {
			return (circle.id, circle)
		}
		return nil
	})

	let dot = try #require(circles["dot"])
	#expect(dot.cx == 10)
	#expect(dot.cy == 20)
	#expect(dot.r == 5)
	#expect(dot.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(dot.unknownAttributes == ["data-note": "kept"])
	let center = Point(10, 20)
	let expectedCommands: [PathCommand] = [
		.move(to: Point(15, 20)),
		.arc(center: center, radius: 5, startAngle: 0, endAngle: .pi / 2, clockwise: true),
		.arc(center: center, radius: 5, startAngle: .pi / 2, endAngle: .pi, clockwise: true),
		.arc(center: center, radius: 5, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true),
		.arc(center: center, radius: 5, startAngle: .pi * 3 / 2, endAngle: .pi * 2, clockwise: true),
		.close,
	]
	#expect(dot.path.commands == expectedCommands)
	#expect(dot.path.svgPathData(precision: 0) == "M 15 20 A 5 5 0 0 1 10 25 A 5 5 0 0 1 5 20 A 5 5 0 0 1 10 15 A 5 5 0 0 1 15 20 Z")

	let defaulted = try #require(circles["defaulted"])
	#expect(defaulted.cx == 0)
	#expect(defaulted.cy == 0)
	#expect(defaulted.r == 0)
	#expect(defaulted.path.commands == [])

	let negativeRadius = try #require(circles["negative-radius"])
	#expect(negativeRadius.r == 0)
	#expect(negativeRadius.path.commands == [])
}

@Test func svgParserPreservesEllipseElementsAndEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">
		<ellipse id="oval" cx="20" cy="12" rx="8" ry="4" fill="#336699" data-note="kept"/>
		<ellipse id="auto-rx" cx="5" cy="6" ry="3"/>
		<ellipse id="auto-ry" cx="7" cy="8" rx="2"/>
		<ellipse id="defaulted"/>
		<ellipse id="zero-radius" cx="10" cy="10" rx="0" ry="4"/>
		<ellipse id="negative-rx" cx="10" cy="10" rx="-2" ry="4"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let ellipses = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGEllipseData)? in
		if case .ellipse(let ellipse) = element {
			return (ellipse.id, ellipse)
		}
		return nil
	})

	let oval = try #require(ellipses["oval"])
	#expect(oval.cx == 20)
	#expect(oval.cy == 12)
	#expect(oval.rx == 8)
	#expect(oval.ry == 4)
	#expect(oval.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(oval.unknownAttributes == ["data-note": "kept"])
	let center = Point(20, 12)
	let expectedCommands: [PathCommand] = [
		.move(to: Point(28, 12)),
		.ellipticalArc(center: center, radiusX: 8, radiusY: 4, startAngle: 0, endAngle: .pi / 2, clockwise: true),
		.ellipticalArc(center: center, radiusX: 8, radiusY: 4, startAngle: .pi / 2, endAngle: .pi, clockwise: true),
		.ellipticalArc(center: center, radiusX: 8, radiusY: 4, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: true),
		.ellipticalArc(center: center, radiusX: 8, radiusY: 4, startAngle: .pi * 3 / 2, endAngle: .pi * 2, clockwise: true),
		.close,
	]
	#expect(oval.path.commands == expectedCommands)
	#expect(oval.path.svgPathData(precision: 0) == "M 28 12 A 8 4 0 0 1 20 16 A 8 4 0 0 1 12 12 A 8 4 0 0 1 20 8 A 8 4 0 0 1 28 12 Z")

	let autoRX = try #require(ellipses["auto-rx"])
	#expect(autoRX.rx == 0)
	#expect(autoRX.ry == 3)
	#expect(autoRX.path.commands.first == .move(to: Point(8, 6)))
	#expect(autoRX.path.svgPathData(precision: 0) == "M 8 6 A 3 3 0 0 1 5 9 A 3 3 0 0 1 2 6 A 3 3 0 0 1 5 3 A 3 3 0 0 1 8 6 Z")

	let autoRY = try #require(ellipses["auto-ry"])
	#expect(autoRY.rx == 2)
	#expect(autoRY.ry == 0)
	#expect(autoRY.path.svgPathData(precision: 0) == "M 9 8 A 2 2 0 0 1 7 10 A 2 2 0 0 1 5 8 A 2 2 0 0 1 7 6 A 2 2 0 0 1 9 8 Z")

	let defaulted = try #require(ellipses["defaulted"])
	#expect(defaulted.path.commands == [])

	let zeroRadius = try #require(ellipses["zero-radius"])
	#expect(zeroRadius.path.commands == [])

	let negativeRX = try #require(ellipses["negative-rx"])
	#expect(negativeRX.rx == 0)
	#expect(negativeRX.path.svgPathData(precision: 0) == "M 14 10 A 4 4 0 0 1 10 14 A 4 4 0 0 1 6 10 A 4 4 0 0 1 10 6 A 4 4 0 0 1 14 10 Z")
}

@Test func svgParserPreservesLineElementsAndEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 40 40">
		<line id="slash" x1="-2" y1="3" x2="12" y2="18" stroke="#336699" data-note="kept"/>
		<line id="defaulted"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let lines = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGLineData)? in
		if case .line(let line) = element {
			return (line.id, line)
		}
		return nil
	})

	let slash = try #require(lines["slash"])
	#expect(slash.x1 == -2)
	#expect(slash.y1 == 3)
	#expect(slash.x2 == 12)
	#expect(slash.y2 == 18)
	#expect(slash.attributes.stroke == .color(Color(0.2, 0.4, 0.6)))
	#expect(slash.unknownAttributes == ["data-note": "kept"])
	let expectedSlashCommands: [PathCommand] = [
		.move(to: Point(-2, 3)),
		.line(to: Point(12, 18)),
	]
	#expect(slash.path.commands == expectedSlashCommands)
	#expect(slash.path.svgPathData(precision: 0) == "M -2 3 L 12 18")

	let defaulted = try #require(lines["defaulted"])
	#expect(defaulted.x1 == 0)
	#expect(defaulted.y1 == 0)
	#expect(defaulted.x2 == 0)
	#expect(defaulted.y2 == 0)
	let expectedDefaultedCommands: [PathCommand] = [
		.move(to: Point.zero),
		.line(to: Point.zero),
	]
	#expect(defaulted.path.commands == expectedDefaultedCommands)
}

@Test func svgParserPreservesPolylineElementsAndOpenEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 40 40">
		<polyline id="zigzag" points="-2,3 4,8 12,18" fill="none" stroke="#336699" data-note="kept"/>
		<polyline id="odd" points="0 0 5 5 9"/>
		<polyline id="defaulted"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let polylines = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGPolylineData)? in
		if case .polyline(let polyline) = element {
			return (polyline.id, polyline)
		}
		return nil
	})

	let zigzag = try #require(polylines["zigzag"])
	#expect(zigzag.points == [Point(-2, 3), Point(4, 8), Point(12, 18)])
	#expect(zigzag.attributes.fill == .none)
	#expect(zigzag.attributes.stroke == .color(Color(0.2, 0.4, 0.6)))
	#expect(zigzag.unknownAttributes == ["data-note": "kept"])
	let expectedCommands: [PathCommand] = [
		.move(to: Point(-2, 3)),
		.line(to: Point(4, 8)),
		.line(to: Point(12, 18)),
	]
	#expect(zigzag.path.commands == expectedCommands)
	#expect(zigzag.path.svgPathData(precision: 0) == "M -2 3 L 4 8 L 12 18")

	let odd = try #require(polylines["odd"])
	#expect(odd.points == [Point(0, 0), Point(5, 5)])
	#expect(odd.path.commands == [.move(to: Point(0, 0)), .line(to: Point(5, 5))])

	let defaulted = try #require(polylines["defaulted"])
	#expect(defaulted.points == [])
	#expect(defaulted.path.commands == [])
}

@Test func svgParserPreservesPolygonElementsAndClosedEquivalentPaths() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 40 40">
		<polygon id="triangle" points="-2,3 4,8 12,18" fill="#336699" data-note="kept"/>
		<polygon id="odd" points="0 0 5 5 9"/>
		<polygon id="defaulted"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let polygons = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGPolygonData)? in
		if case .polygon(let polygon) = element {
			return (polygon.id, polygon)
		}
		return nil
	})

	let triangle = try #require(polygons["triangle"])
	#expect(triangle.points == [Point(-2, 3), Point(4, 8), Point(12, 18)])
	#expect(triangle.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
	#expect(triangle.unknownAttributes == ["data-note": "kept"])
	let expectedCommands: [PathCommand] = [
		.move(to: Point(-2, 3)),
		.line(to: Point(4, 8)),
		.line(to: Point(12, 18)),
		.close,
	]
	#expect(triangle.path.commands == expectedCommands)
	#expect(triangle.path.svgPathData(precision: 0) == "M -2 3 L 4 8 L 12 18 Z")

	let odd = try #require(polygons["odd"])
	#expect(odd.points == [Point(0, 0), Point(5, 5)])
	#expect(odd.path.commands == [.move(to: Point(0, 0)), .line(to: Point(5, 5)), .close])

	let defaulted = try #require(polygons["defaulted"])
	#expect(defaulted.points == [])
	#expect(defaulted.path.commands == [])
}

@Test func svgParserAppliesBasicShapeGeometryPropertiesFromCSS() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" viewBox="0 0 200 100">
		<style>
			.rect-geometry { x: 10%; y: 25%; width: 50%; height: 50%; rx: 4; ry: 3; }
			.circle-geometry { cx: 25%; cy: 50%; r: 10; }
			.ellipse-geometry { cx: 75%; cy: 50%; rx: 10%; ry: 25%; }
		</style>
		<rect id="box" class="rect-geometry" x="1" y="1" width="1" height="1" rx="1" ry="1"/>
		<circle id="dot" class="circle-geometry"/>
		<ellipse id="oval" class="ellipse-geometry" style="cx: 80%; ry: 10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let rects = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGRectData)? in
		if case .rect(let rect) = element {
			return (rect.id, rect)
		}
		return nil
	})
	let circles = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGCircleData)? in
		if case .circle(let circle) = element {
			return (circle.id, circle)
		}
		return nil
	})
	let ellipses = Dictionary(uniqueKeysWithValues: document.elements.compactMap { element -> (String, SVGEllipseData)? in
		if case .ellipse(let ellipse) = element {
			return (ellipse.id, ellipse)
		}
		return nil
	})

	let box = try #require(rects["box"])
	#expect(box.x == 20)
	#expect(box.y == 25)
	#expect(box.width == 100)
	#expect(box.height == 50)
	#expect(box.rx == 4)
	#expect(box.ry == 3)
	#expect(box.path.svgPathData(precision: 0) == "M 24 25 L 116 25 A 4 3 0 0 1 120 28 L 120 72 A 4 3 0 0 1 116 75 L 24 75 A 4 3 0 0 1 20 72 L 20 28 A 4 3 0 0 1 24 25 Z")

	let dot = try #require(circles["dot"])
	#expect(dot.cx == 50)
	#expect(dot.cy == 50)
	#expect(dot.r == 10)
	#expect(dot.path.commands.first == .move(to: Point(60, 50)))

	let oval = try #require(ellipses["oval"])
	#expect(oval.cx == 160)
	#expect(oval.cy == 50)
	#expect(oval.rx == 20)
	#expect(oval.ry == 10)
	#expect(oval.path.commands.first == .move(to: Point(180, 50)))
}

@Test func svgParserAppliesLangAndXMLLangMetadata() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" lang="en">
		<g id="section">
			<path id="mark" d="M0 0 L10 10"/>
			<text id="label" x="1" y="2" lang="FR-ca" xml:lang="fr-CA">Bonjour<tspan>Salut</tspan><tspan lang="">?</tspan></text>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.language == "en")
	#expect(document.unknownAttributes["lang"] == nil)

	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected root element to be a group")
		return
	}
	#expect(group.language == "en")

	guard case .path(let path) = group.children.first else {
		Issue.record("Expected first child to be a path")
		return
	}
	#expect(path.language == "en")

	guard case .text(let text) = group.children.dropFirst().first else {
		Issue.record("Expected second child to be text")
		return
	}
	#expect(text.language == "fr-CA")
	#expect(text.unknownAttributes["lang"] == nil)
	#expect(text.unknownAttributes["xml:lang"] == nil)
	#expect(text.spans.map(\.text) == ["Bonjour", "Salut", "?"])
	#expect(text.spans[0].language == "fr-CA")
	#expect(text.spans[1].language == "fr-CA")
	#expect(text.spans[2].language == nil)
}

@Test func svgParserPreservesSVGIDAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" id="root-icon" viewBox="0 0 20 20">
		<g id="layer-1">
			<path id="mark-1" d="M0 0 L10 10"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.id == "root-icon")
	#expect(document.unknownAttributes["id"] == nil)
	#expect(document.elementIDs == ["layer-1", "mark-1"])

	guard case .group(let group) = document.elements.first else {
		Issue.record("Expected root element to be a group")
		return
	}
	#expect(group.id == "layer-1")
	#expect(group.unknownAttributes["id"] == nil)

	guard case .path(let path) = group.children.first else {
		Issue.record("Expected child element to be a path")
		return
	}
	#expect(path.id == "mark-1")
	#expect(path.unknownAttributes["id"] == nil)
}

@Test func svgParserParsesSignedDecimalAndExponentNumbers() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<rect id="box" x=" +.5 " y="-.25e2" width="+1E2" height=".5e+1" stroke-width=" 1.25e1 " opacity=" +.75 "/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	guard case .rect(let rect) = document.elements.first else {
		Issue.record("Expected root element to be a rect")
		return
	}
	#expect(rect.x == 0.5)
	#expect(rect.y == -25)
	#expect(rect.width == 100)
	#expect(rect.height == 5)
	#expect(rect.attributes.strokeWidth == 12.5)
	#expect(rect.attributes.opacity == 0.75)
}

@Test func svgParserKeepsFallbacksForInvalidNumberValues() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<rect id="box" x="1e" y="." width="10" height="10" stroke-width="1e" opacity="."/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	guard case .rect(let rect) = document.elements.first else {
		Issue.record("Expected root element to be a rect")
		return
	}
	#expect(rect.x == 0)
	#expect(rect.y == 0)
	#expect(rect.width == 10)
	#expect(rect.height == 10)
	#expect(rect.attributes.strokeWidth == 1)
	#expect(rect.attributes.opacity == 1)
}

@Test func svgParserUsesUnitlessRootDimensionsAsUserUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width=" +1.5e2 " height=".25e3">
		<rect id="box" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 150, height: 250))
}

@Test func svgParserUsesDefaultViewportMetricsForPercentageRootDimensions() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="50%" height="25%">
		<rect id="box" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 50, height: 25))
}

@Test func svgParserDoesNotTreatMalformedPercentageOrUppercaseUnitsAsRootDimensions() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="24%%" height="10PX">
		<rect id="box" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 100, height: 100))
}

@Test func svgParserUsesDefaultViewportMetricsForViewportRelativeRootDimensions() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="50vw" height="25vh">
		<rect id="box" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 50, height: 25))
}

@Test func svgParserUsesDefaultFontMetricsForFontRelativeRootDimensions() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="2em" height="4ex">
		<rect id="box" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 32, height: 32))
}

@Test func svgParserUsesAbsoluteRootDimensionsAsUserUnits() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" width="2in" height="72pt">
		<rect id="box" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.viewBox == Rect(x: 0, y: 0, width: 192, height: 96))
}

@Test func svgParserDecodesXMLPredefinedEntitiesAndCharacterReferences() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<text id="label" x="1" y="2">A&amp;B &#x2B; C&lt;D &quot;Q&quot; &apos;Z&apos;</text>
		<image id="asset" href="icons.svg?name=A&amp;mode=1" x="0" y="0" width="10" height="10"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	guard case .text(let text) = document.elements.first else {
		Issue.record("Expected first element to be text")
		return
	}
	#expect(text.spans.first?.text == "A&B + C<D \"Q\" 'Z'")

	guard case .image(let image) = document.elements.dropFirst().first else {
		Issue.record("Expected second element to be image")
		return
	}
	#expect(image.href == "icons.svg?name=A&mode=1")
}

@Test func svgParserRejectsUndeclaredXMLGeneralEntity() {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<text id="label" x="1" y="2">&missing;</text>
	</svg>
	"""

	#expect(SVGParser().parse(svg) == nil)
}

@Test func svgParserIgnoresXMLCommentsAndProcessingInstructions() throws {
	let svg = """
	<?swg before-root?>
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<!-- <path id="commented" d="M0 0 L20 20"/> -->
		<?swg inside-root?>
		<text id="label" x="1" y="2">A<!-- hidden -->B<?swg inside-text?></text>
		<path id="visible" d="M0 0 L10 10"/>
	</svg>
	<?swg after-root?>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["label", "visible"])

	guard case .text(let text) = document.elements.first else {
		Issue.record("Expected first element to be text")
		return
	}
	#expect(text.spans.first?.text == "AB")
}

@Test func svgParserPreservesUnknownSVGElementsAsContainers() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<mysteryElement id="wrapper" fill="#336699">
			<path id="child" d="M0 0 L10 10"/>
		</mysteryElement>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.elementIDs == ["wrapper", "child"])

	guard case .unknown(let unknown) = document.elements.first else {
		Issue.record("Expected root element to be unknown")
		return
	}
	#expect(unknown.name == "mysteryElement")
	#expect(unknown.namespaceURI == "http://www.w3.org/2000/svg")
	#expect(unknown.attributes.fill == .color(Color(0.2, 0.4, 0.6)))

	guard case .path(let child) = unknown.children.first else {
		Issue.record("Expected unknown element child to be a path")
		return
	}
	#expect(child.attributes.fill == .color(Color(0.2, 0.4, 0.6)))
}

@Test func svgParserPreservesUnknownAttributes() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" xmlns:tool="https://example.com/tool" viewBox="0 0 20 20" data-root="root-value" tool:root-note="root-note">
		<path id="mark" d="M0 0 L10 10" fill="#336699" data-name="primary" tool:note="kept"/>
		<mysteryElement id="wrapper" data-wrapper="wrapper-value" tool:state="active">
			<circle id="dot" cx="5" cy="5" r="2" data-dot="dot-value"/>
		</mysteryElement>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	#expect(document.unknownAttributes == [
		"data-root": "root-value",
		"tool:root-note": "root-note"
	])

	guard case .path(let path) = document.elements.first else {
		Issue.record("Expected first element to be a path")
		return
	}
	#expect(path.unknownAttributes == [
		"data-name": "primary",
		"tool:note": "kept"
	])
	#expect(path.unknownAttributes["id"] == nil)
	#expect(path.unknownAttributes["d"] == nil)
	#expect(path.unknownAttributes["fill"] == nil)

	guard case .unknown(let unknown) = document.elements.dropFirst().first else {
		Issue.record("Expected second element to be unknown")
		return
	}
	#expect(unknown.unknownAttributes == [
		"data-wrapper": "wrapper-value",
		"tool:state": "active"
	])

	guard case .circle(let circle) = unknown.children.first else {
		Issue.record("Expected unknown child to be a circle")
		return
	}
	#expect(circle.unknownAttributes == ["data-dot": "dot-value"])
}

@Test func svgParserNormalizesDefaultTextWhitespace() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<text id="label" x="1" y="2">  Alpha
			Beta\t\tGamma  </text>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))

	guard case .text(let text) = document.elements.first else {
		Issue.record("Expected text element")
		return
	}
	#expect(text.spans.first?.text == "Alpha Beta Gamma")
}

@Test func svgParserPreservesXMLSpacePreserveTextWhitespace() throws {
	let svg = #"""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<text id="label" x="1" y="2" xml:space="preserve">  Alpha&#10;&#9;Beta  </text>
	</svg>
	"""#

	let document = try #require(SVGParser().parse(svg))

	guard case .text(let text) = document.elements.first else {
		Issue.record("Expected text element")
		return
	}
	#expect(text.spans.first?.text == "  Alpha  Beta  ")
	#expect(text.unknownAttributes["xml:space"] == nil)
}

@Test func svgParserAppliesInheritedAndOverriddenXMLSpaceToTSpans() throws {
	let svg = #"""
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
		<text id="label" x="1" y="2" xml:space="preserve"> A<tspan>  B&#9;C  </tspan><tspan xml:space="default">  D&#9; E  </tspan> F </text>
	</svg>
	"""#

	let document = try #require(SVGParser().parse(svg))

	guard case .text(let text) = document.elements.first else {
		Issue.record("Expected text element")
		return
	}
	#expect(text.spans.map(\.text) == [" A", "  B C  ", "D E", " F "])
	#expect(text.spans.flatMap(\.unknownAttributes.keys).contains("xml:space") == false)
}

private func expectTransformApproximately(_ actual: Transform, _ expected: Transform, tolerance: Double = 0.000001, sourceLocation: SourceLocation = #_sourceLocation) {
	#expect(abs(actual.a - expected.a) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.b - expected.b) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.c - expected.c) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.d - expected.d) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.tx - expected.tx) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.ty - expected.ty) < tolerance, sourceLocation: sourceLocation)
}

private func expectColorApproximately(_ actual: Color?, _ expected: Color, tolerance: Double = 0.000001, sourceLocation: SourceLocation = #_sourceLocation) {
	guard let actual else {
		Issue.record("Expected color \(expected), got nil", sourceLocation: sourceLocation)
		return
	}
	#expect(abs(actual.red - expected.red) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.green - expected.green) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.blue - expected.blue) < tolerance, sourceLocation: sourceLocation)
	#expect(abs(actual.alpha - expected.alpha) < tolerance, sourceLocation: sourceLocation)
}
