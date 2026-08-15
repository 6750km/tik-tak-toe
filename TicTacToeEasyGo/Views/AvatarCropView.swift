import SwiftUI
import UIKit

struct AvatarCropView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let language: AppLanguage
    let onSave: (Data) async -> AvatarUploadIssue?

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1
    @State private var isSaving = false
    @State private var saveError: String?

    private var copy: AppCopy { AppCopy(language: language) }
    private var normalizedImage: UIImage { image.normalizedForCropping }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let side = min(geometry.size.width - 32, geometry.size.height - 120)
                let effectiveScale = scale * gestureScale
                let effectiveOffset = CGSize(
                    width: offset.width + dragTranslation.width,
                    height: offset.height + dragTranslation.height
                )

                VStack(spacing: 22) {
                    Spacer(minLength: 0)
                    cropCanvas(side: side, scale: effectiveScale, offset: effectiveOffset)
                    Text(copy.text(.moveAndScalePhoto))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let saveError {
                        Text(saveError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    Button {
                        guard let data = croppedJPEG(side: side) else { return }
                        isSaving = true
                        saveError = nil
                        Task {
                            if let issue = await onSave(data) {
                                saveError = message(for: issue)
                            } else {
                                dismiss()
                            }
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(copy.text(.usePhoto))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSaving)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .navigationTitle(copy.text(.cropPhoto))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(copy.text(.cancel)) { dismiss() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func message(for issue: AvatarUploadIssue) -> String {
        switch issue {
        case .notSignedIn: copy.text(.avatarNotSignedIn)
        case .storagePermissionDenied: copy.text(.avatarStoragePermissionDenied)
        case .fileTooLarge: copy.text(.avatarOutputTooLarge)
        case .storageUploadFailed: copy.text(.avatarStorageUploadFailed)
        case .profileUpdateFailed: copy.text(.avatarProfileUpdateFailed)
        }
    }

    private func cropCanvas(side: CGFloat, scale effectiveScale: CGFloat, offset effectiveOffset: CGSize) -> some View {
        let imageSize = normalizedImage.size
        let baseScale = max(side / imageSize.width, side / imageSize.height)
        let displayedWidth = imageSize.width * baseScale * effectiveScale
        let displayedHeight = imageSize.height * baseScale * effectiveScale

        return Image(uiImage: normalizedImage)
            .resizable()
            .frame(width: displayedWidth, height: displayedHeight)
            .offset(effectiveOffset)
            .frame(width: side, height: side)
            .clipped()
            .overlay {
                Rectangle()
                    .stroke(.white, lineWidth: 3)
                    .shadow(color: .black.opacity(0.7), radius: 2)
            }
            .background(.black)
            .overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        dragGesture(side: side)
                            .simultaneously(with: magnificationGesture(side: side))
                    )
            }
    }

    private func dragGesture(side: CGFloat) -> some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let proposed = CGSize(
                    width: offset.width + value.translation.width,
                    height: offset.height + value.translation.height
                )
                offset = clamped(proposed, side: side, scale: scale)
            }
    }

    private func magnificationGesture(side: CGFloat) -> some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                scale = min(max(scale * value, 1), 5)
                offset = clamped(offset, side: side, scale: scale)
            }
    }

    private func clamped(_ proposed: CGSize, side: CGFloat, scale: CGFloat) -> CGSize {
        let imageSize = normalizedImage.size
        let baseScale = max(side / imageSize.width, side / imageSize.height)
        let maxX = max(0, (imageSize.width * baseScale * scale - side) / 2)
        let maxY = max(0, (imageSize.height * baseScale * scale - side) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func croppedJPEG(side: CGFloat) -> Data? {
        let source = normalizedImage
        let baseScale = max(side / source.size.width, side / source.size.height)
        let totalScale = baseScale * scale
        let displayedSize = CGSize(
            width: source.size.width * totalScale,
            height: source.size.height * totalScale
        )
        let origin = CGPoint(
            x: (side - displayedSize.width) / 2 + offset.width,
            y: (side - displayedSize.height) / 2 + offset.height
        )
        let cropRect = CGRect(
            x: -origin.x / totalScale,
            y: -origin.y / totalScale,
            width: side / totalScale,
            height: side / totalScale
        )

        let outputSide: CGFloat = 512
        let outputScale = outputSide / cropRect.width
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSide, height: outputSide))
        let result = renderer.image { _ in
            source.draw(in: CGRect(
                x: -cropRect.minX * outputScale,
                y: -cropRect.minY * outputScale,
                width: source.size.width * outputScale,
                height: source.size.height * outputScale
            ))
        }
        return result.jpegData(compressionQuality: 0.86)
    }
}

private extension UIImage {
    var normalizedForCropping: UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}
