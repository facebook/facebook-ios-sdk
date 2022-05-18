/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import UIKit

/**
 Tooltip bubble with text in it used to display tips for UI elements,
 with a pointed arrow (to refer to the UI element).

 The tooltip fades in and will automatically fade out. See `displayDuration`.
 */
@objc(FBSDKTooltipView)
open class FBTooltipView: UIView {

  // MARK: - Definitions

  /**
   FBSDKTooltipViewArrowDirection enum

    Passed on construction to determine arrow orientation.
   */
  @objc(FBSDKTooltipViewArrowDirection)
  @frozen public enum ArrowDirection: UInt {
    case down = 0
    // swiftlint:disable:next identifier_name
    case up = 1
  }

  /**
   FBSDKTooltipColorStyle enum

   Passed on construction to determine color styling.
   */
  @objc(FBSDKTooltipColorStyle)
  @frozen public enum ColorStyle: UInt {
    case friendlyBlue = 0
    case neutralGray = 1
  }

  /// Constants
  private enum Constants {
    static let kTransitionDuration: CGFloat = 0.3
    static let kZoomOutScale: CGFloat = 0.001
    static let kZoomInScale: CGFloat = 1.1
    static let kZoomBounceScale: CGFloat = 0.98

    static let kNUXRectInset: CGFloat = 6
    static let kNUXBubbleMargin: CGFloat = 17 - kNUXRectInset
    static let kNUXPointMargin: CGFloat = -3
    static let kNUXCornerRadius: CGFloat = 4
    static let kNUXStrokeLineWidth: CGFloat = 0.5
    static let kNUXSideCap: CGFloat = 6
    static let kNUXFontSize: CGFloat = 10
    static let kNUXCrossGlyphSize: CGFloat = 11

    static let kFriendlyBlueGradientColors: [CGColor] = [
      UIColor(red: 0x6e / 255.0, green: 0x9c / 255.0, blue: 0xf5 / 255.0, alpha: 1.0).cgColor,
      UIColor(red: 0x49 / 255.0, green: 0x74 / 255.0, blue: 0xc6 / 255.0, alpha: 1.0).cgColor,
    ]
    static let kNeutralGray: [CGColor] = [
      UIColor(red: 0x51 / 255.0, green: 0x50 / 255.0, blue: 0x4f / 255.0, alpha: 1.0).cgColor,
      UIColor(red: 0x2d / 255.0, green: 0x2c / 255.0, blue: 0x2c / 255.0, alpha: 1.0).cgColor,
    ]
  }

  // MARK: - Properties

  /**
   Gets or sets the amount of time in seconds the tooltip should be displayed.
   Set this to zero to make the display permanent until explicitly dismissed.
   Defaults to six seconds.
   */
  @objc public var displayDuration: TimeInterval = 6.0

  /**
   Gets or sets the color style after initialization.
   Defaults to value passed to -initWithTagline:message:colorStyle:.
   */
  @objc public var colorStyle: ColorStyle {
    didSet {
      updateColors()
    }
  }

  /// Gets or sets the message.
  @objc public var message: String? {
    willSet {
      guard newValue != message else {
        return
      }
      set(message: newValue, tagline: tagline)
    }
  }

  /// Gets or sets the optional phrase that comprises the first part of the label (and is highlighted differently).
  @objc public var tagline: String? {
    willSet {
      guard newValue != tagline else {
        return
      }
      set(message: message, tagline: newValue)
    }
  }

  private var positionInView: CGPoint = .zero
  private var displayTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
  private let minimumDisplayDuration: CFTimeInterval = 6.0

  /// Primary text label for tooltip
  @objc let textLabel: UILabel = {
    let textLabel = UILabel(frame: .zero)
    textLabel.backgroundColor = .clear
    textLabel.autoresizingMask = .flexibleRightMargin
    textLabel.numberOfLines = 0
    textLabel.font = UIFont.boldSystemFont(ofSize: FBTooltipView.Constants.kNUXFontSize)
    textLabel.textAlignment = .left
    return textLabel
  }()

  private var insideTapGestureRecognizer: UITapGestureRecognizer?
  private var leftWidth: CGFloat = .zero
  private var rightWidth: CGFloat = .zero
  private var arrowMidpoint: CGFloat = .zero
  private var pointingUp: Bool = false
  private var isFadingOut: Bool = false

