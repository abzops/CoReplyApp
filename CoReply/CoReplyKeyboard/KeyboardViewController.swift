// KeyboardViewController.swift
// CoReplyKeyboard
//
// Root UIInputViewController that hosts the SwiftUI KeyboardView.
// Manages lifecycle, proxy delegation, and height constraints.

import UIKit
import SwiftUI
import Combine

final class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var hostingController: UIHostingController<KeyboardView>?
    private var keyboardViewModel: KeyboardViewModel!
    private var heightConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupKeyboardView()
        observeViewModelHeight()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardViewModel.onKeyboardAppear(proxy: textDocumentProxy)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardViewModel.onKeyboardDisappear()
    }

    // MARK: - UITextInputDelegate

    override func textDidChange(_ textInput: (any UITextInput)?) {
        keyboardViewModel.textDidChange(proxy: textDocumentProxy)
    }

    override func selectionWillChange(_ textInput: (any UITextInput)?) {
        // no-op – kept for completeness
    }

    override func selectionDidChange(_ textInput: (any UITextInput)?) {
        // no-op
    }

    override func textWillChange(_ textInput: (any UITextInput)?) {
        // no-op
    }

    // MARK: - Setup

    private func setupViewModel() {
        keyboardViewModel = KeyboardViewModel(inputViewController: self)
    }

    private func setupKeyboardView() {
        let keyboardView = KeyboardView(viewModel: keyboardViewModel)
        let hc = UIHostingController(rootView: keyboardView)
        hc.view.backgroundColor = .clear

        addChild(hc)
        view.addSubview(hc.view)
        hc.didMove(toParent: self)

        hc.view.translatesAutoresizingMaskIntoConstraints = false
        let h = hc.view.heightAnchor.constraint(equalToConstant: KeyboardViewModel.preferredHeight)
        h.priority = .defaultHigh
        h.isActive = true
        self.heightConstraint = h

        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.hostingController = hc
    }

    private func observeViewModelHeight() {
        keyboardViewModel.$preferredKeyboardHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newHeight in
                guard let self else { return }
                self.heightConstraint?.constant = newHeight
                self.view.layoutIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: - Next Keyboard

    /// Called by KeyboardView's "Next Keyboard" button.
    func advanceToNextKeyboard() {
        advanceToNextInputMode()
    }
}
