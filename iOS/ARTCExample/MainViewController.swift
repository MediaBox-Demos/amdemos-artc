//
//  MainViewController.swift
//  Example
//
//  Created by Bingo on 2024/1/10.
//

import UIKit
import AliVCSDK_ARTC


class MainViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        GlobalConfig.shared.applySdkEnv()
    }
    
    @IBAction func rightBarButtonItemTapped(_ sender: Any) {
        self.presentVC(storyboardName: "Setting")
    }
    
    
    let actionList: [GroupItem] = [
        GroupItem(name: "QUICK START".localized, actions: [
            ActionItem(name: "Token Generate".localized, detail: "".localized, sbName: "TokenGenerate"),
            ActionItem(name: "Video Call".localized, detail: "".localized, sbName: "VideoCall"),
            ActionItem(name: "Voice Chat".localized, detail: "".localized, sbName: "VoiceChat"),
        ]),
        
        GroupItem(name: "BASIC".localized, actions: [
            ActionItem(name: "Audio Basic Usage".localized, detail: "".localized, sbName: "AudioBasicUsage"),
            ActionItem(name: "Video Basic Usage".localized, detail: "".localized, sbName: "VideoBasicUsage", sbId: "MainVC"),
            ActionItem(name: "Camera Common Control".localized, detail: "", sbName:"CameraCommonControl"),
            ActionItem(name: "SEI Sending and Receiving".localized, detail: "".localized, sbName: "SEIUsage"),
            ActionItem(name: "Common Message Sending And Receiving".localized, detail: "".localized, sbName: "DataChannelMessage"),
            ActionItem(name: "Screen Share".localized, detail: "".localized, sbName: "ScreenShare"),
            ActionItem(name: "Stream Monitoring".localized, detail: "".localized, sbName: "StreamMonitoring"),
            ActionItem(name: "Play Audio Files".localized, detail: "".localized, sbName: "PlayAudioFiles"),
            ActionItem(name: "Set Voice Change、Reverb、Beautify".localized, detail: "".localized, sbName: "VoiceChange")
        ]),
        
        GroupItem(name: "ADVANCED".localized, actions: [
            ActionItem(name: "Process Audio Raw Data".localized, detail: "".localized, sbName: "ProcessAudioRawData"),
            ActionItem(name: "Process Video Raw Data".localized, detail: "".localized, sbName: "ProcessVideoRawData"),
            ActionItem(name: "Custom Audio Capture".localized, detail: "".localized, sbName: "CustomAudioCapture"),
            ActionItem(name: "Custom Audio Render".localized, detail: "".localized, sbName: "CustomAudioRender"),
            ActionItem(name: "Custom Video Capture".localized, detail: "".localized, sbName: "CustomVideoCapture"),
            ActionItem(name: "Custom Video Render".localized, detail: "".localized, sbName: "CustomVideoRender"),
            ActionItem(name: "Custom Video Process".localized, detail: "".localized, sbName: "CustomVideoProcess"),
            ActionItem(name: "Pre-Join Channel Test".localized, detail: "".localized, sbName: "PreJoinChannelTest"),
            ActionItem(name: "Picture In Picture".localized, detail: "".localized, sbName: "PictureInPicture"),
            ActionItem(name: "Intelligent Denoise".localized, detail: "".localized, sbName: "IntelligentDenoise"),
            ActionItem(name: "H265".localized, detail: "".localized, sbName: "H265"),
            ActionItem(name: "Local Record".localized, detail: "".localized, sbName: "Recording")
        ]),
    ]
}

extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.actionList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.actionList[section].actions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let action = self.actionList[indexPath.section].actions[indexPath.row]
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ActionCell
        cell.nameLabel.text = action.name
        cell.detailLabel.text = action.detail
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = self.collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header", for: indexPath) as! HeadView
        header.nameLabel.text = self.actionList[indexPath.section].name
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let action = self.actionList[indexPath.section].actions[indexPath.row]
        if action.detail.isEmpty {
            return CGSize(width: collectionView.bounds.width, height: 48)
        }
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let action = self.actionList[indexPath.section].actions[indexPath.row]
        self.presentVC(storyboardName: action.sbName, storyboardId: action.sbId)
    }
}

class ActionCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var detailLabel: UILabel!
    
}

class HeadView: UICollectionReusableView {
    
    @IBOutlet weak var nameLabel: UILabel!
    
}


struct ActionItem {
    var name: String
    var detail: String
    
    // Storyboard Name
    var sbName: String = ""
    
    // Storyboard ID
    var sbId: String = "EntranceVC"
}

struct GroupItem {
    var name: String
    var actions: [ActionItem]
}
