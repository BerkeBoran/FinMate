import SwiftUI
import VisionKit
import PhotosUI

struct ScanReceiptView: View {
    @ObservedObject var transactionVM: TransactionViewModel

    @State private var selectedImage: UIImage?
    @State private var showActionSheet = false
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isParsing = false
    @State private var parseResult: ReceiptParseResult?
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Fiş Okut")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)

                if !Config.hasValidGeminiKey {
                    GeminiKeyMissingBanner()
                        .padding(.horizontal)
                }

                Button(action: { showActionSheet = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.6),
                                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                                    )
                            )

                        VStack(spacing: 14) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 72, weight: .light))
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                                .shadow(color: Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.6), radius: 12)
                            Text("Fişi Tara")
                                .font(.title3).fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("Kamera veya galeriden seçin")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .disabled(isParsing)

                if isParsing {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Fiş analiz ediliyor…")
                            .font(.subheadline).foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                if let err = errorText {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer().frame(height: 30)
            }
            .padding(.vertical)
        }
        .midnightTheme()
        .navigationTitle("Fiş Okut")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Fiş Kaynağı", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Kameradan Çek") { showScanner = true }
            Button("Galeriden Seç") { showPhotoPicker = true }
            Button("İptal", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView { image in
                showScanner = false
                if let image { handle(image: image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    handle(image: image)
                }
                photoPickerItem = nil
            }
        }
        .sheet(item: Binding(
            get: { parseResult.map { ParseResultWrapper(image: selectedImage, result: $0) } },
            set: { _ in parseResult = nil; selectedImage = nil }
        )) { wrapper in
            if let image = wrapper.image {
                ReceiptReviewView(
                    image: image,
                    initialResult: wrapper.result,
                    transactionVM: transactionVM
                ) {
                    parseResult = nil
                    selectedImage = nil
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Kameradan Çek", systemImage: "camera")
                    }
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Galeriden Seç", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func handle(image: UIImage) {
        selectedImage = image
        errorText = nil
        isParsing = true
        Task {
            do {
                let result = try await GeminiReceiptService().parse(image: image)
                await MainActor.run {
                    parseResult = result
                    isParsing = false
                }
            } catch {
                await MainActor.run {
                    errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isParsing = false
                    selectedImage = nil
                }
            }
        }
    }
}

private struct ParseResultWrapper: Identifiable {
    let id = UUID()
    let image: UIImage?
    let result: ReceiptParseResult
}

struct GeminiKeyMissingBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Gemini API anahtarı eksik")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(Color.white)
                Text("Config.swift dosyasındaki geminiAPIKey'i güncelleyin. aistudio.google.com/apikey'den ücretsiz alabilirsiniz.")
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ReceiptReviewView: View {
    let image: UIImage
    @State var initialResult: ReceiptParseResult
    @ObservedObject var transactionVM: TransactionViewModel
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var items: [ReceiptItem] = []
    @State private var merchant: String = ""
    @State private var saving = false

    private var total: Double { items.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .cornerRadius(12)
                        .padding(.horizontal)

                    if !merchant.isEmpty {
                        HStack {
                            Image(systemName: "storefront")
                            Text(merchant)
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    HStack {
                        Text("\(items.count) kalem")
                            .font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "Toplam: %.2f TL", total))
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    ForEach($items) { $item in
                        ItemEditCard(item: $item)
                            .padding(.horizontal)
                    }

                    Button(role: .destructive) {
                    } label: { EmptyView() }
                        .hidden()

                    Button(action: save) {
                        HStack {
                            if saving { ProgressView().tint(.white) }
                            Text(saving ? "Kaydediliyor…" : "Onayla ve Kaydet")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(items.isEmpty ? Color.green.opacity(0.4) : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }
                    .disabled(saving || items.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("Fiş Önizleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .onAppear {
                items = initialResult.items
                merchant = initialResult.merchant ?? ""
            }
        }
    }

    private func save() {
        saving = true
        let receiptID = UUID()
        let filename = ReceiptStorage.save(image, id: receiptID)
        for item in items {
            transactionVM.addTransaction(
                title: item.name,
                amount: item.amount,
                type: .expense,
                category: item.category,
                receiptID: receiptID,
                receiptImagePath: filename
            )
        }
        saving = false
        dismiss()
        onDismiss()
    }
}

private struct ItemEditCard: View {
    @Binding var item: ReceiptItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Ürün adı", text: $item.name)
                .font(.headline)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    TextField("0.00", value: $item.amount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    Text("TL")
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)

                Spacer()

                Picker("Kategori", selection: $item.category) {
                    ForEach(ExpenseCategories.list, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(8)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: (UIImage?) -> Void
        init(onScan: @escaping (UIImage?) -> Void) { self.onScan = onScan }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil
            controller.dismiss(animated: true) { self.onScan(image) }
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) { self.onScan(nil) }
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) { self.onScan(nil) }
        }
    }
}
