import Foundation
import Testing
@testable import Swg

@Test func svgIntegerParserParsesSignedDigitSequences() {
	#expect(SVGIntegerParser.parse("0") == 0)
	#expect(SVGIntegerParser.parse("42") == 42)
	#expect(SVGIntegerParser.parse("+42") == 42)
	#expect(SVGIntegerParser.parse("-42") == -42)
	#expect(SVGIntegerParser.parse(" 2147483647 ") == 2147483647)
	#expect(SVGIntegerParser.parse("-2147483648") == -2147483648)
}

@Test func svgIntegerParserRejectsNonIntegerSyntax() {
	#expect(SVGIntegerParser.parse("") == nil)
	#expect(SVGIntegerParser.parse("+") == nil)
	#expect(SVGIntegerParser.parse("1.0") == nil)
	#expect(SVGIntegerParser.parse("1e2") == nil)
	#expect(SVGIntegerParser.parse("10px") == nil)
	#expect(SVGIntegerParser.parse("1 2") == nil)
}

@Test func svgLengthParserParsesUnitlessLengthsAsUserUnits() {
	#expect(SVGLengthParser.parseUnitless("0") == 0)
	#expect(SVGLengthParser.parseUnitless("42") == 42)
	#expect(SVGLengthParser.parseUnitless(" +.5 ") == 0.5)
	#expect(SVGLengthParser.parseUnitless("-.25e2") == -25)
}

@Test func svgLengthParserRejectsUnitsForUnitlessLengthParsing() {
	#expect(SVGLengthParser.parseUnitless("") == nil)
	#expect(SVGLengthParser.parseUnitless("10px") == nil)
	#expect(SVGLengthParser.parseUnitless("10pt") == nil)
	#expect(SVGLengthParser.parseUnitless("10%") == nil)
	#expect(SVGLengthParser.parseUnitless("1 2") == nil)
}

@Test func svgLengthParserConvertsAbsoluteLengthUnitsToUserUnits() {
	#expect(SVGLengthParser.parse("5px") == 5)
	#expect(SVGLengthParser.parse("1in") == 96)
	#expect(SVGLengthParser.parse("72pt") == 96)
	#expect(SVGLengthParser.parse("6pc") == 96)
	#expect(SVGLengthParser.parse("2.54cm") == 96)
	#expect(SVGLengthParser.parse("25.4mm") == 96)
}

@Test func svgLengthParserConvertsFontRelativeUnitsToUserUnits() {
	let context = SVGLengthContext(fontSize: 20, rootFontSize: 18, xHeight: 9, zeroAdvance: 11)

	#expect(SVGLengthParser.parse("2em", context: context) == 40)
	#expect(SVGLengthParser.parse("2ex", context: context) == 18)
	#expect(SVGLengthParser.parse("2ch", context: context) == 22)
	#expect(SVGLengthParser.parse("2rem", context: context) == 36)
}

@Test func svgLengthParserUsesFontMetricFallbacksForExAndCh() {
	let horizontal = SVGLengthContext(fontSize: 20, rootFontSize: 16)
	let upright = SVGLengthContext(fontSize: 20, rootFontSize: 16, isUprightText: true)

	#expect(SVGLengthParser.parse("2ex", context: horizontal) == 20)
	#expect(SVGLengthParser.parse("2ch", context: horizontal) == 20)
	#expect(SVGLengthParser.parse("2ch", context: upright) == 40)
}

@Test func svgLengthParserConvertsViewportRelativeUnitsToUserUnits() {
	let context = SVGLengthContext(viewportWidth: 200, viewportHeight: 100)

	#expect(SVGLengthParser.parse("10vw", context: context) == 20)
	#expect(SVGLengthParser.parse("10vh", context: context) == 10)
	#expect(SVGLengthParser.parse("10vmin", context: context) == 10)
	#expect(SVGLengthParser.parse("10vmax", context: context) == 20)
}

@Test func svgLengthParserConvertsPercentageLengthsToUserUnits() throws {
	let context = SVGLengthContext(viewportWidth: 200, viewportHeight: 100)
	let diagonal = try #require(SVGLengthParser.parse("10%", context: context, percentageBasis: .normalizedDiagonal))

	#expect(SVGLengthParser.parse("50%", context: context, percentageBasis: .horizontal) == 100)
	#expect(SVGLengthParser.parse("50%", context: context, percentageBasis: .vertical) == 50)
	#expect(abs(diagonal - 15.811388300841898) < 0.000001)
	#expect(SVGLengthParser.parse("25%", context: context, percentageBasis: .custom(80)) == 20)
	#expect(SVGLengthParser.parse("50%") == 50)
}

@Test func svgLengthParserRejectsUppercaseUnitsAndMalformedPercentages() {
	#expect(SVGLengthParser.parse("10PX") == nil)
	#expect(SVGLengthParser.parse("10EM") == nil)
	#expect(SVGLengthParser.parse("10VW") == nil)
	#expect(SVGLengthParser.parse("%") == nil)
	#expect(SVGLengthParser.parse("10%%") == nil)
}

@Test func svgAngleParserConvertsAngleUnitsToRadians() throws {
	let degrees = try #require(SVGAngleParser.parse("180deg"))
	let gradians = try #require(SVGAngleParser.parse("200grad"))
	let radians = try #require(SVGAngleParser.parse("3.141592653589793rad"))
	let turns = try #require(SVGAngleParser.parse("0.5turn"))
	let unitless = try #require(SVGAngleParser.parse("90"))

	#expect(abs(degrees - .pi) < 0.000001)
	#expect(abs(gradians - .pi) < 0.000001)
	#expect(abs(radians - .pi) < 0.000001)
	#expect(abs(turns - .pi) < 0.000001)
	#expect(abs(unitless - (.pi / 2)) < 0.000001)
}

