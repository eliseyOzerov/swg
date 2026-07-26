import Foundation

/// Evaluates parsed SVG animation elements at a fixed document time.
struct SVGAnimationTimeline {
	private var time: TimeInterval
	private var effectsByTargetID: [String: [SVGAnimationEffect]]

	init(document: SVGDocument, time: TimeInterval) {
		self.time = max(0, time)
		var effectsByTargetID: [String: [SVGAnimationEffect]] = [:]
		for animation in document.animations {
			guard let effect = SVGAnimationEffect(animation), let targetID = effect.targetID, !targetID.isEmpty else { continue }
			effectsByTargetID[targetID, default: []].append(effect)
		}
		self.effectsByTargetID = effectsByTargetID
	}

	func applying(to element: SVGElement) -> SVGElement {
		guard let effects = effectsByTargetID[element.animationTargetID], !effects.isEmpty else { return element }
		return effects.reduce(element) { partial, effect in
			effect.applying(to: partial, time: time)
		}
	}
}

/// A renderer-supported animation effect with a resolved target.
private enum SVGAnimationEffect {
	case animate(SVGAnimateData)
	case animateTransform(SVGAnimateTransformData)
	case set(SVGSetData)

	init?(_ animation: SVGAnimationElement) {
		switch animation {
		case .animate(let data):
			self = .animate(data)
		case .animateTransform(let data):
			self = .animateTransform(data)
		case .set(let data):
			self = .set(data)
		case .animateMotion, .discard:
			return nil
		}
	}

	var targetID: String? {
		switch self {
		case .animate(let data):
			data.target?.animationTargetID
		case .animateTransform(let data):
			data.target?.animationTargetID
		case .set(let data):
			data.target?.animationTargetID
		}
	}

	func applying(to element: SVGElement, time: TimeInterval) -> SVGElement {
		switch self {
		case .animate(let data):
			guard let attributeName = data.attributeName, let interval = SVGAnimationInterval(timing: data.timing, time: time), let sample = SVGAnimationSampler.sample(data, currentValue: element.animationAttributeValue(named: attributeName), progress: interval.progress) else {
				return element
			}
			return element.settingAnimationAttribute(attributeName, to: sample, additive: data.addition.additive)
		case .animateTransform(let data):
			guard let interval = SVGAnimationInterval(timing: data.timing, time: time), let transform = SVGAnimationSampler.transformSample(data, progress: interval.progress) else {
				return element
			}
			return element.settingAnimationAttribute("transform", to: .transform(transform), additive: data.addition.additive)
		case .set(let data):
			guard data.timing.isSetActive(at: time), let attributeName = data.attributeName, let toValue = data.toValue else {
				return element
			}
			return element.settingAnimationAttribute(attributeName, to: .string(toValue), additive: .replace)
		}
	}
}

/// A simple active interval and normalized progress for clock-based SVG animations.
private struct SVGAnimationInterval {
	var progress: Double

	init?(timing: SVGAnimationTimingData, time: TimeInterval) {
		guard let begin = timing.begin.clockSeconds.first else { return nil }
		guard time >= begin else { return nil }
		let elapsed = time - begin
		guard let duration = timing.dur.clockSeconds, duration > 0 else {
			progress = 1
			return
		}
		let activeDuration = timing.activeDuration(simpleDuration: duration)
		if let activeDuration, elapsed > activeDuration {
			return nil
		}
		if let activeDuration, elapsed == activeDuration {
			progress = 1
			return
		}
		progress = max(0, min(1, elapsed.truncatingRemainder(dividingBy: duration) / duration))
	}
}