  // Style
  private var innerStrokeColor: UIColor = .clear
  private let arrowHeight: CGFloat = 7
  private let textPadding: CGFloat = 10
  private let maximumTextWidth: CGFloat = 185
  private let verticalTextOffset: CGFloat = 0
  private let verticalCrossOffset: CGFloat = -2.5
  private var gradientColors: [CGColor] = []
  private var crossCloseGlyphColor: UIColor = .clear

  // MARK: - Init

  /// Convenience constructor
  convenience init() {
    self.init(tagline: nil, message: nil, colorStyle: .friendlyBlue)
  }

  /// Designated initializer.
  /// - Parameters:
  ///   - tagline: First part of the label, that will be highlighted with different color. Can be nil.
  ///   - message: Main message to display.
  ///   - colorStyle: Color style to use for tooltip.
  ///
  /// If you need to show a tooltip for login, consider using the `FBSDKLoginTooltipView` view.
  /// See FBSDKLoginTooltipView
  @objc public init(
    tagline: String?,
    message: String?,
    colorStyle: ColorStyle
  ) {
    self.tagline = tagline
    self.message = message
    self.colorStyle = colorStyle

    super.init(frame: .zero)

    updateColors()
    set(message: message, tagline: tagline)
    addSubview(textLabel)

    // Tap gesture
    let gesture = UITapGestureRecognizer(target: self, action: #selector(onTapInTooltip(_:)))
    addGestureRecognizer(gesture)
    insideTapGestureRecognizer = gesture

    // Other Set Up
    isOpaque = false
    backgroundColor = .clear
    layer.needsDisplayOnBoundsChange = true
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.5
    layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
    layer.shadowRadius = 5.0
    layer.masksToBounds = false
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    insideTapGestureRecognizer?.removeTarget(self, action: nil)
  }

  // MARK: - Presentation

  /// Show tooltip at the top or at the bottom of given view.
  /// Tooltip will be added to anchorView.window.rootViewController.view
  ///
  /// - Parameter anchorView: view to show at, must be already added to window view hierarchy, in order to decide
  /// where tooltip will be shown. (If there's not enough space at the top of the anchorView in window bounds -
  /// tooltip will be shown at the bottom of it)
  ///
  /// Use this method to present the tooltip with automatic positioning or
  /// use -presentInView:withArrowPosition:direction: for manual positioning
  /// If anchorView is nil or has no window - this method does nothing.
  @objc(presentFromView:)
  public func present(from anchorView: UIView) {
    guard let superview = anchorView.window?.rootViewController?.view else {
      return
    }

    // By default - attach to the top, pointing down
    var position = CGPoint(x: anchorView.bounds.midX, y: anchorView.bounds.minY)
    var positionInSuperview = superview.convert(position, from: anchorView)
    var direction: ArrowDirection = .down

    // If not enough space to point up from top of anchor view - point up to it's bottom
    let bubbleHeight: CGFloat = textLabel.bounds.height + verticalTextOffset + textPadding * 2
    if positionInSuperview.y - bubbleHeight - Constants.kNUXBubbleMargin < superview.bounds.minY {
      direction = .up
      position = CGPoint(x: anchorView.bounds.midX, y: anchorView.bounds.maxY)
      positionInSuperview = superview.convert(position, from: anchorView)
    }

    present(in: superview, arrowPosition: positionInSuperview, direction: direction)
  }

  /// Adds tooltip to given view, with given position and arrow direction.
  /// - Parameters:
  ///   - view: View to be used as superview.
  ///   - arrowPosition: Point in view's cordinates, where arrow will be pointing
  ///   - direction: whenever arrow should be pointing up (message bubble is below the arrow) or down (message bubble is above the arrow).
  @objc(presentInView:withArrowPosition:direction:)
  open func present(
    in view: UIView,
    arrowPosition: CGPoint,
    direction: ArrowDirection
  ) {
    pointingUp = direction == .up
    positionInView = arrowPosition
    frame = layoutSubviewsAndDetermineFrame()

    // Add to view, while invisible.
    isHidden = true
    if superview != nil {
      removeFromSuperview()
    }
    view.addSubview(self)

    // Layout & schedule dismissal.
    displayTime = CFAbsoluteTimeGetCurrent()
    isFadingOut = false
    scheduleAutomaticFadeout()
    layoutSubviews()
    animateFadeIn()
  }

  /// Remove tooltip manually.
  /// Calling this method isn't necessary - tooltip will dismiss itself automatically after the `displayDuration`.
  @objc public func dismiss() {
    guard !isFadingOut else {
      return
    }

    isFadingOut = true

    animateFadeOut { [weak self] in
      self?.removeFromSuperview()
      self?.cancelAllScheduledFadeOutMethods()
      self?.isFadingOut = false
    }
  }

  // MARK: - Private Methods

  // MARK: - Animation

  @objc(animateFadeIn)
  func animateFadeIn() {
    // Prepare Animation: Zoom in with bounce. Keep the arrow point in place.
    // Set initial transform (zoomed out) & become visible.
    let centerPos: CGFloat = bounds.size.width / 2.0
    let zoomOffsetX: CGFloat = (centerPos - arrowMidpoint) * (Constants.kZoomOutScale - 1.0)
    var zoomOffsetY: CGFloat = -0.5 * bounds.size.height * (Constants.kZoomOutScale - 1.0)
    if pointingUp {
      zoomOffsetY = -zoomOffsetY
    }
    let transformer = FBSDKTransformer()
    let zoomOutScale = transformer.caTransform3DMakeScale(
      Constants.kZoomOutScale,
      sy: Constants.kZoomOutScale,
      sz: Constants.kZoomOutScale
    )
    let zoomOffsetTranslation = transformer.caTransform3DMakeTranslation(zoomOffsetX, ty: zoomOffsetY, tz: 0)
    layer.transform = transformer.caTransform3DConcat(zoomOutScale, b: zoomOffsetTranslation)
    isHidden = false

    // Prepare animation steps
    // 1st Step.
    let zoomIn: () -> Void = {
      self.alpha = 1.0

      let newZoomOffsetX: CGFloat = (centerPos - self.arrowMidpoint) * (Constants.kZoomInScale - 1.0)
      var newZoomOffsetY: CGFloat = -0.5 * self.bounds.size.height * (Constants.kZoomInScale - 1.0)
      if self.pointingUp {
        newZoomOffsetY = -newZoomOffsetY
      }

      let zoomInScale = transformer.caTransform3DMakeScale(
        Constants.kZoomInScale,
        sy: Constants.kZoomInScale,
        sz: Constants.kZoomInScale
      )
      let newZoomOffsetTranslation = transformer.caTransform3DMakeTranslation(newZoomOffsetX, ty: newZoomOffsetY, tz: 0)
      self.layer.transform = transformer.caTransform3DConcat(zoomInScale, b: newZoomOffsetTranslation)
    }

    // 2nd Step.
    let bounceZoom = {
      let centerPos2: CGFloat = self.bounds.size.width / 2.0
      let zoomOffsetX2: CGFloat = (centerPos2 - self.arrowMidpoint) * (Constants.kZoomBounceScale - 1.0)
      var zoomOffsetY2: CGFloat = -0.5 * self.bounds.size.height * (Constants.kZoomBounceScale - 1.0)
      if self.pointingUp {
        zoomOffsetY2 = -zoomOffsetY2
      }
      let zoomBounceScale = transformer.caTransform3DMakeScale(
        Constants.kZoomBounceScale,
        sy: Constants.kZoomBounceScale,
        sz: Constants.kZoomBounceScale
      )
      let bounceOffsetTranslation = transformer.caTransform3DMakeTranslation(zoomOffsetX2, ty: zoomOffsetY2, tz: 0)
      self.layer.transform = transformer.caTransform3DConcat(zoomBounceScale, b: bounceOffsetTranslation)
    }

    // 3rd Step.
    let normalizeZoom: () -> Void = {
      self.layer.transform = FBSDKCATransform3DIdentity
    }

    // Animate 3 steps sequentially
    UIView.animate(
      withDuration: Constants.kTransitionDuration / 1.5,
      delay: 0,
      options: .curveEaseInOut,
      animations: zoomIn
    ) { _ in
      UIView.animate(
        withDuration: Constants.kTransitionDuration / 2.2,
        animations: bounceZoom
      ) { _ in
        UIView.animate(
          withDuration: Constants.kTransitionDuration / 5,
          animations: normalizeZoom
        )
      }
    }
  }

  /// Fade out tooltip with animation
  /// - Parameter completionHandler: Callback after animation
  private func animateFadeOut(completionHandler: @escaping () -> Void) {
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      options: .curveEaseInOut
    ) {
      self.alpha = 0
    } completion: { _ in
      completionHandler()
    }
  }

