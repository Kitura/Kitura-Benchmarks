import Mustache

extension Fortune: MustacheBoxable {
  var mustacheBox: MustacheBox {
    return Box(["id": self.id, "message": self.message])
  }
}
