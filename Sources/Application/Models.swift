//
//  Models.swift
//  Application
//
//  Created by Eros Maurilio on 23/10/22.
//

import Foundation

public struct ToDo : Codable, Equatable {
    public var id: String?
    public var title: String?
    public var author: String?
    public var pages: Int32?
    public var publisher: String?
    public var hasSequence: Bool?
    public var completed: Bool?
    public var url: String?
    public var orderId: Int32?
    
    public static func ==(lhs: ToDo, rhs: ToDo) -> Bool {
        return (lhs.id == rhs.id) && (lhs.title == rhs.title) && (lhs.author == rhs.author) && (lhs.pages == rhs.pages) && (lhs.publisher == rhs.publisher) && (lhs.hasSequence == rhs.hasSequence) && (lhs.completed == rhs.completed) && (lhs.url == rhs.url) && (lhs.orderId == rhs.orderId)
    }
}
