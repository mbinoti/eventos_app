import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cadastro_evento_view_model.dart';

class CadastroEventoScreen extends StatefulWidget {
  const CadastroEventoScreen({super.key});

  @override
  State<CadastroEventoScreen> createState() => _CadastroEventoScreenState();
}

class _CadastroEventoScreenState extends State<CadastroEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _comentariosController = TextEditingController();

  DateTime? _dataEvento;
  List<File> _imagensSelecionadas = [];

  bool get _isIOS => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  void dispose() {
    _tituloController.dispose();
    _cidadeController.dispose();
    _comentariosController.dispose();
    super.dispose();
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

  Future<void> _selecionarData() async {
    if (_isIOS) {
      DateTime dataSelecionada = _dataEvento ?? DateTime.now();

      await showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () {
                    setState(() => _dataEvento = dataSelecionada);
                    Navigator.pop(context);
                  },
                  child: const Text('Concluir'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: dataSelecionada,
                  minimumDate: DateTime(2024),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (value) => dataSelecionada = value,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (data != null) {
      setState(() => _dataEvento = data);
    }
  }

  Future<void> _selecionarImagens() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final imagens = pickedFiles.map((xfile) => File(xfile.path)).toList();
      setState(() => _imagensSelecionadas = imagens);
    } else {
      await _showMessage('Nenhuma imagem foi selecionada.');
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_isIOS) {
      if (_tituloController.text.trim().isEmpty ||
          _cidadeController.text.trim().isEmpty) {
        await _showMessage('Preencha todos os campos obrigatórios');
        return;
      }
    } else {
      if (!_formKey.currentState!.validate()) {
        await _showMessage('Preencha todos os campos obrigatórios');
        return;
      }
    }

    if (_dataEvento == null) {
      await _showMessage('Selecione a data do evento.');
      return;
    }

    if (_imagensSelecionadas.isEmpty) {
      await _showMessage('Selecione pelo menos uma imagem.');
      return;
    }

    final cadastroViewModel = context.read<CadastroEventoViewModel>();

    final success = await cadastroViewModel.cadastrarEvento(
      titulo: _tituloController.text.trim(),
      cidade: _cidadeController.text.trim(),
      dataEvento: _dataEvento!,
      imagens: _imagensSelecionadas,
      descricao: _comentariosController.text.trim(),
    );

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    final error = cadastroViewModel.errorMessage;
    if (error != null && error.isNotEmpty) {
      await _showMessage('Erro: $error');
    }
  }

  Widget _buildTituloField() {
    if (_isIOS) {
      return CupertinoTextField(
        controller: _tituloController,
        placeholder: 'Título',
        padding: const EdgeInsets.all(12),
      );
    }

    return TextFormField(
      controller: _tituloController,
      decoration: const InputDecoration(labelText: 'Título'),
      validator: (value) =>
          value == null || value.isEmpty ? 'Informe o título' : null,
    );
  }

  Widget _buildCidadeField() {
    if (_isIOS) {
      return CupertinoTextField(
        controller: _cidadeController,
        placeholder: 'Cidade',
        padding: const EdgeInsets.all(12),
      );
    }

    return TextFormField(
      controller: _cidadeController,
      decoration: const InputDecoration(labelText: 'Cidade'),
      validator: (value) =>
          value == null || value.isEmpty ? 'Informe a cidade' : null,
    );
  }

  Widget _buildComentariosField() {
    if (_isIOS) {
      return CupertinoTextField(
        controller: _comentariosController,
        placeholder: 'Comentários (opcional)',
        padding: const EdgeInsets.all(12),
        minLines: 3,
        maxLines: 6,
      );
    }

    return TextFormField(
      controller: _comentariosController,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      minLines: 3,
      decoration: const InputDecoration(
        labelText: 'Comentários (opcional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        _isIOS ? CupertinoColors.systemBackground.resolveFrom(context) : null;

    return Consumer<CadastroEventoViewModel>(
      builder: (context, viewModel, _) {
        final carregando = viewModel.isLoading;

        final content = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTituloField(),
                const SizedBox(height: 12),
                _buildCidadeField(),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _dataEvento == null
                          ? 'Selecione a data do evento'
                          : 'Data: ${_dataEvento!.day}/${_dataEvento!.month}/${_dataEvento!.year}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment:
                          _isIOS ? Alignment.centerLeft : Alignment.centerRight,
                      child: _isIOS
                          ? CupertinoButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              onPressed: _selecionarData,
                              child: const Text('Data'),
                            )
                          : ElevatedButton(
                              onPressed: _selecionarData,
                              child: const Text('Selecionar Data'),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _imagensSelecionadas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(
                          file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: _isIOS
                              ? CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  onPressed: () {
                                    setState(() =>
                                        _imagensSelecionadas.removeAt(index));
                                  },
                                  child: const Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: CupertinoColors.systemRed,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.red),
                                  tooltip: 'Remover imagem',
                                  onPressed: () {
                                    setState(() =>
                                        _imagensSelecionadas.removeAt(index));
                                  },
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                _isIOS
                    ? CupertinoButton(
                        onPressed: _selecionarImagens,
                        child: const Text('Selecionar Imagens'),
                      )
                    : TextButton.icon(
                        onPressed: _selecionarImagens,
                        icon: const Icon(Icons.image),
                        label: const Text('Selecionar Imagens'),
                      ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: _buildComentariosField(),
                  ),
                ),
                const SizedBox(height: 20),
                carregando
                    ? Center(
                        child: _isIOS
                            ? const CupertinoActivityIndicator()
                            : const CircularProgressIndicator(),
                      )
                    : _isIOS
                        ? CupertinoButton.filled(
                            onPressed: () => _submitForm(context),
                            child: const Text('Salvar Evento'),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _submitForm(context),
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar Evento'),
                          ),
              ],
            ),
          ),
        );

        if (_isIOS) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Cadastrar Evento'),
            ),
            child: SafeArea(child: content),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(title: const Text('Cadastrar Evento')),
          body: content,
        );
      },
    );
  }
}
