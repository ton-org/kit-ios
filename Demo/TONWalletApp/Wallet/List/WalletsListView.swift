//
//  WalletsListView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 09.10.2025.
//
//  Copyright (c) 2025 TON Connect
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SwiftUI

struct WalletsListView: View {
    @State private(set) var navigationPath = NavigationPath()
    @ObservedObject var viewModel: WalletsListViewModel
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.wallets) { wallet in
                            WalletRowView(
                                walletViewModel: wallet,
                                walletInfoViewModel: wallet.info
                            )
                            .widget()
                            .contentShape(.rect)
                            .onTapGesture {
                                navigationPath.append(Paths.wallet(viewModel: wallet))
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button("Add Wallet") {
                    navigationPath.append(Paths.addWallet)
                }
                .buttonStyle(TONLegacyButtonStyle(type: .primary))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(AppSpacing.spacing(4.0))
            .background(Color.TON.gray100)
            .navigationTitle("TON Wallets")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.waitForEvents()
            }
            .navigationDestination(for: Paths.self) { value in
                switch value {
                case .wallet(let viewModel):
                    WalletView(viewModel: viewModel) {
                        navigationPath.append(Paths.send(viewModel: $0))
                    } onSwap: {
                        navigationPath.append(Paths.swap(viewModel: $0))
                    } onStaking: {
                        navigationPath.append(Paths.staking(viewModel: $0))
                    }
                case .addWallet:
                    AddWalletView() {
                        viewModel.add(wallets: [$0])
                        navigationPath.removeLast()
                    }
                case .send(let viewModel):
                    SendTokensView(viewModel: viewModel)
                case .swap(let viewModel):
                    SwapView(viewModel: viewModel)
                case .staking(let viewModel):
                    StakingView(viewModel: viewModel)
                case .browser:
                    if let walletKit = viewModel.kit {
                        WebView(walletKit: walletKit, url: URL(string: "https://tonconnect-sdk-demo-dapp.vercel.app/iframe/iframe")!)
                            .ignoresSafeArea()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: {
                            navigationPath.append(Paths.browser)
                        },
                        label: {
                            Image(systemName: "safari")
                        }
                    )
                }
            }
        }
        .onReceive(viewModel.event) { event in
            if let transactionRequest = event.transactionRequest {
                let controller = UIHostingController(
                    rootView: WalletTransactionRequestView(viewModel: .init(request: transactionRequest))
                        .presentationDragIndicator(.visible)
                )
                UIApplication.shared.topViewController()?.present(
                    controller,
                    animated: true,
                    completion: nil
                )
            } else if let signDataRequest = event.signDataRequest {
                let controller = UIHostingController(
                    rootView: WalletSignDataRequestView(viewModel: .init(request: signDataRequest))
                        .presentationDragIndicator(.visible)
                )
                
                UIApplication.shared.topViewController()?.present(
                    controller,
                    animated: true,
                    completion: nil
                )
            } else if let connectRequest = event.connectionRequest {
                let controller = UIHostingController(
                    rootView: WalletConnectionRequestView(
                        viewModel: .init(
                            request: connectRequest,
                            wallets: viewModel.wallets.map { $0.tonWallet}
                        )
                    )
                    .presentationDragIndicator(.visible)
                )
                UIApplication.shared.topViewController()?.present(
                    controller,
                    animated: true,
                    completion: nil
                )
            }
        }
    }
}

private enum Paths: Hashable {
    case wallet(viewModel: WalletViewModel)
    case addWallet
    case browser
    case send(viewModel: SendTokensViewModel)
    case swap(viewModel: SwapViewModel)
    case staking(viewModel: StakingViewModel)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .wallet(let viewModel):
            hasher.combine(viewModel.id)
        case .addWallet:
            hasher.combine("addWallet")
        case .browser:
            hasher.combine("browser")
        case .send:
            hasher.combine("send")
        case .swap:
            hasher.combine("swap")
        case .staking:
            hasher.combine("staking")
        }
    }

    static func == (lhs: Paths, rhs: Paths) -> Bool {
        switch (lhs, rhs) {
        case (.wallet(let lhsViewModel), .wallet(let rhsViewModel)):
            return lhsViewModel.id == rhsViewModel.id
        case (.addWallet, .addWallet):
            return true
        default:
            return false
        }
    }
}

private struct WalletRowView: View {
    @ObservedObject var walletViewModel: WalletViewModel
    @ObservedObject var walletInfoViewModel: WalletInfoViewModel
    
    @State private var balance: String = "Loading balance..."
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "wallet.pass.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // Address
                Text(walletInfoViewModel.address)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if let balance = walletInfoViewModel.formattedBalance {
                    Text("\(balance) TON")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                walletViewModel.remove()
            }) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
        .frame(minHeight: 60.0)
        .task {
            await walletInfoViewModel.load()
        }
    }
}
