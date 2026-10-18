import FoundationModels

// Keep the first POC deliberately small. Every field maps to one exact server
// label; guided generation constrains the on-device model to this vocabulary
// instead of making the app parse unreliable free-form text.
@available(iOS 27.0, *)
@Generable(description: "The supported GarmentCode garment classification.")
struct GarmentLabels: Sendable, Equatable {
    @Guide(description: "The upper garment visible in the photo.")
    let upper: Upper

    @Guide(description: "The waistband treatment. Use none when no waistband is visible.")
    let waistband: Waistband

    @Guide(description: "The lower garment visible in the photo.")
    let bottom: Bottom

    @Guide(description: "True only when the upper and lower garment form one connected dress.")
    let connected: Bool

    @Guide(description: "The front neckline shape.")
    let frontNeckline: Neckline

    @Guide(description: "The back neckline shape.")
    let backNeckline: Neckline

    @Guide(description: "Whether the garment has no sleeves.")
    let sleeveless: Bool

    var serverLabels: [String] {
        [
            "meta__upper__\(upper.rawValue)",
            "meta__wb__\(waistband.rawValue)",
            "meta__bottom__\(bottom.rawValue)",
            "meta__connected__\(connected ? "True" : "False")",
            "collar__f_collar__\(frontNeckline.rawValue)",
            "collar__b_collar__\(backNeckline.rawValue)",
            "sleeve__sleeveless__\(sleeveless ? "True" : "False")",
        ]
    }

    /// Human-readable audit record shown before the values are sent to Qwen.
    var mmuaOutput: String {
        """
        upper: \(upper.rawValue)
        waistband: \(waistband.rawValue)
        bottom: \(bottom.rawValue)
        connected: \(connected)
        front_neckline: \(frontNeckline.rawValue)
        back_neckline: \(backNeckline.rawValue)
        sleeveless: \(sleeveless)

        GarmentCode labels:
        \(serverLabels.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
}

@available(iOS 27.0, *)
@Generable
enum Upper: String, Sendable {
    case fittedShirt = "FittedShirt"
    case shirt = "Shirt"
    case none = "None"
}

@available(iOS 27.0, *)
@Generable
enum Waistband: String, Sendable {
    case straight = "StraightWB"
    case fitted = "FittedWB"
    case none = "None"
}

@available(iOS 27.0, *)
@Generable
enum Bottom: String, Sendable {
    case circleSkirt = "SkirtCircle"
    case asymmetricalCircleSkirt = "AsymmSkirtCircle"
    case godetSkirt = "GodetSkirt"
    case skirt = "Skirt2"
    case paneledSkirt = "SkirtManyPanels"
    case pencilSkirt = "PencilSkirt"
    case tieredSkirt = "SkirtLevels"
    case pants = "Pants"
    case none = "None"
}

@available(iOS 27.0, *)
@Generable
enum Neckline: String, Sendable {
    case round = "CircleNeckHalf"
    case curved = "CurvyNeckHalf"
    case vNeck = "VNeckHalf"
    case square = "SquareNeckHalf"
    case trapezoid = "TrapezoidNeckHalf"
    case arc = "CircleArcNeckHalf"
    case bezier = "Bezier2NeckHalf"
}
