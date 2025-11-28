//
//  UserSeatView.swift
//  ARTCExample
//
//  Created by wy on 2025/9/25.
//

import Foundation
import UIKit
class UserSeatView: UIView {
    let videoRenderView = VideoRenderView()
    let uidLabel = UILabel()

    var uid: String = "" {
        didSet { uidLabel.text = uid }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(videoRenderView)
        addSubview(uidLabel)

        videoRenderView.translatesAutoresizingMaskIntoConstraints = false
        uidLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            videoRenderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoRenderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoRenderView.topAnchor.constraint(equalTo: topAnchor),
            videoRenderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            uidLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            uidLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            uidLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            uidLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        uidLabel.textColor = .white
        uidLabel.font = .systemFont(ofSize: 12)
        uidLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        uidLabel.textAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoRenderView.layer.frame = videoRenderView.bounds
    }
}

