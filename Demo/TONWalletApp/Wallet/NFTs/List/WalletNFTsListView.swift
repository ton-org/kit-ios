//
//  WalletNFTsListView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 29.10.2025.
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

import Foundation
import SwiftUI

struct WalletNFTsListView: View {
    @StateObject var viewModel: WalletNFTsListViewModel
    
    var body: some View {
        VStack(spacing: 8.0) {
            Text("NFTs")
                .font(.headline)
            
            let minHeight = 150.0
            switch viewModel.state {
            case .initial, .loading:
                Spacer(minLength: minHeight)
            case .empty:
                Text("No NFTs found")
            case .nfts:
                LazyVStack(spacing: 8.0) {
                    ForEach(viewModel.nfts) { item in
                        WalletNFTsListItemView(nftItem: item) {
                            viewModel.remove(nft: $0)
                        }
                    }
                }
                
                if viewModel.canLoadMore {
                    Button("Load more") {
                        self.viewModel.loadMoreNFTs()
                    }
                    .buttonStyle(
                        TONLegacyButtonStyle(
                            type: .secondary,
                            isLoading: viewModel.isLoadingMore
                        )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .task { [weak viewModel] in
            await viewModel?.loadNFTs()
        }
    }
}
