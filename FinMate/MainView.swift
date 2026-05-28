import SwiftUI

struct MainView: View {
    @StateObject var viewModel = TransactionViewModel()
    @Environment(PriceStore.self) private var priceStore
    @State private var showMenu = false
    @State private var path = NavigationPath()
    @AppStorage(SettingsKeys.hideBalance) private var hideBalance: Bool = false
    @AppStorage(SettingsKeys.currencySymbol) private var currencySymbol: String = "₺"
    @AppStorage(SettingsKeys.decimalPlaces) private var decimalPlaces: Int = 2
    @AppStorage(SettingsKeys.userName) private var userName: String = "Kullanıcı"
    @AppStorage(SettingsKeys.lastName) private var lastName: String = ""
    @AppStorage(SettingsKeys.userIcon) private var userIcon: String = "person.crop.circle.fill"
    let menuItems: [String] = ["Harcamalar", "Gelirler", "Kategoriler", "Raporlar", "Ödeme Takvimi", "Yatırımlarım", "Fiş Okut", "Fişlerim", "Ayarlar"]
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            Color.midnightBackground.ignoresSafeArea()
            
            if !showMenu {
                NavigationStack(path: $path) {
                    ScrollView {
                        VStack(spacing: 25) {
                            
                            // Header & Balance
                            VStack(spacing: 10) {
                                HStack {
                                    Button(action: { withAnimation { self.showMenu.toggle() } }) {
                                        Image(systemName: "line.horizontal.3")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    Spacer()
                                    Text("FinMate")
                                        .font(.headline)
                                        .tracking(2)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    // Placeholder for balance visuals
                                    Circle().fill(Color.clear).frame(width: 44)
                                }
                                .padding(.horizontal)
                                
                                Text("GÜNCEL BAKİYE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                
                                Group {
                                    if hideBalance {
                                        Text("•••••• \(currencySymbol)")
                                    } else {
                                        Text("\(formattedBalance) \(currencySymbol)")
                                    }
                                }
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .neonBlue.opacity(0.5), radius: 10, x: 0, y: 0)
                                .contentTransition(.opacity)
                                .animation(.easeInOut, value: hideBalance)
                            }
                            .padding(.top, 20)

                            // Actions
                            HStack(spacing: 15) {
                                NavigationLink(destination: AddIncomeView(viewModel: viewModel)) {
                                    HStack {
                                        Image(systemName: "arrow.down.left")
                                        Text("Gelir")
                                    }
                                    .neonButton(color: .neonGreen)
                                }
                                
                                NavigationLink(destination: AddExpenseView(viewModel: viewModel)) {
                                    HStack {
                                        Image(systemName: "arrow.up.right")
                                        Text("Gider")
                                    }
                                    .neonButton(color: .neonRed)
                                }
                            }
                            .padding(.horizontal)

                            // Son Hareketler (line chart, gelir/gider)
                            VStack(alignment: .leading) {
                                Text("Son Hareketler")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                BarChartView(viewModel: viewModel)
                                    .padding(.vertical)
                                    .glassCard()
                                    .padding(.horizontal)
                            }

                            // Varlıklar (line chart + nakit/yatırım/toplam mini kartlar)
                            VStack(alignment: .leading) {
                                Text("Varlıklarım")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                AssetsChartView(viewModel: viewModel)
                                    .padding(.vertical)
                                    .glassCard()
                                    .padding(.horizontal)
                            }

                            // Hızlı Erişim — pusula düzeni
                            VStack(alignment: .leading) {
                                Text("Hızlı Erişim")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)

                                QuickAccessCompass(path: $path)
                                    .padding(.horizontal)
                            }
                            
                            Spacer().frame(height: 50)
                        }
                    }
                    .midnightTheme()
                    .navigationDestination(for: String.self) { item in
                        switch item {
                        case "Harcamalar": ExpensesView(viewModel: viewModel)
                        case "Gelirler": IncomeView(viewModel: viewModel)
                        case "Raporlar": ReportsView(viewModel: viewModel)
                        case "Kategoriler": CategoryView(viewModel: viewModel)
                        case "Ödeme Takvimi": PaymentScheduleView()
                        case "Yatırımlarım": InvestmentsView()
                        case "Fiş Okut": ScanReceiptView(transactionVM: viewModel)
                        case "Fişlerim": ReceiptsView(viewModel: viewModel)
                        case "Ayarlar": SettingsView(viewModel: viewModel)
                        default: EmptyView()
                        }
                    }
                }
            } else {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .onTapGesture { withAnimation { showMenu = false } }
                
                MenuView(path: $path, showMenu: $showMenu, menuItems: menuItems, userName: fullName, userIcon: userIcon)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }

