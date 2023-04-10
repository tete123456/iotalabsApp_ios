
import RealityKit
import MaterialComponents.MaterialButtons
import CoreLocation
import ARKit
import ARCL
import RealmSwift

class ARViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate & LNTouchDelegate & UIGestureRecognizerDelegate {
    

    @IBOutlet weak var view1: UIView!
    //@IBOutlet weak var arkit: ARView!
    let floatingButton = MDCFloatingButton() // 종료
    let floatingButton_s = MDCFloatingButton() // 캡쳐
    let floatingButton_g = MDCFloatingButton() // 공유
    let boxAnchor = try! TestAR.loadBox()
    var sceneLocationView = SceneLocationView()
    var AR_inside :Bool = false
    var str_latitude : String = ""
    var str_longitude : String = ""
    var ar_chek :Bool = true // ar 중복방지
    var timer : Timer?
    var imageView = UIImageView()
    var previousLoc = CGPoint.init(x: 0, y: 0)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //진북 보정
        sceneLocationView.moveSceneHeadingClockwise()
        sceneLocationView.moveSceneHeadingAntiClockwise()
        
        //동작
        sceneLocationView.run()
        view1 = sceneLocationView
        //view = view1
        self.view.addSubview(view1)
        self.sceneLocationView.locationNodeTouchDelegate = self
        
        setFloatingButton_s()
        setFloatingButton_g()
        setFloatingButton()

