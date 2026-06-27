import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/event.dart';
import '../../models/event_like_state.dart';
import '../../services/platform_info.dart';
import 'cupertino_glass.dart';

const _monthNames = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];
const _shareImageDownloadTimeout = Duration(seconds: 12);

String _formatLongDate(DateTime date) {
  return '${date.day} de ${_monthNames[date.month - 1]} de ${date.year}';
}

bool _isAfterDate(DateTime first, DateTime second) {
  final firstDate = DateTime(first.year, first.month, first.day);
  final secondDate = DateTime(second.year, second.month, second.day);
  return firstDate.isAfter(secondDate);
}

DateTime? _effectiveEndDate(Event event) {
  final endDate = event.endDate;
  if (endDate == null || !_isAfterDate(endDate, event.date)) {
    return null;
  }

  return endDate;
}

String _formatLongEventDate(Event event) {
  final startDate = event.date;
  final endDate = _effectiveEndDate(event);
  if (endDate == null) {
    return _formatLongDate(startDate);
  }

  if (startDate.year == endDate.year && startDate.month == endDate.month) {
    return '${startDate.day} a ${endDate.day} de '
        '${_monthNames[startDate.month - 1]} de ${startDate.year}';
  }

  if (startDate.year == endDate.year) {
    return '${startDate.day} de ${_monthNames[startDate.month - 1]} a '
        '${endDate.day} de ${_monthNames[endDate.month - 1]} de '
        '${startDate.year}';
  }

  return '${_formatLongDate(startDate)} a ${_formatLongDate(endDate)}';
}

String _formatShortEventDate(Event event) {
  final formatter = DateFormat('dd/MM/yyyy');
  final start = formatter.format(event.date);
  final endDate = _effectiveEndDate(event);
  if (endDate == null) {
    return start;
  }

  return '$start a ${formatter.format(endDate)}';
}

String _buildEventShareText(Event event) {
  return '''
${event.name}
${event.location}
${_formatShortEventDate(event)}

Confira mais no app Acontece Aqui.
''';
}

Uri? _eventImageUri(Event event) {
  final imageUrl = event.imageUrl.trim();
  if (imageUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(imageUrl);
  if (uri == null || !uri.hasScheme) {
    return null;
  }

  return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
}

String _imageMimeTypeFrom(Uri uri, String? contentType) {
  final normalizedContentType =
      contentType?.split(';').first.trim().toLowerCase();
  if (normalizedContentType != null &&
      normalizedContentType.startsWith('image/')) {
    return normalizedContentType;
  }

  final path = uri.path.toLowerCase();
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.webp')) return 'image/webp';
  if (path.endsWith('.gif')) return 'image/gif';
  if (path.endsWith('.heic')) return 'image/heic';
  if (path.endsWith('.jpeg') || path.endsWith('.jpg')) return 'image/jpeg';

  return 'image/jpeg';
}

String _imageExtensionFor(String mimeType) {
  return switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    'image/heic' => 'heic',
    _ => 'jpg',
  };
}

String _shareImageFileName(Event event, String mimeType) {
  final sourceName = event.id.trim().isEmpty ? event.name : event.id;
  final safeName = sourceName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final baseName = safeName.isEmpty ? 'evento' : safeName;

  return '$baseName.${_imageExtensionFor(mimeType)}';
}

Future<XFile?> _loadEventShareImage(Event event) async {
  final uri = _eventImageUri(event);
  if (uri == null) {
    return null;
  }

  try {
    final response = await http.get(uri).timeout(_shareImageDownloadTimeout);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        response.bodyBytes.isEmpty) {
      return null;
    }

    final mimeType = _imageMimeTypeFrom(uri, response.headers['content-type']);
    final fileName = _shareImageFileName(event, mimeType);
    final tempDirectory = await getTemporaryDirectory();
    final shareDirectory = Directory('${tempDirectory.path}/eventos_share');
    await shareDirectory.create(recursive: true);

    final file = File(
      '${shareDirectory.path}/${DateTime.now().microsecondsSinceEpoch}-$fileName',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);

    return XFile(
      file.path,
      mimeType: mimeType,
      name: fileName,
      length: response.bodyBytes.length,
    );
  } catch (_) {
    return null;
  }
}

/// Exibe um evento como item compacto de agenda.
class EventCard extends StatelessWidget {
  final Event evento;
  final bool isAdmin;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.evento,
    required this.isAdmin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = isCupertinoPlatform;
    final longDate = _formatLongEventDate(evento);
    final content = _EventListItemContent(
      evento: evento,
      isIOS: isIOS,
      longDate: longDate,
    );
    final locationLabel = evento.location.trim().isEmpty
        ? 'cidade não informada'
        : 'em ${evento.location}';
    final semanticsLabel =
        'Abrir detalhes do evento ${evento.name}, $longDate, $locationLabel';

