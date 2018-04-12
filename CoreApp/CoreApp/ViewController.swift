//
//  ViewController.swift
//  CoreApp
//
//  Created by Andrew Finke on 4/11/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - Properties

    @IBOutlet var sceneView: ARSCNView!

    // add items to last plane
    private var lastPlane: SCNNode?

    // blocks main thread until fetched all items
    private let lostItemDiffs = LostItemManager.lostItemDiffs()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!

        // Set the scene to the view
        sceneView.scene = scene

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        sceneView.addGestureRecognizer(gestureRecognizer)

        scene.physicsWorld.gravity = SCNVector3(0.0, -0.6, 0.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - Helpers

    @objc func tap() {
        var nodes = [SCNNode]()
        for item in lostItemDiffs {
            for var i in 0..<item.diff {
                let node = emojiNode(string: item.emoji)
                nodes.append(node)
            }
        }

        func qRand() -> CGFloat {
            return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        }

        for (index, node) in nodes.enumerated() {
            node.position = SCNVector3(0, 0, qRand() + 0.75)
            lastPlane?.addChildNode(node)
        }
    }

    // P4: should just make copy of existing node and replace material
    func emojiNode(string: String) -> SCNNode {
        let emojiSize = CGSize(width: 50, height: 50)
        let emojiRect = CGRect(origin: .zero, size: emojiSize)
        let emojiRenderer = UIGraphicsImageRenderer(size: emojiSize)

        let emojiImage = emojiRenderer.image { context in
            UIColor.black.setFill()
            context.fill(emojiRect)
            let text = string
            let attributes = [
                NSAttributedStringKey.font: UIFont.systemFont(ofSize: 45)
            ]
            text.draw(in: emojiRect, withAttributes: attributes)
        }

        let emptyMaterial = SCNMaterial()
        emptyMaterial.diffuse.contents = UIColor.darkGray

        let emojiMaterial = SCNMaterial()
        emojiMaterial.diffuse.contents = emojiImage

        let backEmojiMaterial = SCNMaterial()
        backEmojiMaterial.diffuse.contents = emojiImage
        backEmojiMaterial.diffuse.contentsTransform =
            SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)

        let emojiBox = SCNBox(width: 0.05, height: 0.005, length: 0.05, chamferRadius: 0.1)
        emojiBox.materials = [
            emptyMaterial,
            emptyMaterial,
            emptyMaterial,
            emptyMaterial,
            backEmojiMaterial,
            emojiMaterial
        ]

        let emojiNode = SCNNode(geometry: emojiBox)
        let emojiShape = SCNPhysicsShape(geometry: emojiBox, options: nil)
        let emojiBody = SCNPhysicsBody(type: .dynamic,
                                       shape: emojiShape)

        emojiBody.mass = 50
        emojiNode.physicsBody = emojiBody

        return emojiNode
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        plane.materials.first?.diffuse.contents = UIColor.clear

        let planeNode = SCNNode(geometry: plane)
        let planeShape = SCNPhysicsShape(node: planeNode, options: nil)
        planeNode.physicsBody = SCNPhysicsBody(type: .static,
                                               shape: planeShape)

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2

        node.addChildNode(planeNode)
        self.lastPlane = planeNode

        // indicate plane added
        sceneView.showsStatistics = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.sceneView.showsStatistics = true
        }

    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y - 0.075)
        let z = CGFloat(planeAnchor.center.z - 0.0)
        planeNode.position = SCNVector3(x, y, z)
    }

}

