//
//  LocationService.swift
//  Lotalabs
//
//  Created by LTS on 2021/11/26.
//

import Foundation
//위도 경도를 싱글톤으로 저장하는 클래스
class LocationService {
    
    static var shared = LocationService()
    var longitude:Double!
    var latitude:Double!
  
}
