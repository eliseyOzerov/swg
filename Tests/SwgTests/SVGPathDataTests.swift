import Testing
@testable import Swg

@Test func svgPathParserHandlesRelativeLinesAndClose() {
	let path = SVGPathDataParser.parse("M 10 10 h 20 v 15 l -5 5 z")

	#expect(path.commands == [
		.move(to: Point(10, 10)),
		.line(to: Point(30, 10)),
		.line(to: Point(30, 25)),
		.line(to: Point(25, 30)),
		.close,
	])
}

@Test func svgPathParserTreatsRepeatedMovetoPairsAsLinetoCommands() {
	let absolutePath = SVGPathDataParser.parse("M 10 10 20 20 30 10")
	let relativeInitialPath = SVGPathDataParser.parse("m 10 10 20 0 0 20")

	#expect(absolutePath.commands == [
		.move(to: Point(10, 10)),
		.line(to: Point(20, 20)),
		.line(to: Point(30, 10)),
	])
	#expect(relativeInitialPath.commands == [
		.move(to: Point(10, 10)),
		.line(to: Point(30, 10)),
		.line(to: Point(30, 30)),
	])
}

@Test func svgPathParserTokenizesCompactNumberBoundaries() {
	let path = SVGPathDataParser.parse("M10-20L30.5.5h-5+10")

	#expect(path.commands == [
		.move(to: Point(10, -20)),
		.line(to: Point(30.5, 0.5)),
		.line(to: Point(25.5, 0.5)),
		.line(to: Point(35.5, 0.5)),
	])
}

@Test func svgPathParserTokenizesExponentNumbers() {
	let path = SVGPathDataParser.parse("M1e2-3e2L.5e1-.25e2h1e1-2E+1")

	#expect(path.commands == [
		.move(to: Point(100, -300)),
		.line(to: Point(5, -25)),
		.line(to: Point(15, -25)),
		.line(to: Point(-5, -25)),
	])
}

@Test func svgPathParserTreatsRepeatedLineArgumentsAsImplicitCommands() {
	let path = SVGPathDataParser.parse("M 0 0 L 10 0 20 10 h 5 5 v 5 -10")

	#expect(path.commands == [
		.move(to: Point(0, 0)),
		.line(to: Point(10, 0)),
		.line(to: Point(20, 10)),
		.line(to: Point(25, 10)),
		.line(to: Point(30, 10)),
		.line(to: Point(30, 15)),
		.line(to: Point(30, 5)),
	])
}

@Test func svgPathParserHandlesSmoothCubicReflection() {
	let path = SVGPathDataParser.parse("M 0 0 C 10 0 20 10 30 10 S 50 20 60 0")

	#expect(path.commands.count == 3)
	guard case .cubic(let end, let control1, let control2) = path.commands[2] else {
		Issue.record("Expected second curve to be cubic")
		return
	}

	#expect(control1 == Point(40, 10))
	#expect(control2 == Point(50, 20))
	#expect(end == Point(60, 0))
}

@Test func svgPathParserTreatsRepeatedBezierArgumentsAsImplicitCommands() {
	let path = SVGPathDataParser.parse(
		"M 0 0 C 10 0 20 0 30 0 40 0 50 0 60 0 S 70 0 80 0 90 0 100 0 Q 110 0 120 0 130 0 140 0 T 150 0 160 0"
	)

	#expect(path.commands == [
		.move(to: Point(0, 0)),
		.cubic(to: Point(30, 0), control1: Point(10, 0), control2: Point(20, 0)),
		.cubic(to: Point(60, 0), control1: Point(40, 0), control2: Point(50, 0)),
		.cubic(to: Point(80, 0), control1: Point(70, 0), control2: Point(70, 0)),
		.cubic(to: Point(100, 0), control1: Point(90, 0), control2: Point(90, 0)),
		.quad(to: Point(120, 0), control: Point(110, 0)),
		.quad(to: Point(140, 0), control: Point(130, 0)),
		.quad(to: Point(150, 0), control: Point(150, 0)),
		.quad(to: Point(160, 0), control: Point(150, 0)),
	])
}

