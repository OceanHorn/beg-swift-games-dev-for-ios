import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var backgroundNode : SKSpriteNode?
    var backgroundStarsNode  : SKSpriteNode?
    var backgroundPlanetNode : SKSpriteNode?
    var foregroundNode  : SKSpriteNode?
    var playerNode : SKSpriteNode?
    
    var impulseCount = 4
    let coreMotionManager = CMMotionManager()
    var xAxisAcceleration : CGFloat = 0.0
    
    let CollisionCategoryPlayer     : UInt32 = 0x1 << 1
    let CollisionCategoryPowerUpOrbs : UInt32 = 0x1 << 2
    let CollisionCategoryBlackHoles : UInt32 = 0x1 << 3

    var engineExhaust : SKEmitterNode?
    
    var score = 0
    let scoreTextNode = SKLabelNode(fontNamed: "Copperplate")
    let impulseTextNode = SKLabelNode(fontNamed: "Copperplate")
    
    let orbPopAction = SKAction.playSoundFileNamed("orb_pop.wav", waitForCompletion: false)
    
    let startGameTextNode = SKLabelNode(fontNamed: "Copperplate")
    
    required init?(coder aDecoder: NSCoder) {
    
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
    
        super.init(size: size)
        
        physicsWorld.contactDelegate = self
    
        physicsWorld.gravity = CGVectorMake(0.0, -5.0);
        
        backgroundColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
        userInteractionEnabled = true
        
        // adding the background
        backgroundNode = SKSpriteNode(imageNamed: "Background")
        backgroundNode!.size.width = self.frame.size.width
        backgroundNode!.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundNode!.position = CGPoint(x: size.width / 2.0, y: 0.0)
        addChild(backgroundNode!)
        
        backgroundStarsNode = SKSpriteNode(imageNamed: "Stars")
        backgroundStarsNode!.size.width = self.frame.size.width
        backgroundStarsNode!.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundStarsNode!.position = CGPoint(x: size.width / 2.0, y: 0.0)
        addChild(backgroundStarsNode!)
        
        backgroundPlanetNode = SKSpriteNode(imageNamed: "PlanetStart")
        backgroundPlanetNode!.size.width = self.frame.size.width
        backgroundPlanetNode!.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundPlanetNode!.position = CGPoint(x: size.width / 2.0, y: 0.0)
        addChild(backgroundPlanetNode!)
        
        foregroundNode = SKSpriteNode()
        addChild(foregroundNode!)
        
        // add the player
        playerNode = SKSpriteNode(imageNamed: "Player")
        
        playerNode!.physicsBody =
            SKPhysicsBody(circleOfRadius: playerNode!.size.width / 2)
        playerNode!.physicsBody!.dynamic = false
        
        playerNode!.position = CGPoint(x: size.width / 2.0, y: 220.0)
        playerNode!.physicsBody!.linearDamping = 1.0
        playerNode!.physicsBody!.allowsRotation = false
        playerNode!.physicsBody!.categoryBitMask = CollisionCategoryPlayer
        playerNode!.physicsBody!.contactTestBitMask =
            CollisionCategoryPowerUpOrbs | CollisionCategoryBlackHoles
        playerNode!.physicsBody!.collisionBitMask = 0
        
        foregroundNode!.addChild(playerNode!)
        
        addBlackHolesToForeground()
        addOrbsToForeground()
        
        let engineExhaustPath = NSBundle.mainBundle().pathForResource("EngineExhaust", ofType: "sks")
        engineExhaust = NSKeyedUnarchiver.unarchiveObjectWithFile(engineExhaustPath!) as? SKEmitterNode;
        engineExhaust!.position = CGPointMake(0.0, -(playerNode!.size.height / 2));
        playerNode!.addChild(engineExhaust!)
        engineExhaust!.hidden = true;
        
        scoreTextNode.text = "SCORE : \(score)"
        scoreTextNode.fontSize = 20
        scoreTextNode.fontColor = SKColor.whiteColor()
        scoreTextNode.position =
            CGPointMake(size.width - 10, size.height - 20)
        scoreTextNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        
        addChild(scoreTextNode)
        
        impulseTextNode.text = "IMPULSES : \(impulseCount)"
        impulseTextNode.fontSize = 20
        impulseTextNode.fontColor = SKColor.whiteColor()
        impulseTextNode.position = CGPointMake(10.0, size.height - 20)
        impulseTextNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        addChild(impulseTextNode)
        
        startGameTextNode.text = "TAP ANYWHERE TO START!"
        startGameTextNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        startGameTextNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        startGameTextNode.fontSize = 20
        startGameTextNode.fontColor = SKColor.whiteColor()
        startGameTextNode.position =
            CGPoint(x: scene!.size.width / 2, y: scene!.size.height / 2)
        addChild(startGameTextNode)
    }
    
    func addOrbsToForeground() {
        
        var orbNodePosition = CGPoint(x: playerNode!.position.x, y: playerNode!.position.y + 100)
        var orbXShift : CGFloat = -1.0
        
        for _ in 1...50 {
            
            var orbNode = SKSpriteNode(imageNamed: "PowerUp")
            
            if orbNodePosition.x - (orbNode.size.width * 2) <= 0 {
                
                orbXShift = 1.0
            }
            
            if orbNodePosition.x + orbNode.size.width >= size.width {
                
                orbXShift = -1.0
            }
            
            orbNodePosition.x += 40.0 * orbXShift
            orbNodePosition.y += 120
            orbNode.position = orbNodePosition
            orbNode.physicsBody = SKPhysicsBody(circleOfRadius: orbNode.size.width / 2)
            orbNode.physicsBody!.dynamic = false
            
            orbNode.physicsBody!.categoryBitMask = CollisionCategoryPowerUpOrbs
            orbNode.physicsBody!.collisionBitMask = 0
            orbNode.name = "POWER_UP_ORB"
            
            foregroundNode!.addChild(orbNode)
        }
    }
    
    func addBlackHolesToForeground() {
        
        let textureAtlas = SKTextureAtlas(named: "sprites.atlas")
        
        let frame0 = textureAtlas.textureNamed("BlackHole0")
        let frame1 = textureAtlas.textureNamed("BlackHole1")
        let frame2 = textureAtlas.textureNamed("BlackHole2")
        let frame3 = textureAtlas.textureNamed("BlackHole3")
        let frame4 = textureAtlas.textureNamed("BlackHole4")
        
        let blackHoleTextures = [frame0, frame1, frame2, frame3, frame4]
        
        let animateAction =
            SKAction.animateWithTextures(blackHoleTextures, timePerFrame: 0.2)
        let rotateAction = SKAction.repeatActionForever(animateAction)
        
        let moveLeftAction = SKAction.moveToX(0.0, duration: 2.0)
        let moveRightAction = SKAction.moveToX(size.width, duration: 2.0)
        let actionSequence = SKAction.sequence([moveLeftAction, moveRightAction])
        let moveAction = SKAction.repeatActionForever(actionSequence)
        
        for i in 1...10 {
            
            var blackHoleNode = SKSpriteNode(imageNamed: "BlackHole0")
            
            blackHoleNode.position = CGPoint(x: size.width - 80.0, y: 600.0 * CGFloat(i))
            blackHoleNode.physicsBody = SKPhysicsBody(circleOfRadius: blackHoleNode.size.width / 2)
            blackHoleNode.physicsBody!.dynamic = false
            blackHoleNode.physicsBody!.categoryBitMask = CollisionCategoryBlackHoles
            blackHoleNode.physicsBody!.collisionBitMask = 0
            blackHoleNode.name = "BLACK_HOLE"
            
            blackHoleNode.runAction(moveAction)
            blackHoleNode.runAction(rotateAction)
            
            foregroundNode!.addChild(blackHoleNode)
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if !playerNode!.physicsBody!.dynamic {
            
            startGameTextNode.removeFromParent()
            
            playerNode!.physicsBody!.dynamic = true
            
            coreMotionManager.accelerometerUpdateInterval = 0.3
            coreMotionManager.startAccelerometerUpdatesToQueue(NSOperationQueue(),
                withHandler: {
                    
                    (data: CMAccelerometerData!, error: NSError!) in
                    
                    if let constVar = error {
                        
                        println("There was an error")
                    }
                    else {
                        
                        self.xAxisAcceleration = CGFloat(data!.acceleration.x)
                    }
            })
        }
        
        if impulseCount > 0 {
            
            playerNode!.physicsBody!.applyImpulse(CGVectorMake(0.0, 40.0))
            
            impulseCount--
            impulseTextNode.text = "IMPULSES : \(impulseCount)"
            
            engineExhaust!.hidden = false
            
            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self,
                selector: "hideEngineExaust:", userInfo: nil, repeats: false)
        }
    }

    func didBeginContact(contact: SKPhysicsContact) {
        
        var nodeB = contact.bodyB!.node!
        
        if nodeB.name == "POWER_UP_ORB"  {
            
            self.runAction(orbPopAction)
            
            self.impulseCount++
            self.impulseTextNode.text = "IMPULSES : \(self.impulseCount)"
            
            self.score++
            self.scoreTextNode.text = "SCORE : \(self.score)"
            
            nodeB.removeFromParent()
        }
        else if nodeB.name == "BLACK_HOLE"  {
            
            playerNode!.physicsBody!.contactTestBitMask = 0
            impulseCount = 0
            
            var colorizeAction = SKAction.colorizeWithColor(UIColor.redColor(),
                colorBlendFactor: 1.0, duration: 1)
            playerNode!.runAction(colorizeAction)
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if playerNode != nil {
            
            if playerNode!.position.y >= 180.0
                && playerNode!.position.y < 6400.0 {
                    
                backgroundNode!.position =
                    CGPointMake(self.backgroundNode!.position.x,
                        -((playerNode!.position.y - 180.0)/8));
                    
                backgroundStarsNode!.position =
                    CGPointMake(self.backgroundStarsNode!.position.x,
                        -((playerNode!.position.y - 180.0)/6));
                    
                backgroundPlanetNode!.position =
                    CGPointMake(backgroundPlanetNode!.position.x,
                        -((playerNode!.position.y - 180.0)/8));
                    
                foregroundNode!.position =
                    CGPointMake(self.foregroundNode!.position.x,
                        -(playerNode!.position.y - 180.0));
            }
            else if playerNode!.position.y > 7000.0 {
                
                gameOverWithResult(true)
            }
            else if playerNode!.position.y + playerNode!.size.height < 0.0 {
                
                gameOverWithResult(false)
            }
        }
    }
    
    func gameOverWithResult(gameResult: Bool) {
        
        playerNode!.removeFromParent()
        playerNode = nil
        
        let transition = SKTransition.crossFadeWithDuration(2.0)
        let menuScene = MenuScene(size: size,
            gameResult: gameResult,
            score: score)
        
        view?.presentScene(menuScene, transition: transition)
    }
    
    override func didSimulatePhysics() {
        
        if playerNode != nil {
            
            playerNode!.physicsBody!.velocity =
                CGVectorMake(xAxisAcceleration * 380.0,
                    playerNode!.physicsBody!.velocity.dy)
            
            if playerNode!.position.x < -(playerNode!.size.width / 2) {
                
                playerNode!.position = CGPoint(x: size.width - playerNode!.size.width / 2, y: playerNode!.position.y)
            }
            else if playerNode!.position.x > size.width {
                
                playerNode!.position =
                    CGPoint(x: playerNode!.size.width / 2,
                        y: playerNode!.position.y)
            }
        }
    }
    
    deinit {
        
        self.coreMotionManager.stopAccelerometerUpdates()
    }
    
    func hideEngineExaust(timer:NSTimer!) {
        
        if !engineExhaust!.hidden {
            
            engineExhaust!.hidden = true
        }
    }
}
