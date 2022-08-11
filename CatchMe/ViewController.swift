//
//  ViewController.swift
//  CatchMe
//
//  Created by Вадим Лавор on 10.08.22.
//

import UIKit

class ViewController: UIViewController {
    
    fileprivate enum DisplayEdge: Int {
        case top = 0
        case right = 1
        case bottom = 2
        case left = 3
    }
    
    fileprivate enum GameCondition {
        case ready
        case playing
        case gameOver
    }
    
    fileprivate let radiusUserDot: CGFloat = 10
    fileprivate let userAnimationDuration = 5.0
    fileprivate let opponentSpeed: CGFloat = 60
    fileprivate let opponentColors = [#colorLiteral(red: 0.08235294118, green: 0.6980392157, blue: 0.5411764706, alpha: 1), #colorLiteral(red: 0.07058823529, green: 0.5725490196, blue: 0.4470588235, alpha: 1), #colorLiteral(red: 0.9333333333, green: 0.7333333333, blue: 0, alpha: 1), #colorLiteral(red: 0.9411764706, green: 0.5450980392, blue: 0, alpha: 1), #colorLiteral(red: 0.1411764706, green: 0.7803921569, blue: 0.3529411765, alpha: 1), #colorLiteral(red: 0.1176470588, green: 0.6431372549, blue: 0.2941176471, alpha: 1), #colorLiteral(red: 0.8784313725, green: 0.4156862745, blue: 0.03921568627, alpha: 1), #colorLiteral(red: 0.7882352941, green: 0.2470588235, blue: 0, alpha: 1), #colorLiteral(red: 0.1490196078, green: 0.5098039216, blue: 0.8352941176, alpha: 1), #colorLiteral(red: 0.1137254902, green: 0.4156862745, blue: 0.6784313725, alpha: 1), #colorLiteral(red: 0.7019607843, green: 0.1411764706, blue: 0.1098039216, alpha: 1), #colorLiteral(red: 0.537254902, green: 0.2352941176, blue: 0.662745098, alpha: 1), #colorLiteral(red: 0.4823529412, green: 0.1490196078, blue: 0.6235294118, alpha: 1), #colorLiteral(red: 0.6862745098, green: 0.7137254902, blue: 0.7333333333, alpha: 1), #colorLiteral(red: 0.1529411765, green: 0.2196078431, blue: 0.2980392157, alpha: 1), #colorLiteral(red: 0.1294117647, green: 0.1843137255, blue: 0.2470588235, alpha: 1), #colorLiteral(red: 0.5137254902, green: 0.5843137255, blue: 0.5843137255, alpha: 1), #colorLiteral(red: 0.4235294118, green: 0.4745098039, blue: 0.4784313725, alpha: 1)]
    fileprivate var userView = UIView(frame: .zero)
    fileprivate var userAnimator: UIViewPropertyAnimator?
    fileprivate var opponentViews = [UIView]()
    fileprivate var opponentAnimators = [UIViewPropertyAnimator]()
    fileprivate var opponentTimer: Timer?
    fileprivate var displayLink: CADisplayLink?
    fileprivate var startTimestamp: TimeInterval = 0
    fileprivate var pastTime: TimeInterval = 0
    fileprivate var gameCondition = GameCondition.ready
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var beginLabel: UILabel!
    @IBOutlet weak var bestTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserView()
        prepareGame()
        self.setGradientBackground(view: self.view, colorTop: UIColor(red: 210/255, green: 109/255, blue: 180/255, alpha: 1).cgColor, colorBottom: UIColor(red: 52/255, green: 148/255, blue: 230/255, alpha: 1).cgColor)
        beginLabel.layer.cornerRadius = 10
        beginLabel.layer.masksToBounds = true
        //self.setGradientBackground(view: self.beginLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameCondition == .ready {
            startGame()
        }
        if let touchLocation = event?.allTouches?.first?.location(in: view) {
            moveUser(to: touchLocation)
            moveOpponents(to: touchLocation)
        }
    }
    
    @objc func generateOpponent(timer: Timer) {
        let displayEdge = DisplayEdge.init(rawValue: Int(arc4random_uniform(4)))
        let displayBounds = UIScreen.main.bounds
        var position: CGFloat = 0
        switch displayEdge! {
        case .left, .right:
            position = CGFloat(arc4random_uniform(UInt32(displayBounds.height)))
        case .top, .bottom:
            position = CGFloat(arc4random_uniform(UInt32(displayBounds.width)))
        }
        let opponentView = UIView(frame: .zero)
        opponentView.bounds.size = CGSize(width: radiusUserDot, height: radiusUserDot)
        opponentView.backgroundColor = getRandomColor()
        switch displayEdge! {
        case .left:
            opponentView.center = CGPoint(x: 0, y: position)
        case .right:
            opponentView.center = CGPoint(x: displayBounds.width, y: position)
        case .top:
            opponentView.center = CGPoint(x: position, y: displayBounds.height)
        case .bottom:
            opponentView.center = CGPoint(x: position, y: 0)
        }
        view.addSubview(opponentView)
        let duration = getOpponentDuration(opponentView: opponentView)
        let opponentAnimator = UIViewPropertyAnimator(duration: duration,
                                                   curve: .linear,
                                                   animations: { [weak self] in
            if let strongSelf = self {
                opponentView.center = strongSelf.userView.center
            }
        }
        )
        opponentAnimator.startAnimation()
        opponentAnimators.append(opponentAnimator)
        opponentViews.append(opponentView)
    }
    
    @objc func mark(sender: CADisplayLink) {
        updateCountUpTimer(timestamp: sender.timestamp)
        checkConflict()
    }
    
    func setGradientBackground(view: UIView, colorTop: CGColor = UIColor(red: 29.0/255.0, green: 34.0/255.0, blue:234.0/255.0, alpha: 1.0).cgColor, colorBottom: CGColor = UIColor(red: 38.0/255.0, green: 0.0/255.0, blue: 6.0/255.0, alpha: 1.0).cgColor) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}

