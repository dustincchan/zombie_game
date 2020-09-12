import SpriteKit

class GameScene: SKScene {
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var clickLocation: CGPoint?
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady", waitForCompletion: false)
    
    override init(size: CGSize) {
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = .red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1
    //    background.zRotation = CGFloat.pi / 8
        
        zombie.position = CGPoint(x: 400, y: 400)
    //    zombie.setScale(2.0)
            
        addChild(background)
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
        
        if isZombieAtClickLocation() {
            zombie.position = clickLocation!
            velocity = CGPoint.zero
            stopZombieAnimation()
        } else {
            move(sprite: zombie, velocity: velocity)
            boundsCheckZombie()
            rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        }
        
//        checkCollisions()
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
        cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX, max: playableRect.maxX), y: CGFloat.random(min: playableRect.minY, max: playableRect.maxY))
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
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: playableRect.maxX, y: playableRect.maxY)
        
        let zombie_x = zombie.position.x
        let zombie_y = zombie.position.y
        
        if zombie_x <= bottomLeft.x || zombie_x >= topRight.x {
            velocity.x = -velocity.x
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
//        let halfScreenWidth = size.width / 2
        
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: CGFloat.random(min: playableRect.minY + halfEnemyHeight, max: playableRect.maxY - halfEnemyHeight))
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: -halfEnemyWidth, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func zombieHit(cat: SKSpriteNode) {
        cat.removeFromParent()
        run(catCollisionSound)
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        run(enemyCollisionSound)
    }
    
    func checkCollisions() {
        for nodeName in ["cat", "enemy"] {
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
