//
//  FriendViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/11/20.
//

import SwiftUI
import UIKit
import RealmSwift

class FriendViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    let IP_ADDRESS = (Value.sharedInstance().IP_ADDRESS)
    let TO_FRIEND = UIDevice.current.identifierForVendor?.uuidString
    var FROM_FRIEND : String?
    let progressDialog:ProgressDialogView = ProgressDialogView()

    //MARK: - 오버라이드 메소드
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            tableView.delegate = self
            tableView.dataSource = self
        }
    
    override func viewWillAppear(_ animated: Bool) {
        //뷰가 보일때 업데이트
        tableUpdayte()
    }
    
    public func tableUpdayte() {
        // Do any additional setup after loading the view.
        tableView.reloadData()
    }
    
    // 테이블 뷰 데이터 소스
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // realm가져오기
        let realm = try! Realm()
        let savedPerson = realm.objects(Person.self)
        
        return savedPerson.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // realm가져오기
        let realm = try! Realm()
        let savedPerson = realm.objects(Person.self)
        
        let cell: MyTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MyTableViewCell", for: indexPath) as! MyTableViewCell
        
        cell.mylable?.text = savedPerson[indexPath.row].name
        
        return cell
    }
    
    
    //스와이프해서 삭제하기
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            // realm가져오기
            let realm = try! Realm()
            let savedPerson = realm.objects(Person.self)
            FROM_FRIEND = savedPerson[indexPath.row].uuid
            Task.init{//비동기처리 해결
                self.view.addSubview(progressDialog)
                showProgressDialog()
                if await deleteFriend() == "삭제 완료!"{//서버에도 삭제되었을 때
                    if editingStyle == .delete {
                        //db에서 삭제
                        try! realm.write {
                            realm.delete(savedPerson[indexPath.row])
                        }
                        print(savedPerson)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    } else if editingStyle == .insert {}
                }
            else{//서버에 삭제 못했을 때
                let alert = UIAlertController(title: "오류", message: "친구추가에 실패했습니다. 네트워크상태를 확인하세요.", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
                    //확인시 엑션
                }
                alert.addAction(okAction)
                present(alert, animated: false, completion: nil)
            }
                hideProgressDialog()
            }
            
        }
    func deleteFriend() async -> String {
        do{
            guard let url = URL(string: "http://\(IP_ADDRESS)/deleteFriend.php") else { fatalError("Missing URL") }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let postString = "TO_FRIEND=\(String(describing: TO_FRIEND!))&FROM_FRIEND=\(String(describing: FROM_FRIEND!))"
            urlRequest.httpBody = postString.data(using: String.Encoding.utf8)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
            let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(responseString!)
            return responseString! as String
        }catch{
            return "error"
        }
    }
    //테이블 삭제 코멘트 Delete에서 삭제로 바꾸기
        func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
            return "삭제"
        }
    
    //클릭한 셀의 이벤트 처리
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            print("Click Cell Number : " + String(indexPath.row))
        }
    func showProgressDialog() {
        self.progressDialog.show()
    }
    func hideProgressDialog() {
        self.progressDialog.hide()
    }
}
