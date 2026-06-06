// SubscriptionService.swift
// CoReply
//
// Manages App Store payments, product loading, and subscriptions via StoreKit 2.

import Foundation
import StoreKit

@MainActor
public final class SubscriptionService: ObservableObject {
    public static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    
    @Published public var products: [Product] = []
    @Published public var subscriptionTier: SubscriptionTier = .free
    @Published public var isPurchasing = false
    @Published public var isRestoring = false
    @Published public var purchaseSuccess = false
    @Published public var purchaseError: String? = nil
    
    // MARK: - Properties
    
    private var transactionListener: Task<Void, Error>?
    
    private let productIDs = [
        AppConstants.Subscription.proProductID,
        AppConstants.Subscription.premiumProductID,
        AppConstants.Subscription.proAnnualProductID
    ]
    
    // MARK: - Init & Deinit
    
    private init() {
        // Start listening for asynchronous transactions from the App Store
        self.transactionListener = listenForTransactions()
        
        // Load stored subscription status
        self.subscriptionTier = AppGroupStorage.shared.subscriptionTier
        
        // Perform initial status check
        Task {
            await checkActiveSubscriptions()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Products
    
    public func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            // Sort by price
            self.products = storeProducts.sorted { $0.price < $1.price }
            print("[SubscriptionService] Loaded \(products.count) products from App Store.")
        } catch {
            print("[SubscriptionService] Failed to load StoreKit products: \(error.localizedDescription)")
            self.purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Purchase Product
    
    public func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        
        isPurchasing = true
        purchaseError = nil
        purchaseSuccess = false
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify transaction details
                let transaction = try checkVerified(verification)
                
                // Process the successful transaction
                await updateSubscriptionStatus(for: transaction)
                
                // Complete transaction with the App Store
                await transaction.finish()
                
                purchaseSuccess = true
                print("[SubscriptionService] Purchase successful for \(product.id)")
                
            case .userCancelled:
                print("[SubscriptionService] User cancelled purchase.")
                purchaseError = "Purchase was cancelled."
                
            case .pending:
                print("[SubscriptionService] Purchase pending (parental control/etc).")
                purchaseError = "Purchase is pending approval."
                
            @unknown default:
                break
            }
        } catch {
            print("[SubscriptionService] Purchase failed: \(error.localizedDescription)")
            purchaseError = error.localizedDescription
        }
        
        isPurchasing = false
    }
    
    // MARK: - Restore Purchases
    
    public func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        purchaseError = nil
        
        do {
            try await AppStore.sync()
            await checkActiveSubscriptions()
            print("[SubscriptionService] Restored purchases sync complete.")
        } catch {
            print("[SubscriptionService] Restore sync failed: \(error.localizedDescription)")
            purchaseError = "Failed to sync purchases: \(error.localizedDescription)"
        }
        
        isRestoring = false
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Subscription Checks
    
    public func checkActiveSubscriptions() async {
        var highestTier: SubscriptionTier = .free
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Entitlement is active if revocation date is nil
                guard transaction.revocationDate == nil else { continue }
                
                let tier = tier(for: transaction.productID)
                if tier == .premium {
                    highestTier = .premium
                } else if tier == .pro && highestTier != .premium {
                    highestTier = .pro
                }
            } catch {
                print("[SubscriptionService] Entitlement verification failed: \(error.localizedDescription)")
            }
        }
        
        setSubscriptionTier(highestTier)
    }
    
    private func updateSubscriptionStatus(for transaction: Transaction) async {
        let tier = tier(for: transaction.productID)
        setSubscriptionTier(tier)
    }
    
    private func setSubscriptionTier(_ tier: SubscriptionTier) {
        self.subscriptionTier = tier
        AppGroupStorage.shared.subscriptionTier = tier
        
        // Also log event
        Task {
            await SupabaseService.shared.trackEvent(name: "subscription_status_changed", metadata: ["tier": tier.rawValue])
        }
    }
    
    private func tier(for productID: String) -> SubscriptionTier {
        switch productID {
        case AppConstants.Subscription.premiumProductID:
            return .premium
        case AppConstants.Subscription.proProductID, AppConstants.Subscription.proAnnualProductID:
            return .pro
        default:
            return .free
        }
    }
    
    // MARK: - Async Listener Task
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update entitlement status on the main thread
                    await self.updateSubscriptionStatus(for: transaction)
                    
                    // Finish transaction
                    await transaction.finish()
                } catch {
                    print("[SubscriptionService] Failed to process incoming Transaction update: \(error.localizedDescription)")
                }
            }
        }
    }
}
