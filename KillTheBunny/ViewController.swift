//
//  ViewController.swift
//  KillTheBunny
//
//  Created by Zsolt Kovacs on 06.11.19.
//  Copyright © 2019 Zsolt Kovacs. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let scene = GameScene(size: view.frame.size)

		(view as! SKView).presentScene(scene)
	}

	override var prefersStatusBarHidden: Bool {
		return true
	}
}

