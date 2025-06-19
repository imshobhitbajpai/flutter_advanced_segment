import 'package:flutter/material.dart';

/// An advanced
class AdvancedSegment<K extends Object, V extends String>
    extends StatefulWidget {
  const AdvancedSegment({
    Key? key,
    required this.segments,
    this.controller,
    this.activeStyle = const TextStyle(
      fontWeight: FontWeight.w600,
    ),
    this.inactiveStyle,
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 15,
      vertical: 10,
    ),
    //this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.radius: 8,
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.sliderColor,
    this.sliderOffset = 2.0,
    this.animationDuration = const Duration(milliseconds: 250),
    this.shadow = const <BoxShadow>[
      BoxShadow(
        color: Color(0x42000000),
        blurRadius: 8.0,
      ),
    ],
    this.sliderDecoration,
    this.customMaxItemSize,
  })  : assert(segments.length > 1, 'Minimum segments amount is 2'),
        super(key: key);

  /// Controls segments selection.
  final ValueNotifier<K>? controller;

  /// Map of segments should be more than one keys.
  final Map<K, V> segments;

  /// Map of segments should be more than one keys.
  final Size? customMaxItemSize;

  /// Active text style.
  final TextStyle activeStyle;

  /// Inactive text style.
  final TextStyle? inactiveStyle;

  /// Padding of each item.
  final EdgeInsetsGeometry itemPadding;

  /// Common border radius.
  //final BorderRadius borderRadius;
  final double radius;

  /// Color of slider.
  final Color? sliderColor;

  /// Layout background color.
  final Color? backgroundColor;

  /// Layout surface color.
  final Color? surfaceTintColor;

  /// Layout shadow color.
  final Color? shadowColor;

  /// Gap between slider and layout.
  final double sliderOffset;

  /// Selection animation duration.
  final Duration animationDuration;

  /// Slide's Shadow
  final List<BoxShadow>? shadow;

  /// Slider decoration
  final BoxDecoration? sliderDecoration;

  @override
  _AdvancedSegmentState<K, V> createState() => _AdvancedSegmentState();
}

