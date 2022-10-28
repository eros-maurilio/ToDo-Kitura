import SwiftKuery

class ToDoTable: Table {
    let tableName = "ToDoTable"
    let id = Column("id", String.self, primaryKey: true)
    let title = Column("title", String.self)
    let author = Column("author", String.self)
    let pages = Column("pages", Int32.self)
    let publisher = Column("publisher", String.self)
    let hasSequence = Column("hasSequence", Bool.self)
    let completed = Column("completed", Bool.self)
    let url = Column("url", String.self)
    let orderId = Column("orderId", Int32.self)
}

/*
 
 "id": "13",
 "title": "Laranja mecânica",
 "author": "Burges",
 "pages": 321,
 "publisher": "Darkside",
 "hasSequence": false,
 "completed": true,
 "url": " ",
 "orderId": 1
 
 
 
 */
