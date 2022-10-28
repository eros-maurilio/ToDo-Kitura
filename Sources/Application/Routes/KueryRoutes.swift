import KituraContracts
import SwiftKuery
import LoggerAPI
import Foundation

extension App {
    
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
}