  // MARK: - Gestures

  /// Handle tap gesture
  /// - Parameter sender: Tap gesture reference
  @objc private func onTapInTooltip(_ sender: UIGestureRecognizer) {
    // ignore incomplete tap gestures
    guard sender.state == .ended else {
      return
    }

    // fade out the tooltip view right away
    dismiss()
  }

  // MARK: - Drawing

  /// Create up pointing tooltip bubble
  /// - Parameters:
  ///   - rect: Bubble rect
  ///   - arrowMidpoint: Arrow x anchor midPoint
  ///   - arrowHeight: Arrow size height
  ///   - radius: Bubble radius
  /// - Returns: `CGMutablePath`
  private func fbsdkCreateUpPointingBubbleWithRect(
    _ rect: CGRect,
    _ arrowMidpoint: CGFloat,
    _ arrowHeight: CGFloat,
    _ radius: CGFloat
  ) -> CGMutablePath {
    let path = CGMutablePath()
    let arrowHalfWidth: CGFloat = arrowHeight

    // start with arrow
    path.move(to: CGPoint(x: arrowMidpoint - arrowHalfWidth, y: rect.minY))
    path.addLine(to: CGPoint(x: arrowMidpoint, y: rect.minY - arrowHeight))
    path.addLine(to: CGPoint(x: arrowMidpoint + arrowHalfWidth, y: rect.minY))

    // rest of curved rectangle
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
      tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.minX, y: rect.maxY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.minX, y: rect.minY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.minY),
      tangent2End: CGPoint(x: rect.maxX, y: rect.minY),
      radius: radius
    )
    path.closeSubpath()
    return path
  }

  /// Create down pointing tooltip bubble
  /// - Parameters:
  ///   - rect: Bubble rect
  ///   - arrowMidpoint: Arrow x anchor midPoint
  ///   - arrowHeight: Arrow size height
  ///   - radius: Bubble radius
  /// - Returns: `CGMutablePath`
  private func fbsdkCreateDownPointingBubbleWithRect(
    _ rect: CGRect,
    _ arrowMidpoint: CGFloat,
    _ arrowHeight: CGFloat,
    _ radius: CGFloat
  ) -> CGMutablePath {
    let path = CGMutablePath()
    let arrowHalfWidth: CGFloat = arrowHeight

    // start with arrow
    path.move(to: CGPoint(x: arrowMidpoint + arrowHalfWidth, y: rect.maxY))
    path.addLine(to: CGPoint(x: arrowMidpoint, y: rect.maxY + arrowHeight))
    path.addLine(to: CGPoint(x: arrowMidpoint - arrowHalfWidth, y: rect.maxY))

    // rest of curved rectangle
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.minX, y: rect.minY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.minY),
      tangent2End: CGPoint(x: rect.maxX, y: rect.minY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
      tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.minX, y: rect.maxY),
      radius: radius
    )
    path.closeSubpath()
    return path
  }

  /// Create path for close icon
  /// - Parameter rect: Rect to draw in
  /// - Returns: `CGMutablePath`
  private func createCloseCrossGlyphWithRect(_ rect: CGRect) -> CGMutablePath {
    let lineThickness: CGFloat = 0.20 * rect.height

    // One rectangle
    let path1 = CGMutablePath()
    path1.move(to: CGPoint(x: rect.minX, y: rect.minY + lineThickness))
    path1.addLine(to: CGPoint(x: rect.minX + lineThickness, y: rect.minY))
    path1.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - lineThickness))
    path1.addLine(to: CGPoint(x: rect.maxX - lineThickness, y: rect.maxY))
    path1.closeSubpath()

    // 2nd rectangle - mirrored horizontally
    let path2 = CGMutablePath()
    path2.move(to: CGPoint(x: rect.minX, y: rect.maxY - lineThickness))
    path2.addLine(to: CGPoint(x: rect.maxX - lineThickness, y: rect.minY))
    path2.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + lineThickness))
    path2.addLine(to: CGPoint(x: rect.minX + lineThickness, y: rect.maxY))
    path2.closeSubpath()

    let groupedPath = CGMutablePath()
    groupedPath.addPath(path1)
    groupedPath.addPath(path2)

    return groupedPath
  }

  public override func draw(_ rect: CGRect) {
    // Ignore dirty rect and just redraw the entire nux bubble
    let arrowSideMargin: CGFloat = 1 + 0.5 * max(Constants.kNUXRectInset, arrowHeight)
    let arrowYMarginOffset: CGFloat = pointingUp ? arrowSideMargin : Constants.kNUXRectInset
    let halfStroke: CGFloat = Constants.kNUXStrokeLineWidth / 2.0
    let outerRect = CGRect(
      x: Constants.kNUXRectInset + halfStroke,
      y: arrowYMarginOffset + halfStroke,
      width: bounds.size.width - 2 * Constants.kNUXRectInset - Constants.kNUXStrokeLineWidth,
      height: bounds.size.height - Constants.kNUXRectInset - arrowSideMargin - Constants.kNUXStrokeLineWidth
    ).insetBy(dx: 5, dy: 5)

    let innerRect: CGRect = outerRect.insetBy(dx: Constants.kNUXStrokeLineWidth, dy: Constants.kNUXStrokeLineWidth)
    let fillRect: CGRect = innerRect.insetBy(
      dx: Constants.kNUXStrokeLineWidth / 2.0,
      dy: Constants.kNUXStrokeLineWidth / 2.0
    )
    let closeCrossGlyphPositionY: CGFloat = min(
      fillRect.minY + textPadding + verticalCrossOffset,
      fillRect.midY - 0.5 * Constants.kNUXCrossGlyphSize
    )
    let closeCrossGlyphRect = CGRect(
      x: fillRect.maxX - 2 * Constants.kNUXFontSize,
      y: closeCrossGlyphPositionY,
      width: Constants.kNUXCrossGlyphSize,
      height: Constants.kNUXCrossGlyphSize
    )

    // setup and get paths
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }

    let outerPath: CGMutablePath
    let innerPath: CGMutablePath
    let fillPath: CGMutablePath
    let crossCloseGlyphPath = createCloseCrossGlyphWithRect(closeCrossGlyphRect)
    var gradientRect: CGRect = fillRect
    if pointingUp {
      outerPath = fbsdkCreateUpPointingBubbleWithRect(
        outerRect,
        arrowMidpoint,
        arrowHeight,
        Constants.kNUXCornerRadius + Constants.kNUXStrokeLineWidth
      )
      innerPath = fbsdkCreateUpPointingBubbleWithRect(
        innerRect,
        arrowMidpoint,
        arrowHeight,
        Constants.kNUXCornerRadius
      )
      fillPath = fbsdkCreateUpPointingBubbleWithRect(
        fillRect,
        arrowMidpoint,
        arrowHeight,
        Constants.kNUXCornerRadius - Constants.kNUXStrokeLineWidth
      )
      gradientRect.origin.y -= arrowHeight
      gradientRect.size.height += arrowHeight
    } else {
      outerPath = fbsdkCreateDownPointingBubbleWithRect(
        outerRect,
        arrowMidpoint,
        arrowHeight,
        Constants.kNUXCornerRadius + Constants.kNUXStrokeLineWidth
      )
      innerPath = fbsdkCreateDownPointingBubbleWithRect(
        innerRect,
        arrowMidpoint,
        arrowHeight,
        Constants.kNUXCornerRadius
      )
      fillPath = fbsdkCreateDownPointingBubbleWithRect(
        fillRect,
        arrowMidpoint,
        arrowHeight,
        Constants.kNUXCornerRadius - Constants.kNUXStrokeLineWidth
      )
      gradientRect.size.height += arrowHeight
    }
    layer.shadowPath = outerPath

    // This tooltip has two borders, so draw two strokes and a fill.
    let strokeColor = innerStrokeColor.cgColor
    context.saveGState()
    context.setStrokeColor(strokeColor)
    context.setLineWidth(Constants.kNUXStrokeLineWidth)
    context.addPath(innerPath)
    context.strokePath()
    context.addPath(fillPath)
    context.clip()

    let rgbColorspace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(
      colorsSpace: rgbColorspace,
      colors: gradientColors as CFArray,
      locations: nil
    ) else {
      return
    }

    let start = CGPoint(x: gradientRect.origin.x, y: gradientRect.origin.y)
    let end = CGPoint(x: gradientRect.origin.x, y: gradientRect.maxY)
    context.drawLinearGradient(gradient, start: start, end: end, options: .init(rawValue: 0))
    context.addPath(crossCloseGlyphPath)
    context.setFillColor(crossCloseGlyphColor.cgColor)
    context.fillPath()
    context.restoreGState()
  }

  /// Update style based colors
  private func updateColors() {
    switch colorStyle {
    case .neutralGray:
      gradientColors = Constants.kNeutralGray
      innerStrokeColor = UIColor(white: 0.13, alpha: 1)
      crossCloseGlyphColor = UIColor(white: 0.69, alpha: 1)

    case .friendlyBlue:
      gradientColors = Constants.kFriendlyBlueGradientColors
      innerStrokeColor = UIColor(red: 0.12, green: 0.26, blue: 0.55, alpha: 1.0)
      crossCloseGlyphColor = UIColor(red: 0.60, green: 0.73, blue: 1.0, alpha: 1.0)
    }

    textLabel.textColor = .white
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    // We won't set the frame in layoutSubviews to avoid potential infinite loops.
    // Frame is set in -presentInView:withArrowPosition:direction: method.
    _ = layoutSubviewsAndDetermineFrame()
  }

  private func layoutSubviewsAndDetermineFrame() -> CGRect {
    // Compute the positioning of the arrow.
    var screenBounds: CGRect = UIScreen.main.bounds
    let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
    if !orientation.isPortrait {
      screenBounds = CGRect(x: 0, y: 0, width: screenBounds.size.height, height: screenBounds.size.width)
    }
    let arrowHalfWidth: CGFloat = arrowHeight
    var arrowXPos: CGFloat = positionInView.x - arrowHalfWidth
    arrowXPos = max(arrowXPos, Constants.kNUXSideCap + Constants.kNUXBubbleMargin)
    arrowXPos = min(
      arrowXPos,
      screenBounds.size.width - Constants.kNUXBubbleMargin - Constants.kNUXSideCap - 2 * arrowHalfWidth
    )
    positionInView = CGPoint(x: arrowXPos + arrowHalfWidth, y: positionInView.y)

    let arrowYMarginOffset: CGFloat = pointingUp ? max(Constants.kNUXRectInset, arrowHeight) : Constants.kNUXRectInset

    // Set the lock image frame.
    let xPos: CGFloat = Constants.kNUXRectInset + textPadding + Constants.kNUXStrokeLineWidth
    let yPos: CGFloat = arrowYMarginOffset + Constants.kNUXStrokeLineWidth + textPadding

    // Set the text label frame.
    textLabel.frame = CGRect(
      x: xPos,
      y: yPos + verticalTextOffset, // sizing function may not return desired height exactly
      width: textLabel.bounds.width,
      height: textLabel.bounds.height
    )

    // Determine the size of the nux bubble.
    let bubbleHeight = textLabel.bounds.height + verticalTextOffset + textPadding * 2
    let crossGlyphWidth = 2 * Constants.kNUXFontSize
    let bubbleWidth = textLabel.bounds.width + textPadding * 2 + Constants.kNUXStrokeLineWidth * 2 + crossGlyphWidth

    // Compute the widths to the left and right of the arrow.
    leftWidth = CGFloat(roundf(0.5 * Float(bubbleWidth - 2 * arrowHalfWidth)))
    rightWidth = leftWidth

    var originX: CGFloat = arrowXPos - leftWidth
    if originX < Constants.kNUXBubbleMargin {
      let xShift: CGFloat = Constants.kNUXBubbleMargin - originX
      originX += xShift
      leftWidth -= xShift
      rightWidth += xShift
    } else if originX + bubbleWidth > screenBounds.size.width - Constants.kNUXBubbleMargin {
      let xShift: CGFloat = originX + bubbleWidth - (screenBounds.size.width - Constants.kNUXBubbleMargin)
      originX -= xShift
      leftWidth += xShift
      rightWidth -= xShift
    }

    arrowMidpoint = positionInView.x - originX + Constants.kNUXRectInset

    // Set the frame for the view.
    let nuxWidth: CGFloat = bubbleWidth + 2 * Constants.kNUXRectInset
    let nuxHeight: CGFloat = bubbleHeight + Constants.kNUXRectInset + max(
      Constants.kNUXRectInset,
      arrowHeight
    ) + 2 * Constants.kNUXStrokeLineWidth
    var yOrigin: CGFloat = 0
    if pointingUp {
      yOrigin = positionInView.y + Constants.kNUXPointMargin - max(0, Constants.kNUXRectInset - arrowHeight)
    } else {
      yOrigin = positionInView.y - nuxHeight - Constants.kNUXPointMargin + max(0, Constants.kNUXRectInset - arrowHeight)
    }

    return CGRect(
      x: originX - Constants.kNUXRectInset,
      y: yOrigin,
      width: nuxWidth,
      height: nuxHeight
    )
  }

  // MARK: - Message & Tagline

  /// Set tooltip content
  /// - Parameters:
  ///   - message: Nullable message text
  ///   - tagline: Nullable tagline text
  private func set(message: String?, tagline: String?) {
    var kmessage = message ?? ""
    // Ensure tagline is empty string or ends with space
    var ktagline = tagline ?? ""
    if !ktagline.isEmpty, !ktagline.hasSuffix(" ") {
      ktagline = "\(ktagline) "
    }

    // Concatenate tagline & main message
    kmessage = ktagline + kmessage

    let fullRange = NSRange(location: 0, length: kmessage.count)
    let attrString = NSMutableAttributedString(string: kmessage)
    let font = UIFont.boldSystemFont(ofSize: Constants.kNUXFontSize)

    attrString.addAttribute(.font, value: font, range: fullRange)
    attrString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)

    if !ktagline.isEmpty {
      let color = UIColor(
        red: 0x6D / 255.0,
        green: 0x87 / 255.0,
        blue: 0xC7 / 255.0,
        alpha: 1
      )
      attrString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: ktagline.count))
    }

    textLabel.attributedText = attrString

    let textLabelSize: CGSize = textLabel.sizeThatFits(
      CGSize(
        width: maximumTextWidth,
        height: .greatestFiniteMagnitude
      )
    )
    textLabel.bounds = CGRect(x: 0, y: 0, width: textLabelSize.width, height: textLabelSize.height)
    frame = layoutSubviewsAndDetermineFrame()
    setNeedsDisplay()
  }

  // MARK: - Auto Dismiss Timeout

  /// Schedule view fade out
  private func scheduleAutomaticFadeout() {
    Self.cancelPreviousPerformRequests(
      withTarget: self,
      selector: #selector(scheduleFadeoutRespectingMinimumDisplayDuration),
      object: nil
    )

    if displayDuration > 0.0, superview != nil {
      let intervalAlreadyDisplaying: CFTimeInterval = CFAbsoluteTimeGetCurrent() - displayTime
      let timeRemainingBeforeAutomaticFadeout: CFTimeInterval = displayDuration - intervalAlreadyDisplaying
      if timeRemainingBeforeAutomaticFadeout > 0.0 {
        perform(
          #selector(scheduleFadeoutRespectingMinimumDisplayDuration),
          with: nil,
          afterDelay: timeRemainingBeforeAutomaticFadeout
        )
      } else {
        scheduleFadeoutRespectingMinimumDisplayDuration()
      }
    }
  }

  /// Schedules faded out while respecting minimum display duration
  @objc private func scheduleFadeoutRespectingMinimumDisplayDuration() {
    let intervalAlreadyDisplaying: CFTimeInterval = CFAbsoluteTimeGetCurrent() - displayTime
    let remainingDisplayTime: CFTimeInterval = minimumDisplayDuration - intervalAlreadyDisplaying
    if remainingDisplayTime > 0.0 {
      perform(#selector(dismiss), with: nil, afterDelay: remainingDisplayTime)
    } else {
      dismiss()
    }
  }

  /// Cancel scheduled methods (selectors schedule via `perform(:)` API)
  private func cancelAllScheduledFadeOutMethods() {
    Self.cancelPreviousPerformRequests(
      withTarget: self,
      selector: #selector(scheduleFadeoutRespectingMinimumDisplayDuration),
      object: nil
    )
    Self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismiss), object: nil)
  }
}

#endif
