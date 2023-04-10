//
//  SettingViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/12/07.
//

import SwiftUI

class SettingViewController: UIViewController {
    
    @IBOutlet weak var myPlaceBT: UISwitch!
    @IBOutlet weak var frPlaceBT: UISwitch!
    @IBOutlet weak var hittmapBT: UISwitch!
    @IBOutlet weak var backgroundBT: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //스위치 상태 불러오기
        myPlaceBT.isOn =  UserDefaults.standard.bool(forKey: "switch1State")
        frPlaceBT.isOn =  UserDefaults.standard.bool(forKey: "switch2State")
        hittmapBT.isOn =  UserDefaults.standard.bool(forKey: "switch3State")
        backgroundBT.isOn =  UserDefaults.standard.bool(forKey: "switch4State")
        

    }

    //체크박스 on / off 감지
    @IBAction func BT1Changed(_ sender: Any) {
        if myPlaceBT.isOn {
            print("BT1 on")
            

        }
        else {
            print("BT1 off")
        }
        UserDefaults.standard.set(myPlaceBT.isOn, forKey: "switch1State") // 스위치 상태 저장
    }
    @IBAction func BT2Changed(_ sender: Any) {
        UserDefaults.standard.set(frPlaceBT.isOn, forKey: "switch2State") // 스위치 상태 저장
    }
    @IBAction func BT3Changed(_ sender: Any) {
        UserDefaults.standard.set(hittmapBT.isOn, forKey: "switch3State") // 스위치 상태 저장
    }
    @IBAction func BT4Changed(_ sender: Any) {
        UserDefaults.standard.set(backgroundBT.isOn, forKey: "switch4State") // 스위치 상태 저장
    }
    
}
