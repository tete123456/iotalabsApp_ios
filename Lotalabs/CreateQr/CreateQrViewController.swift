//
//  CreateQrViewController.swift
//  Lotalabs
//
//  Created by 제로 on 2021/11/28.
//
import UIKit
import RealmSwift

class CreateQrViewController: UIViewController {
    let uuid = UIDevice.current.identifierForVendor?.uuidString
    
    @IBOutlet weak var qrcodeView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = CGRect(origin: .zero, size: qrcodeView.frame.size)
        let qrcode = QRCodeView(frame: frame)
        
        let realm = try! Realm()
        let savedName = realm.objects(me.self)
        let myName = savedName[0].name
        let myInfo = "\(uuid!)문자열나누기\(myName)"

        qrcode.generateCode(myInfo, foregroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), backgroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        qrcodeView.addSubview(qrcode)
    }
}
