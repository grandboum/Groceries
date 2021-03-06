//
//  AppDelegate.swift
//  Groceries
//
//  Created by Illia Akhaiev on 3/6/17.
//  Copyright © 2017 Illia Akhaiev. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var brain: Brain!
    private var clerk: CancellableClerk!
    private var router: Router!
    private var actor: Actor!
    private var engine: Engine!
    private var cache: UpdatableCache!

    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        let path = Librarian.databasePath()
        engine = FMDBDatabaseEngine(with: path)
        cache = CacheImpl()
        brain = BrainImpl(withEngine: engine, cache: cache)
        clerk = ClerkImpl(withBrain: brain, cache: cache)
        actor = ActorImpl(withBrain: brain)
        router = iOSRouter(withClerk: clerk, actor: actor)

        router.presentRootViewController(forWindow: window!)
        window?.makeKeyAndVisible()

        return true
    }

    func applicationDidBecomeActive(_: UIApplication) {
        clerk.updateRecords()
    }
}
