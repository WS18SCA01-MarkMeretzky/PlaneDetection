//
//  ViewController.swift
//  PlaneDetection
//
//  Created by Mark Meretzky on 1/14/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;
import SceneKit;
import ARKit;

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Set the view's delegate.
        sceneView.delegate = self;
        
        // Show statistics such as fps and timing information.
        sceneView.showsStatistics = true;
        
        sceneView.debugOptions = [
            .showFeaturePoints,   //page 472: lots of yellow dots
            .showWorldOrigin      //red, green, blue axes
        ];
        
        // Create a new scene.
        guard let scene: SCNScene = SCNScene(named: "art.scnassets/ship.scn") else {
            fatalError("Unable to load scene file art.scnassets/ship.scn.");
        }
        
        // Set the scene to the view
        sceneView.scene = scene;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // Create a session configuration.
        let configuration: ARWorldTrackingConfiguration = ARWorldTrackingConfiguration();
        
        // Enable horizontal plane detection.
        configuration.planeDetection = [.horizontal];   //page 473

        // Run the view's session.
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        // Pause the view's session
        sceneView.session.pause();
    }

    // MARK: - ARSCNViewDelegate
    
    //Called when the app recognizes a new plane and creates a new node at that plane.
    //We will attach our own nodes to this node at lines 73 and 76.
    //The anchor contains information about the new plane.
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) { //p. 475
        
        guard let planeAnchor: ARPlaneAnchor = anchor as? ARPlaneAnchor else {
            return; //We're interested only in plane anchors, not oyther kinds of anchors.
        }
        
        let floor: SCNNode = createFloor(planeAnchor: planeAnchor); //argument added, p. 477
        node.addChildNode(floor);   //p. 476
        
        let ship: SCNNode = createShip(planeAnchor: planeAnchor);
        node.addChildNode(ship);    //p. 480
        
        var alignmentName: String = "";
        
        switch planeAnchor.alignment {
        case .horizontal:
            alignmentName = "horizontal";   //perpendicular to gravity
        case .vertical:
            alignmentName = "vertical";     //parallel to gravity
        }
        
        //Get the position of the plane's anchor.
        let column3: simd_float4 = planeAnchor.transform.columns.3;
        let anchorPosition: SCNVector3 = SCNVector3(column3.x, column3.y, column3.z);
        
        print(String(format: "A new %.2f by %.2f %@ plane discovered at altitude %.2f",
            planeAnchor.extent.x, planeAnchor.extent.z, alignmentName, anchorPosition.y), terminator: "");
        
        if ARPlaneAnchor.isClassificationSupported {   //only on some devices
            let classificationName: String;
            switch planeAnchor.classification {
            case .none:
                classificationName = "none";
            case .wall:
                classificationName = "wall";
            case .floor:
                classificationName = "floor";
            case .ceiling:
                classificationName = "ceiling";
            case .table:
                classificationName = "table";
            case .seat:
                classificationName = "seat";
            }
            print(" (\(classificationName))");
        }
        
        print(".");
    }

    //Page 479: update a node created by createFloor or createShip.

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor: ARPlaneAnchor = anchor as? ARPlaneAnchor else {
            return;      //We're interested only in plane anchors.
        }
        
        for node in node.childNodes {   //p. 481
            node.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z);
            if let plane: SCNPlane = node.geometry as? SCNPlane {
                plane.width = CGFloat(planeAnchor.extent.x);
                plane.height = CGFloat(planeAnchor.extent.z);
            }
        }
    }
    
    func createFloor(planeAnchor: ARPlaneAnchor) -> SCNNode {   //pp. 476, 477
        let geometry: SCNPlane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z));
        
        //Create, configure, and return the node.
        let node: SCNNode = SCNNode();
        node.geometry = geometry;
        node.eulerAngles.x = -Float.pi / 2;   //Make the plane horizontal.
        node.opacity = 0.25;
        return node;
    }
    
    func createShip(planeAnchor: ARPlaneAnchor) -> SCNNode {   //p. 480
        guard let scene: SCNScene = SCNScene(named: "art.scnassets/ship.scn") else {
            fatalError("Unable to load scene file art.scnassets/ship.scn.");
        }
        
        let node: SCNNode = scene.rootNode.clone();
        node.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z);
        return node;
    }
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
