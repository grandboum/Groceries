//
//  AbstractTypes.swift
//  Groceries
//
//  Created by Illia Akhaiev on 3/4/18.
//  Copyright © 2018 Illia Akhaiev. All rights reserved.
//

import UIKit
import FMDB

// MARK: -- Clerk

struct Interests: OptionSet {
    let rawValue: Int

    static let groceries = Interests(rawValue: 1 << 0)
    static let products = Interests(rawValue: 1 << 1)
}

enum ChangeType: String {
    case groceries = "update.groceries"
    case products = "create.product"
}

protocol ModelConsumer: class {
    func consume(_ model: [Any], change: ChangeType)
    func interests() -> Interests
}

protocol MortalModelConsumer: ModelConsumer {
    func injectMortician(_ mortician: Mortician)
}

protocol Clerk {
    func subscribe(_ consumer: ModelConsumer, for inerests: Interests)
    func notify(about interests: Interests)
}

protocol Mortician: class {
    func unsubscribe(_ consumer: ModelConsumer, for interests: Interests)
}

protocol CancellableClerk: Clerk, Mortician {
}

// MARK: -- Router

protocol RoutePleader {
    func injectRouter(_ presenter: Router)
}

protocol Router {
    init(withClerk: CancellableClerk, actor: Actor)

    func presentController(withId: String, pleader: UIViewController)

    func presentRootViewController(forWindow window: UIWindow)

    func presentProductSelectionScreen(pleader: UIViewController)
}

// MARK: -- Engine

protocol Engine {
    func executeFetchBlock(_ block: @escaping (FMDatabase) -> Void)
    func executeUpdateBlock(_ block: @escaping (FMDatabase) -> Void)
}

// MARK: -- Actor

protocol Actor {
    func createProduct(name: String)
    func purchaseProduct(product: Product)
    func enqueue(product: Product)
    func dequeue(product: Product)
}

protocol ActionPleader {
    func injectActor(_ actor: Actor)
}