class _AdvancedSegmentState<K extends Object, V extends String>
    extends State<AdvancedSegment<K, V>> with SingleTickerProviderStateMixin {
  late final borderRadius;
  late final TextStyle _defaultTextStyle;
  late final AnimationController _animationController;
  late final ValueNotifier<K> _defaultController;
  late ValueNotifier<K> _controller;
  late Size _itemSize;
  late Size _containerSize;

  @override
  void initState() {
    super.initState();
    borderRadius = BorderRadius.all(Radius.circular(widget.radius));
    _defaultTextStyle = const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
    );

    _initSizes();

    _defaultController = ValueNotifier<K>(widget.segments.keys.first);

    _controller = widget.controller ?? _defaultController;
    _controller.addListener(_handleControllerChanged);

    _animationController = AnimationController(
      vsync: this,
      value: _obtainAnimationValue(),
      duration: widget.animationDuration,
    );
  }

  void _handleControllerChanged() {
    final animationValue = _obtainAnimationValue();

    _animationController.animateTo(
      animationValue,
      duration: widget.animationDuration,
    );
  }

  void _initSizes() {
    final maxSize = widget.customMaxItemSize ??
        widget.segments.values.map(_obtainTextSize).reduce((value, element) {
          return value.width.compareTo(element.width) >= 1 ? value : element;
        });

    _itemSize = Size(
      maxSize.width + widget.itemPadding.horizontal,
      maxSize.height + widget.itemPadding.vertical,
    );

    _containerSize = Size(
      _itemSize.width * widget.segments.length,
      _itemSize.height,
    );
  }

  @override
  void didUpdateWidget(covariant AdvancedSegment<K, V> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleControllerChanged);
      _controller = widget.controller ?? _defaultController;

      _handleControllerChanged();

      _controller.addListener(_handleControllerChanged);
    }

    if (oldWidget.segments != widget.segments) {
      _initSizes();

      _animationController.value = _obtainAnimationValue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.backgroundColor,
      shadowColor: widget.shadowColor,
      surfaceTintColor: widget.surfaceTintColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Container(
        width: _containerSize.width,
        height: _containerSize.height,
        //clipBehavior: Clip.antiAlias,
        // decoration: BoxDecoration(
        //   color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface.withOpacity(.5),
        //   borderRadius: borderRadius,
        // ),
        child: Opacity(
          opacity: widget.controller != null ? 1 : 0.75,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (_, child) {
                  return Transform.translate(
                    offset: Tween<Offset>(
                      begin: Offset.zero,
                      end: _obtainEndOffset(Directionality.of(context)),
                    )
                        .animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.linear,
                        ))
                        .value,
                    child: child,
                  );
                },
                child: FractionallySizedBox(
                  widthFactor: 1 / widget.segments.length,
                  heightFactor: 1,
                  child: Container(
                    margin: EdgeInsets.all(widget.sliderOffset),
                    // height: _itemSize.height - widget.sliderOffset * 2,
                    decoration: widget.sliderDecoration ??
                        BoxDecoration(
                          color: widget.sliderColor ??
                              Theme.of(context).primaryColor,
                          // borderRadius: borderRadius.subtract(
                          //     BorderRadius.all(
                          //         Radius.circular(widget.sliderOffset))),
                          borderRadius: borderRadius,
                          boxShadow: widget.shadow,
                        ),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (_, value, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: widget.segments.entries.map((entry) {
                      return InkWell(
                        // onHorizontalDragUpdate: (details) => _handleSegmentMove(
                        //   details,
                        //   entry.key,
                        //   Directionality.of(context),
                        // ),
                        radius:  widget.radius,
                        borderRadius: borderRadius,
                        onTap: () => _handleSegmentPressed(entry.key),
                        child: Container(
                          width: _itemSize.width,
                          height: _itemSize.height,
                          alignment: Alignment.center,
                          //padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: AnimatedDefaultTextStyle(
                              duration: widget.animationDuration,
                              style: _defaultTextStyle.merge(value == entry.key
                                  ? widget.activeStyle.merge(TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer))
                                  : widget.inactiveStyle ??
                                      TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                              softWrap: false,
                              child: Center(
                                child: Text(entry.value),
                              ),
                          ),
                          // child: RawChip(
                          //   padding: EdgeInsets.zero,
                          //   side: const BorderSide(width: 0, color: Colors.transparent),
                          //   shape:  RoundedRectangleBorder(borderRadius: borderRadius),
                          //   backgroundColor: Colors.transparent,
                          //   onPressed: () => _handleSegmentPressed(entry.key),
                          //   label: Align(
                          //     alignment: Alignment.center,
                          //     child: AnimatedDefaultTextStyle(
                          //       duration: widget.animationDuration,
                          //       style: _defaultTextStyle.merge(value == entry.key
                          //           ? widget.activeStyle.merge(TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer))
                          //           : widget.inactiveStyle ?? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          //       overflow: TextOverflow.clip,
                          //       maxLines: 1,
                          //       softWrap: false,
                          //       child: Center(
                          //         child: Text(entry.value),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Size _obtainTextSize(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: _defaultTextStyle.merge(widget.activeStyle),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(
        minWidth: 0,
        maxWidth: double.infinity,
      );

    return textPainter.size;
  }

  double _obtainAnimationValue() {
    return widget.segments.keys
            .toList(growable: false)
            .indexOf(_controller.value)
            .toDouble() /
        (widget.segments.keys.length - 1);
  }

  void _handleSegmentPressed(K key) {
    if (widget.controller != null) {
      _controller.value = key;
    }
  }

  void _handleSegmentMove(
    DragUpdateDetails touch,
    K value,
    TextDirection textDirection,
  ) {
    if (widget.controller != null) {
      final indexKey = widget.segments.keys.toList().indexOf(value);

      final indexMove = textDirection == TextDirection.rtl
          ? (_itemSize.width * indexKey - touch.localPosition.dx) /
                  _itemSize.width +
              1
          : (_itemSize.width * indexKey + touch.localPosition.dx) /
              _itemSize.width;

      if (indexMove >= 0 && indexMove <= widget.segments.keys.length) {
        _controller.value = widget.segments.keys.elementAt(indexMove.toInt());
      }
    }
  }

  Offset _obtainEndOffset(TextDirection textDirection) {
    final dx = _itemSize.width * (widget.segments.length - 1);

    return Offset(textDirection == TextDirection.rtl ? -dx : dx, 0);
  }

  @override
  void dispose() {
    _animationController.dispose();

    _controller.removeListener(_handleControllerChanged);

    _defaultController.dispose();

    super.dispose();
  }
}
