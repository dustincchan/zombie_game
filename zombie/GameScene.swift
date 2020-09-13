import SpriteKit

class GameScene: SKScene {
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    var zombieInvincible = false
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var clickLocation: CGPoint?
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat", waitForCompletion: false)
    let catMovePointsPerSec: CGFloat = 480.0
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady", waitForCompletion: false)
    
    var lives = 5
    var gameOver = false
    
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0
    
    override init(size: CGSize) {
        zombie.name = "zombie"
        zombie.zPosition = 100
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
    
        var textures: [SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    func loseCats() {
        // 1
        var loseCount = 0
        enumerateChildNodes(withName: "train") { node, stop in
        // 2
        var randomSpot = node.position
        randomSpot.x += CGFloat.random(min: -100, max: 100)
        randomSpot.y += CGFloat.random(min: -100, max: 100) // 3
        node.name = ""
        node.run(
        SKAction.sequence([ SKAction.group([
            SKAction.rotate(byAngle: π*4, duration: 1.0),
            SKAction.move(to: randomSpot, duration: 1.0),
            SKAction.scale(to: 0, duration: 1.0)
        ]), SKAction.removeFromParent()
        ]))
        // 4
            loseCount += 1
            if loseCount >= 2 {
              stop[0] = true
            }
        }
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        enumerateChildNodes(withName: "train") { node, stop in
            trainCount += 1
          if !node.hasActions() {
            let actionDuration = 0.3
            let offset = targetPosition - node.position
            let direction = offset.normalized()
            let amountToMovePerSec = direction * self.catMovePointsPerSec
            let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
            let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
            node.run(moveAction)
          }
          targetPosition = node.position
        }
        
        if trainCount >= 8 && !gameOver {
            gameOver = true
            print("You Win!")
            
            revealGameOverScene(won: true)
        }
    }
    
    func revealGameOverScene(won: Bool) {
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.scaleMode = scaleMode
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = .red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y
                )
            }
        }
    }
    
    var cameraRect: CGRect {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    override func didMove(to view: SKView) {
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            background.zPosition = -1
            addChild(background)
        }
        
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
            self?.spawnEnemy() },
            SKAction.wait(forDuration: 2.0)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
            self?.spawnCat() },
            SKAction.wait(forDuration: 1.0)])
        ))
                
        debugDrawPlayableArea()
        
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
    }
    
    
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
        
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
//        print("\(dt*1000) milliseconds since last update")
        
        move(sprite: zombie, velocity: velocity)
        boundsCheckZombie()
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)

        
        moveTrain()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You Lose!")
            revealGameOverScene(won: false)
        }
        
        moveCamera()
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        // 2
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        // 3
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        // 4
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height
        )
        
        return backgroundNode
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func isZombieAtClickLocation() -> Bool {
        guard let clickLocation = clickLocation else { return false }
        
        let movement = (velocity * CGFloat(dt)).length()
        let distance = (clickLocation - zombie.position).length()
        
        if distance <= movement {
            return true
        }
        
        return false
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
//        print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()

        self.clickLocation = location
        velocity = (location - zombie.position).normalized() * zombieMovePointsPerSec
        if velocity.x.isNaN {
            velocity = CGPoint.zero
        }
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(
                min: cameraRect.minX,
                max: cameraRect.maxX
            ),
            y: CGFloat.random(
                min: cameraRect.minY,
                max: cameraRect.maxY
            )
        )
        cat.zPosition = 50
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let wiggleWait = SKAction.repeat(fullWiggle, count: 10)
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence(
        [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        
        cat.run(SKAction.sequence(actions))
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        let zombie_x = zombie.position.x
        let zombie_y = zombie.position.y
        
        if zombie_x <= bottomLeft.x || zombie_x >= topRight.x {
            if zombie.position.x <= bottomLeft.x {
                zombie.position.x = bottomLeft.x
                velocity.x = abs(velocity.x)
            } else {
                velocity.x = -velocity.x
            }
            
        }
        
        if zombie_y <= bottomLeft.y || zombie_y >= topRight.y {
            velocity.y = -velocity.y
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneTouched(touchLocation: getTouchLocation(touches))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        sceneTouched(touchLocation: getTouchLocation(touches))
    }
    
    func getTouchLocation(_ touches: Set<UITouch>) -> CGPoint {
        guard let touch = touches.first else {
            return CGPoint.zero
        }
        let touchLocation = touch.location(in: self)
        
        return touchLocation
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        let halfEnemyWidth = enemy.size.width / 2
        let halfEnemyHeight = enemy.size.height / 2
        let cameraStart = cameraNode.position.x
        
        enemy.position = CGPoint(x: cameraStart + size.width, y: CGFloat.random(min: playableRect.minY + halfEnemyHeight, max: playableRect.maxY - halfEnemyHeight))
        addChild(enemy)
        
        print(cameraStart)
        let actionMove = SKAction.moveTo(x: cameraStart - halfEnemyWidth, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func zombieHit(cat: SKSpriteNode) {
        // change the cat's name
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        colorize(cat, color: .green)
        
        run(catCollisionSound)
    }
    
    func colorize(_ sprite: SKSpriteNode, color: UIColor) {
        let colorize = SKAction.colorize(with: color, colorBlendFactor: 1, duration: 0.2)
        sprite.run(colorize)
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        run(enemyCollisionSound)
        
        // zombie starts blinking and becomes invincible
        blinkNode(zombie)
        
        loseCats()
        lives -= 1
    }
    
    func blinkNode(_ node: SKSpriteNode) {
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let isZombie = node.name == "zombie"
        if isZombie {
            zombieInvincible = true
        }
        node.run(blinkAction, completion: {
            if isZombie {
                self.zombieInvincible = false
            }
            self.zombie.isHidden = false
        })
    }
    
    func checkCollisions() {
        for nodeName in ["cat", "enemy"] {
            if zombieInvincible && nodeName == "enemy" {
                // ignore damage while zombie is invincible
                continue
            }
            var hitNodes: [SKSpriteNode] = []
            enumerateChildNodes(withName: nodeName) { (node, _) in
                if node.frame.intersects(self.zombie.frame) {
                    hitNodes.append(node as! SKSpriteNode)
                }
                
                for node in hitNodes {
                    nodeName == "cat" ? self.zombieHit(cat: node) : self.zombieHit(enemy: node)
                }
            }
        }
    }
}
