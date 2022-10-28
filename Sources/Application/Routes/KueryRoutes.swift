import KituraContracts
import SwiftKuery
import LoggerAPI
import Foundation

func initializeKueryRoutes(app: App) {
//    app.router.post("/kuery", handler: app.insertHandler)
//    app.router.get("/kuery", handler: app.selectHandler)
}

extension App {
    
    func insertHandler(toDo: ToDo, completion: @escaping (ToDo?, RequestError?) -> Void) {
        let rows = [["123",
                     toDo.title!,
                     toDo.author!,
                     toDo.pages!,
                     toDo.publisher!,
                     toDo.hasSequence!,
                     toDo.completed!,
                     " ",
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
    
    func getNextId(completion: @escaping ([Int]?, RequestError?) -> Void) {
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
                var ids = [Int]()
                resultSet.forEach() { row, error in
                    guard let row = row else {
                        if let error = error {
                            debugPrint("Error getting row: \(error)")
                            return completion(nil, .internalServerError)
                        } else {
                            return completion(ids, nil)
                        }
                    }
                    guard let id = row[0] as? String else {
                        debugPrint("Unable to decode ID")
                        return completion(nil, .internalServerError)
                    }
                    
                    let convertedInt = Int(id) ?? 0
                    ids.append(convertedInt)
                    
                }
            }
        }
    }
    
    func selectHandler(completion: @escaping ([ToDo]?, RequestError?) -> Void) {
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
                    
                    todos.append(ToDo(
                                      title: title,
                                      author: author,
                                      pages: pages,
                                      publisher: publisher,
                                      hasSequence: Bool(truncating: hasSequence),
                                      completed: Bool(truncating: completed),
//                                      url: " ",
                                      orderId: orderId))
                    
                }
            }
        }
    }
}
