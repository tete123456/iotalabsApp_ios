//
//  MapViewController.swift
//  Lotalabs
//
//  Created by LTS on 2021/11/20.
//

import UserNotifications
import NotificationCenter
import SwiftUI
import Foundation
import CoreLocation
import GoogleMaps
import GoogleMapsUtils
import MaterialComponents.MaterialButtons
import Firebase
import RealmSwift
class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    let IP_ADDRESS = (Value.sharedInstance().IP_ADDRESS)
    
    private var mapView: GMSMapView!
    private var heatmapLayer: GMUHeatmapTileLayer!
    
    private var gradientColors = [UIColor.green, UIColor.red]
    private var gradientStartPoint = [0.2, 1.0] as [NSNumber]
    
    var locationManager:CLLocationManager?
    let UUID = UIDevice.current.identifierForVendor?.uuidString
    var str_latitude : String = ""
    var str_longitude : String = ""
    var list = [GMUWeightedLatLng]()
    let floatingButton = MDCFloatingButton() // 새로고침 버튼
    let floatingButtonAR = MDCFloatingButton() // AR 버튼
    var geo_check = false  //메인 공원 범위
    var AR_geo_chek = false // (모든)ar 구역에 들어갔는지
    var AR_object_chek = 0 // 어떠한 ar오브젝트를 만들지
    var AR_OnOff = false // ar 뷰 켜짐 감지
    var ARinside = ""
    let notificationCenter = UNUserNotificationCenter.current() // noti권한요청
    var name :String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //내 이름 가져오기
        let realm = try! Realm()
        let savedMe = realm.objects(me.self)
        name = savedMe[0].name
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            // 델리게이트 설정
            locationManager!.delegate = self
            // 거리 정확도 설정
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            // 업데이트 이벤트가 발생하기전 장치가 수평으로 이동해야 하는 최소 거리(미터 단위)
            locationManager!.distanceFilter = 10
            // 앱이 suspend 상태일때 위치정보를 수신받는지에 대한 결정
            locationManager!.allowsBackgroundLocationUpdates = true
            // location manager가 위치정보를 수신을 일시 중지 할수 있는지에 대한 결정
            locationManager!.pausesLocationUpdatesAutomatically = false
            // 사용자에게 허용 받기 alert 띄우기
            locationManager!.requestWhenInUseAuthorization()
            locationManager!.requestAlwaysAuthorization()
            // 아이폰 설정에서의 위치 서비스가 켜진 상태라면
            if CLLocationManager.locationServicesEnabled() {
                print("위치 서비스 On 상태")
                locationManager!.startUpdatingLocation() //위치 정보 받아오기 시작
                print(locationManager?.location?.coordinate as Any)
            } else {
                print("위치 서비스 Off 상태")
            }
        }
        
        
        //뷰에 지도를 붙임
        mapView = GMSMapView()
        view = mapView
        //새로고침 버튼
        setFloatingButton_new()
        //ar버튼 추가
        setFloatingButton_AR()
        move()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        addPolygon()
        
        //테스트용 좌표==--==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        addAR_Polygon()
        Task.init{//비동기처리 해결
            if UserDefaults.standard.bool(forKey: "switch1State") {
                mapView.isMyLocationEnabled = true//내위치
            }
            else {
                mapView.isMyLocationEnabled = false//내위치
            }
            //히트맵 관련
            if UserDefaults.standard.bool(forKey: "switch3State") {
                heatmapLayer = GMUHeatmapTileLayer()
                heatmapLayer.radius = 40
                heatmapLayer.gradient = GMUGradient(colors: gradientColors, startPoints: gradientStartPoint, colorMapSize: 256)
                await addHeatmap()
                heatmapLayer.weightedData.removeAll()
                heatmapLayer.weightedData = list
                heatmapLayer.map = mapView
            }
            if UserDefaults.standard.bool(forKey: "switch2State") {
                await addFriendLocation()//친구 마커 추가
            }
        }

    }
    override func viewWillDisappear(_ animated: Bool) {
        if UserDefaults.standard.bool(forKey: "switch3State") {
            heatmapLayer.map = nil
        }
        mapView.clear()
    }
    func addPolygon(){
        let path = GMSMutablePath() // 순천만 좌표
        path.addLatitude(34.930171, longitude: 127.502751)
        path.addLatitude(34.931365, longitude: 127.511754)
        path.addLatitude(34.922191, longitude: 127.515112)
        path.addLatitude(34.921927, longitude: 127.514125)
        path.addLatitude(34.923393, longitude: 127.510939)
        path.addLatitude(34.925601, longitude: 127.508901)
        path.addLatitude(34.926551, longitude: 127.507141)
        path.addLatitude(34.927927, longitude: 127.503872)
        path.addLatitude(34.930171, longitude: 127.502751)
        //폴리 라인 그리기
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.strokeColor = .red
        polyline.geodesic = true
        polyline.map = mapView

    }
    func addFriendLocation() async{
        do{
            guard let url = URL(string: "http://\(IP_ADDRESS)/getMyFriend.php") else { fatalError("Missing URL") }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let postString = "TO_FRIEND=\(String(describing: UUID!))"
            urlRequest.httpBody = postString.data(using: String.Encoding.utf8)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            let friendLocations = json
            let friendLocation =  friendLocations["friend"] as? [[String: String]]
            for item in friendLocation ?? [] {
                let position = CLLocationCoordinate2D(latitude: Double(item["str_latitude"]!)!, longitude: Double(item["str_longitude"]!)!)
                let marker = GMSMarker(position: position)
                marker.title = item["name"]!
                marker.map = mapView
                
        }
        }catch{
            //return "error"
        }
    }
    func addHeatmap() async  {
        list.removeAll()
        let url = URL(string: "http://\(IP_ADDRESS)/getjson.php")!
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                let heatLocations = json
                let heatLocation =  heatLocations["webnautes"] as? [[String: String]]
                for item in heatLocation ?? [] {
                    if UUID! != item["UUID"]{//내위치엔 안찍음
                        let lat = Double(item["str_latitude"]!)
                        let lng = Double(item["str_longitude"]!)
                        let coords = GMUWeightedLatLng(
                            coordinate: CLLocationCoordinate2DMake(lat! ,lng!),
                            intensity: 1.0
                          )
                        list.append(coords)
                    }
            }
            }catch {
                print("Invalid data")
            }
             }
    func move() {
        let camera = GMSCameraPosition.camera(withLatitude: 34.928875, longitude: 127.498907, zoom: 14.0)//순천 국가 정원
            mapView.camera = camera
        }
    // 위치 정보 계속 업데이트 -> 위도 경도 받아옴
       func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           insertToken() // 서버에 내기기 토큰 보내기
           
           print("didUpdateLocations")
           if let location = locations.first {
               print("위도: \(location.coordinate.latitude)")
               print("경도: \(location.coordinate.longitude)")
               str_latitude = String(location.coordinate.latitude)
               str_longitude = String(location.coordinate.longitude)
               let request = NSMutableURLRequest(url: NSURL(string: "http://\(IP_ADDRESS)/insert.php")! as URL)
               request.httpMethod = "POST"
               let postString = "UUID=\(String(describing: UUID!))&str_latitude=\(str_latitude)&str_longitude=\(str_longitude)"
               request.httpBody = postString.data(using: String.Encoding.utf8)

               let task = URLSession.shared.dataTask(with: request as URLRequest) {
                           data, response, error in

                           if error != nil {
                               print("error=\(String(describing: error))")
                               return
                           }
                       }
                       task.resume()
           }
           
           // 폴리곤 그리기 ( 범위 안에 있는지 확인하기 위함 )
           //==================================공원에서 빠져나갔는지 확인=======================================
           //메인 공원 범위 지정
           let parkLine = GMSMutablePath()
           parkLine.add(CLLocationCoordinate2D(latitude:34.930171, longitude: 127.502751))
           parkLine.add(CLLocationCoordinate2D(latitude:34.931365, longitude: 127.511754))
           parkLine.add(CLLocationCoordinate2D(latitude:34.922191, longitude: 127.515112))
           parkLine.add(CLLocationCoordinate2D(latitude:34.921927, longitude: 127.514125))
           parkLine.add(CLLocationCoordinate2D(latitude:34.923393, longitude: 127.510939))
           parkLine.add(CLLocationCoordinate2D(latitude:34.925601, longitude: 127.508901))
           parkLine.add(CLLocationCoordinate2D(latitude:34.926551, longitude: 127.507141))
           parkLine.add(CLLocationCoordinate2D(latitude:34.927927, longitude: 127.503872))
           parkLine.add(CLLocationCoordinate2D(latitude:34.930171, longitude: 127.502751))
           
           //폴리곤 지정
           let polygon = GMSPolygon(path: parkLine)
           // 옵셔널 변수가 아닌 더블형으로 받아옴
           let myLat : Double = (locations.first?.coordinate.latitude)!
           let myLong : Double = (locations.first?.coordinate.longitude)!
           
           let myPosition = CLLocationCoordinate2D(latitude: myLat, longitude: myLong)
           let inside = polygon.contains(coordinate: myPosition)
    
           // 안으로 들어온 경우 1번 실행 ( 현재 앱 구동시 처음 3번이 연속으로 실행되는 오류있음 )
           if inside {
               geo_check = true
           }// 밖으로 나간경우 1번 실행
           else {
               if(geo_check==true){
                  //나한테 노티띄우고 나를 친구로 하는 기기에게 푸시알림
                   generateUserNotification() //내기기에 노티 띄우기
                   pushNoti() // 서버로 uuid보내기
               }
               geo_check=false
           }
        //========================================================================================
           
        //==================================ar구역 확인용=======================================@@@
           //AR범위 지정
           //  테스트용 집 좌표
               let arLine = GMSMutablePath()
               arLine.add(CLLocationCoordinate2D(latitude:37.304963, longitude: 126.830609))
               arLine.add(CLLocationCoordinate2D(latitude:37.304959, longitude: 126.830842))
               arLine.add(CLLocationCoordinate2D(latitude:37.304029, longitude: 126.830724))
               arLine.add(CLLocationCoordinate2D(latitude:37.304102, longitude: 126.829619))
               arLine.add(CLLocationCoordinate2D(latitude:37.304963, longitude: 126.830609))
        /*
           let arLine = GMSMutablePath()
           arLine.add(CLLocationCoordinate2D(latitude:37.215201, longitude: 126.952440))
           arLine.add(CLLocationCoordinate2D(latitude:37.215194, longitude: 126.952627))
           arLine.add(CLLocationCoordinate2D(latitude:37.215149, longitude: 126.952614))
           arLine.add(CLLocationCoordinate2D(latitude:37.215075, longitude: 126.952437))
           arLine.add(CLLocationCoordinate2D(latitude:37.215201, longitude: 126.952440))
         */
               //폴리곤 지정
               let ARpolygon = GMSPolygon(path: arLine)
               // 옵셔널 변수가 아닌 더블형으로 받아옴
               //let myLat : Double = (locations.first?.coordinate.latitude)!
               //let myLong : Double = (locations.first?.coordinate.longitude)!         // 이미 받아옴
               //let myPosition = CLLocationCoordinate2D(latitude: myLat, longitude: myLong)
               ARinside = String(ARpolygon.contains(coordinate: myPosition)) //내위치가 속해있는지 확인
           
           print(ARinside)
           //ar상태 저장
           let realm = try! Realm()
           let mydata = realm.objects(me.self)
           try! realm.write{
               //mydata[0].AR_place = ARinside
               mydata[0].AR_place = "true"
           }
        //===================================================================================@@@
       }

    func addAR_Polygon(){
      
        let path = GMSMutablePath() // ar_라인
        path.addLatitude(37.304963, longitude: 126.830609)
        path.addLatitude(37.304959, longitude: 126.830842)
        path.addLatitude(37.304029, longitude: 126.830724)
        path.addLatitude(37.304102, longitude: 126.829619)
        path.addLatitude(37.304963, longitude: 126.830609)
         
        /*
        let path = GMSMutablePath() // ar_라인
        path.addLatitude(37.215201, longitude: 126.952440)
        path.addLatitude(37.215194, longitude: 126.952627)
        path.addLatitude(37.215149, longitude: 126.952614)
        path.addLatitude(37.215075, longitude: 126.952437)
        path.addLatitude(37.215201, longitude: 126.952440)
         */
        //폴리 라인 그리기
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.strokeColor = .blue
        polyline.geodesic = true
        polyline.map = mapView

    }
       // 위도 경도 받아오기 에러
       func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           print(error)
       }

    //새로고침 버튼
    func setFloatingButton_new() {
            let image = UIImage(systemName: "arrow.triangle.2.circlepath")
            floatingButton.sizeToFit()
            floatingButton.translatesAutoresizingMaskIntoConstraints = false
            floatingButton.setImage(image, for: .normal)
            floatingButton.setImageTintColor(.white, for: .normal)
            let bgColor = Color(#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)) // 컬러 코드로 뽑기용
        floatingButton.backgroundColor = UIColor(Color(#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 0.7)))
            floatingButton.addTarget(self, action: #selector(tap_new), for: .touchUpInside)
            view.addSubview(floatingButton)
        view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 100))
            view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -15))
        }
    // 새로고침 버튼 클릭시 실행
    @objc func tap_new(_ sender: Any) {
        mapView.clear()
        addPolygon()
        Task.init{//비동기처리 해결
            if UserDefaults.standard.bool(forKey: "switch1State") {
                mapView.isMyLocationEnabled = true//내위치
            }
            else {
                mapView.isMyLocationEnabled = false//내위치
            }
            //히트맵 관련
            if UserDefaults.standard.bool(forKey: "switch3State") {
                heatmapLayer = GMUHeatmapTileLayer()
                heatmapLayer.radius = 40
                heatmapLayer.gradient = GMUGradient(colors: gradientColors, startPoints: gradientStartPoint, colorMapSize: 256)
                await addHeatmap()
                heatmapLayer.weightedData.removeAll()
                heatmapLayer.weightedData = list
                heatmapLayer.map = mapView
            }
            if UserDefaults.standard.bool(forKey: "switch2State") {
                await addFriendLocation()//친구 마커 추가
            }
        }
    }
    
    //ar 버튼
    func setFloatingButton_AR() {

        let image = UIImage(systemName: "arkit")
        floatingButtonAR.sizeToFit()
        floatingButtonAR.mode = .expanded
        floatingButtonAR.setTitle("AR", for: .normal)
        floatingButtonAR.translatesAutoresizingMaskIntoConstraints = false
        floatingButtonAR.setImage(image, for: .normal)
        floatingButtonAR.setImageTintColor(.white, for: .normal)
            let bgColor = Color(#colorLiteral(red: 0.1718172431, green: 0.3568878174, blue: 0.866679728, alpha: 1)) // 컬러 코드로 뽑기용
        floatingButtonAR.backgroundColor = UIColor(Color(#colorLiteral(red: 0.1718172431, green: 0.3568878174, blue: 0.866679728, alpha: 0.78)))
        floatingButtonAR.addTarget(self, action: #selector(tap_AR), for: .touchUpInside)
            view.addSubview(floatingButtonAR)
        view.addConstraint(NSLayoutConstraint(item: floatingButtonAR, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 100))
            view.addConstraint(NSLayoutConstraint(item: floatingButtonAR, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -280))
        }
    // ar 버튼 클릭시 실행
    @objc func tap_AR(_ sender: Any) {
        goARView()
    }

    
    func goARView(){
        let ARStoryboard = UIStoryboard.init(name : "AR", bundle : nil)
        guard let arViewC = ARStoryboard.instantiateViewController(identifier: "AR") as? ARViewController else {return}
        arViewC.modalPresentationStyle = .fullScreen
        arViewC.modalTransitionStyle = .crossDissolve
        
        self.floatingButton.removeFromSuperview() //버튼 삭제
        self.present(arViewC, animated: true, completion: nil)
    }

    
    //내 기기에 노티 띄우기
    private func generateUserNotification() { notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) {(granted, error) in
        if let error = error {
            print(error)
        }
        else {
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "알림"
                content.body = "설정구역을 벗어났습니다!"
                content.badge = 1
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)// 1초뒤 실행
                let request = UNNotificationRequest(identifier: "Sample Notification", content: content, trigger: trigger)
                self.notificationCenter.add(request, withCompletionHandler: nil)
                
            }
            else { print("Not Granted")
            }
            
        }
    }}

    // 서버에 토큰 보내기
    func insertToken(){
            InstanceID.instanceID().instanceID { (result, error) in
                let IP_ADDRESS_2 = (Value.sharedInstance().IP_ADDRESS)
                let UUID_2 = UIDevice.current.identifierForVendor?.uuidString
                       if let error = error {
                           print("Error fetching remote instance ID: \(error)")
                       } else if let result = result {
                           let request = NSMutableURLRequest(url: NSURL(string: "http://\(IP_ADDRESS_2)/insertToken.php")! as URL)
                           request.httpMethod = "POST"
                           let postString = "UUID=\(String(describing: UUID_2!))&Token=\(result.token)"
                           request.httpBody = postString.data(using: String.Encoding.utf8)
                           let task = URLSession.shared.dataTask(with: request as URLRequest) {
                                       data, response, error in

                                       if error != nil {
                                           print("error=\(String(describing: error))")
                                           return
                                       }
                                   }
                                   task.resume()
                       }
                    }
            
        }

    // 서버측에 uuid와 이름을 보내기
    func pushNoti(){
            let request = NSMutableURLRequest(url: NSURL(string: "http://\(IP_ADDRESS)/push.php")! as URL)
            request.httpMethod = "POST"
            let postString = "UUID=\(String(describing: UUID!))&name=\(name)"
            request.httpBody = postString.data(using: String.Encoding.utf8)

            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in

                        if error != nil {
                            print("error=\(String(describing: error))")
                            return
                        }
                    }
                    task.resume()
            
        }
}