@Test func svgPathParserHandlesQuadraticBezierCommands() {
	let path = SVGPathDataParser.parse("M 10 10 Q 15 5 20 10 q 5 5 10 0")

	#expect(path.commands == [
		.move(to: Point(10, 10)),
		.quad(to: Point(20, 10), control: Point(15, 5)),
		.quad(to: Point(30, 10), control: Point(25, 15)),
	])
}

@Test func svgPathParserHandlesSmoothQuadraticBezierCommands() {
	let path = SVGPathDataParser.parse("M 0 0 Q 10 10 20 0 T 40 0 t 20 0 L 70 0 T 80 0")

	#expect(path.commands == [
		.move(to: Point(0, 0)),
		.quad(to: Point(20, 0), control: Point(10, 10)),
		.quad(to: Point(40, 0), control: Point(30, -10)),
		.quad(to: Point(60, 0), control: Point(50, 10)),
		.line(to: Point(70, 0)),
		.quad(to: Point(80, 0), control: Point(70, 0)),
	])
}

@Test func svgPathParserConvertsArcsToCubics() throws {
	let path = SVGPathDataParser.parse("M 0 0 A 10 10 0 0 1 10 10")

	#expect(path.commands.count == 2)
	guard case .cubic(let end, _, _) = path.commands[1] else {
		Issue.record("Expected arc to become a cubic")
		return
	}

	#expect(end.distance(to: Point(10, 10)) < 0.000001)
}

@Test func svgPathParserTreatsRepeatedArcArgumentsAsImplicitCommands() throws {
	let path = SVGPathDataParser.parse("M 0 0 A 10 10 0 0 1 10 0 10 10 0 0 1 20 0")

	#expect(path.commands.count == 3)
	guard case .cubic(let firstEnd, _, _) = path.commands[1] else {
		Issue.record("Expected first arc argument group to become a cubic")
		return
	}
	guard case .cubic(let secondEnd, _, _) = path.commands[2] else {
		Issue.record("Expected second arc argument group to become a cubic")
		return
	}

	#expect(firstEnd.distance(to: Point(10, 0)) < 0.000001)
	#expect(secondEnd.distance(to: Point(20, 0)) < 0.000001)
}

@Test func svgPathParserUsesArcLargeArcAndSweepFlags() throws {
	func arcCubics(largeArc: Int, sweep: Int) -> [PathCommand] {
		let path = SVGPathDataParser.parse("M 0 0 A 75 75 0 \(largeArc) \(sweep) 100 0")
		return Array(path.commands.dropFirst())
	}

	func cubicEnd(_ command: PathCommand) -> Point? {
		guard case .cubic(let end, _, _) = command else { return nil }
		return end
	}

	let smallNegative = arcCubics(largeArc: 0, sweep: 0)
	let smallPositive = arcCubics(largeArc: 0, sweep: 1)
	let largeNegative = arcCubics(largeArc: 1, sweep: 0)
	let largePositive = arcCubics(largeArc: 1, sweep: 1)

	#expect(smallNegative.count == 1)
	#expect(smallPositive.count == 1)
	#expect(largeNegative.count == 4)
	#expect(largePositive.count == 4)

	guard case .cubic(let smallNegativeEnd, let smallNegativeControl, _) = smallNegative[0],
		  case .cubic(let smallPositiveEnd, let smallPositiveControl, _) = smallPositive[0],
		  case .cubic(let largeNegativeEnd, let largeNegativeControl, _) = largeNegative[0],
		  case .cubic(let largePositiveEnd, let largePositiveControl, _) = largePositive[0] else {
		Issue.record("Expected arcs to be approximated with cubic segments")
		return
	}

	#expect(smallNegativeEnd.distance(to: Point(100, 0)) < 0.000001)
	#expect(smallPositiveEnd.distance(to: Point(100, 0)) < 0.000001)
	guard let largeNegativeFinalEnd = largeNegative.last.flatMap(cubicEnd),
		  let largePositiveFinalEnd = largePositive.last.flatMap(cubicEnd) else {
		Issue.record("Expected large arcs to end with cubic segments")
		return
	}
	#expect(largeNegativeFinalEnd.distance(to: Point(100, 0)) < 0.000001)
	#expect(largePositiveFinalEnd.distance(to: Point(100, 0)) < 0.000001)

	#expect(largeNegativeEnd.y > 0)
	#expect(largePositiveEnd.y < 0)

	#expect(smallNegativeControl.y > 0)
	#expect(smallPositiveControl.y < 0)
	#expect(largeNegativeControl.y > 0)
	#expect(largePositiveControl.y < 0)
}

