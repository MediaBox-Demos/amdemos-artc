//
//  ConfigView.swift
//  ARTCExample
//
//  Created by wy on 2025/7/18.
//

import Foundation
import UIKit

enum ConfigType {
    case textField
    case switchControl
    case picker
    case slider
    case segmented
}

struct ConfigModel {
    let title: String
    let type: ConfigType
    var value: Any
    var options: [String]? // for picker and segmented
}

class ConfigViewController: UIViewController, UITextFieldDelegate {

    // 配置数据和回调
    var configData: [ConfigModel] = []
    // 修改配置并点击确认
    var onConfigChanged: (([ConfigModel]) -> Void)?
    // 取消回调
    var onCancel: (() -> Void)?

    private var stackView: UIStackView!
    private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        setupHeaderWithTopButtons()
        setupScrollView()
        setupConfigRows()
        
        // 用于关闭键盘
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }

    // 设置顶部的标题和按钮
    private func setupHeaderWithTopButtons() {
        let headerView = UIView()
        headerView.backgroundColor = .white
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(cancelButton)

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Confirm".localized, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(confirmButton)

        let titleLabel = UILabel()
        titleLabel.text = "Configuration Panel".localized
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        self.view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            confirmButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            confirmButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    // 设置滚动视图，用于显示配置项
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 50),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
    }

    // 渲染配置项
    private func setupConfigRows() {
        for (index, config) in configData.enumerated() {
            let row = createConfigRow(for: config, at: index)
            stackView.addArrangedSubview(row)
        }
    }

    private func createConfigRow(for config: ConfigModel, at index: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let label = UILabel()
        label.text = config.title
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        switch config.type {
        case .textField:
            let textField = UITextField()
            textField.borderStyle = .roundedRect
            textField.text = (config.value as? String) ?? ""
            textField.tag = index
            textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            textField.delegate = self
            textField.returnKeyType = .done
            textField.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(textField)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),

                textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                textField.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16)
            ])

        case .switchControl:
            let switchControl = UISwitch()
            switchControl.isOn = (config.value as? Bool) ?? false
            switchControl.tag = index
            switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            switchControl.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(switchControl)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),

                switchControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                switchControl.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

        case .slider:
            let slider = UISlider()
            slider.minimumValue = 0.0
            slider.maximumValue = 100.0
            slider.value = Float((config.value as? Double) ?? 50.0)
            slider.tag = index
            slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
            slider.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(slider)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),

                slider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16)
            ])

        case .segmented:
            guard let segments = config.options, !segments.isEmpty else {
                let segmentedControl = UISegmentedControl(items: ["未定义"])
                segmentedControl.selectedSegmentIndex = 0
                segmentedControl.tag = index
                segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
                segmentedControl.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(segmentedControl)
                
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),

                    segmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    segmentedControl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    segmentedControl.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16)
                ])
                break
            }
            let segmentedControl = UISegmentedControl(items: segments)
            let selectedIndex = (config.value as? Int) ?? 0
            segmentedControl.selectedSegmentIndex = selectedIndex
            segmentedControl.tag = index
            segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(segmentedControl)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),

                segmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                segmentedControl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                segmentedControl.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16)
            ])
        case .picker:
            let button = UIButton(type: .system)
            // 获取选项数组（优先使用传入的options）
            var options: [String] = []
            if let modelOptions = config.options, !modelOptions.isEmpty {
                options = modelOptions
            } else if let fallbackOptions = config.value as? [String], !fallbackOptions.isEmpty {
                options = fallbackOptions
            } else {
                options = ["Option 1", "Option 2"]
            }
            // 设置按钮标题（优先使用已保存的值）
            let currentSelection = (config.value as? String) ?? options.first ?? "Default"
            button.setTitle(currentSelection, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(pickerTapped(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.4),

                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                button.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16)
            ])
        }

        return container
    }

    // MARK: 响应逻辑
    @objc private func cancelButtonTapped() {
        self.dismiss(animated: true) {
            self.onCancel?()
        }
    }

    @objc private func confirmButtonTapped() {
        self.dismiss(animated: true) {
            self.onConfigChanged?(self.configData)
        }
    }

    @objc private func textFieldChanged(_ sender: UITextField) {
        configData[sender.tag].value = sender.text ?? ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        configData[sender.tag].value = sender.isOn
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        configData[sender.tag].value = Double(sender.value)
    }

    @objc private func pickerTapped(_ sender: UIButton) {
        let index = sender.tag
        guard let options = configData[index].options ?? (configData[index].value as? [String]), !options.isEmpty else {
            return
        }

        let alertController = UIAlertController(title: "请选择".localized, message: nil, preferredStyle: .actionSheet)
        for option in options {
            alertController.addAction(UIAlertAction(title: option, style: .default, handler: { _ in
                // 更新按钮标题
                sender.setTitle(option, for: .normal)
                // 更新数据模型的当前值
                self.configData[index].value = option
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        present(alertController, animated: true)
    }

    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        configData[sender.tag].value = sender.selectedSegmentIndex
    }
}
