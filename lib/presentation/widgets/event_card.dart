import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/event.dart';

/// Um card de evento clicável que exibe os detalhes básicos do evento e permite ações como compartilhar, excluir e favoritar.
class EventCard extends StatefulWidget {
  final Event evento;
  final bool isAdmin;
  final Future<void> Function()? onDelete;

  const EventCard({
    super.key,
    required this.evento,
    required this.isAdmin,
    this.onDelete,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool get _isIOS => Theme.of(context).platform == TargetPlatform.iOS;

  TextStyle _eventCaptionStyle(BuildContext context) {
    if (_isIOS) {
      return TextStyle(
        inherit: false,
        color: CupertinoColors.label.resolveFrom(context),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        decoration: TextDecoration.none,
        decorationColor: const Color(0x00000000),
      );
    }

    return const TextStyle(
      inherit: false,
      color: Color(0xFFE0E0E0),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
  }

  Future<void> compartilharEvento() async {
    final texto = '''
🎉 ${widget.evento.name}
📍 ${widget.evento.location}
📅 ${DateFormat('dd/MM/yyyy').format(widget.evento.date)}
Confira mais no app Eventos Locais!
''';

    await SharePlus.instance.share(
      ShareParams(text: texto),
    );
  }

  Future<void> _handleDelete() async {
    bool confirm = false;

    if (_isIOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Excluir Evento'),
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
          title: const Text('Excluir Evento'),
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

    if (confirm) {
      await widget.onDelete?.call();
    }
  }

  Widget _buildActions() {
    if (_isIOS) {
      return Row(
        children: [
          SmallHeartAnimation(
            initialLikesCount: widget.evento.likesCount,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: compartilharEvento,
            child: const Icon(CupertinoIcons.paperplane),
          ),
          if (widget.isAdmin)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: _handleDelete,
              child: const Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.systemRed,
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        SmallHeartAnimation(
          initialLikesCount: widget.evento.likesCount,
        ),
        IconButton(
          icon: const Icon(FontAwesomeIcons.paperPlane, color: Colors.white),
          onPressed: compartilharEvento,
        ),
        if (widget.isAdmin)
          IconButton(
            icon: const Icon(FontAwesomeIcons.trash, color: Colors.white),
            onPressed: _handleDelete,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(widget.evento.date);
    final imageUrl = widget.evento.imageUrl;

    if (_isIOS) {
      return Container(
        margin: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty) SafeImageBox(imageUrl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.evento.name} • $dataFormatada • ${widget.evento.location}',
                    style: _eventCaptionStyle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildActions(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty) SafeImageBox(imageUrl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.evento.name} • $dataFormatada • ${widget.evento.location}',
                  style: _eventCaptionStyle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SafeImageBox extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;

  const SafeImageBox(
    this.url, {
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      width: width ?? double.infinity,
      height: height ?? 400,
      color: Colors.grey[200],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Center(
                    child: isIOS
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  ),
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text('Erro ao carregar imagem')),
          ),
        ),
      ),
    );
  }
}

class SmallHeartAnimation extends StatefulWidget {
  final int initialLikesCount;

  const SmallHeartAnimation({
    super.key,
    this.initialLikesCount = 0,
  });

  @override
  State<SmallHeartAnimation> createState() => _SmallHeartAnimationState();
}

class _SmallHeartAnimationState extends State<SmallHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUpAnimation;
  bool showHeart = false;
  bool isFavorited = false;
  late int likesCount;

  bool get _isIOS => Theme.of(context).platform == TargetPlatform.iOS;

  String get _likesLabel => '$likesCount curtida${likesCount == 1 ? '' : 's'}';

  @override
  void initState() {
    super.initState();
    likesCount = widget.initialLikesCount;
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

  void _toggleFavorite() {
    setState(() {
      final isLiking = !isFavorited;
      isFavorited = isLiking;
      showHeart = isLiking;
      if (isLiking) {
        likesCount += 1;
      } else if (likesCount > 0) {
        likesCount -= 1;
      }
    });

    if (isFavorited) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlinedIcon = _isIOS ? CupertinoIcons.heart : FontAwesomeIcons.heart;
    final filledIcon =
        _isIOS ? CupertinoIcons.heart_fill : FontAwesomeIcons.solidHeart;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _isIOS
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: _toggleFavorite,
                    child: Icon(
                      isFavorited ? filledIcon : outlinedIcon,
                      color: isFavorited
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      isFavorited ? filledIcon : outlinedIcon,
                      color: isFavorited ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
            if (showHeart)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Positioned(
                    top: _moveUpAnimation.value,
                    child: Opacity(
                      opacity: 1.0 - _controller.value,
                      child: Icon(
                        filledIcon,
                        color: _isIOS ? CupertinoColors.systemRed : Colors.red,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        if (likesCount > 0)
          Text(
            _likesLabel,
            style: TextStyle(
              inherit: false,
              color: _isIOS
                  ? CupertinoColors.label.resolveFrom(context)
                  : const Color(0xFFE0E0E0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}

class EventDetailPage extends StatelessWidget {
  final Event evento;

  const EventDetailPage({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final content = Column(
      children: [
        Hero(
          tag: 'evento-${evento.id}',
          child: SafeImageBox(evento.imageUrl, height: 300),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView(
              children: [
                Text(
                  evento.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd/MM/yyyy – HH:mm').format(evento.date),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  evento.location,
                  style: const TextStyle(fontSize: 18),
                ),
                if (evento.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    evento.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Detalhes do Evento'),
        ),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: content,
    );
  }
}
