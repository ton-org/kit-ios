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
import TONWalletKit

struct WalletHomeView: View {
    @ObservedObject var walletsList: WalletsListViewModel
    @StateObject private var viewModel: WalletHomeViewModel

    @State private var navigationPath = NavigationPath()
    @State private var addWalletPath = NavigationPath()
    @State private var isWalletsSheetPresented = false
    @State private var isAddWalletPresented = false
    @State private var isScannerPresented = false
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
                VStack(spacing: 8) {
                    balanceBlock

                    WalletHomeActionsRow(
                        onSend: openSend,
                        onSwap: openSwap,
                        onStake: openStaking
                    )
                    // Sections sit 8 apart; keep a larger gap above the action row.
                    .padding(.top, 16)

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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isScannerPresented = true
                    } label: {
                        TONIcon.iconScan.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .size(24)
                            .foregroundStyle(Color.tonTextPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    WalletHomeHeaderView(
                        title: viewModel.title,
                        onTap: { isWalletsSheetPresented = true }
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationPath.append(HomePath.investigation(viewModel.wallet))
                    } label: {
                        TONIcon.iconSettings.image
                            .renderingMode(.template)
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
                case .swap(let viewModel):
                    SwapView(viewModel: viewModel)
                case .staking(let viewModel):
                    StakingView(viewModel: viewModel)
                case .allAssets(let walletViewModel):
                    allAssetsScreen(for: walletViewModel)
                case .allNFTs(let walletViewModel):
                    allNFTsScreen(for: walletViewModel)
                case .investigation(let walletViewModel):
                    WalletKitInvestigationView(wallet: walletViewModel)
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
            NavigationStack(path: $addWalletPath) {
                WalletWelcomeView(
                    onCreateNew: { addWalletPath.append(AddWalletPath.createNew) },
                    onAddExisting: { addWalletPath.append(AddWalletPath.importExisting) }
                )
                .navigationDestination(for: AddWalletPath.self) { path in
                    switch path {
                    case .createNew:
                        CreateWalletView { newWallet in
                            walletsList.add(wallets: [newWallet])
                            if let added = walletsList.wallets.last {
                                walletsList.selectActive(wallet: added)
                            }
                            isAddWalletPresented = false
                        }
                    case .importExisting:
                        AddWalletView { newWallet in
                            walletsList.add(wallets: [newWallet])
                            if let added = walletsList.wallets.last {
                                walletsList.selectActive(wallet: added)
                            }
                            isAddWalletPresented = false
                        }
                    }
                }
            }
            .onDisappear { addWalletPath = NavigationPath() }
        }
        .sheet(item: $nftDetailsViewModel) { details in
            WalletNFTDetailsView(viewModel: details)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isScannerPresented) {
            QRScannerView(
                onScanned: { payload in
                    isScannerPresented = false
                    handleScanned(payload)
                },
                onClose: { isScannerPresented = false }
            )
        }
        .onReceive(walletsList.event) { event in
            handleWalletsEvent(event)
        }
    }

    private var balanceBlock: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(viewModel.totalBalanceInteger)
                    .textStyle(.price50)
                    .foregroundStyle(Color.tonTextPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.totalBalanceInteger)
                if !viewModel.totalBalanceFraction.isEmpty {
                    Text(".")
                        .textStyle(.price40)
                        .foregroundStyle(Color.tonTextSecondary)
                    Text(balanceFractionDigits)
                        .textStyle(.price30)
                        .foregroundStyle(Color.tonTextSecondary)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: balanceFractionDigits)
                }
                Text(" GRAM")
                    .textStyle(.price30)
                    .foregroundStyle(Color.tonTextSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            WalletAddressPill(address: viewModel.wallet.address)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// Fractional digits without the leading dot — `totalBalanceFraction` is like ".47" and the
    /// dot is rendered separately at its own size.
    private var balanceFractionDigits: String {
        String(viewModel.totalBalanceFraction.dropFirst())
    }

    private var assetsSection: some View {
        VStack(spacing: 16) {
            sectionHeader(
                title: "Assets",
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
        .sectionCard()
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
                // Cancel the section card's 16 padding so the scroll view spans the full card
                // width; the 16 left/right inset now lives inside the scroll content.
                .padding(.horizontal, -16)
            }
        }
        .sectionCard()
    }

    private func sectionHeader(title: String, showAll: Bool, onShowAll: @escaping () -> Void) -> some View {
        HStack {
            Button(action: onShowAll) {
                HStack(spacing: 4) {
                    Text(title)
                        .textStyle(.calloutMedium)
                        .foregroundStyle(Color.tonTextPrimary)
                    if showAll {
                        TONIcon.chevronForwardSmall.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .size(20)
                            .foregroundStyle(Color.tonTextTertiary)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!showAll)

            Spacer()
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

    private func openSwap() {
        navigationPath.append(HomePath.swap(viewModel.wallet.swapViewModel()))
    }

    private func openStaking() {
        navigationPath.append(HomePath.staking(viewModel.wallet.stakingViewModel()))
    }

    // MARK: - QR scanning

    /// Forwards a scanned payload to the kit's TON Connect handler, but only when it actually
    /// looks like a URL (a scheme, or a recognizable TON Connect deep link). Anything else is ignored.
    private func handleScanned(_ payload: String) {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isConnectURL(trimmed) else { return }

        Task {
            do {
                try await TONWalletKit.shared().connect(url: trimmed)
            } catch {
                debugPrint("Failed to handle scanned connect URL: \(error)")
            }
        }
    }

    private static func isConnectURL(_ string: String) -> Bool {
        guard !string.isEmpty, let components = URLComponents(string: string) else { return false }
        if components.scheme != nil { return true }
        // Bare TON Connect payloads have no scheme; `connect(url:)` prepends `tc` for them.
        let lowered = string.lowercased()
        return lowered.contains("tonconnect") || lowered.hasPrefix("tc?") || lowered.hasPrefix("tc/")
    }

    private func handleWalletsEvent(_ event: WalletsListViewModel.Event) {
        if let transactionRequest = event.transactionRequest {
            presentEvent(.transactionRequest(transactionRequest))
        } else if let signMessageRequest = event.signMessageRequest {
            presentEvent(.signMessageRequest(signMessageRequest))
        } else if let signDataRequest = event.signDataRequest {
            presentEvent(.signDataRequest(signDataRequest))
        } else if let connectRequest = event.connectionRequest {
            presentEvent(.connectRequest(connectRequest))
        }
    }

    private func presentEvent(_ event: TONWalletKitEvent) {
        switch event {
        case .transactionRequest(let request):
            present(
                WalletTransactionRequestView(viewModel: .init(request: request))
                    .presentationDragIndicator(.visible)
            )
        case .signMessageRequest(let request):
            present(
                WalletSignMessageRequestView(viewModel: .init(request: request))
                    .presentationDragIndicator(.visible)
            )
        case .signDataRequest(let request):
            present(
                WalletSignDataRequestView(viewModel: .init(request: request))
                    .presentationDragIndicator(.visible)
            )
        case .connectRequest(let request):
            present(
                WalletConnectionRequestView(
                    viewModel: .init(
                        request: request,
                        wallets: walletsList.wallets.map { $0.tonWallet }
                    ),
                    onNextEvent: { followUp in presentEvent(followUp) }
                )
                .presentationDragIndicator(.visible)
            )
        default: ()
        }
    }

    private func present<Content: View>(_ view: Content) {
        let controller = UIHostingController(rootView: view)
        Self.presentDeferringDismissal(controller)
    }

    private static func presentDeferringDismissal(_ controller: UIViewController) {
        guard let presenter = UIApplication.shared.topViewController() else { return }

        // If another sheet (e.g. the connection request that just produced a
        // follow-up event) is mid-dismissal, wait for that transition to
        // finish before presenting — UIKit refuses simultaneous transitions.
        if let dismissing = presenter.presentedViewController, dismissing.isBeingDismissed {
            if let coordinator = dismissing.transitionCoordinator {
                coordinator.animate(alongsideTransition: nil) { _ in
                    presentDeferringDismissal(controller)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    presentDeferringDismissal(controller)
                }
            }
            return
        }

        presenter.present(controller, animated: true)
    }
}

// MARK: - Address pill

/// Truncated wallet address shown under the balance. Tapping copies the full address to the
/// clipboard and briefly confirms with a "Copied" label.
private struct WalletAddressPill: View {
    let address: String

    @State private var didCopy = false

    var body: some View {
        Button(action: copy) {
            HStack(spacing: 6) {
                TONIcon.ton.image
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .size(16)

                Text(didCopy ? "Copied" : Self.short(address))
                    .textStyle(.subheadline2)
                    .foregroundStyle(Color.tonTextSecondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func copy() {
        UIPasteboard.general.string = address
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { didCopy = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { didCopy = false }
        }
    }

    private static func short(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))…\(address.suffix(6))"
    }
}

// MARK: - Section card

private extension View {
    /// Wraps a home section (Assets / NFTs) in a "background level 2" card:
    /// 16 padding, 24pt continuous corners.
    func sectionCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.tonBgSecondary)
            )
    }
}

private enum HomePath: Hashable {
    case send(SendTokensViewModel)
    case swap(SwapViewModel)
    case staking(StakingViewModel)
    case allAssets(WalletViewModel)
    case allNFTs(WalletViewModel)
    case investigation(WalletViewModel)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .send(let vm): hasher.combine("send"); hasher.combine(ObjectIdentifier(vm))
        case .swap(let vm): hasher.combine("swap"); hasher.combine(ObjectIdentifier(vm))
        case .staking(let vm): hasher.combine("staking"); hasher.combine(ObjectIdentifier(vm))
        case .allAssets(let vm): hasher.combine("allAssets"); hasher.combine(vm.id)
        case .allNFTs(let vm): hasher.combine("allNFTs"); hasher.combine(vm.id)
        case .investigation(let vm): hasher.combine("investigation"); hasher.combine(vm.id)
        }
    }

    static func == (lhs: HomePath, rhs: HomePath) -> Bool {
        switch (lhs, rhs) {
        case (.send(let l), .send(let r)): return l === r
        case (.swap(let l), .swap(let r)): return l === r
        case (.staking(let l), .staking(let r)): return l === r
        case (.allAssets(let l), .allAssets(let r)): return l.id == r.id
        case (.allNFTs(let l), .allNFTs(let r)): return l.id == r.id
        case (.investigation(let l), .investigation(let r)): return l.id == r.id
        default: return false
        }
    }
}
