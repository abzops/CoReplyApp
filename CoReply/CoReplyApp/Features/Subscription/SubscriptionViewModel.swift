// SubscriptionViewModel.swift
// CoReply
//
// View model connecting billing interface properties with StoreKit manager.

import SwiftUI
import StoreKit
import Combine

@MainActor
public final class SubscriptionViewModel: ObservableObject {
    @Published public var products: [Product] = []
    @Published public var currentTier: SubscriptionTier = .free
    @Published public var isPurchasing = false
    @Published public var isRestoring = false
    @Published public var purchaseError: String? = nil
    @Published public var purchaseSuccess = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        let service = SubscriptionService.shared
        
        service.$products
            .assign(to: &$products)
        service.$subscriptionTier
            .assign(to: &$currentTier)
        service.$isPurchasing
            .assign(to: &$isPurchasing)
        service.$isRestoring
            .assign(to: &$isRestoring)
        service.$purchaseError
            .assign(to: &$purchaseError)
        service.$purchaseSuccess
            .assign(to: &$purchaseSuccess)
            
        Task {
            await service.loadProducts()
        }
    }
    
    public func purchase(_ product: Product) async {
        await SubscriptionService.shared.purchase(product)
    }
    
    public func restorePurchases() async {
        await SubscriptionService.shared.restorePurchases()
    }
    
    public func priceString(for product: Product) -> String {
        return product.displayPrice
    }
    
    public func formattedSavingsForAnnual() -> String {
        // Mock estimate or math comparing to monthly products
        return "Save 40%"
    }
}
