//
//  FlotingViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/11/27.
//

import SwiftUI
import JJFloatingActionButton
import AVFoundation
import UIKit
import MaterialComponents.MaterialButtons
import RealmSwift

class FlotingViewController: UITabBarController, AVCaptureMetadataOutputObjectsDelegate {
    
    
    var get_uuid: String?
    let floatingButton = MDCFloatingButton()
    let floatingButtonAR = MDCFloatingButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // 플로팅 버튼 생성
        let actionButton = JJFloatingActionButton()
        actionButton.buttonColor = .darkGray

        actionButton.addItem(title: "QR생성", image: UIImage(systemName: "qrcode")?.withRenderingMode(.alwaysTemplate)) { item in
            
            // QR코드 생성 부분
            let createQrStoryboard = UIStoryboard.init(name : "CreateQr", bundle : nil)
            guard let createQr = createQrStoryboard.instantiateViewController(identifier: "CreateQr") as? CreateQrViewController else {return}
            
            self.present(createQr, animated: true, completion: nil)
           
        }
        actionButton.addItem(title: "QR스캔", image: UIImage(systemName: "camera")?.withRenderingMode(.alwaysTemplate)) { item in
          //QR리더로 이동
            let status = AVCaptureDevice.authorizationStatus(for:
            .video)
            if (status == .authorized) {
                self.goReader()
            }
            else if (status == .denied) {
                let alert = UIAlertController(title: "알림", message: "바코드 촬영을 위해 카메라 권한이 필요합니다.\n설정 > 어플리케이션에서 카메라 권한을 허용으로 변경해주세요.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
            else if (status == .notDetermined) {
                AVCaptureDevice.requestAccess(for: .video) { (isSuccess) in
                    if (isSuccess) {
                        DispatchQueue.main.async { self.goReader() }
                        
                    }
                    else {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "알림", message: "바코드 촬영을 위해 카메라 권한이 필요합니다.\n설정 > 어플리케이션에서 카메라 권한을 허용으로 변경해주세요.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                }
                
            }
        }
        view.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -66).isActive = true
        
        
    }
    func goReader(){
        let readQrStoryboard = UIStoryboard.init(name : "ReadQr", bundle : nil)
        guard let ReadQRVC = readQrStoryboard.instantiateViewController(identifier: "ReadQr") as? ReadQrController else {return}
        ReadQRVC.modalPresentationStyle = .fullScreen
        ReadQRVC.modalTransitionStyle = .crossDissolve
        self.floatingButton.removeFromSuperview() //버튼 삭제
        self.present(ReadQRVC, animated: true, completion: nil)
    }
    
    
}
