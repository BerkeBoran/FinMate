//
//  CategoryView.swift
//  FinMate
//
//  Created by Berke Boran on 11.10.2025.
//

import SwiftUI
struct CategoryView: View {
    @ObservedObject var viewModel: TransactionViewModel
    let categories = ["Yemek", "Ulaşım", "Faturalar", "Market Alışverişi", "Eğlence","Giyim", "Diğer"]

    var body: some View {
        List(categories, id: \.self) { category in
                    NavigationLink(destination: CategorySelectedView(viewModel: viewModel, category: category)) {
                        Text(category)
                    }
                }
                .navigationTitle("Kategoriler")   }
}
#Preview {
CategoryView(viewModel: TransactionViewModel())}
