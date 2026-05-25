//
//  CategoryView.swift
//  FinMate
//
//  Created by Berke Boran on 11.10.2025.
//

import SwiftUI

struct CategoryView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        List {
            Section("Gider Kategorileri") {
                ForEach(ExpenseCategories.list, id: \.self) { category in
                    NavigationLink(destination: CategorySelectedView(viewModel: viewModel, category: category)) {
                        Text(category)
                    }
                }
            }
            Section("Gelir Kategorileri") {
                ForEach(IncomeCategories.list.filter { $0 != "Diğer" }, id: \.self) { category in
                    NavigationLink(destination: CategorySelectedView(viewModel: viewModel, category: category)) {
                        Text(category)
                    }
                }
            }
        }
        .navigationTitle("Kategoriler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CategoryView(viewModel: TransactionViewModel())
}
