import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/event.dart';
import '../../models/event_like_state.dart';
import '../../services/platform_info.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: 'evento-${evento.id}',
            child: SafeImageBox(
              evento.imageUrl,
              semanticLabel: 'Imagem de ${evento.name}',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final iconContent = IconTheme.merge(
      data: IconThemeData(size: 22, color: color),
      child: icon,
    );

    if (isIOS) {
      return Semantics(
        label: label,
        button: true,
        child: CupertinoButton(
          minimumSize: const Size.square(44),
          padding: const EdgeInsets.all(10),
          onPressed: onPressed,
          child: iconContent,
        ),
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
        : Image.network(
            url,
            semanticLabel: semanticLabel,
            width: double.infinity,
            height: double.infinity,
            fit: fit,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return Center(
                child: isIOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) => placeholder,
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
      return Semantics(
        label: _likesSemanticLabel,
        button: true,
        child: CupertinoButton(
          minimumSize: const Size.square(44),
          padding: const EdgeInsets.all(10),
          onPressed: widget.isBusy ? null : _toggleFavorite,
          child: content,
        ),
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
  final Future<EventLikeState?> Function()? onLoadLikeState;
  final Future<EventLikeState?> Function(bool isLiked)? onLikeChanged;
  final String? Function()? likeErrorMessage;

  const EventDetailPage({
    super.key,
    required this.evento,
    this.isAdmin = false,
    this.onDelete,
    this.onLoadLikeState,
    this.onLikeChanged,
    this.likeErrorMessage,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late int _likesCount;
  late bool _isLiked;
  bool _isSyncingLike = false;

  bool get _isIOS => isCupertinoPlatform;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.evento.likesCount;
    _isLiked = widget.evento.isLiked;
    _loadLikeState();
  }

  @override
  void didUpdateWidget(covariant EventDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id) {
      _likesCount = widget.evento.likesCount;
      _isLiked = widget.evento.isLiked;
      _loadLikeState();
    }
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

    setState(() {
      _likesCount = loadedLikeState.likesCount;
      _isLiked = loadedLikeState.isLiked;
    });
  }

  Future<void> _shareEventOnWhatsApp() async {
    final uri = Uri.https('wa.me', '/', {
      'text': _buildEventShareText(widget.evento),
    });
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      await _showMessage('Não foi possível abrir o WhatsApp.');
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
          label: 'Compartilhar no WhatsApp',
          icon: const FaIcon(FontAwesomeIcons.whatsapp),
          color: secondaryColor,
          onPressed: _shareEventOnWhatsApp,
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
      evento: widget.evento,
      isIOS: _isIOS,
      actions: _buildActions(context),
    );

    if (_isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Evento'),
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

                return Hero(
                  tag: 'evento-${evento.id}',
                  child: SafeImageBox(
                    evento.imageUrl,
                    semanticLabel: 'Imagem de ${evento.name}',
                    height: imageHeight,
                    aspectRatio: 4 / 5,
                    fit: BoxFit.cover,
                  ),
                );
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
