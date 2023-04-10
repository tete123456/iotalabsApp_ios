//
//  Floㅁting.swift.swift
//  Lotalabs
//
//  Created by LTS on 2021/11/28.
//

import Foundation
import MaterialComponents.MaterialButtons
// 플로팅 버튼 생성 함수
func setFloatingButton() {
        let floatingButton = MDCFloatingButton()
        let image = UIImage(systemName: "message.fill")
        floatingButton.sizeToFit()
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        floatingButton.setImage(image, for: .normal)
        floatingButton.setImageTintColor(.white, for: .normal)
        floatingButton.backgroundColor = .systemBlue
        floatingButton.addTarget(self, action: #selector(tap), for: .touchUpInside)
        view.addSubview(floatingButton)
        view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -64))
        view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -32))
    }


//버튼 눌렸을 때에 이벤트
@objc func tap(_ sender: Any) {
    print("Hello World")
}
