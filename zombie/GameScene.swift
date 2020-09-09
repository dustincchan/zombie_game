import SpriteKit

class GameScene: SKScene {
  override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
    let background = SKSpriteNode(imageNamed: "background1")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    background.zPosition = -1
//    background.zRotation = CGFloat.pi / 8
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    zombie.position = CGPoint(x: 400, y: 400)
//    zombie.setScale(2.0)
        
    addChild(background)
    addChild(zombie)
    }
}