fileprivate extension ViewController {
    
    func setupUserView() {
        userView.bounds.size = CGSize(width: radiusUserDot * 2, height: radiusUserDot * 2)
        userView.layer.cornerRadius = radiusUserDot
        userView.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.2, blue: 0.1607843137, alpha: 1)
        view.addSubview(userView)
    }
    
    func startOpponentTimer() {
        opponentTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(generateOpponent(timer:)), userInfo: nil, repeats: true)
    }
    
    func stopOpponentTimer() {
        guard let enemyTimer = opponentTimer,
              enemyTimer.isValid else {
                  return
              }
        enemyTimer.invalidate()
    }
    
    func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(mark(sender:)))
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
    
    func stopDisplayLink() {
        displayLink?.isPaused = true
        displayLink?.remove(from: RunLoop.main, forMode: RunLoop.Mode.default)
        displayLink = nil
    }
    
    func getRandomColor() -> UIColor {
        let index = arc4random_uniform(UInt32(opponentColors.count))
        return opponentColors[Int(index)]
    }
    
    func getOpponentDuration(opponentView: UIView) -> TimeInterval {
        let dx = userView.center.x - opponentView.center.x
        let dy = userView.center.y - opponentView.center.y
        return TimeInterval(sqrt(dx * dx + dy * dy) / opponentSpeed)
    }
    
    func gameOver() {
        stopGame()
        displayGameOverAlert()
    }
    
    func stopGame() {
        stopOpponentTimer()
        stopDisplayLink()
        stopAnimators()
        gameCondition = .gameOver
    }
    
    func prepareGame() {
        getBestTime()
        removeOpponents()
        centerUserView()
        popUserView()
        beginLabel.isHidden = false
        timeLabel.text = "00:00.000"
        gameCondition = .ready
    }
    
    func startGame() {
        startOpponentTimer()
        startDisplayLink()
        beginLabel.isHidden = true
        startTimestamp = 0
        gameCondition = .playing
    }
    
    func removeOpponents() {
        opponentViews.forEach {
            $0.removeFromSuperview()
        }
        opponentViews = []
    }
    
    func stopAnimators() {
        userAnimator?.stopAnimation(true)
        userAnimator = nil
        opponentAnimators.forEach {
            $0.stopAnimation(true)
        }
        opponentAnimators = []
    }
    
    func updateCountUpTimer(timestamp: TimeInterval) {
        if startTimestamp == 0 {
            startTimestamp = timestamp
        }
        pastTime = timestamp - startTimestamp
        timeLabel.text = format(timeInterval: pastTime)
    }
    
    func format(timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let milliseconds = Int(timeInterval * 1000) % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    func checkConflict() {
        opponentViews.forEach {
            guard let userFrame = userView.layer.presentation()?.frame,
                  let opponentFrame = $0.layer.presentation()?.frame,
                  userFrame.intersects(opponentFrame) else {
                      return
                  }
            gameOver()
        }
    }
    
    func moveUser(to touchLocation: CGPoint) {
        userAnimator = UIViewPropertyAnimator(duration: userAnimationDuration,
                                                dampingRatio: 0.5,
                                                animations: { [weak self] in
            self?.userView.center = touchLocation
        })
        userAnimator?.startAnimation()
    }
    
    func moveOpponents(to touchLocation: CGPoint) {
        for (index, opponentView) in opponentViews.enumerated() {
            let duration = getOpponentDuration(opponentView: opponentView)
            opponentAnimators[index] = UIViewPropertyAnimator(duration: duration,
                                                           curve: .linear,
                                                           animations: {
                opponentView.center = touchLocation
            })
            opponentAnimators[index].startAnimation()
        }
    }
    
    func displayGameOverAlert() {
        let (title, message) = getGameOverMessage()
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: title, style: .default,
                                   handler: { _ in
            self.prepareGame()
        })
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func getGameOverMessage() -> (String, String) {
        let pastSeconds = Int(pastTime) % 60
        setBestTime(with: format(timeInterval: pastTime))
        switch pastSeconds {
        case 0..<10: return ("Not bad", "You need more practice")
        case 10..<30: return ("Good👍", "Next time can be better")
        case 30..<60: return ("Very good 👍👍", "There is room to grow")
        default:
            return ("Excellent 👍👍👍", "Try to beat your record")
        }
    }
    
    func centerUserView() {
        userView.center = view.center
    }
    
    func popUserView() {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [0, 0.2, -0.2, 0.2, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.duration = CFTimeInterval(0.7)
        animation.isAdditive = true
        animation.repeatCount = 1
        animation.beginTime = CACurrentMediaTime()
        userView.layer.add(animation, forKey: "pop")
    }
    
    func setBestTime(with time:String){
        let defaults = UserDefaults.standard
        defaults.set(time, forKey: "bestTime")
    }
    
    func getBestTime(){
        let defaults = UserDefaults.standard
        if let time = defaults.value(forKey: "bestTime") as? String {
            self.bestTimeLabel.text = "Best Time: \(time)"
        }
    }
    
}