/// Interpolates raw SVG animation value attributes into renderer samples.
private enum SVGAnimationSampler {
	static func sample(_ animation: SVGAnimateData, currentValue: SVGAnimationAttributeValue?, progress: Double) -> SVGAnimationSample? {
		let values = valueList(values: animation.valueControl.values, from: animation.fromValue, to: animation.toValue, by: animation.byValue, currentValue: currentValue)
		guard !values.isEmpty else { return nil }
		if animation.attributeName?.isPaintAnimationAttribute == true, let sample = paintSample(values, progress: progress, valueControl: animation.valueControl) {
			return sample
		}
		if let numbers = numericValues(values), let sample = numericSample(numbers, progress: progress, valueControl: animation.valueControl) {
			return sample
		}
		return .string(discreteValue(values, progress: progress, valueControl: animation.valueControl))
	}

	static func transformSample(_ animation: SVGAnimateTransformData, progress: Double) -> Transform? {
		let values = valueList(values: animation.valueControl.values, from: animation.fromValue, to: animation.toValue, by: animation.byValue, currentValue: nil)
		let numberLists = values.map { SVGAnimationParser.numberList($0) }
		guard numberLists.count >= 2, numberLists.allSatisfy({ !$0.isEmpty }) else { return nil }
		let segment = SVGAnimationSegment(progress: progress, valueCount: numberLists.count, valueControl: animation.valueControl)
		let lhs = numberLists[segment.lowerIndex]
		let rhs = numberLists[segment.upperIndex]
		let count = min(lhs.count, rhs.count)
		guard count > 0 else { return nil }
		let interpolatedValues = (0..<count).map { SVGAnimationMath.lerp(lhs[$0], rhs[$0], segment.localProgress) }
		return transform(type: animation.type, values: interpolatedValues)
	}

	private static func valueList(values: [String]?, from: String?, to: String?, by: String?, currentValue: SVGAnimationAttributeValue?) -> [String] {
		if let values, !values.isEmpty { return values }
		if let from, let to { return [from, to] }
		if let from, let by, let fromNumber = SVGAnimationParser.number(from), let byNumber = SVGAnimationParser.number(by) {
			return [from, "\(fromNumber + byNumber)"]
		}
		if let to, let currentValue {
			return [currentValue.rawValue, to]
		}
		if let by, let currentValue, let currentNumber = currentValue.number, let byNumber = SVGAnimationParser.number(by) {
			return [currentValue.rawValue, "\(currentNumber + byNumber)"]
		}
		return []
	}

	private static func numericValues(_ values: [String]) -> [Double]? {
		let numbers = values.compactMap(SVGAnimationParser.number)
		return numbers.count == values.count ? numbers : nil
	}

	private static func numericSample(_ values: [Double], progress: Double, valueControl: SVGAnimationValueControlData) -> SVGAnimationSample? {
		guard values.count >= 2 else { return values.first.map(SVGAnimationSample.number) }
		if valueControl.calcMode == .discrete {
			return .number(values[SVGAnimationSegment.discreteIndex(progress: progress, valueCount: values.count, valueControl: valueControl)])
		}
		let segment = SVGAnimationSegment(progress: progress, valueCount: values.count, valueControl: valueControl)
		return .number(SVGAnimationMath.lerp(values[segment.lowerIndex], values[segment.upperIndex], segment.localProgress))
	}

	private static func paintSample(_ values: [String], progress: Double, valueControl: SVGAnimationValueControlData) -> SVGAnimationSample? {
		guard values.count >= 2 else {
			return values.first.flatMap(SVGAnimationParser.paint).map(SVGAnimationSample.paint)
		}
		let paints = values.compactMap(SVGAnimationParser.paint)
		guard paints.count == values.count else { return nil }
		if valueControl.calcMode == .discrete {
			return .paint(paints[SVGAnimationSegment.discreteIndex(progress: progress, valueCount: paints.count, valueControl: valueControl)])
		}
		let segment = SVGAnimationSegment(progress: progress, valueCount: paints.count, valueControl: valueControl)
		if case .color(let lhs) = paints[segment.lowerIndex], case .color(let rhs) = paints[segment.upperIndex] {
			return .paint(.color(SVGAnimationMath.lerp(lhs, rhs, segment.localProgress)))
		}
		return .paint(paints[SVGAnimationSegment.discreteIndex(progress: progress, valueCount: paints.count, valueControl: valueControl)])
	}

