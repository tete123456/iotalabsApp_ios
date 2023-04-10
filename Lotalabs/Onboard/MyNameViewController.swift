//
//  MyNameViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/12/12.
//

import SwiftUI
import UIKit
import RealmSwift

class MyNameViewController: UIViewController {
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var callMain: UIButton!
    var textName : String?
    let realm = try! Realm()
    //내 UUID
    let uuid = UIDevice.current.identifierForVendor?.uuidString
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 화면 터치해서 키보드 내리기
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // 키보드에 Done 버튼 만들기
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(done))
                
        toolbar.setItems([doneButton], animated: false)
                
        //toolbar를 넣고싶은 textField 및 textView 필자의 경우 recommendDataTextView
        name.inputAccessoryView = toolbar
        
        
    }
    @IBAction func CallMain(_ sender: Any) {
        
        textName = name.text?.trimmingCharacters(in: .whitespaces)
        
        let meData = me()
        meData.name = textName!
        meData.uuid = uuid!
        
        // Realm 에 저장하기
        try! realm.write {
            realm.add(meData)
        }
        
        //메인 뷰 연결
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "FloatingView") as! FlotingViewController
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: false, completion: nil)
        
        let savedMe = realm.objects(me.self)
        print(savedMe)
    }
    
    //키보드 내리기
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    //done 버튼
    @objc func done() {
        self.view.endEditing(true)
    }
}
