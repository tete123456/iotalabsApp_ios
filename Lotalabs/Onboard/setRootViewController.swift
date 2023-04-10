//
//  setRootViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/12/12.
//

import SwiftUI
import UIKit
import RealmSwift

let realm = try! Realm()

extension SceneDelegate {
    
    
    public func setRootViewController(_ scene: UIScene){
        if (!CheckFirst.isFirstTime()) && (!realm.isEmpty)  {
            print(realm.isEmpty)
            setRootViewController(scene, name: "Main",
                                identifier: "FloatingView")
        }else {
            print(realm.isEmpty)
            setRootViewController(scene, name: "Onboarding",
                                  identifier: "MyNameViewController")
        }
    }
    
    public func setRootViewController(_ scene: UIScene, name: String, identifier: String) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let storyboard = UIStoryboard(name: name, bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: identifier)
            window.rootViewController = viewController
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
