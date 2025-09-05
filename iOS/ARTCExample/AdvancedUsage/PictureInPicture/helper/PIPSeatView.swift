//
//  PIPSeatView.swift
//  ARTCExample
//
//  Created by wy on 2025/9/3.
//

import UIKit

class PIPSeatView: UIView {
    let uidLabel = UILabel()
    var canvasView: AliRTCPixelBufferRenderView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // UID Label
        uidLabel.textAlignment = .center
        uidLabel.font = UIFont.systemFont(ofSize: 14)
        uidLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        uidLabel.textColor = .white
        uidLabel.layer.cornerRadius = 4
        uidLabel.clipsToBounds = true
        addSubview(uidLabel)
        
        // Canvas View
        canvasView = AliRTCPixelBufferRenderView()
        canvasView.backgroundColor = .darkGray
        addSubview(canvasView)
        
        // Auto Layout
        uidLabel.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            uidLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            uidLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            uidLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            uidLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
