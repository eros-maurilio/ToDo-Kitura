import Kitura
import HeliumLogger
import Logging
import LoggerAPI
import KituraOpenAPI
import Configuration
import KituraContracts
import Health
import KituraCORS
import Foundation
import SwiftKuery
import SwiftKueryMySQL

public class App {

    let health = Health()
    let router = Router()
    private var todoStore: [ToDo] = []
    private var nextId: Int = 0
    private let workerQueue = DispatchQueue(label: "worker")
    static let toDoTable = ToDoTable()
    static let poolOptions = ConnectionPoolOptions(initialCapacity: 1, maxCapacity: 5)
    static let pool = MySQLConnection.createPool(user: "eros", password: "eros", database: "tododb", poolOptions: poolOptions)

    public init() throws { }

    func postInit() throws {
        let options = Options(allowedOrigin: .all)
        let cors = CORS(options: options)
        initializeKueryRoutes(app: self)
        KituraOpenAPI.addEndpoints(to: router)
        router.all("/*", middleware: cors)
        router.delete("/", handler: deleteAllHandler)
        router.post("/", handler: storeHandler)
        router.get("/", handler: getAllHandler)
        router.get("/", handler: getOneHandler)
        router.patch("/", handler: updateHandler)
        router.delete("/", handler: deleteOneHandler)
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: 8080, with: router)
        Kitura.run()
    }
    
    func execute(_ block: (() -> Void)) {
       workerQueue.sync {
           block()
       }
    }
    
    func storeHandler(toDo: ToDo, completion: @escaping(ToDo?, RequestError?) -> Void ) {
        var nextID = Int()
        getNextId { ids, _ in
            if let maxID = ids?.max() {
                nextID = maxID
                nextID += 1
            }
            
            print(nextID)
            let convertedNextId = String(nextID)
            let url = "http://localhost:8080/\(convertedNextId)"
            
            let rows = [[convertedNextId,
                         toDo.title!,
                         toDo.author!,
                         toDo.pages!,
                         toDo.publisher!,
                         toDo.hasSequence!,
                         toDo.completed!,
                         url,
                         toDo.orderId!]]
            
        
            App.pool.getConnection() { connection, error in
                guard let connection = connection else {
                    print("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                    return completion(nil, .internalServerError)
                }
                
                let insertQuery = Insert(into: App.toDoTable, rows: rows)
                
                connection.execute(query: insertQuery) { insertResult in
                    guard insertResult.success else {
                        print("Error executing query: \(insertResult.asError?.localizedDescription ?? "Unknown Error")")
                        return completion(nil, .internalServerError)
                    }
                    completion(toDo, nil)
                }
            }
        }
    }
    
    func deleteAllHandler(completion: @escaping(RequestError?) -> Void ) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                print("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return completion(.internalServerError)
            }
            
            let deleteQuery = Delete(from: App.toDoTable)
            
            connection.execute(query: deleteQuery) { insertResult in
                guard insertResult.success else {
                    print("Error executing query: \(insertResult.asError?.localizedDescription ?? "Unknown Error")")
                    return completion(.internalServerError)
                }
            }
        }
    }
    
    func getAllHandler(completion: @escaping([ToDo]?, RequestError?) -> Void ) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                debugPrint("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return completion(nil, .internalServerError)
            }
            let selectQuery = Select(from: App.toDoTable)
            connection.execute(query: selectQuery) { selectResult in
                guard let resultSet = selectResult.asResultSet else {
                    debugPrint("Error connecting: \(selectResult.asError?.localizedDescription ?? "Unknown Error")")
                    return completion(nil, .internalServerError)
                }
                var todos = [ToDo]()
                resultSet.forEach() { row, error in
                    guard let row = row else {
                        if let error = error {
                            debugPrint("Error getting row: \(error)")
                            return completion(nil, .internalServerError)
                        } else {
                            // All rows have been processed
                            return completion(todos, nil)
                        }
                    }
                    
                    guard let id = row[0] as? String,
                          let title = row[1] as? String,
                          let author = row[2] as? String,
                          let pages = row[3] as? Int32,
                          let publisher = row[4] as? String,
                          let hasSequence = row[5] as? NSNumber,
                          let completed = row[6] as? NSNumber,
                          let url = row[7] as? String,
                          let orderId = row[8] as? Int32
                    else {
                        debugPrint("Unable to decode ToDo")
                        return completion(nil, .internalServerError)
                    }
                    
                    todos.append(ToDo(id: id,
                                      title: title,
                                      author: author,
                                      pages: pages,
                                      publisher: publisher,
                                      hasSequence: Bool(truncating: hasSequence),
                                      completed: Bool(truncating: completed),
                                      url: url,
                                      orderId: orderId))
                    
                }
            }
        }
    }
    
    func getOneHandler(id: Int, completion: @escaping(ToDo?, RequestError?) -> Void ) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                debugPrint("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return completion(nil, .internalServerError)
            }
            let selectQuery = Select(from: App.toDoTable)
            
            
            connection.execute(query: selectQuery) { selectResult in
                guard let resultSet = selectResult.asResultSet else {
                    debugPrint("Error connecting: \(selectResult.asError?.localizedDescription ?? "Unknown Error")")
                    return completion(nil, .internalServerError)
                }
                
                var todos = ToDo.init()
                resultSet.forEach() { row, error in
                    guard let row = row else {
                        if let error = error {
                            debugPrint("Error getting row: \(error)")
                            return completion(nil, .internalServerError)
                        } else {
                            // All rows have been processed
                            return completion(todos, nil)
                        }
                    }
                    
                    guard let todoId = row[0] as? String,
                          let title = row[1] as? String,
                          let author = row[2] as? String,
                          let pages = row[3] as? Int32,
                          let publisher = row[4] as? String,
                          let hasSequence = row[5] as? NSNumber,
                          let completed = row[6] as? NSNumber,
                          let url = row[7] as? String,
                          let orderId = row[8] as? Int32
                    else {
                        debugPrint("Unable to decode ToDo")
                        return completion(nil, .internalServerError)
                    }
                    
                    let convertedTodoId = Int(todoId) ?? 0
                    
                    if id == convertedTodoId {
                        todos = ToDo(id: todoId,
                                     title: title,
                                     author: author,
                                     pages: pages,
                                     publisher: publisher,
                                     hasSequence: Bool(truncating: hasSequence),
                                     completed: Bool(truncating: completed),
                                     url: url,
                                     orderId: orderId)
                    }
                }
            }
        }
    }
    
    func updateHandler(id: Int, new: ToDo, completion: @escaping(ToDo?, RequestError?) -> Void ) {
        
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                debugPrint("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return completion(nil, .internalServerError)
            }
            
            let selectQuery = Select(from: App.toDoTable)
            let table = App.toDoTable
                        
            let updateQuery = Update(table,
                                     set: [(table.title, table.title ?? new.title),
                                           (table.author, table.author ?? new.author),
                                           (table.pages, table.pages ?? new.pages),
                                           (table.publisher, table.publisher ?? new.publisher),
                                           (table.hasSequence, table.hasSequence ?? new.hasSequence),
                                           (table.completed, table.completed ?? new.completed),
                                           (table.orderId, table.orderId ?? new.orderId)],
                                     where: table.id == String(id))
            
            connection.execute(query: updateQuery) { selectResult in
                guard let resultSet = selectResult.asResultSet else {
                    debugPrint("Error connecting: \(selectResult.asError?.localizedDescription ?? "Unknown Error")")
                    return completion(nil, .internalServerError)
                }
            }
        }
    }
    
    func deleteOneHandler(id: Int, completion: @escaping(RequestError?) -> Void ) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                print("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return completion(.internalServerError)
            }
                        
            let deleteQuery = Delete(from: App.toDoTable, where: App.toDoTable.id == String(id))
            
            connection.execute(query: deleteQuery) { insertResult in
                guard insertResult.success else {
                    print("Error executing query: \(insertResult.asError?.localizedDescription ?? "Unknown Error")")
                    return completion(.internalServerError)
                }
            }
        }
    }
}