	private static func discreteValue(_ values: [String], progress: Double, valueControl: SVGAnimationValueControlData) -> String {
		values[SVGAnimationSegment.discreteIndex(progress: progress, valueCount: values.count, valueControl: valueControl)]
	}

	private static func transform(type: String, values: [Double]) -> Transform? {
		switch type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
		case "translate":
			guard let x = values.first else { return nil }
			return .identity.translatedBy(x: x, y: values.count > 1 ? values[1] : 0)
		case "scale":
			guard let x = values.first else { return nil }
			return .identity.scaledBy(x: x, y: values.count > 1 ? values[1] : x)
		case "rotate":
			guard let angle = values.first else { return nil }
			if values.count >= 3 {
				return .identity.rotated(by: angle * .pi / 180, center: Point(values[1], values[2]))
			}
			return .identity.rotated(by: angle * .pi / 180)
		case "skewx":
			guard let angle = values.first else { return nil }
			return .identity.skewedX(by: angle * .pi / 180)
		case "skewy":
			guard let angle = values.first else { return nil }
			return .identity.skewedY(by: angle * .pi / 180)
		default:
			return nil
		}
	}
}

/// A sampled value ready to apply to an SVG element.
private enum SVGAnimationSample {
	case number(Double)
	case string(String)
	case paint(SVGPaint)
	case transform(Transform)
}

/// An element's current attribute value expressed for animation sampling.
private struct SVGAnimationAttributeValue {
	var rawValue: String
	var number: Double?
	var paint: SVGPaint?
}

/// A normalized interpolation segment between two animation values.
private struct SVGAnimationSegment {
	var lowerIndex: Int
	var upperIndex: Int
	var localProgress: Double

	init(progress: Double, valueCount: Int, valueControl: SVGAnimationValueControlData) {
		let keyTimes = valueControl.keyTimes.validValues(expectedCount: valueCount)
		if let keyTimes {
			let clampedProgress = max(0, min(1, progress))
			let lower = keyTimes.indices.dropLast().last { keyTimes[$0] <= clampedProgress } ?? 0
			let upper = min(lower + 1, valueCount - 1)
			let span = keyTimes[upper] - keyTimes[lower]
			let local = span > 0 ? (clampedProgress - keyTimes[lower]) / span : 0
			lowerIndex = lower
			upperIndex = upper
			localProgress = SVGAnimationSegment.easedProgress(local, segmentIndex: lower, valueControl: valueControl)
		} else {
			let scaled = max(0, min(1, progress)) * Double(valueCount - 1)
			let lower = min(Int(floor(scaled)), valueCount - 2)
			lowerIndex = lower
			upperIndex = lower + 1
			localProgress = SVGAnimationSegment.easedProgress(scaled - Double(lower), segmentIndex: lower, valueControl: valueControl)
		}
	}

	static func discreteIndex(progress: Double, valueCount: Int, valueControl: SVGAnimationValueControlData) -> Int {
		guard valueCount > 1 else { return 0 }
		if let keyTimes = valueControl.keyTimes.validValues(expectedCount: valueCount) {
			let clampedProgress = max(0, min(1, progress))
			return min(keyTimes.indices.last { keyTimes[$0] <= clampedProgress } ?? 0, valueCount - 1)
		}
		return min(Int(max(0, min(0.999999, progress)) * Double(valueCount)), valueCount - 1)
	}

	private static func easedProgress(_ progress: Double, segmentIndex: Int, valueControl: SVGAnimationValueControlData) -> Double {
		guard valueControl.calcMode == .spline, let splines = valueControl.keySplines.validValues, splines.indices.contains(segmentIndex) else {
			return max(0, min(1, progress))
		}
		return SVGAnimationMath.cubicBezierY(forX: max(0, min(1, progress)), spline: splines[segmentIndex])
	}
}

