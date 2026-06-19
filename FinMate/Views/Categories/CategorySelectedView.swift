
import SwiftUI

struct CategorySelectedView: View {
    @ObservedObject var viewModel: TransactionViewModel
    var category: String

    @State private var period: Calendar.Component = .day
    @State private var selectedDate = Date()
    @State private var previewImagePath: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(category) Kayıtları")
                .font(.largeTitle)
                .bold()
                .padding()

            Picker("Tarih", selection: $period) {
                Text("Gün").tag(Calendar.Component.day)
                Text("Ay").tag(Calendar.Component.month)
                Text("Yıl").tag(Calendar.Component.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            DatePicker("Gün Seçin", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .padding(.horizontal)

            let total = viewModel.totalAmount(for: category, period: period, referenceDate: selectedDate)
            Text("Toplam: \(total, specifier: "%.2f")")
                .font(.title2)
                .padding()

            List(viewModel.transactions(for: category)) { tx in
                HStack {
                    Image(systemName: tx.type == TransactionType.income.rawValue ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                        .foregroundColor(tx.type == TransactionType.income.rawValue ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.title ?? "Başlık Yok")
                        Text(tx.date ?? Date(), style: .date)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    Spacer()
                    if let path = tx.receiptImagePath {
                        Button {
                            previewImagePath = path
                        } label: {
                            Image(systemName: "doc.text.image")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("\(tx.type == TransactionType.income.rawValue ? "+" : "-")\(tx.amount, specifier: "%.2f") TL")
                        .foregroundColor(tx.type == TransactionType.income.rawValue ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.midnightBackground.ignoresSafeArea())
        .navigationTitle(category)
        .sheet(item: Binding(
            get: { previewImagePath.map { ImagePath(path: $0) } },
            set: { _ in previewImagePath = nil }
        )) { wrapper in
            ReceiptImageSheet(filename: wrapper.path)
        }
    }
}

private struct ImagePath: Identifiable {
    let id = UUID()
    let path: String
}

private struct ReceiptImageSheet: View {
    let filename: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if let image = ReceiptStorage.load(filename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    
                        .padding()
                } else {
                    Text("Fiş bulunamadı")
                        .foregroundColor(.secondary)
                        .padding(40)
                }
            }
            .navigationTitle("Fiş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
