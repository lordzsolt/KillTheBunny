//
//  GameScene.swift
//  KillTheBunny
//
//  Created by Zsolt Kovacs on 06.11.19.
//  Copyright © 2019 Zsolt Kovacs. All rights reserved.
//

import SpriteKit

private enum BitMask {
	static let background: UInt32 = 0x01 << 0
	static let bunny: UInt32 = 0x01 << 1
	static let prize: UInt32 = 0x01 << 2
	static let obstacle: UInt32 = 0x01 << 3
}

class GameScene: SKScene {
	private static let backgroundName = "background"
	private static let bunnyName = "Bunny"
	private static let obstacleName = "Computer"
	private static let prizeName = "Carrot"

	private static let bunnyMass: CGFloat = 1
	private static let jumpImpulse = GameScene.bunnyMass * 600
	private static let obstacleSpeed: CGFloat = 5
	private static let obstacleFrequency: TimeInterval = 2
	private static let prizeFrequency: TimeInterval = 5

	private let bunny = SKSpriteNode(imageNamed: "\(GameScene.bunnyName)1")
	private let background = SKSpriteNode(imageNamed: GameScene.backgroundName)

	private var lastObstacleAdded: TimeInterval = -1
	private var lastPrizeAdded: TimeInterval = -1

	// These 2 methods are supposed to be helped methods to use game speed
	private func duration(_ duration: TimeInterval) -> TimeInterval {
		return duration
	}

	private func distance(_ distance: CGFloat) -> CGFloat {
		return distance
	}
}

// MARK: - Setup
extension GameScene {
	override func didMove(to view: SKView) {
		backgroundColor = .white

		// Prevent things from falling off the screen
//		physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)

		physicsWorld.speed = 1
		physicsWorld.contactDelegate = self

		isUserInteractionEnabled = true

		addBackground()
		addBunny()
	}

	func addBackground() {
		background.size = frame.size
		background.position = CGPoint(x: 0, y: 0)
		background.anchorPoint = .zero
		background.name = GameScene.backgroundName

		background.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
		background.physicsBody?.categoryBitMask = BitMask.background
		background.physicsBody?.restitution = 0

		addChild(background)
	}

	func addBunny() {
		let textures = (1 ... 8).map { "\(GameScene.bunnyName)\($0)" }.map(SKTexture.init)
		let bunnyAnimation = SKAction.animate(with: textures, timePerFrame: 0.05)

		bunny.size = CGSize(width: bunny.size.width * 0.3, height: bunny.size.height * 0.3)
		bunny.run(SKAction.repeatForever(bunnyAnimation))
		bunny.position = CGPoint(x: 0.001, y: 0.001)
		bunny.anchorPoint = CGPoint(x: 0.01, y: 0.01)
		bunny.name = GameScene.bunnyName

		bunny.physicsBody = SKPhysicsBody(rectangleOf: bunny.size)
		bunny.physicsBody?.restitution = 0
		bunny.physicsBody?.mass = GameScene.bunnyMass
		bunny.physicsBody?.categoryBitMask = BitMask.bunny
		bunny.physicsBody?.contactTestBitMask = BitMask.background | BitMask.prize | BitMask.obstacle
		bunny.physicsBody?.collisionBitMask = BitMask.background
		bunny.physicsBody?.usesPreciseCollisionDetection = true

		addChild(bunny)
	}

	func addObstacle() {
		let obstacle = SKSpriteNode(imageNamed: GameScene.obstacleName)
		obstacle.setScale(0.1)
		obstacle.name = GameScene.obstacleName

		obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
		obstacle.physicsBody?.isDynamic = true
		obstacle.physicsBody?.categoryBitMask = BitMask.obstacle
		obstacle.physicsBody?.affectedByGravity = false
		obstacle.physicsBody?.usesPreciseCollisionDetection = true
		obstacle.physicsBody?.contactTestBitMask = 0
		obstacle.physicsBody?.collisionBitMask = 0

		obstacle.position = CGPoint(x: frame.width + obstacle.size.width, y: 30)
		obstacle.anchorPoint = CGPoint(x: 0.01, y: 0.01)
		addChild(obstacle)
	}

	func addPrize() {
		let obstacle = SKSpriteNode(imageNamed: GameScene.prizeName)
		obstacle.setScale(0.25)
		obstacle.name = GameScene.prizeName

		obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
		obstacle.physicsBody?.isDynamic = true
		obstacle.physicsBody?.categoryBitMask = BitMask.prize
		obstacle.physicsBody?.affectedByGravity = false
		obstacle.physicsBody?.usesPreciseCollisionDetection = true
		obstacle.physicsBody?.contactTestBitMask = 0
		obstacle.physicsBody?.collisionBitMask = 0

		obstacle.position = CGPoint(x: frame.width + obstacle.size.width, y: 50)
		obstacle.anchorPoint = CGPoint(x: 0.01, y: 0.01)
		addChild(obstacle)
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		bunny.physicsBody?.applyImpulse(CGVector(dx: 0, dy: GameScene.jumpImpulse))
		isUserInteractionEnabled = false
	}
}

// MARK - Updating
extension GameScene {
	override func update(_ currentTime: TimeInterval) {
		if lastObstacleAdded < 0 {
			lastObstacleAdded = currentTime
		}

		if lastPrizeAdded < 0 {
			lastPrizeAdded = currentTime
		}

		moveObjects()

		if currentTime - lastObstacleAdded > GameScene.obstacleFrequency {
			lastObstacleAdded = currentTime + Double.random(in: 0...GameScene.obstacleFrequency)
			addObstacle()
		}

		if currentTime - lastPrizeAdded > GameScene.prizeFrequency {
			lastPrizeAdded = currentTime + Double.random(in: 0...GameScene.prizeFrequency)
			addPrize()
		}
	}

	private func moveObjects() {
		let updateBlock: ((SKNode, UnsafeMutablePointer<ObjCBool>) -> Void) = { obstacle, stop in
			guard let obstacle = obstacle as? SKSpriteNode else { return }
			obstacle.position = CGPoint(x: obstacle.position.x - self.distance(GameScene.obstacleSpeed), y: obstacle.position.y)

			if obstacle.position.x <= -obstacle.size.width {
				obstacle.removeFromParent()
			}
		}

		enumerateChildNodes(withName: GameScene.obstacleName, using: updateBlock)
		enumerateChildNodes(withName: GameScene.prizeName, using: updateBlock)
	}


}

extension GameScene: SKPhysicsContactDelegate {
	func didBegin(_ contact: SKPhysicsContact) {
		let isBunny = contact.bodyA.categoryBitMask == BitMask.bunny || contact.bodyB.categoryBitMask == BitMask.bunny
		let isBackground = contact.bodyA.categoryBitMask == BitMask.background || contact.bodyB.categoryBitMask == BitMask.background
		let isObstacle = contact.bodyA.categoryBitMask == BitMask.obstacle || contact.bodyB.categoryBitMask == BitMask.obstacle
		let isPrize = contact.bodyA.categoryBitMask == BitMask.prize || contact.bodyB.categoryBitMask == BitMask.prize

		if isBunny, isBackground {
			isUserInteractionEnabled = true
		}

		if isBunny, isObstacle {
			print("You died")
		}

		if isBunny, isPrize {
			print("You levelled up")
		}
	}
}
