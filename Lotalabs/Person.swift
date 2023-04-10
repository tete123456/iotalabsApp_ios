import Foundation
import RealmSwift


class Person: Object {
    @objc dynamic var uuid:String = ""
    @objc dynamic var name:String = ""
    
    // id 가 고유 값입니다.
    override static func primaryKey() -> String? {
      return "uuid"
    }
}