    if (isIOS) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          pressedOpacity: 0.72,
          onPressed: onTap,
          child: content,
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

class _EventListItemContent extends StatelessWidget {
  const _EventListItemContent({
    required this.evento,
    required this.isIOS,
    required this.longDate,
  });

  final Event evento;
  final bool isIOS;
  final String longDate;

  @override
  Widget build(BuildContext context) {
    final styles = _EventTextStyles.resolve(context, isIOS: isIOS);
    final cityLabel = evento.location.trim().isEmpty
        ? 'Cidade não informada'
        : evento.location;
    final image = SafeImageBox(
      evento.imageUrl,
      semanticLabel: 'Imagem de ${evento.name}',
      width: 76,
      height: 76,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          image,
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: styles.title,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.metadata,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    longDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.metadata,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _EventDisclosureIcon(isIOS: isIOS),
        ],
      ),
    );
  }
}

class _EventDisclosureIcon extends StatelessWidget {
  const _EventDisclosureIcon({
    required this.isIOS,
  });

  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    final color = isIOS
        ? CupertinoColors.tertiaryLabel.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = isIOS ? CupertinoIcons.chevron_forward : Icons.chevron_right;

    return SizedBox(
      width: 28,
      height: 44,
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: color.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _AdaptiveActionButton extends StatelessWidget {
  const _AdaptiveActionButton({
    required this.isIOS,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final bool isIOS;
  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconContent = IconTheme.merge(
      data: IconThemeData(size: 22, color: color),
      child: icon,
    );

    if (isIOS) {
      return CupertinoGlassButton(
        semanticLabel: label,
        minSize: 44,
        padding: const EdgeInsets.all(10),
        foregroundColor: color,
        onPressed: onPressed,
        child: iconContent,
      );
    }

    return IconButton(
      tooltip: label,
      color: color,
      iconSize: 22,
      onPressed: onPressed,
      icon: iconContent,
    );
  }
}

class SafeImageBox extends StatelessWidget {
  final String url;
  final String semanticLabel;
  final double? width;
  final double? height;
  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const SafeImageBox(
    this.url, {
    super.key,
    this.semanticLabel = 'Imagem do evento',
    this.width,
    this.height,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = isCupertinoPlatform;
    final backgroundColor = isIOS
        ? CupertinoColors.secondarySystemBackground.resolveFrom(context)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foregroundColor = isIOS
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final placeholderTextStyle = isIOS
        ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )
        : Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            );

    final placeholder = LayoutBuilder(
      builder: (context, constraints) {
        final isThumbnail =
            constraints.maxHeight <= 112 || constraints.maxWidth <= 112;
        final isCompact =
            constraints.maxHeight < 160 || constraints.maxWidth < 280;

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isThumbnail ? 8 : 16,
              vertical: 8,
            ),
            child: isThumbnail
                ? Icon(
                    isIOS ? CupertinoIcons.photo : Icons.image_outlined,
                    color: foregroundColor,
                    size: 24,
                  )
                : isCompact
                    ? Text(
                        'Imagem indisponível',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: placeholderTextStyle,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIOS ? CupertinoIcons.photo : Icons.image_outlined,
                            color: foregroundColor,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Imagem do evento indisponível',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: placeholderTextStyle,
                          ),
                        ],
                      ),
          ),
        );
      },
    );

    final image = url.trim().isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            height: double.infinity,
            fit: fit,
            filterQuality: FilterQuality.high,
            imageBuilder: (context, imageProvider) => Image(
              image: imageProvider,
              semanticLabel: semanticLabel,
              width: double.infinity,
              height: double.infinity,
              fit: fit,
              filterQuality: FilterQuality.high,
            ),
            progressIndicatorBuilder: (context, imageUrl, progress) {
              return Center(
                child: isIOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorWidget: (context, imageUrl, error) => placeholder,
          );

    final imageFrame = ColoredBox(
      color: backgroundColor,
      child: image,
    );

    final constrainedImage = height == null
        ? AspectRatio(
            aspectRatio: aspectRatio,
            child: imageFrame,
          )
        : SizedBox(
            height: height,
            child: imageFrame,
          );

    return SizedBox(
      width: width ?? double.infinity,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: constrainedImage,
      ),
    );
  }
}

