import AppKit

final class ToastPresenter {
    private var toastWindow: NSWindow?
    private var hideTask: DispatchWorkItem?

    func show(title: String, body: String) {
        hideTask?.cancel()
        toastWindow?.close()

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let width: CGFloat = 360
        let horizontalPadding: CGFloat = 36
        let verticalPadding: CGFloat = 28
        let spacing: CGFloat = body.isEmpty ? 0 : 6
        let titleHeight = height(for: title, width: width - horizontalPadding, font: .systemFont(ofSize: 14, weight: .semibold), maxHeight: 22)
        let bodyHeight = body.isEmpty ? 0 : height(for: body, width: width - horizontalPadding, font: .systemFont(ofSize: 13), maxHeight: 84)
        let height = verticalPadding + titleHeight + spacing + bodyHeight
        let margin: CGFloat = 18
        let frame = NSRect(
            x: screen.visibleFrame.maxX - width - margin,
            y: screen.visibleFrame.maxY - height - margin,
            width: width,
            height: height
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.hasShadow = true

        let container = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        container.material = .hudWindow
        container.blendingMode = .behindWindow
        container.state = .active
        container.wantsLayer = true
        container.layer?.cornerRadius = 14
        container.layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        stack.addArrangedSubview(titleLabel)

        if !body.isEmpty {
            let bodyLabel = NSTextField(wrappingLabelWithString: body)
            bodyLabel.font = .systemFont(ofSize: 13)
            bodyLabel.textColor = .secondaryLabelColor
            bodyLabel.maximumNumberOfLines = 3
            stack.addArrangedSubview(bodyLabel)
        }

        window.contentView = container
        window.alphaValue = 0
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            window.animator().alphaValue = 1
        }

        toastWindow = window

        let task = DispatchWorkItem { [weak self, weak window] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                window?.animator().alphaValue = 0
            } completionHandler: {
                window?.close()
                if self?.toastWindow === window {
                    self?.toastWindow = nil
                }
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: task)
    }

    private func height(for text: String, width: CGFloat, font: NSFont, maxHeight: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        let rect = NSString(string: text).boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        return min(ceil(rect.height), maxHeight)
    }
}
