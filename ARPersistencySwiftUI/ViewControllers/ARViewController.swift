//
//  ARViewController.swift
//  ARPersistencySwiftUI
//
//  Created by Jose Castillo on 2/8/23.
//

import UIKit
import ARKit
import RealityKit

#if !targetEnvironment(simulator)
class ARViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func placeModel() {
        guard let drummer = try? Entity.load(named: "toy_drummer") else { return }
        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(drummer)
        arView.scene.anchors.append(anchor)
        for animation in drummer.availableAnimations {
            drummer.playAnimation(animation.repeat())
        }
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