class SmallHeartAnimation extends StatefulWidget {
  final int likesCount;
  final bool isLiked;
  final bool isBusy;
  final Future<void> Function(bool isLiked) onChanged;

  const SmallHeartAnimation({
    super.key,
    required this.likesCount,
    required this.isLiked,
    required this.onChanged,
    this.isBusy = false,
  });

  @override
  State<SmallHeartAnimation> createState() => _SmallHeartAnimationState();
}

class _SmallHeartAnimationState extends State<SmallHeartAnimation>
    with SingleTickerProviderStateMixin {
  static const double _countSlotWidth = 28;

  late AnimationController _controller;
  late Animation<double> _moveUpAnimation;
  bool showHeart = false;

  bool get _isIOS => isCupertinoPlatform;

  String get _likesSemanticLabel {
    final likesCount = widget.likesCount;
    final count = '$likesCount curtida${likesCount == 1 ? '' : 's'}';
    return widget.isLiked ? 'Descurtir, $count' : 'Curtir, $count';
  }

  String get _visibleLikesCount {
    final likesCount = widget.likesCount;
    if (likesCount == 0) return '';
    if (likesCount > 9) return '9+';
    return likesCount.toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _moveUpAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => showHeart = false);
        _controller.reset();
      }
    });
  }

  Future<void> _toggleFavorite() async {
    if (widget.isBusy) {
      return;
    }

    final isLiking = !widget.isLiked;
    if (isLiking) {
      setState(() => showHeart = true);
      _controller.forward();
    }

    await widget.onChanged(isLiking);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.isLiked;
    final color = isLiked
        ? (_isIOS
            ? CupertinoColors.systemRed.resolveFrom(context)
            : Theme.of(context).colorScheme.error)
        : (_isIOS
            ? CupertinoColors.secondaryLabel.resolveFrom(context)
            : Theme.of(context).colorScheme.onSurfaceVariant);
    final icon = _isIOS
        ? (isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart)
        : (isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded);
    final filledIcon =
        _isIOS ? CupertinoIcons.heart_fill : Icons.favorite_rounded;

    final iconStack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        if (showHeart)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: _moveUpAnimation.value,
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Icon(filledIcon, color: color, size: 24),
                ),
              );
            },
          ),
      ],
    );
    final countSlotWidth =
        MediaQuery.textScalerOf(context).scale(_countSlotWidth);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconStack,
        SizedBox(
          width: countSlotWidth,
          child: _visibleLikesCount.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _visibleLikesCount,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );

    if (_isIOS) {
      return CupertinoGlassButton(
        semanticLabel: _likesSemanticLabel,
        minSize: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        foregroundColor: color,
        onPressed: widget.isBusy ? null : _toggleFavorite,
        child: content,
      );
    }

    return IconButton(
      tooltip: _likesSemanticLabel,
      color: color,
      iconSize: 22,
      onPressed: widget.isBusy ? null : _toggleFavorite,
      icon: content,
    );
  }
}

class EventDetailPage extends StatefulWidget {
  final Event evento;
  final bool isAdmin;
  final Future<bool> Function()? onDelete;
  final Future<bool> Function()? onEdit;
  final Future<EventLikeState?> Function()? onLoadLikeState;
  final Stream<Event?> Function()? onWatchEvent;
  final Stream<EventLikeState> Function()? onWatchLikeState;
  final Future<EventLikeState?> Function(bool isLiked)? onLikeChanged;
  final String? Function()? likeErrorMessage;