    private var fullName: String {
        let combined = "\(userName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Kullanıcı" : combined
    }

    private var formattedBalance: String {
        let converted = priceStore.convertFromTRY(viewModel.balance, toSymbol: currencySymbol)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: converted)) ?? String(format: "%.\(decimalPlaces)f", converted)
    }
}

// MARK: - Quick Access Compass

struct QuickAccessCompass: View {
    @Binding var path: NavigationPath

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 12) {
                QuickActionCard(title: "Gelirler", icon: "arrow.down.left", color: .neonGreen)
                    .onTapGesture { path.append("Gelirler") }
                QuickActionCard(title: "Yatırımlarım", icon: "chart.line.uptrend.xyaxis", color: .neonBlue)
                    .onTapGesture { path.append("Yatırımlarım") }
            }

            QuickActionCard(title: "Fiş Okut", icon: "camera.viewfinder", color: Color(red: 1.0, green: 0.65, blue: 0.2), isLarge: true)
                .onTapGesture { path.append("Fiş Okut") }

            VStack(spacing: 12) {
                QuickActionCard(title: "Harcamalar", icon: "arrow.up.right", color: .neonRed)
                    .onTapGesture { path.append("Harcamalar") }
                QuickActionCard(title: "Ödeme Takvimi", icon: "calendar", color: .neonPurple)
                    .onTapGesture { path.append("Ödeme Takvimi") }
            }
        }
        .padding(.bottom, 8)
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    var isLarge: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 38 : 26, weight: .semibold))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 8)
            Text(title)
                .font(isLarge ? .subheadline : .caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isLarge ? 184 : 86)
        .background(Color.white.opacity(0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(isLarge ? 0.5 : 0.25), lineWidth: 1)
        )
    }
}

struct MenuView: View {
    @Binding var path: NavigationPath
    @Binding var showMenu: Bool
    let menuItems: [String]
    let userName: String
    let userIcon: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                // Menu Header
                HStack {
                    Image(systemName: userIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.neonBlue)
                    VStack(alignment: .leading) {
                        Text("Merhaba")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(userName)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                .padding(25)
                .padding(.top, 40)
                
                Divider().background(Color.white.opacity(0.2))

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(menuItems, id: \.self) { item in
                            Button(action: {
                                withAnimation { showMenu = false }
                                path.append(item)
                            }) {
                                HStack(spacing: 15) {
                                    Image(systemName: iconFor(item))
                                        .frame(width: 24)
                                        .foregroundColor(.neonBlue)
                                    Text(item)
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.9))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: { withAnimation { showMenu = false } }) {
                    HStack {
                        Image(systemName: "arrow.left.circle")
                        Text("Kapat")
                    }
                    .foregroundColor(.gray)
                    .padding()
                }
            }
            .frame(width: 280)
            .background(Color.surface)
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil, alignment: .trailing)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .trailing
            )
            
            Spacer()
        }
    }
    
    func iconFor(_ item: String) -> String {
        switch item {
        case "Harcamalar": return "creditcard"
        case "Gelirler": return "banknote"
        case "Kategoriler": return "folder"
        case "Raporlar": return "chart.pie"
        case "Ödeme Takvimi": return "calendar"
        case "Ayarlar": return "gearshape"
        case "Yatırımlarım": return "chart.line.uptrend.xyaxis"
        case "Fiş Okut": return "camera.viewfinder"
        case "Fişlerim": return "doc.text"
        default: return "circle"
        }
    }
}

#Preview {
    MainView()
}


