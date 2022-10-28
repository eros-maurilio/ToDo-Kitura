import Application

do {
    let app = try App()
    try app.run()
} catch let error {
    print(error.localizedDescription)
}