  const EventDetailPage({
    super.key,
    required this.evento,
    this.isAdmin = false,
    this.onDelete,
    this.onEdit,
    this.onLoadLikeState,
    this.onWatchEvent,
    this.onWatchLikeState,
    this.onLikeChanged,
    this.likeErrorMessage,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Event _event;
  late int _likesCount;
  late bool _isLiked;
  StreamSubscription<Event?>? _eventSubscription;
  StreamSubscription<EventLikeState>? _likeStateSubscription;
  bool _isSyncingLike = false;
  bool _isPreparingShare = false;

  bool get _isIOS => isCupertinoPlatform;

  @override
  void initState() {
    super.initState();
    _event = widget.evento;
    _likesCount = widget.evento.likesCount;
    _isLiked = widget.evento.isLiked;
    _subscribeToEvent();
    _subscribeToLikeState();
    if (widget.onWatchLikeState == null) {
      unawaited(_loadLikeState());
    }
  }

  @override
  void didUpdateWidget(covariant EventDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento != widget.evento) {
      _event = widget.evento;
    }
    if (oldWidget.evento.id != widget.evento.id ||
        oldWidget.onWatchEvent != widget.onWatchEvent) {
      _subscribeToEvent();
    }
    if (oldWidget.evento.id != widget.evento.id ||
        oldWidget.onWatchLikeState != widget.onWatchLikeState) {
      _likesCount = widget.evento.likesCount;
      _isLiked = widget.evento.isLiked;
      _subscribeToLikeState();
      if (widget.onWatchLikeState == null) {
        unawaited(_loadLikeState());
      }
    }
  }

  void _subscribeToEvent() {
    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;

    final watchEvent = widget.onWatchEvent;
    if (watchEvent == null) {
      return;
    }

    _eventSubscription = watchEvent().listen(
      (event) {
        if (!mounted) {
          return;
        }

        if (event == null) {
          Navigator.maybePop(context);
          return;
        }

        setState(() => _event = event);
      },
      onError: (_) {},
    );
  }

  void _subscribeToLikeState() {
    unawaited(_likeStateSubscription?.cancel());
    _likeStateSubscription = null;

    final watchLikeState = widget.onWatchLikeState;
    if (watchLikeState == null) {
      return;
    }

    _likeStateSubscription = watchLikeState().listen(
      _applyLikeState,
      onError: (_) {
        if (!mounted) {
          return;
        }

        setState(() => _isSyncingLike = false);
      },
    );
  }

  void _applyLikeState(EventLikeState likeState) {
    if (!mounted) {
      return;
    }

    setState(() {
      _likesCount = likeState.likesCount;
      _isLiked = likeState.isLiked;
      _isSyncingLike = false;
    });
  }

  Future<void> _showMessage(String message) async {
    if (_isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadLikeState() async {
    final loadLikeState = widget.onLoadLikeState;
    if (loadLikeState == null) {
      return;
    }

    final loadedLikeState = await loadLikeState();
    if (loadedLikeState == null || !mounted) {
      return;
    }

    _applyLikeState(loadedLikeState);
  }

  Rect? _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _shareEvent() async {
    if (_isPreparingShare) {
      return;
    }

    setState(() => _isPreparingShare = true);

    final event = _event;
    final shareText = _buildEventShareText(event);

    try {
      final shareImage = await _loadEventShareImage(event);
      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: event.name,
          title: 'Compartilhar evento',
          files: shareImage == null ? null : [shareImage],
          fileNameOverrides: shareImage == null ? null : [shareImage.name],
          sharePositionOrigin: _sharePositionOrigin(),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      try {
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            subject: event.name,
            title: 'Compartilhar evento',
            sharePositionOrigin: _sharePositionOrigin(),
          ),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }

        await _showMessage('Não foi possível abrir o compartilhamento.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPreparingShare = false);
      }
    }
  }

  Future<void> _handleLikeChanged(bool isLiked) async {
    final previousLikesCount = _likesCount;
    final previousIsLiked = _isLiked;
    final optimisticLikesCount =
        isLiked ? _likesCount + 1 : (_likesCount > 0 ? _likesCount - 1 : 0);

    setState(() {
      _isSyncingLike = true;
      _isLiked = isLiked;
      _likesCount = optimisticLikesCount;
    });

    final changeLike = widget.onLikeChanged;
    EventLikeState? likeState;
    try {
      likeState = changeLike == null
          ? EventLikeState(
              likesCount: optimisticLikesCount,
              isLiked: isLiked,
            )
          : await changeLike(isLiked);
    } catch (_) {
      likeState = null;
    }

    if (!mounted) {
      return;
    }

    final savedLikeState = likeState;
    if (savedLikeState == null) {
      setState(() {
        _isSyncingLike = false;
        _likesCount = previousLikesCount;
        _isLiked = previousIsLiked;
      });
      await _showMessage(
        widget.likeErrorMessage?.call() ??
            'Não foi possível atualizar a curtida.',
      );
      return;
    }

    setState(() {
      _isSyncingLike = false;
      _likesCount = savedLikeState.likesCount;
      _isLiked = savedLikeState.isLiked;
    });
  }

  Future<void> _handleDelete() async {
    bool confirm = false;

    if (_isIOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Excluir evento'),
          content: const Text('Tem certeza que deseja excluir este evento?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      confirm = result == true;
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir evento'),
          content: const Text('Tem certeza que deseja excluir este evento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      confirm = result == true;
    }

    if (!confirm) {
      return;
    }

    final deleted = await widget.onDelete?.call() ?? false;
    if (deleted && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleEdit() async {
    final updated = await widget.onEdit?.call() ?? false;
    if (updated && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    unawaited(_likeStateSubscription?.cancel());
    super.dispose();
  }

  Widget _buildActions(BuildContext context) {
    final secondaryColor = _isIOS
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final destructiveColor = _isIOS
        ? CupertinoColors.systemRed.resolveFrom(context)
        : Theme.of(context).colorScheme.error;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        SmallHeartAnimation(
          likesCount: _likesCount,
          isLiked: _isLiked,
          isBusy: _isSyncingLike,
          onChanged: _handleLikeChanged,
        ),
        _AdaptiveActionButton(
          isIOS: _isIOS,
          label: 'Compartilhar evento',
          icon: Icon(_isIOS ? CupertinoIcons.share : Icons.share_outlined),
          color: _isPreparingShare
              ? secondaryColor.withValues(alpha: 0.48)
              : secondaryColor,
          onPressed: _isPreparingShare ? null : _shareEvent,
        ),
        if (widget.isAdmin && widget.onEdit != null)
          _AdaptiveActionButton(
            isIOS: _isIOS,
            label: 'Editar',
            icon: Icon(_isIOS ? CupertinoIcons.pencil : Icons.edit_outlined),
            color: secondaryColor,
            onPressed: _handleEdit,
          ),
        if (widget.isAdmin && widget.onDelete != null)
          _AdaptiveActionButton(
            isIOS: _isIOS,
            label: 'Excluir',
            icon: Icon(_isIOS ? CupertinoIcons.delete : Icons.delete_outline),
            color: destructiveColor,
            onPressed: _handleDelete,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _EventDetailContent(
      evento: _event,
      isIOS: _isIOS,
      actions: _buildActions(context),
    );

    if (_isIOS) {
      return CupertinoPageScaffold(
        navigationBar: cupertinoGlassNavigationBar(
          middle: const Text('Evento'),
        ),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Evento')),
      body: SafeArea(child: content),
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  const _EventDetailContent({
    required this.evento,
    required this.isIOS,
    required this.actions,
  });

  final Event evento;
  final bool isIOS;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final styles = _EventTextStyles.resolve(context, isIOS: isIOS);
    final description = evento.description.trim();
    final locationLabel = evento.location.trim().isEmpty
        ? 'Cidade não informada'
        : 'Em ${evento.location}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final imageHeight = constraints.maxWidth >= 560 ? 420.0 : null;
                final image = SafeImageBox(
                  evento.imageUrl,
                  semanticLabel: 'Imagem de ${evento.name}',
                  height: imageHeight,
                  aspectRatio: 4 / 5,
                  fit: BoxFit.cover,
                );

                return image;
              },
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evento.name, style: styles.detailTitle),
                const SizedBox(height: 10),
                Text(_formatLongEventDate(evento), style: styles.metadata),
                const SizedBox(height: 4),
                Text(locationLabel, style: styles.metadata),
                const SizedBox(height: 14),
                actions,
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('Sobre o evento', style: styles.sectionTitle),
              const SizedBox(height: 10),
              Text(description, style: styles.detailDescription),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventTextStyles {
  const _EventTextStyles({
    required this.title,
    required this.detailTitle,
    required this.metadata,
    required this.sectionTitle,
    required this.detailDescription,
  });

  final TextStyle title;
  final TextStyle detailTitle;
  final TextStyle metadata;
  final TextStyle sectionTitle;
  final TextStyle detailDescription;

  factory _EventTextStyles.resolve(
    BuildContext context, {
    required bool isIOS,
  }) {
    if (isIOS) {
      final textTheme = CupertinoTheme.of(context).textTheme;
      final labelColor = CupertinoColors.label.resolveFrom(context);
      final secondaryLabelColor =
          CupertinoColors.secondaryLabel.resolveFrom(context);

      return _EventTextStyles(
        title: textTheme.navTitleTextStyle.copyWith(
          color: labelColor,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        detailTitle: textTheme.navLargeTitleTextStyle.copyWith(
          color: labelColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        metadata: textTheme.textStyle.copyWith(
          color: secondaryLabelColor,
          fontSize: 15,
          height: 1.3,
        ),
        sectionTitle: textTheme.navTitleTextStyle.copyWith(
          color: labelColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        detailDescription: textTheme.textStyle.copyWith(
          color: labelColor,
          fontSize: 17,
          height: 1.5,
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return _EventTextStyles(
      title: textTheme.titleLarge!.copyWith(
        color: colorScheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      detailTitle: textTheme.headlineMedium!.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      metadata: textTheme.bodyMedium!.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
      sectionTitle: textTheme.titleLarge!.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      detailDescription: textTheme.bodyLarge!.copyWith(
        color: colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }
}
