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
