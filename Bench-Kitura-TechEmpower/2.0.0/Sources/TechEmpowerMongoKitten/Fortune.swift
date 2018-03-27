struct Fortune {

  let id: Int
  let message: String

  public init(id: Int, message: String) {
    self.id = id
    self.message = message
  }

  init(row: [String:Any?]) throws {
    guard let idField = row["id"] else {
      throw AppError.DataFormatError("Missing 'id' field")
    }
    guard let msgField = row["message"] else {
      throw AppError.DataFormatError("Missing 'message' field")
    }
    guard let message = msgField as? String else {
      throw AppError.DataFormatError("'message' field not a String")
    }
    guard let id = idField as? Int32 else {
      throw AppError.DataFormatError("'id' field not an Int32")
    }
    self.init(id: Int(id), message: message)
  }

}

extension Fortune: Comparable {

  static func == (lhs: Fortune, rhs: Fortune) -> Bool {
    return lhs.id == rhs.id && lhs.message == rhs.message
  }

  static func < (lhs: Fortune, rhs: Fortune) -> Bool {
    return lhs.message < rhs.message || (lhs.message == rhs.message && lhs.id < rhs.id)
  }

}