        startTimer()
    }
    
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()

      sceneLocationView.frame = view.bounds
    }
    
    
    func startTimer(){
        //기존에 타이머 동작중이면 중지 처리
        if timer != nil && timer!.isValid {
            timer!.invalidate()
        }
            
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(createAR), userInfo: nil, repeats: true)
    }
    
    @objc func createAR() {
        let realm = try! Realm()
        let mydata = realm.objects(me.self)
        //===========================================================================================
        //ar위치정보 추가
                let coordinate = CLLocationCoordinate2D(latitude: 37.305186, longitude: 126.831107)
                let location = CLLocation(coordinate: coordinate, altitude: 2)
        //ar이미지 추가
                let image1: UIImage? = UIImage(named:"pokemon.png")!
        //노드생성
                let annotationNode = LocationAnnotationNode(location: location, image: image1!)
        //============================================================================================
        
        print(mydata[0].AR_place)
        //ar_chek 는 기본값으로 True
        if ar_chek{
            
            if mydata[0].AR_place == "true"{
                    print("AR띄우기!!!!!!!!!!")

            //씬뷰에 노드 추가
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
                //
                let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
                let material = SCNMaterial()
                material.diffuse.contents = UIImage(named : "brick.jpg")
                let node = SCNNode()
                node.geometry = box
                node.geometry?.materials = [material]
                node.position = SCNVector3(-0.1, 0.1, -0.5)
                let scene = SCNScene()
                scene.rootNode.addChildNode(node)
                
                sceneLocationView.scene.rootNode.addChildNode(node)
                //
                
                buildDemoData().forEach {
                    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0)
                }
                
                    ar_chek = false
            }
        }
        else{
            if mydata[0].AR_place == "false"{
                print("AR지우기!!!!!!!!!!")
                
                //해당되는 ar노드 지우기
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                  // 1초 후 실행될 부분
                    self.sceneLocationView.removeAllNodes()
                    
                    self.ar_chek = true
                }
                
            }
        }
    }
    //노드 생성
    func buildDemoData() -> [LocationAnnotationNode] {
        var nodes: [LocationAnnotationNode] = []

        let theAlamo = buildViewNode(latitude: 37.305186, longitude: 126.831107, altitude: 30, text: "The Alamo")
        //nodes.append(theAlamo)

        let pikesPeakLayer = CATextLayer()
        pikesPeakLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        pikesPeakLayer.cornerRadius = 4
        pikesPeakLayer.fontSize = 14
        pikesPeakLayer.alignmentMode = .center
        pikesPeakLayer.foregroundColor = UIColor.black.cgColor
        pikesPeakLayer.backgroundColor = UIColor.white.cgColor

        // This demo uses a simple periodic timer to showcase dynamic text in a node.  In your implementation,
        // the view's content will probably be changed as the result of a network fetch or some other asynchronous event.

        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            pikesPeakLayer.string = "Pike's Peak\n" + Date().description
        }

        let pikesPeak = buildLayerNode(latitude: 37.305186, longitude: 126.831107, altitude: 45, layer: pikesPeakLayer)
        nodes.append(pikesPeak)

        return nodes
    }
    //노드 틀
     //- 이미지
    func buildNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                   altitude: CLLocationDistance, imageName: String) -> LocationAnnotationNode {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: altitude)
        let image = UIImage(named: imageName)!
        return LocationAnnotationNode(location: location, image: image)
    }
    //- 텍스트박스
    func buildViewNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                       altitude: CLLocationDistance, text: String) -> LocationAnnotationNode {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: altitude)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.text = text
        label.backgroundColor = .green
        label.textAlignment = .center
        return LocationAnnotationNode(location: location, view: label)
    }
     //-
    func buildLayerNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                        altitude: CLLocationDistance, layer: CALayer) -> LocationAnnotationNode {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: altitude)
        return LocationAnnotationNode(location: location, layer: layer)
    }
    
    //scene노드 터치 이벤트
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
   {
    let touch = touches.first!
    let location = touch.location(in: sceneLocationView)
    let hitResults = sceneLocationView.hitTest(location, options: nil)
    if let result = hitResults.first {
         handleTouchFor(node: result.node)
        }
     }
    func handleTouchFor(node: SCNNode) {
        print(node.name,"877778777787778777")
    }
    
    //로케이션노드 터치 이벤트
    func locationNodeTouched(node: LocationNode) {
        guard let name = node.tag else { return }
        guard let selectedNode = node.childNodes.first(where: { $0.geometry is SCNBox }) else { return }
        
        print(name," +++++++ ",selectedNode)
        // Interact with the selected node
    }
    func annotationNodeTouched(node: AnnotationNode) {
        // Do stuffs with the node instance
        
        // node could have either node.view or node.image
        if let nodeView = node.view{
            // Do stuffs with the nodeView
            // ...
            print("저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!저기요잠시만요!!")
        }
        if let nodeImage = node.image{
            // Do stuffs with the nodeImage
            // ...
            print("이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요이건좀아니라고생각해요"," + ",nodeImage)
            
            let image1: UIImage? = UIImage(named:"logo.png")!
            node.image = image1
        }
    }

    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            print("dasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsddasfdjakshlkjfsd")
            // retrieve the SCNView
        let view = sceneLocationView
            // check what nodes are tapped
            let p = gestureRecognize.location(in: view)
            let hitResults = view.hitTest(p, options: [:])
            // check that we clicked on at least one object
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result = hitResults[0]
         
                // get material for selected geometry element
                let material = result.node.geometry!.materials[(result.geometryIndex)]
                // highlight it
                SCNTransaction.begin()
               SCNTransaction.animationDuration = 0.5
                // on completion - unhighlight
                SCNTransaction.completionBlock = {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.5
                    
                    material.emission.contents = UIColor.black
                    
                    SCNTransaction.commit()
                }
                
                material.emission.contents = UIColor.green
                
                SCNTransaction.commit()
            }
        }
     
    
    
    //종료버튼 ar내에서 작동
    func setFloatingButton() {
            let image = UIImage(systemName: "xmark")
            floatingButton.sizeToFit()
            floatingButton.translatesAutoresizingMaskIntoConstraints = false
            floatingButton.setImage(image, for: .normal)
            floatingButton.setImageTintColor(.white, for: .normal)
            floatingButton.backgroundColor = .systemRed
            floatingButton.addTarget(self, action: #selector(tap), for: .touchUpInside)
            view.addSubview(floatingButton)
            view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -80))
            view.addConstraint(NSLayoutConstraint(item: floatingButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -280))
    }
    @objc func tap(_ sender: Any) {
        // 모든 ar 노드 지우기
        sceneLocationView.removeAllNodes()
        //타이머 종료
        timer?.invalidate()
        timer = nil
        floatingButton.removeFromSuperview()
        floatingButton_s.removeFromSuperview()
        self.dismiss(animated:true)
    }
    
    
    
    //스크린샷버튼 ar내에서 작동
    func setFloatingButton_s() {
            let image = UIImage(systemName: "camera.fill")
        floatingButton_s.sizeToFit()
        floatingButton_s.translatesAutoresizingMaskIntoConstraints = false
        floatingButton_s.setImage(image, for: .normal)
        floatingButton_s.setImageTintColor(.white, for: .normal)
        floatingButton_s.backgroundColor = .darkGray
        floatingButton_s.addTarget(self, action: #selector(tap_s), for: .touchUpInside)
            view.addSubview(floatingButton_s)
            view.addConstraint(NSLayoutConstraint(item: floatingButton_s, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -700))
            view.addConstraint(NSLayoutConstraint(item: floatingButton_s, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        }
    @objc func tap_s(_ sender: Any) {
        //현재 화면 캡쳐 후 저장
        let s_image = sceneLocationView.snapshot()
        UIImageWriteToSavedPhotosAlbum(s_image, nil, nil, nil)

        //토스트메세지
        self.showToast(message: "사진을 저장하였습니다!!")
    }
    
    
    //공유버튼 ar내에서 작동
    func setFloatingButton_g() {
            let image = UIImage(systemName: "square.and.arrow.up.fill")
        floatingButton_g.sizeToFit()
        floatingButton_g.translatesAutoresizingMaskIntoConstraints = false
        floatingButton_g.setImage(image, for: .normal)
        floatingButton_g.setImageTintColor(.white, for: .normal)
        floatingButton_g.backgroundColor = .lightGray
        floatingButton_g.addTarget(self, action: #selector(tap_g), for: .touchUpInside)
            view.addSubview(floatingButton_g)
            view.addConstraint(NSLayoutConstraint(item: floatingButton_g, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -620))
            view.addConstraint(NSLayoutConstraint(item: floatingButton_g, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -20))
        }
    @objc func tap_g(_ sender: Any) {
        uploadPhoto()
    }
    
    //공유하기 기능
    @objc func uploadPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    //uploadPhoto 함수의 imagePicker 기능 구현
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                imageView.image = pickedImage
            
                var objectsToShare = [Any]()
                objectsToShare.append(pickedImage)
            
                let activityVC = UIActivityViewController(activityItems:objectsToShare ,applicationActivities: nil)
                   activityVC.popoverPresentationController?.sourceView = self.view
                dismiss(animated: true, completion: nil)
                self.present(activityVC, animated: true, completion: nil)
            }
        dismiss(animated: true, completion: nil)
        }
    //취소시 내리기
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    

    
    //토스트 메세지
    func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 10.0, delay: 0.1, options: .curveEaseOut, animations: { toastLabel.alpha = 0.0 }, completion: {(isCompleted) in toastLabel.removeFromSuperview() })
        
    }

}