/// Lightweight parsing helpers used by the animation evaluator.
private enum SVGAnimationParser {
	static func number(_ value: String) -> Double? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.hasSuffix("%") {
			return Double(trimmed.dropLast().trimmingCharacters(in: .whitespacesAndNewlines)).map { $0 / 100 }
		}
		return Double(trimmed)
	}

	static func numberList(_ value: String) -> [Double] {
		value
			.replacingOccurrences(of: ",", with: " ")
			.split(whereSeparator: \.isWhitespace)
			.compactMap { Double($0) }
	}

	static func paint(_ value: String) -> SVGPaint? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed == "none" { return SVGPaint.none }
		if trimmed == "currentColor" { return .currentColor }
		if trimmed.hasPrefix("url("), trimmed.hasSuffix(")") {
			let id = trimmed.dropFirst(4).dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
			return .url(String(id))
		}
		return color(trimmed).map(SVGPaint.color)
	}

	static func color(_ value: String) -> Color? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		if trimmed.hasPrefix("#") {
			return hexColor(trimmed)
		}
		switch trimmed {
		case "black":
			return .black
		case "white":
			return .white
		case "red":
			return .red
		case "green":
			return .green
		case "blue":
			return .blue
		case "gray", "grey":
			return .gray
		case "transparent":
			return .clear
		default:
			return nil
		}
	}

	private static func hexColor(_ value: String) -> Color? {
		let hex = String(value.dropFirst())
		if hex.count == 3 {
			let values = hex.map(String.init).compactMap { Int($0 + $0, radix: 16) }
			guard values.count == 3 else { return nil }
			return Color(Double(values[0]) / 255, Double(values[1]) / 255, Double(values[2]) / 255)
		}
		if hex.count == 6 {
			let scanner = Scanner(string: hex)
			var value: UInt64 = 0
			guard scanner.scanHexInt64(&value) else { return nil }
			return Color(Double((value >> 16) & 0xff) / 255, Double((value >> 8) & 0xff) / 255, Double(value & 0xff) / 255)
		}
		return nil
	}
}

/// Math helpers for scalar, color, and spline interpolation.
private enum SVGAnimationMath {
	static func lerp(_ lhs: Double, _ rhs: Double, _ progress: Double) -> Double {
		lhs + (rhs - lhs) * max(0, min(1, progress))
	}

	static func lerp(_ lhs: Color, _ rhs: Color, _ progress: Double) -> Color {
		Color(
			lerp(lhs.red, rhs.red, progress),
			lerp(lhs.green, rhs.green, progress),
			lerp(lhs.blue, rhs.blue, progress),
			lerp(lhs.alpha, rhs.alpha, progress)
		)
	}

	static func cubicBezierY(forX x: Double, spline: SVGAnimationKeySpline) -> Double {
		var low = 0.0
		var high = 1.0
		var t = x
		for _ in 0..<16 {
			t = (low + high) / 2
			let sampleX = cubicBezier(t, 0, spline.x1, spline.x2, 1)
			if sampleX < x {
				low = t
			} else {
				high = t
			}
		}
		return cubicBezier(t, 0, spline.y1, spline.y2, 1)
	}

	private static func cubicBezier(_ t: Double, _ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> Double {
		let inverse = 1 - t
		return inverse * inverse * inverse * p0
			+ 3 * inverse * inverse * t * p1
			+ 3 * inverse * t * t * p2
			+ t * t * t * p3
	}
}

private extension SVGElement {
	var animationTargetID: String {
		switch self {
		case .path(let data): data.id
		case .rect(let data): data.id
		case .circle(let data): data.id
		case .ellipse(let data): data.id
		case .line(let data): data.id
		case .polygon(let data): data.id
		case .polyline(let data): data.id
		case .group(let data): data.id
		case .switch(let data): data.id
		case .link(let data): data.id
		case .svg(let data): data.id
		case .unknown(let data): data.id
		case .use(let data): data.id
		case .image(let data): data.id
		case .foreignObject(let data): data.id
		case .text(let data): data.id
		}
	}

