//
//  WalletHomeView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 27.04.2026.
//
//  Copyright (c) 2026 TON Connect
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

struct WalletHomeView: View {
    @ObservedObject var walletsList: WalletsListViewModel
    @StateObject private var viewModel: WalletHomeViewModel

    @State private var navigationPath = NavigationPath()
    @State private var isWalletsSheetPresented = false
    @State private var isAddWalletPresented = false
    @State private var nftDetailsViewModel: WalletNFTDetailsViewModel?

    init(walletsList: WalletsListViewModel, activeWallet: WalletViewModel) {
        self.walletsList = walletsList
        _viewModel = StateObject(
            wrappedValue: WalletHomeViewModel(walletsList: walletsList, wallet: activeWallet)
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    balanceBlock

                    WalletHomeActionsRow(
                        onDeposit: {},
                        onSend: openSend,
                        onReceive: {}
                    )

                    assetsSection

                    nftsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.tonBgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    WalletHomeHeaderView(
                        title: viewModel.title,
                        networkLabel: "MainNet",
                        truncatedAddress: viewModel.truncatedAddress,
                        onTap: { isWalletsSheetPresented = true }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isWalletsSheetPresented = true
                    } label: {
                        TONIcon.settings24.image
                            .resizable()
                            .scaledToFit()
                            .size(24)
                            .foregroundStyle(Color.tonTextPrimary)
                    }
                }
            }
            .navigationDestination(for: HomePath.self) { path in
                switch path {
                case .send(let viewModel):
                    SendTokensView(viewModel: viewModel)
                case .allAssets(let walletViewModel):
                    allAssetsScreen(for: walletViewModel)
                case .allNFTs(let walletViewModel):
                    allNFTsScreen(for: walletViewModel)
                }
            }
        }
        .onAppear {
            walletsList.waitForEvents()
            viewModel.loadIfNeeded()
        }
        .onChange(of: walletsList.activeWallet?.id) { _ in
            if let active = walletsList.activeWallet {
                viewModel.bind(toActive: active)
                viewModel.loadIfNeeded()
            }
        }
        .sheet(isPresented: $isWalletsSheetPresented) {
            WalletsBottomSheetView(
                viewModel: walletsList,
                onClose: { isWalletsSheetPresented = false },
                onAddWallet: {
                    isWalletsSheetPresented = false
                    isAddWalletPresented = true
                },
                onDelete: { wallet in
                    wallet.remove()
                }
            )
            .automaticHeightPresentationDetents()
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isAddWalletPresented) {
            NavigationStack {
                AddWalletView { newWallet in
                    walletsList.add(wallets: [newWallet])
                    if let added = walletsList.wallets.last {
                        walletsList.selectActive(wallet: added)
                    }
                    isAddWalletPresented = false
                }
            }
        }
        .sheet(item: $nftDetailsViewModel) { details in
            WalletNFTDetailsView(viewModel: details)
                .presentationDragIndicator(.visible)
        }
        .onReceive(walletsList.event) { event in
            handleWalletsEvent(event)
        }
    }

    private var balanceBlock: some View {
        VStack(spacing: 4) {
            Text("Balance")
                .textStyle(.title3RoundedRegular)
                .foregroundStyle(Color.tonTextPrimary.opacity(0.6))
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(viewModel.totalBalanceInteger)
                    .textStyle(.price64)
                    .foregroundStyle(Color.tonTextPrimary)
                if !viewModel.totalBalanceFraction.isEmpty {
                    Text(viewModel.totalBalanceFraction)
                        .textStyle(.price40)
                        .foregroundStyle(Color.tonTextPrimary)
                }
                Text(" TON")
                    .textStyle(.price40)
                    .foregroundStyle(Color.tonTextPrimary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var assetsSection: some View {
        VStack(spacing: 16) {
            sectionHeader(
                title: "My assets",
                showAll: viewModel.hasMoreAssets,
                onShowAll: {
                    navigationPath.append(HomePath.allAssets(viewModel.wallet))
                }
            )

            VStack(spacing: 16) {
                ForEach(viewModel.assets) { asset in
                    WalletHomeAssetRowView(item: asset)
                }
            }
        }
    }

    private var nftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "NFTs",
                showAll: viewModel.hasMoreNFTs,
                onShowAll: {
                    navigationPath.append(HomePath.allNFTs(viewModel.wallet))
                }
            )

            if !viewModel.nftsPreview.isEmpty {
                WalletHomeNFTsCarousel(nfts: viewModel.nftsPreview) { nft in
                    nftDetailsViewModel = WalletNFTDetailsViewModel(
                        wallet: nft.wallet,
                        nft: nft.tonNFT,
                        onRemove: {}
                    )
                }
                .padding(.horizontal, -16)
                .padding(.leading, 16)
            }
        }
    }

    private func sectionHeader(title: String, showAll: Bool, onShowAll: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .textStyle(.title3Bold)
                .foregroundStyle(Color.tonTextPrimary)
            Spacer()
            if showAll {
                Button(action: onShowAll) {
                    Text("Show All")
                        .textStyle(.body)
                        .foregroundStyle(Color.tonTextBrand)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func allAssetsScreen(for walletViewModel: WalletViewModel) -> some View {
        ScrollView {
            WalletJettonsListView(viewModel: walletViewModel.jettonsViewModel)
                .padding(16)
        }
        .background(Color.tonBgSecondary)
        .navigationTitle("My assets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func allNFTsScreen(for walletViewModel: WalletViewModel) -> some View {
        ScrollView {
            WalletNFTsListView(viewModel: walletViewModel.nftsViewModel)
                .padding(16)
        }
        .background(Color.tonBgSecondary)
        .navigationTitle("NFTs")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openSend() {
        guard let send = viewModel.sendTokensViewModel() else { return }
        navigationPath.append(HomePath.send(send))
    }

    private func handleWalletsEvent(_ event: WalletsListViewModel.Event) {
        if let transactionRequest = event.transactionRequest {
            present(
                WalletTransactionRequestView(viewModel: .init(request: transactionRequest))
                    .presentationDragIndicator(.visible)
            )
        } else if let signDataRequest = event.signDataRequest {
            present(
                WalletSignDataRequestView(viewModel: .init(request: signDataRequest))
                    .presentationDragIndicator(.visible)
            )
        } else if let connectRequest = event.connectionRequest {
            present(
                WalletConnectionRequestView(
                    viewModel: .init(
                        request: connectRequest,
                        wallets: walletsList.wallets.map { $0.tonWallet }
                    )
                )
                .presentationDragIndicator(.visible)
            )
        }
    }

    private func present<Content: View>(_ view: Content) {
        let controller = UIHostingController(rootView: view)
        UIApplication.shared.topViewController()?.present(controller, animated: true)
    }
}

private enum HomePath: Hashable {
    case send(SendTokensViewModel)
    case allAssets(WalletViewModel)
    case allNFTs(WalletViewModel)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .send(let vm): hasher.combine("send"); hasher.combine(ObjectIdentifier(vm))
        case .allAssets(let vm): hasher.combine("allAssets"); hasher.combine(vm.id)
        case .allNFTs(let vm): hasher.combine("allNFTs"); hasher.combine(vm.id)
        }
    }

    static func == (lhs: HomePath, rhs: HomePath) -> Bool {
        switch (lhs, rhs) {
        case (.send(let l), .send(let r)): return l === r
        case (.allAssets(let l), .allAssets(let r)): return l.id == r.id
        case (.allNFTs(let l), .allNFTs(let r)): return l.id == r.id
        default: return false
        }
    }
}
