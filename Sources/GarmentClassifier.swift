import FoundationModels
import UIKit

@available(iOS 27.0, *)
enum GarmentClassifierError: LocalizedError {
    case modelUnavailable(String)
    case unusableImage

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple Intelligence is unavailable: \(reason)"
        case .unusableImage:
            return "The selected photo could not be prepared for on-device analysis."
        }
    }
}

@available(iOS 27.0, *)
actor GarmentClassifier {
    private let model = SystemLanguageModel.default

    func availabilityMessage() -> String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This iPad does not support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in Settings, then try again."
        case .unavailable(.modelNotReady):
            return "Apple’s on-device model is still downloading or is not ready."
        case .unavailable(let reason):
            return "Apple’s on-device model is unavailable: \(reason)."
        @unknown default:
            return "Apple’s on-device model is unavailable."
        }
    }

    func classify(_ image: UIImage) async throws -> GarmentLabels {
        if let message = availabilityMessage() {
            throw GarmentClassifierError.modelUnavailable(message)
        }
        guard let cgImage = image.cgImage else {
            throw GarmentClassifierError.unusableImage
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You classify one fashion garment photo for a sewing-pattern prototype.
            Select only what is visibly supported by the image. Do not invent
            clothing layers or details hidden by the pose. A one-piece dress has
            connected true. A top, skirt, or trousers by itself has connected false.
            """
        )
        let response = try await session.respond(generating: GarmentLabels.self) {
            "Classify this garment photo into the supplied GarmentCode fields."
            Attachment(cgImage).label("garment photo")
        }
        return response.content
    }
}