	func animationAttributeValue(named name: String) -> SVGAnimationAttributeValue? {
		let name = name.animationAttributeName
		if let number = animationNumericAttribute(named: name) {
			return SVGAnimationAttributeValue(rawValue: "\(number)", number: number, paint: nil)
		}
		if let attributes = animationPaintAttributes {
			switch name {
			case "opacity":
				return SVGAnimationAttributeValue(rawValue: "\(attributes.opacity)", number: attributes.opacity, paint: nil)
			case "fill-opacity":
				return SVGAnimationAttributeValue(rawValue: "\(attributes.fillOpacity)", number: attributes.fillOpacity, paint: nil)
			case "stroke-opacity":
				return SVGAnimationAttributeValue(rawValue: "\(attributes.strokeOpacity)", number: attributes.strokeOpacity, paint: nil)
			case "stroke-width":
				return SVGAnimationAttributeValue(rawValue: "\(attributes.strokeWidth)", number: attributes.strokeWidth, paint: nil)
			case "fill":
				return SVGAnimationAttributeValue(rawValue: attributes.fill.animationRawValue, number: nil, paint: attributes.fill)
			case "stroke":
				return SVGAnimationAttributeValue(rawValue: attributes.stroke.animationRawValue, number: nil, paint: attributes.stroke)
			default:
				return nil
			}
		}
		return nil
	}

	func settingAnimationAttribute(_ name: String, to sample: SVGAnimationSample, additive: SVGAnimationAdditive) -> SVGElement {
		let name = name.animationAttributeName
		if let numericElement = settingAnimationNumericAttribute(name, to: sample) {
			return numericElement
		}
		return settingAnimationPresentationAttribute(name, to: sample, additive: additive)
	}

	private var animationPaintAttributes: SVGPaintAttributes? {
		switch self {
		case .path(let data): data.attributes
		case .rect(let data): data.attributes
		case .circle(let data): data.attributes
		case .ellipse(let data): data.attributes
		case .line(let data): data.attributes
		case .polygon(let data): data.attributes
		case .polyline(let data): data.attributes
		case .group(let data): data.attributes
		case .switch(let data): data.attributes
		case .link(let data): data.attributes
		case .svg(let data): data.attributes
		case .unknown(let data): data.attributes
		case .use(let data): data.attributes
		case .image(let data): data.attributes
		case .foreignObject(let data): data.attributes
		case .text(let data): data.attributes
		}
	}

	private func animationNumericAttribute(named name: String) -> Double? {
		switch self {
		case .rect(let data):
			switch name {
			case "x": data.x
			case "y": data.y
			case "width": data.width
			case "height": data.height
			case "rx": data.rx
			case "ry": data.ry
			default: nil
			}
		case .circle(let data):
			switch name {
			case "cx": data.cx
			case "cy": data.cy
			case "r": data.r
			default: nil
			}
		case .ellipse(let data):
			switch name {
			case "cx": data.cx
			case "cy": data.cy
			case "rx": data.rx
			case "ry": data.ry
			default: nil
			}
		case .line(let data):
			switch name {
			case "x1": data.x1
			case "y1": data.y1
			case "x2": data.x2
			case "y2": data.y2
			default: nil
			}
		case .svg(let data):
			switch name {
			case "x": data.x
			case "y": data.y
			case "width": data.width
			case "height": data.height
			default: nil
			}
		case .use(let data):
			switch name {
			case "x": data.x
			case "y": data.y
			case "width": data.width
			case "height": data.height
			default: nil
			}
		case .image(let data):
			switch name {
			case "x": data.x
			case "y": data.y
			case "width": data.width
			case "height": data.height
			default: nil
			}
		case .foreignObject(let data):
			switch name {
			case "x": data.x
			case "y": data.y
			case "width": data.width
			case "height": data.height
			default: nil
			}
		case .text(let data):
			switch name {
			case "x": data.x
			case "y": data.y
			case "font-size": data.fontSize
			default: nil
			}
		case .path, .polygon, .polyline, .group, .switch, .link, .unknown:
			nil
		}
	}

