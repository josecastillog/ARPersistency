//
//  ARViewController.swift
//  ARPersistencySwiftUI
//
//  Created by Jose Castillo on 2/8/23.
//

import UIKit
import ARKit
import RealityKit
import Combine

#if !targetEnvironment(simulator)
class ARViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    var model = Entity()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        self.model = try! Entity.load(named: "toy_drummer")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var raycastAnchors: [AnchorEntity] = []

    @objc func handleTap(gesture: UITapGestureRecognizer) {
        guard let query = arView.makeRaycastQuery(from: gesture.location(in: self.arView), allowing: .existingPlaneInfinite, alignment: .any)
        else { return }
        
        guard let result = arView.session.raycast(query).first
                
        else { return }
        
        let newModel = model.clone(recursive: true)
        let raycastAnchor = AnchorEntity(world: result.worldTransform)
        raycastAnchor.addChild(newModel)
        arView.scene.addAnchor(raycastAnchor)
    }


}

extension ARViewController {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("didAdd")
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("didRemove")
    }
    
}
#endif
