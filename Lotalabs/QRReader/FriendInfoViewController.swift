//
//  FriendInfoViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/11/30.
//

import SwiftUI
import RealmSwift
import Foundation

class FriendInfoViewController: UIViewController,UITextFieldDelegate {
    //QRReader에서 받아올 uuid
    var uuid: String?
    //Realm가져오기
    var textName : String?
    let realm = try! Realm()
    let IP_ADDRESS = (Value.sharedInstance().IP_ADDRESS)

    let UUID = UIDevice.current.identifierForVendor?.uuidString
    
    let progressDialog:ProgressDialogView = ProgressDialogView()

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var plusBT: UIButton!
    
    @IBAction func backButton(_ sender: UIButton) {//뒤로가기
        dismiss(animated: true)
    }
    
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
    
    // 버튼 클릭 이벤트
    @IBAction func onClick(_ sender: Any) {
        textName = name.text?.trimmingCharacters(in: .whitespaces)
        // Realm 파일 위치
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        if textName == "" {//앞뒤 공백 제거후 비교
            self.showToast(message: "이름을 입력해주세요.")
        }
        else{
            Task.init{//비동기처리 해결
                self.view.addSubview(progressDialog)
                showProgressDialog()
                if await insertFriend() == "새로운 사용자를 추가했습니다."{//서버에도 추가되었을 때
                     let person = Person()
                     person.name = textName!
                     person.uuid = uuid!

                     // Realm 에 저장하기
                     try! realm.write {
                         realm.add(person)
                     }
                    hideProgressDialog()
                    dismiss(animated: true, completion: nil)
                }
            else{//서버에 추가 못했을 때
                let alert = UIAlertController(title: "오류", message: "친구추가에 실패했습니다. 네트워크상태를 확인하세요.", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
                    //확인시 엑션
                    self.dismiss(animated: true, completion: nil)
                }
                hideProgressDialog()
                alert.addAction(okAction)
                present(alert, animated: false, completion: nil)
            }
            }
        }
    }
    
    func insertFriend() async -> String {
        do{
            guard let url = URL(string: "http://\(IP_ADDRESS)/insertFriend.php") else { fatalError("Missing URL") }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let postString = "TO_FRIEND=\(String(describing: UUID!))&FROM_FRIEND=\(String(describing: uuid!))&name=\(String(describing: textName!))"
            urlRequest.httpBody = postString.data(using: String.Encoding.utf8)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
            let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            return responseString! as String
        }catch{
            return "error"
        }
    }
    //키보드 내리기
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    //done 버튼
    @objc func done() {
        self.view.endEditing(true)
    }
    //토스트 메시지 함수
    func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35));
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 10.0, delay: 0.01, options: .curveEaseOut, animations: { toastLabel.alpha = 0.0 }, completion: {(isCompleted) in toastLabel.removeFromSuperview() }) }
    
    func showProgressDialog() {
        self.progressDialog.show()
        
    }
    func hideProgressDialog() {
        self.progressDialog.hide()
        
    }
}

