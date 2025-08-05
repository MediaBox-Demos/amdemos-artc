//
//  SeatView.swift
//  ARTCExample
//
//  Created by Bingo on 2025/5/27.
//

import UIKit

public struct SeatInfo {
    public init(uid: String = "",streamType: StreamType = .audio, isMuteAudio: Bool = false, audioVolume: Int = 100) {
        self.uid = uid
        self.streamType = streamType
        self.isMuteAudio = isMuteAudio
        self.audioVolume = audioVolume
    }
    
    public var uid: String = ""
    public var streamType: StreamType
    public var isMuteAudio: Bool = false
    public var audioVolume: Int = 100
}

public enum StreamType {
    case camera
    case screen
    case audio // 纯音频场景占位
}

@IBDesignable
class SeatView: UIView {

    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var streamTypeLabel: UILabel!
    
    @IBOutlet weak var canvasView: UIView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nibName = String(describing: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)

        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }

        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func onTap() {
        self.clickBlock?(self)
    }
    
    public var clickBlock: ((_ view: SeatView)->Void)? = nil
    
    public var seatInfo: SeatInfo = SeatInfo() {
        didSet {
            self.refreshUI()
        }
    }
    
    public func refreshUI() {
        self.uidLabel.text = self.seatInfo.uid
        if self.seatInfo.streamType != .audio {
            self.streamTypeLabel.text = self.seatInfo.streamType == .screen ? "screen" : "camera"
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}
