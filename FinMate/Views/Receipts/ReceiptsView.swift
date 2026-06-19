import SwiftUI

struct ReceiptsView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var pendingDelete: ReceiptSummary?

    var body: some View {
        let receipts = viewModel.receipts()

        Group {
            if receipts.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 56))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Henüz fiş okutulmadı")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Sol menüden 'Fiş Okut' ile başlayın")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                List {
                    ForEach(receipts) { receipt in
                        ZStack {
                            ReceiptRow(receipt: receipt)
                            NavigationLink(destination: ReceiptDetailView(receipt: receipt, viewModel: viewModel)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = receipt
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                pendingDelete = receipt
                            } label: {
                                Label("Fişi Sil", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .midnightTheme()
        .navigationTitle("Fişlerim")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Fişi silmek istediğine emin misin?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
        ) {
            Button("Vazgeç", role: .cancel) { pendingDelete = nil }
            Button("Sil", role: .destructive) {
                if let r = pendingDelete {
                    viewModel.deleteReceipt(r.id)
                }
                pendingDelete = nil
            }
        } message: {
            if let r = pendingDelete {
                Text("Bu fişle birlikte fişten eklediğiniz \(r.itemCount) gider kalemi de silinecek ve toplam giderlerinizden düşülecek. Bu işlem geri alınamaz.")
            } else {
                Text("")
            }
        }
    }
}

private struct ReceiptRow: View {
    let receipt: ReceiptSummary

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy, HH:mm"
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            if let path = receipt.imagePath, let image = ReceiptStorage.load(path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipped()
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 64, height: 64)
                    .overlay(Image(systemName: "doc.text").foregroundColor(.gray))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: receipt.date))
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(receipt.itemCount) kalem")
                    .font(.caption).foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f TL", receipt.total))
                    .font(.headline)
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }
}

struct ReceiptDetailView: View {
    let receipt: ReceiptSummary
    @ObservedObject var viewModel: TransactionViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showFullImage = false
    @State private var showDeleteConfirm = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy, HH:mm"
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let path = receipt.imagePath, let image = ReceiptStorage.load(path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .onTapGesture { showFullImage = true }
                        .fullScreenCover(isPresented: $showFullImage) {
                            FullScreenImage(image: image) { showFullImage = false }
                        }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.dateFormatter.string(from: receipt.date))
                            .font(.subheadline).foregroundColor(.gray)
                        Text("\(receipt.itemCount) kalem")
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Text(String(format: "%.2f TL", receipt.total))
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                }
                .padding(.horizontal)

                Divider().background(Color.white.opacity(0.15)).padding(.horizontal)

                VStack(spacing: 10) {
                    ForEach(receipt.items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title ?? "Kalem")
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.white)
                                Text(item.category ?? "—")
                                    .font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "%.2f TL", item.amount))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }

                Spacer().frame(height: 30)
            }
            .padding(.vertical)
        }
        .midnightTheme()
        .navigationTitle("Fiş Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Fişi silmek istediğine emin misin?", isPresented: $showDeleteConfirm) {
            Button("Vazgeç", role: .cancel) {}
            Button("Sil", role: .destructive) {
                viewModel.deleteReceipt(receipt.id)
                dismiss()
            }
        } message: {
            Text("Bu fişle birlikte fişten eklediğiniz \(receipt.itemCount) gider kalemi de silinecek ve toplam giderlerinizden düşülecek. Bu işlem geri alınamaz.")
        }
    }
}

private struct FullScreenImage: View {
    let image: UIImage
    var onClose: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 120 {
                                onClose()
                            } else {
                                withAnimation(.spring()) { dragOffset = 0 }
                            }
                        }
                )
                .onTapGesture { onClose() }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }
            .padding(.top, 8)
            .padding(.trailing, 16)

            VStack {
                Spacer()
                Text("Kapatmak için dokunun veya aşağı kaydırın")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 24)
            }
        }
        .statusBarHidden()
    }
}
