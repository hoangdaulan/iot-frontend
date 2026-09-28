import 'package:flutter/material.dart';

enum AnimatedOverlayDirection { top, bottom, auto }

enum AnimatedOverlayAlignment { bottomLeft, bottomRight, topLeft, topRight, auto }

class AnimatedOverlay extends StatefulWidget {
  const AnimatedOverlay({
    super.key,
    required this.overlay,
    required this.child,
    this.overlayDecoration,
    this.direction = AnimatedOverlayDirection.auto,
    this.alignment = AnimatedOverlayAlignment.auto,
    this.overlayWidth,
    this.overlayPaddingBottom = 0,
    this.duration = Durations.medium1,
  });

  final Widget Function(VoidCallback hideOverlay) overlay;
  final Widget Function(VoidCallback showOverlay) child;
  final BoxDecoration? overlayDecoration;

  final AnimatedOverlayDirection direction;
  final AnimatedOverlayAlignment alignment;

  /// The width of the overlay. If null, the overlay will match the width of the child.
  final double? overlayWidth;

  /// The minimum distance between the overlay and the bottom edge of the screen.
  ///
  /// Use this to prevent the overlay from overlapping a bottom navigation bar
  /// or other bottom UI elements.
  ///
  /// Only applies when [direction] is [AnimatedOverlayDirection.auto].
  final double overlayPaddingBottom;

  /// The duration of the overlay animation. Defaults to [Durations.medium1].
  final Duration duration;

  @override
  State<AnimatedOverlay> createState() => _AnimatedOverlayState();
}

class _AnimatedOverlayState extends State<AnimatedOverlay> {
  final layerLink = LayerLink();
  final overlayController = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (_) {
        return _Overlay(
          layerLink: layerLink,
          parentBox: context.findRenderObject() as RenderBox,
          overlay: widget.overlay,
          decoration: widget.overlayDecoration,
          onHideOverlay: overlayController.hide,
          direction: widget.direction,
          alignment: widget.alignment,
          overlayWidth: widget.overlayWidth,
          overlayPaddingBottom: widget.overlayPaddingBottom,
          duration: widget.duration,
        );
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: widget.child(overlayController.show),
      ),
    );
  }
}

class _AnimatedSection extends StatefulWidget {
  final bool expand;
  final VoidCallback animationDismissed;
  final Widget child;
  final AlignmentGeometry alignment;
  final Duration duration;

  const _AnimatedSection({
    required this.expand,
    required this.animationDismissed,
    required this.child,
    required this.alignment,
    required this.duration,
  });

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection> with SingleTickerProviderStateMixin {
  late AnimationController animController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    runExpand();
  }

  void prepareAnimations() {
    animController = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          widget.animationDismissed();
        }
      });

    animation = CurvedAnimation(parent: animController, curve: Curves.linearToEaseOut);
  }

  void runExpand() {
    if (widget.expand) {
      animController.forward();
    } else {
      animController.reverse();
    }
  }

  @override
  void didUpdateWidget(_AnimatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      animController.duration = widget.duration;
    }
    if (widget.expand != oldWidget.expand) {
      runExpand();
    }
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        alignment: widget.alignment,
        sizeFactor: animation,
        child: widget.child,
      ),
    );
  }
}

enum _OverlayAlignment { bottomLeft, bottomRight, topLeft, topRight }

class _Overlay extends StatefulWidget {
  const _Overlay({
    required this.layerLink,
    required this.parentBox,
    required this.overlay,
    required this.decoration,
    required this.onHideOverlay,
    required this.direction,
    required this.alignment,
    this.overlayWidth,
    required this.overlayPaddingBottom,
    required this.duration,
  });

  final LayerLink layerLink;
  final RenderBox parentBox;
  final Widget Function(VoidCallback hideOverlay) overlay;
  final BoxDecoration? decoration;
  final VoidCallback onHideOverlay;
  final AnimatedOverlayDirection direction;
  final AnimatedOverlayAlignment alignment;
  final double? overlayWidth;
  final double overlayPaddingBottom;
  final Duration duration;

  @override
  State<_Overlay> createState() => __OverlayState();
}

class __OverlayState extends State<_Overlay> {
  final overlayKey = GlobalKey();
  bool overlayBottom = true;
  bool expandOverlay = true;

  @override
  void initState() {
    super.initState();
    overlayBottom =
        widget.direction == AnimatedOverlayDirection.auto ||
        widget.direction == AnimatedOverlayDirection.bottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.direction != AnimatedOverlayDirection.auto) return;
      final overlayRender = overlayKey.currentContext?.findRenderObject() as RenderBox;

      final screenHeight = MediaQuery.of(context).size.height;
      double childHeight = widget.parentBox.localToGlobal(Offset.zero).dy;
      if ((screenHeight - childHeight) <
          (overlayRender.size.height + widget.overlayPaddingBottom)) {
        overlayBottom = false;
        setState(() {});
      }
    });
  }

  double get overlayWidth {
    return widget.overlayWidth ?? widget.parentBox.size.width;
  }

  _OverlayAlignment get _overlayAlignment {
    final isRightAligned =
        widget.parentBox.localToGlobal(Offset.zero).dx > MediaQuery.of(context).size.width / 2;
    return switch (widget.alignment) {
      .bottomLeft => .bottomLeft,
      .bottomRight => .bottomRight,
      .topLeft => .topLeft,
      .topRight => .topRight,
      .auto =>
        overlayBottom
            ? (isRightAligned ? .topRight : .topLeft)
            : (isRightAligned ? .bottomRight : .bottomLeft),
    };
  }

  Alignment get alignment {
    return switch (_overlayAlignment) {
      .bottomRight || .topRight => overlayBottom ? .topRight : .bottomRight,
      .bottomLeft || .topLeft => overlayBottom ? .topLeft : .bottomLeft,
    };
  }

  Offset get overlayOffset {
    final parentHeight = widget.parentBox.size.height;
    final parentWidth = widget.parentBox.size.width;
    return switch (_overlayAlignment) {
      .bottomLeft => Offset(0, parentHeight),
      .bottomRight => Offset(parentWidth, parentHeight),
      .topLeft => Offset.zero,
      .topRight => Offset(parentWidth, 0),
    };
  }

  void hideOverlay() {
    if (!mounted) return;
    setState(() => expandOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: hideOverlay,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
        ),
        Positioned(
          width: widget.overlayWidth ?? widget.parentBox.size.width,
          child: CompositedTransformFollower(
            link: widget.layerLink,
            followerAnchor: alignment,
            showWhenUnlinked: false,
            offset: overlayOffset,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration:
                  widget.decoration ??
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8.0,
                        color: Colors.black.withValues(alpha: .1),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
              child: _AnimatedSection(
                animationDismissed: () {
                  widget.onHideOverlay();
                  if (!mounted) return;
                  setState(() => expandOverlay = true);
                },
                expand: expandOverlay,
                alignment: overlayBottom ? Alignment.bottomCenter : Alignment.topCenter,
                duration: widget.duration,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(key: overlayKey, child: widget.overlay(hideOverlay)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
