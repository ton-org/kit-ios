//
//  QRScannerView.swift
//  TONWalletApp
//
//  Created by Nikita Rodionov on 18.06.2026.
//
//  Copyright (c) 2026 TON Connect
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import AVFoundation
import SwiftUI
import UIKit

/// Full-screen QR scanner. Calls `onScanned` once with the decoded payload, then the
/// presenter is responsible for dismissing and acting on it. `onClose` dismisses manually.
struct QRScannerView: View {
    let onScanned: (String) -> Void
    let onClose: () -> Void

    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            Color.tonBgInverse.ignoresSafeArea()

            if permissionDenied {
                permissionMessage
            } else {
                QRScannerRepresentable(
                    onScanned: onScanned,
                    onPermissionDenied: { permissionDenied = true }
                )
                .ignoresSafeArea()

                scanReticle
            }

            chrome
        }
    }

    // MARK: - Overlay chrome

    private var chrome: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    TONIcon.close.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .size(20)
                        .foregroundStyle(Color.tonTextOnBrand)
                        .padding(10)
                        .background(Circle().fill(Color.tonBgInverse.opacity(0.4)))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(16)

            Spacer()

            if !permissionDenied {
                Text("Point the camera at a TON Connect QR code")
                    .textStyle(.body)
                    .foregroundStyle(Color.tonTextOnBrand)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
        }
    }

    private var scanReticle: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.tonTextOnBrand.opacity(0.9), lineWidth: 3)
            .frame(width: 240, height: 240)
    }

    private var permissionMessage: some View {
        VStack(spacing: 12) {
            TONIcon.qrCode40.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .size(48)
                .foregroundStyle(Color.tonTextOnBrand)
            Text("Camera access is required to scan QR codes")
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.tonTextOnBrand)
                .multilineTextAlignment(.center)
            Text("Enable camera access for this app in Settings.")
                .textStyle(.subheadline2)
                .foregroundStyle(Color.tonTextOnBrand.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - AVFoundation bridge

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void
    let onPermissionDenied: () -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onScanned = onScanned
        controller.onPermissionDenied = onPermissionDenied
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController {
    var onScanned: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.tonwalletapp.qrscanner.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didScan = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestAccessAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func requestAccessAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.onPermissionDenied?()
                    }
                }
            }
        default:
            onPermissionDenied?()
        }
    }

    private func configureSession() {
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            onPermissionDenied?()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            onPermissionDenied?()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            !didScan,
            let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            object.type == .qr,
            let value = object.stringValue,
            !value.isEmpty
        else {
            return
        }

        didScan = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
        onScanned?(value)
    }
}
