//
//  ReadQrController.swift
//  Lotalabs
//
//  Created by 제로 on 2021/12/18.
//
import SwiftUI
import JJFloatingActionButton
import AVFoundation
import UIKit
import MaterialComponents.MaterialButtons
import RealmSwift

class ReadQrController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let floatingButton = MDCFloatingButton()
    let IP_ADDRESS = (Value.sharedInstance().IP_ADDRESS)
    let TO_FRIEND = UIDevice.current.identifierForVendor?.uuidString
    var FROM_FRIEND : String? = nil
    var name : String? = nil
    let realm = try! Realm()
    let progressDialog:ProgressDialogView = ProgressDialogView()
    
    //MARK: - 오버라이드 메소드
    override func viewDidLoad() {
        super.viewDidLoad()
        let status = AVCaptureDevice.authorizationStatus(for:
        .video)
        if (status == .authorized) {
            setBarcodeReader()
        }
    }
    // 바코드 리더기 부분
    func setBarcodeReader() {
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        if let captureDevice = captureDevice {
            do {
                captureSession = AVCaptureSession()
                let input: AVCaptureDeviceInput
                input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession?.addInput(input)
                let metadataOutput = AVCaptureMetadataOutput()
                captureSession?.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self,queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr] //바코드 형식에 따라 다름
                //captureSession?.startRunning()
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.videoGravity = .resizeAspectFill
                videoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
                view.layer.addSublayer(videoPreviewLayer!)
                captureSession?.startRunning()
                //setCenterGuideLineView()
                setFloatingButton()
                
            }catch {
                print("error")
                    
            }
            
        }
        
    }
    // 리더기에서 받아온 값 저장하는 부분
    @objc(captureOutput:didOutputMetadataObjects:fromConnection:) func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        captureSession?.stopRunning() //인식 될시 멈춤
        videoPreviewLayer?.removeFromSuperlayer() // 레이어 닫음
        self.floatingButton.removeFromSuperview() //버튼 삭제

        if metadataObjects.count == 0 { return }
        let metaDataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
        guard let StringCodeValue = metaDataObject.stringValue // 카메라로 읽어온 값
            else { return }
        
        print(StringCodeValue," ","김유미김유미김유미김유미김유미김유미김유미김유미")
        
        guard let _ = self.videoPreviewLayer?.transformedMetadataObject(for: metaDataObject)
        else { return }
                let pattern: String = "[a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12}"
        //QR정보가 UUID+이름 형식인지 검사
        if (StringCodeValue.range(of: pattern, options: .regularExpression) == nil) {
            // 아니면 실행
            //메세지 띄우기
            let alert = UIAlertController(title: "오류", message: "친구추가 QR코드가 아닙니다.", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
                //확인시 엑션
                self.dismiss(animated: true)
            }
            alert.addAction(okAction)
            present(alert, animated: false, completion: nil)
        }
        else{
            //UUID형식이 맞으면 실행
            let personInfo = StringCodeValue.components(separatedBy: "문자열나누기")
            //문자열나누기라는 문자열을 기준으로 왼쪽에는 uuid, 오른쪽은 이름
            FROM_FRIEND = personInfo[0]
            name = personInfo[1]

        // 데이터베이스 가져오기
            
            let savedPerson = realm.objects(Person.self)
        
        // 중복된 값 가져오기 ( 없으면 isEmpty == true )
            let filter = savedPerson.filter("uuid == %FROM_FRIEND", FROM_FRIEND as Any)
            if !(filter.isEmpty) {
                self.floatingButton.removeFromSuperview() //버튼 삭제
                //메세지 띄우기
                let alert = UIAlertController(title: "오류", message: "이미 등록된 친구 입니다!", preferredStyle: UIAlertController.Style.alert)
                let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
                    //확인시 엑션
                    self.dismiss(animated: true)
                }
                alert.addAction(okAction)
                present(alert, animated: false, completion: nil)
            }
        else{
            //친구 추가
            Task.init{//비동기처리 해결
                self.view.addSubview(progressDialog)
                showProgressDialog()
                if await insertFriend() == "새로운 사용자를 추가했습니다."{//서버에도 추가되었을 때
                     let person = Person()
                     person.name = name!
                     person.uuid = FROM_FRIEND!

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
    }
    func insertFriend() async -> String {
        do{
            guard let url = URL(string: "http://\(IP_ADDRESS)/insertFriend.php") else { fatalError("Missing URL") }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let postString = "TO_FRIEND=\(String(describing: TO_FRIEND!))&FROM_FRIEND=\(String(describing: FROM_FRIEND!))&name=\(String(describing: name!))"
            urlRequest.httpBody = postString.data(using: String.Encoding.utf8)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
            let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            return responseString! as String
        }catch{
            return "error"
        }
    }
    @objc func tap(_ sender: Any) {
        videoPreviewLayer?.removeFromSuperlayer() // 레이어 닫음
        floatingButton.removeFromSuperview()
        self.dismiss(animated:true)
    }
    //종료버튼
    func setFloatingButton() {
            let image = UIImage(systemName: "xmark")
            floatingButton.sizeToFit()
            floatingButton.translatesAutoresizingMaskIntoConstraints = false
            floatingButton.setImage(image, for: .normal)
            floatingButton.setImageTintColor(.white, for: .normal)
            floatingButton.backgroundColor = .systemRed
            floatingButton.addTarget(self, action: #selector(tap), for: .touchUpInside)
            view.addSubview(floatingButton)
            view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -60))
            view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -280))
        }
    func showProgressDialog() {
        self.progressDialog.show()
        
    }
    func hideProgressDialog() {
        self.progressDialog.hide()
        
    }
}
