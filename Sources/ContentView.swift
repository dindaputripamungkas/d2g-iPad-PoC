import PhotosUI
import SwiftUI

@available(iOS 27.0, *)
@MainActor
final class PatternViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var labels: [String] = []
    @Published var mmuaOutput: String?
    @Published var result: PatternAPIResponse?
    @Published var errorMessage: String?
    @Published var status = "Choose a garment photo to begin."
    @Published var isWorking = false

    private let classifier = GarmentClassifier()

    func modelAvailabilityMessage() async -> String? {
        await classifier.availabilityMessage()
    }

    func analyze() async {
        guard let selectedImage else { return }
        isWorking = true
        errorMessage = nil
        result = nil
        do {
            status = "Analyzing the garment on this iPad…"
            let detected = try await classifier.classify(selectedImage)
            labels = detected.serverLabels
            mmuaOutput = detected.mmuaOutput
            status = "MMUA output is ready. Review it, then send it to Qwen."
        } catch {
            errorMessage = error.localizedDescription
            status = "Could not analyze the garment."
        }
        isWorking = false
    }

    func generate(serverURL: String) async {
        guard let selectedImage, !labels.isEmpty else { return }
        isWorking = true
        errorMessage = nil
        result = nil
        do {
            status = "Sending MMUA output to Qwen on your server…"
            let client = try PatternAPIClient(serverURL: serverURL)
            result = try await client.createPattern(image: selectedImage, labels: labels)
            status = "Pattern ready."
        } catch {
            errorMessage = error.localizedDescription
            status = "Could not generate a pattern."
        }
        isWorking = false
    }
}

@available(iOS 27.0, *)
struct ContentView: View {
    @AppStorage("serverURL") private var serverURL = "http://10.63.48.118:8000"
    @StateObject private var viewModel = PatternViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var availabilityMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Pattern server") {
                    TextField("Server URL", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Text("Use your Mac’s Wi-Fi address, not 127.0.0.1.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Garment photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo.on.rectangle")
                    }
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let availabilityMessage {
                    Section("Apple Intelligence unavailable") {
                        Text(availabilityMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.analyze() }
                    } label: {
                        if viewModel.isWorking {
                            HStack { ProgressView(); Text(viewModel.status) }
                        } else {
                            Label("Analyze garment on iPad", systemImage: "eye")
                        }
                    }
                    .disabled(viewModel.selectedImage == nil || viewModel.isWorking || availabilityMessage != nil)
                    Text(viewModel.status).font(.footnote).foregroundStyle(.secondary)
                }

                if let output = viewModel.mmuaOutput {
                    Section("MMUA output — before Qwen") {
                        Text(output)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        Text("This structured on-device result will be sent with the photo to Qwen on your Mac.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await viewModel.generate(serverURL: serverURL) }
                        } label: {
                            Label("Send MMUA output to Qwen and create pattern", systemImage: "wand.and.stars")
                        }
                        .disabled(viewModel.isWorking)
                    }
                }

                if let result = viewModel.result {
                    Section("Generated pattern") {
                        if let client = try? PatternAPIClient(serverURL: serverURL),
                           let previewURL = client.artifactURL(result.artifacts.previewPng) {
                            AsyncImage(url: previewURL) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        if let client = try? PatternAPIClient(serverURL: serverURL) {
                            if let svgURL = client.artifactURL(result.artifacts.svg) {
                                Link("Open SVG", destination: svgURL)
                            }
                            if let pdfURL = client.artifactURL(result.artifacts.printablePdf) {
                                Link("Download printable PDF", destination: pdfURL)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Section("Error") { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("GarmentCode")
            .task { availabilityMessage = await viewModel.modelAvailabilityMessage() }
            .onChange(of: photoItem) {
                Task {
                    guard let data = try? await photoItem?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    viewModel.selectedImage = image
                    viewModel.labels = []
                    viewModel.mmuaOutput = nil
                    viewModel.result = nil
                }
            }
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    ContentView()
}