@Test func svgPathParserCorrectsOutOfRangeArcRadii() throws {
	func arcCubics(_ data: String) -> [PathCommand] {
		Array(SVGPathDataParser.parse(data).commands.dropFirst())
	}

	let corrected = arcCubics("M 0 0 A 20 10 0 0 1 100 0")
	let negative = arcCubics("M 0 0 A -50 -25 0 0 1 100 0")

	#expect(corrected.count == 2)
	#expect(negative.count == 2)

	guard case .cubic(let correctedMidpoint, _, _) = corrected[0],
		  case .cubic(let correctedEnd, _, _) = corrected[1],
		  case .cubic(let negativeMidpoint, _, _) = negative[0],
		  case .cubic(let negativeEnd, _, _) = negative[1] else {
		Issue.record("Expected corrected arcs to be approximated with cubic segments")
		return
	}

	#expect(correctedMidpoint.distance(to: Point(50, -25)) < 0.000001)
	#expect(correctedEnd.distance(to: Point(100, 0)) < 0.000001)
	#expect(negativeMidpoint.distance(to: Point(50, -25)) < 0.000001)
	#expect(negativeEnd.distance(to: Point(100, 0)) < 0.000001)
}

@Test func svgPathParserHandlesDegenerateArcs() {
	let sameEndpoint = SVGPathDataParser.parse("M 10 10 A 20 20 0 0 1 10 10 L 20 20")
	let zeroRX = SVGPathDataParser.parse("M 0 0 A 0 10 0 0 1 20 0")
	let zeroRY = SVGPathDataParser.parse("M 0 0 A 10 0 0 0 1 20 0")

	#expect(sameEndpoint.commands == [
		.move(to: Point(10, 10)),
		.line(to: Point(20, 20)),
	])
	#expect(zeroRX.commands == [
		.move(to: Point(0, 0)),
		.line(to: Point(20, 0)),
	])
	#expect(zeroRY.commands == [
		.move(to: Point(0, 0)),
		.line(to: Point(20, 0)),
	])
}

@Test func svgPathParserStopsAtUnrecognizedPathData() {
	let path = SVGPathDataParser.parse("M 0 0 L 10 0 @ L 20 0")

	#expect(path.commands == [
		.move(to: Point(0, 0)),
		.line(to: Point(10, 0)),
	])
}

@Test func svgPathParserKeepsLastCompleteSegmentForParameterErrors() {
	let path = SVGPathDataParser.parse("M 10 10 L 20 20 30")

	#expect(path.commands == [
		.move(to: Point(10, 10)),
		.line(to: Point(20, 20)),
	])
}

@Test func svgPathParserRejectsInvalidArcFlags() throws {
	let path = SVGPathDataParser.parse("M 0 0 A 10 10 0 0 1 10 0 A 10 10 0 2 1 20 0 L 30 0")

	#expect(path.commands.count == 2)
	guard case .cubic(let end, _, _) = path.commands[1] else {
		Issue.record("Expected first valid arc to be preserved")
		return
	}

	#expect(end.distance(to: Point(10, 0)) < 0.000001)
}

@Test func svgPathDataSerializesEditableCommands() {
	let path = Path(commands: [
		.move(to: Point(0, 0)),
		.line(to: Point(10, 0)),
		.quad(to: Point(20, 0), control: Point(15, 5)),
		.cubic(to: Point(30, 0), control1: Point(22.5, 6.25), control2: Point(28, 2)),
		.close,
	])

	let data = path.svgPathData(precision: 2)

	#expect(data == "M 0 0 L 10 0 Q 15 5 20 0 C 22.5 6.25 28 2 30 0 Z")
	#expect(Path(svgPathData: data).commands == path.commands)
}

@Test func svgPathDataCanCreatePathElementFromPath() {
	let path = Path(commands: [
		.move(to: Point(1, 2)),
		.line(to: Point(3, 4)),
	])

	let element = SVGPathData(id: "stroke", path: path)

	#expect(element.id == "stroke")
	#expect(element.d == "M 1 2 L 3 4")
	#expect(element.path.commands == path.commands)
}
