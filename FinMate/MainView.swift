import SwiftUI

struct MainView: View {
    @StateObject var viewModel = TransactionViewModel()
    @State private var showMenu=false
    @State private var path = NavigationPath()
    let menuItems: [String]=["Harcamalar", "Gelirler", "Kategoriler", "Raporlar", "Ayarlar"]
    
    
    var body: some View {
        ZStack(alignment: .leading){
            if !showMenu{
                NavigationStack(path: $path){
                    VStack(spacing: 30) {
                        Text("Güncel Bakiye: \(viewModel.balance, specifier: "%.2f") TL")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 40)
                            .navigationBarTitle("FinMate", displayMode: .inline)
                            .navigationBarItems(leading: Button(action: {
                                withAnimation {
                                    self.showMenu.toggle()
                                }
                            }) {
                                Image(systemName: "line.horizontal.3")
                                    .imageScale(.large)
                            })
                        HStack(spacing: 20) {
                            
                            NavigationLink(destination: AddIncomeView(viewModel: viewModel)) {
                                HStack{
                                    Image(systemName: "plus.circle")
                                    Text("Gelir Ekle")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                            
                            NavigationLink(destination: AddExpenseView(viewModel: viewModel)){
                                HStack{
                                    Image(systemName: "minus.circle")
                                    Text("Gider Ekle")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                        }
                        
                        
                        VStack(alignment: .leading) {
                            BarChartView(viewModel: viewModel)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(["Yemek","Ulaşım","Faturalar","Market","Kredi Kartı","Giyim","Eğlence","Kira","Diğer"], id: \.self) { category in
                                    VStack {
                                        Image(systemName: "folder.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.blue)
                                        Text(category)
                                            .font(.caption)
                                            .bold()
                                    }
                                    .frame(width: 80, height: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        
                        Spacer()
                    }
                    .navigationDestination(for: String.self) { item in
                        switch item {
                        case "Harcamalar":
                            ExpensesView(viewModel: viewModel)
                        case "Gelirler":
                            IncomeView(viewModel: viewModel)
                        case "Raporlar":
                            ReportsView(viewModel: viewModel)
                        case "Kategoriler":
                            CategoryView(viewModel: viewModel)
                        default:
                            EmptyView()
                        }
                    }
                    
                }
                
            }
            
            else  {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showMenu = false
                        }
                    }
                
                MenuView(path: $path,showMenu: $showMenu,menuItems: menuItems)
                    .frame(width: 250,height: .leastNonzeroMagnitude )
                    .background(Color.white)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        
    }
}
struct MenuView: View {
    @Binding var path: NavigationPath
    @ObservedObject var viewModel = TransactionViewModel()
    @Binding var showMenu: Bool
    let menuItems: [String]
    var body: some View {
        VStack(spacing:20){
            ForEach(menuItems, id: \.self) { item in
                Button(action: {
                    withAnimation {
                        showMenu = false
                    }
                    path.append(item)
                }) {
                    Text(item)
                        .foregroundColor(.black)
                        .padding(.vertical, 25)
                        .padding(.horizontal)
                }
            }
            Spacer()
            Button("Kapat") {
                withAnimation {
                    showMenu = false
                }
            }
            .padding()
        }
        
    }
    
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

