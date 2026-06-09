import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/event_repository.dart';
import '../../repositories/storage_repository.dart';
import '../viewmodels/cadastro_evento_view_model.dart';
import 'cadastro_evento_screen.dart';
import '../../services/platform_info.dart';

class AdminPanelScreen extends StatelessWidget {
  final bool isAdmin;

  const AdminPanelScreen({
    super.key,
    required this.isAdmin,
  });

  Future<void> _openCadastro(BuildContext context) async {
    final isIOS = isCupertinoPlatform;
    final eventRepository = context.read<EventRepository>();
    final storageRepository = context.read<StorageRepository>();

    final page = ChangeNotifierProvider(
      create: (_) => CadastroEventoViewModel(
        storageRepository: storageRepository,
        eventRepository: eventRepository,
      ),
      child: const CadastroEventoScreen(),
    );

    final result = await Navigator.push(
      context,
      isIOS
          ? CupertinoPageRoute(builder: (_) => page)
          : MaterialPageRoute(builder: (_) => page),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = isCupertinoPlatform;
    final titleStyle = isIOS
        ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            )
        : Theme.of(context).textTheme.titleMedium;

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Modo administrador ativo.' : 'Perfil de usuário.',
            style: titleStyle,
          ),
          const SizedBox(height: 16),
          if (isAdmin)
            isIOS
                ? CupertinoButton.filled(
                    onPressed: () => _openCadastro(context),
                    child: const Text('Cadastrar novo evento'),
                  )
                : FilledButton.icon(
                    onPressed: () => _openCadastro(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar novo evento'),
                  ),
        ],
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Perfil'),
        ),
        child: SafeArea(child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: body,
    );
  }
}