	private func settingAnimationNumericAttribute(_ name: String, to sample: SVGAnimationSample) -> SVGElement? {
		guard case .number(let value) = sample else { return nil }
		switch self {
		case .rect(let data):
			return .rect(SVGRectData(id: data.id, x: name == "x" ? value : data.x, y: name == "y" ? value : data.y, width: name == "width" ? value : data.width, height: name == "height" ? value : data.height, rx: name == "rx" ? value : data.rx, ry: name == "ry" ? value : data.ry, attributes: data.attributes, rxIsAuto: data.rxIsAuto, ryIsAuto: data.ryIsAuto, language: data.language, unknownAttributes: data.unknownAttributes))
		case .circle(let data):
			return .circle(SVGCircleData(id: data.id, cx: name == "cx" ? value : data.cx, cy: name == "cy" ? value : data.cy, r: name == "r" ? value : data.r, attributes: data.attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .ellipse(let data):
			return .ellipse(SVGEllipseData(id: data.id, cx: name == "cx" ? value : data.cx, cy: name == "cy" ? value : data.cy, rx: name == "rx" ? value : data.rx, ry: name == "ry" ? value : data.ry, attributes: data.attributes, rxIsAuto: data.rxIsAuto, ryIsAuto: data.ryIsAuto, language: data.language, unknownAttributes: data.unknownAttributes))
		case .line(let data):
			return .line(SVGLineData(id: data.id, x1: name == "x1" ? value : data.x1, y1: name == "y1" ? value : data.y1, x2: name == "x2" ? value : data.x2, y2: name == "y2" ? value : data.y2, attributes: data.attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .svg(let data):
			return .svg(SVGViewportData(id: data.id, x: name == "x" ? value : data.x, y: name == "y" ? value : data.y, width: name == "width" ? value : data.width, height: name == "height" ? value : data.height, viewBox: data.viewBox, preserveAspectRatio: data.preserveAspectRatio, attributes: data.attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .use(let data):
			return .use(SVGUseData(id: data.id, href: data.href, x: name == "x" ? value : data.x, y: name == "y" ? value : data.y, width: name == "width" ? value : data.width, height: name == "height" ? value : data.height, attributes: data.attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .image(let data):
			return .image(SVGImageData(id: data.id, x: name == "x" ? value : data.x, y: name == "y" ? value : data.y, width: name == "width" ? value : data.width, height: name == "height" ? value : data.height, href: data.href, attributes: data.attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .foreignObject(let data):
			return .foreignObject(SVGForeignObjectData(id: data.id, x: name == "x" ? value : data.x, y: name == "y" ? value : data.y, width: name == "width" ? value : data.width, height: name == "height" ? value : data.height, attributes: data.attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .text(let data):
			return .text(SVGTextData(id: data.id, x: name == "x" ? value : data.x, y: name == "y" ? value : data.y, xValues: data.xValues, yValues: data.yValues, dxValues: data.dxValues, dyValues: data.dyValues, rotateValues: data.rotateValues, fontSize: name == "font-size" ? value : data.fontSize, fontFamily: data.fontFamily, fontWeight: data.fontWeight, textAnchor: data.textAnchor, dominantBaseline: data.dominantBaseline, whiteSpace: data.whiteSpace, attributes: data.attributes, spans: data.spans, language: data.language, unknownAttributes: data.unknownAttributes))
		case .path, .polygon, .polyline, .group, .switch, .link, .unknown:
			return nil
		}
	}

	private func settingAnimationPresentationAttribute(_ name: String, to sample: SVGAnimationSample, additive: SVGAnimationAdditive) -> SVGElement {
		guard var attributes = animationPaintAttributes else { return self }
		attributes.setAnimationPresentationAttribute(name, to: sample, additive: additive)
		return settingAnimationPaintAttributes(attributes)
	}

	private func settingAnimationPaintAttributes(_ attributes: SVGPaintAttributes) -> SVGElement {
		switch self {
		case .path(let data):
			return .path(SVGPathData(id: data.id, d: data.d, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .rect(let data):
			return .rect(SVGRectData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, rx: data.rx, ry: data.ry, attributes: attributes, rxIsAuto: data.rxIsAuto, ryIsAuto: data.ryIsAuto, language: data.language, unknownAttributes: data.unknownAttributes))
		case .circle(let data):
			return .circle(SVGCircleData(id: data.id, cx: data.cx, cy: data.cy, r: data.r, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .ellipse(let data):
			return .ellipse(SVGEllipseData(id: data.id, cx: data.cx, cy: data.cy, rx: data.rx, ry: data.ry, attributes: attributes, rxIsAuto: data.rxIsAuto, ryIsAuto: data.ryIsAuto, language: data.language, unknownAttributes: data.unknownAttributes))
		case .line(let data):
			return .line(SVGLineData(id: data.id, x1: data.x1, y1: data.y1, x2: data.x2, y2: data.y2, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .polygon(let data):
			return .polygon(SVGPolygonData(id: data.id, points: data.points, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .polyline(let data):
			return .polyline(SVGPolylineData(id: data.id, points: data.points, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .group(let data):
			return .group(SVGGroupData(id: data.id, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .switch(let data):
			return .switch(SVGSwitchData(id: data.id, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .link(let data):
			return .link(SVGLinkData(id: data.id, href: data.href, target: data.target, download: data.download, ping: data.ping, rel: data.rel, hreflang: data.hreflang, type: data.type, referrerPolicy: data.referrerPolicy, xlinkTitle: data.xlinkTitle, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .svg(let data):
			return .svg(SVGViewportData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, viewBox: data.viewBox, preserveAspectRatio: data.preserveAspectRatio, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .unknown(let data):
			return .unknown(SVGUnknownElementData(id: data.id, name: data.name, namespaceURI: data.namespaceURI, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .use(let data):
			return .use(SVGUseData(id: data.id, href: data.href, x: data.x, y: data.y, width: data.width, height: data.height, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .image(let data):
			return .image(SVGImageData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, href: data.href, attributes: attributes, language: data.language, unknownAttributes: data.unknownAttributes))
		case .foreignObject(let data):
			return .foreignObject(SVGForeignObjectData(id: data.id, x: data.x, y: data.y, width: data.width, height: data.height, attributes: attributes, children: data.children, language: data.language, unknownAttributes: data.unknownAttributes))
		case .text(let data):
			return .text(SVGTextData(id: data.id, x: data.x, y: data.y, xValues: data.xValues, yValues: data.yValues, dxValues: data.dxValues, dyValues: data.dyValues, rotateValues: data.rotateValues, fontSize: data.fontSize, fontFamily: data.fontFamily, fontWeight: data.fontWeight, textAnchor: data.textAnchor, dominantBaseline: data.dominantBaseline, whiteSpace: data.whiteSpace, attributes: attributes, spans: data.spans, language: data.language, unknownAttributes: data.unknownAttributes))
		}
	}
}

private extension SVGPaintAttributes {
	mutating func setAnimationPresentationAttribute(_ name: String, to sample: SVGAnimationSample, additive: SVGAnimationAdditive) {
		switch name {
		case "opacity":
			if case .number(let value) = sample { opacity = max(0, min(1, value)) }
		case "fill-opacity":
			if case .number(let value) = sample { fillOpacity = max(0, min(1, value)) }
		case "stroke-opacity":
			if case .number(let value) = sample { strokeOpacity = max(0, min(1, value)) }
		case "stroke-width":
			if case .number(let value) = sample { strokeWidth = max(0, value) }
		case "fill":
			if let paint = sample.paintValue { fill = paint }
		case "stroke":
			if let paint = sample.paintValue { stroke = paint }
		case "display":
			if case .string(let value) = sample { display = value.trimmingCharacters(in: .whitespacesAndNewlines) == "none" ? .none : .inline }
		case "visibility":
			if case .string(let value) = sample { visibility = SVGVisibility.animationValue(value) ?? visibility }
		case "transform":
			if case .transform(let value) = sample {
				transform = additive == .sum ? transform.concatenating(value) : value
			}
		default:
			break
		}
	}
}

private extension SVGAnimationSample {
	var paintValue: SVGPaint? {
		switch self {
		case .paint(let paint):
			return paint
		case .string(let value):
			return SVGAnimationParser.paint(value)
		case .number, .transform:
			return nil
		}
	}
}

private extension SVGAnimationTarget {
	var animationTargetID: String? {
		switch self {
		case .parent(let id):
			return id
		case .href(let href):
			return href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		}
	}
}

private extension SVGAnimationTimingData {
	func isSetActive(at time: TimeInterval) -> Bool {
		guard let begin = begin.clockSeconds.first, time >= begin else { return false }
		guard let duration = dur.clockSeconds, duration > 0 else { return true }
		if let activeDuration = activeDuration(simpleDuration: duration) {
			return time - begin <= activeDuration
		}
		return true
	}

	func activeDuration(simpleDuration: TimeInterval) -> TimeInterval? {
		var duration: TimeInterval? = simpleDuration
		switch repeatCount {
		case .number(_, let value):
			duration = value > 0 ? simpleDuration * value : 0
		case .indefinite:
			duration = nil
		case .unresolved, .none:
			break
		}
		if let repeatDuration = repeatDur?.clockSeconds {
			duration = duration.map { Swift.min($0, repeatDuration) } ?? repeatDuration
		}
		return duration
	}
}

private extension Array where Element == SVGAnimationTimeValue {
	var clockSeconds: [TimeInterval] {
		compactMap(\.clockSeconds)
	}
}

private extension SVGAnimationTimeValue {
	var clockSeconds: TimeInterval? {
		if case .clock(_, let seconds) = self {
			return seconds
		}
		return nil
	}
}

private extension SVGAnimationKeyTimes? {
	func validValues(expectedCount: Int) -> [Double]? {
		guard case .values(let values) = self, values.count == expectedCount, values.first == 0, values.last == 1 else { return nil }
		return values
	}
}

private extension SVGAnimationKeySplines? {
	var validValues: [SVGAnimationKeySpline]? {
		if case .values(let splines) = self {
			return splines
		}
		return nil
	}
}

private extension SVGPaint {
	var animationRawValue: String {
		switch self {
		case .none:
			return "none"
		case .color(let color):
			return "\(color.red) \(color.green) \(color.blue) \(color.alpha)"
		case .currentColor:
			return "currentColor"
		case .url(let id):
			return "url(\(id))"
		case .urlWithFallback(let id, _):
			return "url(\(id))"
		case .contextFill:
			return "context-fill"
		case .contextStroke:
			return "context-stroke"
		}
	}
}

private extension SVGVisibility {
	static func animationValue(_ value: String) -> SVGVisibility? {
		switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
		case "visible":
			return .visible
		case "hidden":
			return .hidden
		case "collapse":
			return .collapse
		default:
			return nil
		}
	}
}

private extension String {
	var animationAttributeName: String {
		trimmingCharacters(in: .whitespacesAndNewlines)
			.replacingOccurrences(of: "_", with: "-")
			.lowercased()
	}

	var isPaintAnimationAttribute: Bool {
		let name = animationAttributeName
		return name == "fill" || name == "stroke"
	}
}
