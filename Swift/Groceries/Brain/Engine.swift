//
//  Engine.swift
//  Groceries
//
//  Responsible for loading/updating data from db. That's all.
//
//  Created by Illia Akhaiev on 11/21/17.
//  Copyright © 2017 Illia Akhaiev. All rights reserved.
//

import FMDB
import Foundation

enum DatabaseAction: String {
    case testGroceriesFetch = """
    SELECT
        Groceries.Name,
        Groceries.uid,
        1 AS Enqueued
    FROM GroceriesLists
    INNER JOIN Groceries
        ON GroceriesLists.ProductID=Groceries.uid
        WHERE GroceriesLists.ListID=1
        ORDER BY GroceriesLists.Position
    """
    case testDelete = "DELETE FROM GroceriesLists WHERE ListID=1 AND ProductId = ?"
    case testInsert = "INSERT INTO Groceries (Name) VALUES (?)"
    case testProductsFetch = """
    SELECT
        Name,
        uid,
        CASE WHEN GroceriesLists.ProductID IS NOT NULL
            THEN 1
            ELSE 0
        END AS Enqueued
    FROM Groceries
        LEFT JOIN GroceriesLists
            ON Groceries.uid = GroceriesLists.ProductID
            AND GroceriesLists.ListID=1
    """
    case testEnqueue = "INSERT INTO GroceriesLists (Position, ListID, ProductId) VALUES (?, 1, ?)"
    case testFetchLastInsertedGrocery = """
    SELECT
        Name,
        uid,
        CASE WHEN GroceriesLists.ProductID IS NOT NULL
            THEN 1
            ELSE 0
        END AS Enqueued
    FROM Groceries
        LEFT JOIN GroceriesLists
            ON Groceries.uid = GroceriesLists.ProductID
            AND GroceriesLists.ListID=1
    ORDER BY uid DESC
    LIMIT 1
    """
}

final class FMDBDatabaseEngine: Engine {
    private let serialQueue = DispatchQueue(label: "com.twealm.groceries.db.serial")
    private var database: FMDatabase

    init(with url: URL) {
        database = FMDBDatabaseEngine.createDatabase(url.path, queue: serialQueue)
    }

    func executeFetchBlock(_ block: @escaping (FMDatabase) -> Void) {
        serialQueue.async {
            [weak self] in
            if let db = self?.database {
                autoreleasepool {
                    block(db)
                }
            }
        }
    }

    func executeUpdateBlock(_ block: @escaping (FMDatabase) -> Void) {
        serialQueue.async {
            [weak self] in
            if let db = self?.database {
                autoreleasepool {
                    block(db)
                }
            }
        }
    }

    deinit {
        database.close()
    }
}

extension FMDBDatabaseEngine {
    fileprivate static func createDatabase(_ path: String, queue: DispatchQueue) -> FMDatabase {
        let exists = FileManager.default.fileExists(atPath: path)
        let db = FMDatabase(path: path)

        if !exists {
            let schema = Bundle.main.path(forResource: "schema", ofType: "sql", inDirectory: "sql")!
            let st = try! String(contentsOf: URL(fileURLWithPath: schema))

            db.open()
            _ = db.executeStatements(st)

            #if DEBUG
                FMDBDatabaseEngine.prepareTestDatabase(db: db, queue: queue)
            #endif

        } else {
            db.open()
        }

        return db
    }
}

#if DEBUG
    extension FMDBDatabaseEngine {
        static func prepareTestDatabase(db: FMDatabase, queue _: DispatchQueue) {
            let url = Librarian.testSqlDirectory()

            do {
                let result = try FileManager.default.contentsOfDirectory(atPath: url.path)
                for item in result {
                    let itemUrl = url.appendingPathComponent(item, isDirectory: false)
                    let st = try! String(contentsOf: itemUrl)
                    _ = db.executeStatements(st)
                }
            } catch {
                print(error)
            }
        }
    }
#endif