@Test func svgAngleParserRejectsMalformedAndUppercaseAngles() {
	#expect(SVGAngleParser.parse("") == nil)
	#expect(SVGAngleParser.parse("deg") == nil)
	#expect(SVGAngleParser.parse("90DEG") == nil)
	#expect(SVGAngleParser.parse("90Grad") == nil)
	#expect(SVGAngleParser.parse("1turns") == nil)
	#expect(SVGAngleParser.parse("1 2deg") == nil)
}

@Test func svgClockValueParserConvertsTimecountUnitsToSeconds() throws {
	let hours = try #require(SVGClockValueParser.parse("3.2h"))
	let minutes = try #require(SVGClockValueParser.parse("45min"))
	let seconds = try #require(SVGClockValueParser.parse("30s"))
	let milliseconds = try #require(SVGClockValueParser.parse("5ms"))
	let unitless = try #require(SVGClockValueParser.parse("12.467"))

	#expect(abs(hours - 11520) < 0.000001)
	#expect(abs(minutes - 2700) < 0.000001)
	#expect(abs(seconds - 30) < 0.000001)
	#expect(abs(milliseconds - 0.005) < 0.000001)
	#expect(abs(unitless - 12.467) < 0.000001)
}

@Test func svgClockValueParserConvertsFullAndPartialClockValuesToSeconds() throws {
	let full = try #require(SVGClockValueParser.parse("02:30:03"))
	let fullFraction = try #require(SVGClockValueParser.parse("50:00:10.25"))
	let partial = try #require(SVGClockValueParser.parse("02:33"))
	let partialFraction = try #require(SVGClockValueParser.parse("00:10.5"))

	#expect(abs(full - 9003) < 0.000001)
	#expect(abs(fullFraction - 180010.25) < 0.000001)
	#expect(abs(partial - 153) < 0.000001)
	#expect(abs(partialFraction - 10.5) < 0.000001)
}

@Test func svgClockValueParserRejectsMalformedClockValues() {
	#expect(SVGClockValueParser.parse("") == nil)
	#expect(SVGClockValueParser.parse("+3s") == nil)
	#expect(SVGClockValueParser.parse("-3s") == nil)
	#expect(SVGClockValueParser.parse(".5s") == nil)
	#expect(SVGClockValueParser.parse("1e3s") == nil)
	#expect(SVGClockValueParser.parse("3 s") == nil)
	#expect(SVGClockValueParser.parse("01:60") == nil)
	#expect(SVGClockValueParser.parse("01:02:60") == nil)
	#expect(SVGClockValueParser.parse("1:02") == nil)
	#expect(SVGClockValueParser.parse("5MS") == nil)
	#expect(SVGClockValueParser.parse("indefinite") == nil)
	#expect(SVGClockValueParser.parse("media") == nil)
}

@Test func svgFrequencyParserConvertsFrequencyUnitsToHertz() throws {
	let hertz = try #require(SVGFrequencyParser.parse("440Hz"))
	let kilohertz = try #require(SVGFrequencyParser.parse("2kHz"))
	let lowerHertz = try #require(SVGFrequencyParser.parse("200hz"))
	let mixedKilohertz = try #require(SVGFrequencyParser.parse("1.5KHz"))
	let exponent = try #require(SVGFrequencyParser.parse("1e3Hz"))

	#expect(abs(hertz - 440) < 0.000001)
	#expect(abs(kilohertz - 2000) < 0.000001)
	#expect(abs(lowerHertz - 200) < 0.000001)
	#expect(abs(mixedKilohertz - 1500) < 0.000001)
	#expect(abs(exponent - 1000) < 0.000001)
}

@Test func svgFrequencyParserRejectsMalformedAndNegativeFrequencies() {
	#expect(SVGFrequencyParser.parse("") == nil)
	#expect(SVGFrequencyParser.parse("Hz") == nil)
	#expect(SVGFrequencyParser.parse("440") == nil)
	#expect(SVGFrequencyParser.parse("440 Hz") == nil)
	#expect(SVGFrequencyParser.parse("-1Hz") == nil)
	#expect(SVGFrequencyParser.parse("1MHz") == nil)
	#expect(SVGFrequencyParser.parse("1khzz") == nil)
	#expect(SVGFrequencyParser.parse("1%") == nil)
}

@Test func svgListParserSplitsCommaAndWhitespaceSeparatedValues() {
	#expect(SVGListParser.parse("10") == ["10"])
	#expect(SVGListParser.parse("10 20 30") == ["10", "20", "30"])
	#expect(SVGListParser.parse("10,20,30") == ["10", "20", "30"])
	#expect(SVGListParser.parse("10, 20 \t30\n40\r50\u{000C}60") == ["10", "20", "30", "40", "50", "60"])
	#expect(SVGListParser.parse("  10 ,\t20\n,\r30\u{000C}40  ") == ["10", "20", "30", "40"])
}

@Test func svgListParserRejectsMissingItemsAndBareSeparators() {
	#expect(SVGListParser.parse("") == nil)
	#expect(SVGListParser.parse("   ") == nil)
	#expect(SVGListParser.parse(",") == nil)
	#expect(SVGListParser.parse(",10") == nil)
	#expect(SVGListParser.parse("10,") == nil)
	#expect(SVGListParser.parse("10,,20") == nil)
	#expect(SVGListParser.parse("10, ,20") == nil)
	#expect(SVGListParser.parse("10  ,  , 20") == nil)
}

@Test func svgListParserMapsTokensThroughScalarParser() {
	#expect(SVGListParser.parse("1, 2 -3", itemParser: SVGNumberParser.parse) == [1, 2, -3])
	#expect(SVGListParser.parse("1, nope", itemParser: SVGNumberParser.parse) == nil)
}
