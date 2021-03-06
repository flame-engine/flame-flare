part of flame_flare;

/// A class that wraps all the settings of a flare animation from [filename].
///
/// It has a similar API to the [FlareActor] widget.
class FlareActorAnimation {
  FlareActorAnimation(
    this.filename, {
    this.boundsNode,
    this.animation,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.isPaused = false,
    this.snapToEnd = false,
    this.controller,
    this.callback,
    this.color,
    this.shouldClip = true,
    this.sizeFromArtboard = false,
    this.artboard,
    this.useAntialias = true,
  }) : flareProvider = null;

  FlareActorAnimation.asset(
    this.flareProvider, {
    this.boundsNode,
    this.animation,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.isPaused = false,
    this.snapToEnd = false,
    this.controller,
    this.callback,
    this.color,
    this.shouldClip = true,
    this.sizeFromArtboard = false,
    this.artboard,
    this.useAntialias = true,
  }) : filename = null;

  FlareActorRenderObject _renderObject;

  // Flare only allows the render box to be loaded if it is considered "attached", we need this ugly dumb thing here to do that.
  final _pipelineOwner = _FlareActorComponentPipelineOwner();

  // Fields are ported from flare actor widget
  /// Mirror to [FlareActor.filename]
  final String filename;

  /// Mirror to [FlareActor.flareProvider]
  final AssetProvider flareProvider;

  /// Mirror to [FlareActor.artboard]
  final String artboard;

  /// Mirror to [FlareActor.animation]
  final String animation;

  /// Mirror to [FlareActor.snapToEnd]
  final bool snapToEnd;

  /// Mirror to [FlareActor.fit]
  final BoxFit fit;

  /// Mirror to [FlareActor.alignment]
  final Alignment alignment;

  /// Mirror to [FlareActor.isPaused]
  final bool isPaused;

  /// Mirror to [FlareActor.shouldClip]
  final bool shouldClip;

  /// Mirror to [FlareActor.controller]
  final FlareController controller;

  /// Mirror to [FlareActor.callback]
  final FlareCompletedCallback callback;

  /// Mirror to [FlareActor.color]
  final Color color;

  /// Mirror to [FlareActor.boundsNode]
  final String boundsNode;

  /// Mirror to [FlareActor.sizeFromArtboard]
  final bool sizeFromArtboard;

  /// When false disables antialiasing on drawables.
  final bool useAntialias;

  void init() {
    _renderObject = FlareActorRenderObject()
      ..assetProvider =
          flareProvider ?? AssetFlare(bundle: Flame.bundle, name: filename)
      ..alignment = alignment
      ..animationName = animation
      ..snapToEnd = snapToEnd
      ..isPaused = isPaused
      ..controller = controller
      ..completed = callback
      ..color = color
      ..shouldClip = shouldClip
      ..boundsNodeName = boundsNode
      ..useIntrinsicSize = sizeFromArtboard
      ..artboardName = artboard
      ..useAntialias = useAntialias;

    _loadRenderBox();
  }

  void render(Canvas canvas, ui.Size size) {
    assert(_renderObject != null,
        "FlareActorAnimation was rendered before initialization. Run FlareActorAnimation.init() before rendering it");
    final bounds = _renderObject.aabb;

    if (bounds != null) {
      _paintActor(canvas, bounds, size);
    }
  }

  void advance(double dt) {
    assert(_renderObject != null,
        "FlareActorAnimation was advanced before initialization. Run FlareActorAnimation.init() before calling .advance");
    _renderObject.advance(dt);
  }

  void destroy() {
    assert(_renderObject != null,
        "FlareActorAnimation was destroyed before initialization. Run FlareActorAnimation.init() before destroying it");
    _renderObject.dispose();
  }

  void _loadRenderBox() {
    _renderObject.attach(_pipelineOwner);
    if (!_renderObject.warmLoad()) {
      _renderObject.coldLoad();
    }
  }

  // Paint procedures ported from FlareRenderBox.paint with some changes that
  // makes sense on a flame context
  void _paintActor(Canvas c, AABB bounds, ui.Size size) {
    final position = Offset.zero;

    final contentWidth = bounds[2] - bounds[0];
    final contentHeight = bounds[3] - bounds[1];
    final x = -1 * bounds[0] -
        contentWidth / 2.0 -
        (alignment.x * contentWidth / 2.0);
    final y = -1 * bounds[1] -
        contentHeight / 2.0 -
        (alignment.y * contentHeight / 2.0);

    double scaleX = 1.0, scaleY = 1.0;

    c.save();
    // pre paint
    if (shouldClip) {
      c.clipRect(position & size);
    }

    // boxfit
    switch (fit) {
      case BoxFit.fill:
        scaleX = size.width / contentWidth;
        scaleY = size.height / contentHeight;
        break;
      case BoxFit.contain:
        double minScale =
            min(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = minScale;
        break;
      case BoxFit.cover:
        double maxScale =
            max(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = maxScale;
        break;
      case BoxFit.fitHeight:
        double minScale = size.height / contentHeight;
        scaleX = scaleY = minScale;
        break;
      case BoxFit.fitWidth:
        double minScale = size.width / contentWidth;
        scaleX = scaleY = minScale;
        break;
      case BoxFit.none:
        scaleX = scaleY = 1.0;
        break;
      case BoxFit.scaleDown:
        double minScale =
            min(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
        break;
    }

    final transform = Mat2D();
    transform[4] = size.width / 2.0 + (alignment.x * size.width / 2.0);
    transform[5] = size.height / 2.0 + (alignment.y * size.height / 2.0);
    Mat2D.scale(transform, transform, Vec2D.fromValues(scaleX, scaleY));
    final center = Mat2D();
    center[4] = x;
    center[5] = y;
    Mat2D.multiply(transform, transform, center);

    c.translate(
      size.width / 2.0 + (alignment.x * size.width / 2.0),
      size.height / 2.0 + (alignment.y * size.height / 2.0),
    );

    c.scale(scaleX, scaleY);
    c.translate(x, y);

    _renderObject.paintFlare(c, transform);
    c.restore();
    _renderObject.postPaint(c, position);
  }
}
