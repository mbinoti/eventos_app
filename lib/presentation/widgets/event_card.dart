import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/event.dart';
import '../../repositories/event_repository.dart';

/// Um card de evento clicável que exibe os detalhes básicos do evento e permite ações como compartilhar, excluir e favoritar.
class EventCard extends StatefulWidget {
  final Event evento;
  final bool isAdmin;
  final EventRepository repository;

  const EventCard({
    super.key,
    required this.evento,
    required this.isAdmin,
    required this.repository,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  void compartilharEvento() {
    final texto = '''
🎉 ${widget.evento.name}
📍 ${widget.evento.location}
📅 ${DateFormat('dd/MM/yyyy').format(widget.evento.date)}
Confira mais no app Eventos Locais!
''';
    Share.share(texto);
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(widget.evento.date);
    final imageUrl = widget.evento.imageUrl;

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
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SmallHeartAnimation(),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.paperPlane,
                          color: Colors.white),
                      onPressed: compartilharEvento,
                    ),
                    if (widget.isAdmin)
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.trash,
                            color: Colors.white),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Excluir Evento'),
                              content: const Text(
                                  'Tem certeza que deseja excluir este evento?'),
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
                          if (confirm == true) {
                            await widget.repository
                                .deleteEvent(widget.evento.id);
                          }
                        },
                      ),
                  ],
                ),
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
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text('Erro ao carregar imagem')),
          ),
        ),
      ),
    );
  }
}

class SmallHeartAnimation extends StatefulWidget {
  const SmallHeartAnimation({super.key});

  @override
  State<SmallHeartAnimation> createState() => _SmallHeartAnimationState();
}

class _SmallHeartAnimationState extends State<SmallHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUpAnimation;
  bool showHeart = false;
  bool isFavorited = false;

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

  void _toggleFavorite() {
    setState(() {
      isFavorited = !isFavorited;
      showHeart = isFavorited;
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
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            isFavorited ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
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
                  child: const Icon(FontAwesomeIcons.solidHeart,
                      color: Colors.red, size: 24),
                ),
              );
            },
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
    return Scaffold(
      body: Column(
        children: [
          // Botão de voltar
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // Imagem do evento
          Hero(
            tag: 'evento-${evento.id}',
            child: SafeImageBox(evento.imageUrl, height: 300),
          ),

          // Detalhes do evento
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
