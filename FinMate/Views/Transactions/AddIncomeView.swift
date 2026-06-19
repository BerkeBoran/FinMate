
import SwiftUI

struct AddIncomeView: View {
    @ObservedObject var viewModel: TransactionViewModel

    @State private var selectedCategory: String = IncomeCategories.list.first ?? "Diğer"
    @State private var customTitle: String = ""
    @State private var amount: String = ""

    private var isOther: Bool { selectedCategory == "Diğer" }

    var body: some View {
        VStack(spacing: 20) {
            Text("Güncel Bakiye: \(viewModel.balance, specifier: "%.2f") TL")
                .font(.title2)
                .bold()
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 15) {
                Text("Kategori")
                    .font(.headline)
                Picker("Kategori", selection: $selectedCategory) {
                    ForEach(IncomeCategories.list, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                if isOther {
                    Text("Başlık")
                        .font(.headline)
                    TextField("Örn: Borç İadesi", text: $customTitle)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                }

                Text("Tutar")
                    .font(.headline)
                TextField("Örn: 1000", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: addIncome) {
                Text("Gelir Ekle")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canSubmit ? Color.green : Color.green.opacity(0.4))
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
            .disabled(!canSubmit)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Gelir Ekle")
    }

    private var canSubmit: Bool {
        guard Double(amount.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        if isOther { return !customTitle.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }

    private func addIncome() {
        guard let amt = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }
        let title = isOther ? customTitle.trimmingCharacters(in: .whitespaces) : selectedCategory
        viewModel.addTransaction(title: title, amount: amt, type: .income, category: selectedCategory)
        customTitle = ""
        amount = ""
    }
}

enum IncomeCategories {
    static let list: [String] = [
        "Maaş",
        "Ek Gelir",
        "Yatırım Geliri",
        "Kira Geliri",
        "Faiz Geliri",
        "Hediye",
        "Diğer"
    ]
}

#Preview {
    AddIncomeView(viewModel: TransactionViewModel())
}
