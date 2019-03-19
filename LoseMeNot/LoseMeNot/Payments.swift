//
//  Payments.swift
//  LoseMeNot
//
//  Created by Horseman on 21/02/2019.
//  Copyright © 2019 ITSln. All rights reserved.
//

import Foundation
import StoreKit

public struct LmnProducts {
        public static let LmnSub = "ru.sors.lmn" // product ID встроенной покупки "Monthly payment"
        private static let productIDs: Set<String> = [LmnProducts.LmnSub]
        public static let store = Payments(products: LmnProducts.productIDs)
}

public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void
public typealias ProductPurchaseCompletionHandler = (_ success: Bool, _ productId: String?) -> Void

public class Payments: NSObject  {
    private let products: Set<String>
    private var purchasedProducts: Set<String>
    private var request: SKProductsRequest?
    private var requestHandler: ProductsRequestCompletionHandler?
    private var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
    
    private var MonthlyProduct: SKProduct! // месячная подписка - по идее она одна
    
    public init(products: Set<String>) {
        self.products = products
        self.purchasedProducts = products.filter { productID in
            let purchased = UserDefaults.standard.bool(forKey: productID)
            if purchased {
                print("Already purchased: \(productID)")
            } else {
                print("Not purchased: \(productID)")
            }
            return purchased
        }
        super.init()
        SKPaymentQueue.default().add(self)
    }
}

// MARK: - StoreKit API
extension Payments {

    public func load(_ completion: @escaping (_ success: Bool) -> Void) {
        requestProducts { [weak self] success, list in
            guard success, let self = self, let prods = list, prods.count > 0 else {
                completion(false)
                return
            }
            
            self.MonthlyProduct = prods[0] // считаем, что у нас только одна подписка
            completion(true)
        }
    }
    
    public func checkMonthly() -> Bool {
        return purchasedProducts.contains(LmnProducts.LmnSub)
    }
    
    public func buy(_ completion: @escaping (_ success: Bool) -> Void) {
        guard let product = MonthlyProduct else {
            completion(false)
            return
        }
        buyProduct(product) { success, _ in completion(success)}
    }
    
    private func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        request?.cancel()
        requestHandler = completionHandler

        request = SKProductsRequest(productIdentifiers: products)
        request!.delegate = self
        request!.start()
    }

    private func buyProduct(_ product: SKProduct, _ completionHandler: @escaping ProductPurchaseCompletionHandler) {
        productPurchaseCompletionHandler = completionHandler
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
//
//    public func isProductPurchased(_ productID: String) -> Bool {
//        return purchasedProducts.contains(productID)
//    }
//
//    public class func canMakePayments() -> Bool {
//        return SKPaymentQueue.canMakePayments()
//    }
//
//    public func restorePurchases() {
//        SKPaymentQueue.default().restoreCompletedTransactions()
//    }
}

// MARK: - SKProductsRequestDelegate
extension Payments: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        guard !products.isEmpty else {
            print("Product list is empty...!")
            print("Did you configure the project and set up the IAP?")
            requestHandler?(false, nil)
            return
        }
        requestHandler?(true, products)
        clearRequestAndHandler()
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        requestHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        request = nil
        requestHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension Payments: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("Payment complete.")
        productPurchaseCompleted(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        print("Payment restore - \(productIdentifier)")
        productPurchaseCompleted(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("Payment fail!")
        if let transactionError = transaction.error as NSError?,
            let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
            print("Error: \(localizedDescription)")
        }

        productPurchaseCompletionHandler?(false, nil)
        SKPaymentQueue.default().finishTransaction(transaction)
        clearHandler()
    }

    private func productPurchaseCompleted(identifier: String?) {
        guard let identifier = identifier else { return }

        purchasedProducts.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        productPurchaseCompletionHandler?(true, identifier)
        clearHandler()
    }

    private func clearHandler() {
        productPurchaseCompletionHandler = nil
    }
}
