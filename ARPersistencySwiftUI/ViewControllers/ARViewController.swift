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
import CoreData

#if !targetEnvironment(simulator)
class ARViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var arView: ARView!
    
    var model = Entity()
    var anchorMetaData = Set<UUID>()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // RealityKit Config
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        arView.session.delegate = self
        // Loads sample model (USDZ)
        self.model = try! Entity.load(named: "toy_drummer")
        // Gesture recognizer config
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
        // Config buttons
        saveButton.layer.cornerRadius = 10
        loadButton.layer.cornerRadius = 10
        if mapDataFromFile != nil {
            self.loadButton.isHidden = false
        }
        saveButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Add AnchorEntity to arView
    
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
    
    // MARK: - Persistence: Saving and Loading
    
    @IBAction func loadButton(_ sender: Any) {
        // Load screenshot on screen
        do {
            let items = try context.fetch(Screenshot.fetchRequest())
            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: items.last!.screenshot!)
                self.imageView.isHidden = false
            }
        } catch {
            print("Unable to load Screenshot")
        }
        // Load world map to scene
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        // Reset arView to loaded state
        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.isRelocalizingMap = true
    }
    
    @IBAction func saveButton(_ sender: Any) {
        // Deactivate save button
        self.saveButton.isEnabled = false
        // Save screenshot
        arView.snapshot(saveToHDR: false) { image in
            // Compress the image
            let compressedImage = UIImage(data: (image?.pngData())!)
            // Save in CoreData
            let newImage = Screenshot(context: self.context)
            newImage.screenshot = compressedImage?.pngData()
            do {
                try self.context.save()
            } catch {
                print("Unable to save image into CoreData")
            }
        }
        // Save world map
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { self.showAlert(title: "Can't get current world map", message: error!.localizedDescription); return }
            
            // Add a snapshot image indicating where the map was captured.
            // Capture Screenshot
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.mapSaveURL, options: [.atomic])
                DispatchQueue.main.async {
                    self.loadButton.isEnabled = true
                }
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - AR session managment
    
    var isRelocalizingMap = false
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    // This switch can be modified to just detect the space in MARCO KIDS main app
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        imageView.isHidden = true
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            message = "Tap 'Save Experience' to save the current map."
            self.saveButton.isEnabled = true
        case (.normal, _) where mapDataFromFile != nil && !isRelocalizingMap:
            message = "Move around to map the environment or tap 'Load Experience' to load a saved experience."
        case (.normal, _) where mapDataFromFile == nil:
            message = "Move around to map the environment."
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            imageView.isHidden = false
        default:
            message = trackingState.localizedFeedback
        }
        sessionInfoLabel.text = message
    }

}

#endif
