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
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
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
        spawnEnemy()
        
        debugDrawPlayableArea()
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
        } else {
            move(sprite: zombie, velocity: velocity)
            boundsCheckZombie()
            rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
        }
        
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
        self.clickLocation = location
        velocity = (location - zombie.position).normalized() * zombieMovePointsPerSec
        if velocity.x.isNaN {
            velocity = CGPoint.zero
        }
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
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: size.height / 2)
        addChild(enemy)
        
        let actionMidMove = SKAction.move(to: CGPoint(x: size.width/2, y: playableRect.minY + enemy.size.height/2), duration: 1.0)
        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration: 1.0)
        let wait = SKAction.wait(forDuration: 0.25)
        let logMessage = SKAction.run() {
            print("Reached bottom!")
        }
        let sequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
        enemy.run(sequence)
    }
}
