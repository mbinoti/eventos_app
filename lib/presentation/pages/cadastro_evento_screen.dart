import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../viewmodels/cadastro_evento_view_model.dart';
import '../widgets/cupertino_glass.dart';
import '../../services/platform_info.dart';

class CadastroEventoScreen extends StatefulWidget {
  const CadastroEventoScreen({
    super.key,
    this.eventoInicial,
  });

  final Event? eventoInicial;

  @override
  State<CadastroEventoScreen> createState() => _CadastroEventoScreenState();
}

class _CadastroEventoScreenState extends State<CadastroEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _comentariosController = TextEditingController();

  DateTime? _dataEvento;
  DateTime? _dataFimEvento;
  List<File> _imagensSelecionadas = [];

  bool get _isIOS => isCupertinoPlatform;
  bool get _isEditing => widget.eventoInicial != null;

  @override
  void initState() {
    super.initState();
    final evento = widget.eventoInicial;
    if (evento == null) {
      return;
    }

    _tituloController.text = evento.name;
    _cidadeController.text = evento.location;
    _comentariosController.text = evento.description;
    _dataEvento = evento.date;
    _dataFimEvento = evento.endDate;
  }

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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isBeforeDate(DateTime first, DateTime second) {
    return _dateOnly(first).isBefore(_dateOnly(second));
  }

  bool _isAfterDate(DateTime first, DateTime second) {
    return _dateOnly(first).isAfter(_dateOnly(second));
  }

  DateTime _today() {
    final now = DateTime.now();
    return _dateOnly(now);
  }

  void _setSelectedDate(DateTime date, {required bool isEndDate}) {
    setState(() {
      if (isEndDate) {
        final startDate = _dataEvento;
        _dataFimEvento =
            startDate != null && !_isAfterDate(date, startDate) ? null : date;
        return;
      }

      _dataEvento = date;
      final endDate = _dataFimEvento;
      if (endDate != null && !_isAfterDate(endDate, date)) {
        _dataFimEvento = null;
      }
    });
  }

  Future<void> _selecionarData({required bool isEndDate}) async {
    final today = _today();
    final firstDate = isEndDate
        ? _dataEvento ?? (_isEditing ? DateTime(2024) : today)
        : _isEditing
            ? DateTime(2024)
            : today;
    final selectedDate = isEndDate ? _dataFimEvento : _dataEvento;
    final fallbackDate =
        isEndDate ? _dataEvento ?? DateTime.now() : DateTime.now();
    final initialDate = _isBeforeDate(selectedDate ?? fallbackDate, firstDate)
        ? firstDate
        : selectedDate ?? fallbackDate;

    if (_isIOS) {
      DateTime dataSelecionada = initialDate;

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onPressed: () {
                    _setSelectedDate(dataSelecionada, isEndDate: isEndDate);
                    Navigator.pop(context);
                  },
                  child: const Text('Concluir'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
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
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );
    if (data != null) {
      _setSelectedDate(data, isEndDate: isEndDate);
    }
  }

  Future<void> _selecionarImagensDaGaleria() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final imagens = pickedFiles.map((xfile) => File(xfile.path)).toList();
      setState(() => _imagensSelecionadas = imagens);
    } else {
      await _showMessage('Nenhuma imagem foi selecionada.');
    }
  }

  Future<void> _selecionarImagensDosArquivos() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
      allowMultiple: true,
    );

    final paths = result?.paths.whereType<String>().toList() ?? [];
    if (paths.isNotEmpty) {
      setState(() => _imagensSelecionadas = paths.map(File.new).toList());
    } else {
      await _showMessage('Nenhuma imagem foi selecionada.');
    }
  }

  Future<void> _selecionarImagens() async {
    if (_isIOS) {
      await _selecionarImagensDaGaleria();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Fotos'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarImagensDaGaleria();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Arquivos'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarImagensDosArquivos();
                },
              ),
            ],
          ),
        );
      },
    );
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

    if (!_isEditing && _isBeforeDate(_dataEvento!, _today())) {
      await _showMessage(
          'A data de início não pode ser anterior à data de hoje.');
      return;
    }

    final dataFimEvento = _dataFimEvento;
    if (dataFimEvento != null && _isBeforeDate(dataFimEvento, _dataEvento!)) {
      await _showMessage(
          'A data de fim não pode ser anterior à data de início.');
      return;
    }

    if (!_isEditing && _imagensSelecionadas.isEmpty) {
      await _showMessage('Selecione pelo menos uma imagem.');
      return;
    }

    final cadastroViewModel = context.read<CadastroEventoViewModel>();

    final eventoInicial = widget.eventoInicial;
    final success = eventoInicial == null
        ? await cadastroViewModel.cadastrarEvento(
            titulo: _tituloController.text.trim(),
            cidade: _cidadeController.text.trim(),
            dataEvento: _dataEvento!,
            dataFimEvento: dataFimEvento,
            imagens: _imagensSelecionadas,
            descricao: _comentariosController.text.trim(),
          )
        : await cadastroViewModel.atualizarEvento(
            evento: eventoInicial,
            titulo: _tituloController.text.trim(),
            cidade: _cidadeController.text.trim(),
            dataEvento: _dataEvento!,
            dataFimEvento: dataFimEvento,
            novasImagens: _imagensSelecionadas,
            descricao: _comentariosController.text.trim(),
          );

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    final error = cadastroViewModel.errorMessage;
    if (error != null && error.isNotEmpty) {
      await _showMessage(error);
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

  Widget _buildDateField({
    required String title,
    required String emptyText,
    required String actionLabel,
    required DateTime? value,
    required VoidCallback onPressed,
    VoidCallback? onClear,
  }) {
    final text = value == null ? emptyText : '$title: ${_formatDate(value)}';
    final textStyle = _isIOS
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
              fontSize: 16,
            )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            );

    final clearButton = onClear == null
        ? null
        : _isIOS
            ? CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: onClear,
                child: const Icon(CupertinoIcons.clear_circled),
              )
            : IconButton(
                tooltip: 'Limpar data de fim',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              );

    final selectButton = _isIOS
        ? CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onPressed,
            child: Text(actionLabel),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_month),
            label: Text(actionLabel),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          style: textStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: _isIOS ? Alignment.centerLeft : Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (clearButton != null) clearButton,
              selectButton,
            ],
          ),
        ),
      ],
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
    final title = _isEditing ? 'Editar Evento' : 'Cadastrar Evento';
    final saveLabel = _isEditing ? 'Salvar Alterações' : 'Salvar Evento';
    final imageActionLabel =
        _isEditing ? 'Substituir Imagem' : 'Selecionar Imagens';

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
                    _buildDateField(
                      title: 'Início',
                      emptyText: 'Selecione a data de início do evento',
                      actionLabel: _dataEvento == null
                          ? 'Data de início'
                          : 'Alterar início',
                      value: _dataEvento,
                      onPressed: () => _selecionarData(isEndDate: false),
                    ),
                    const SizedBox(height: 12),
                    _buildDateField(
                      title: 'Fim',
                      emptyText: 'Sem data de fim',
                      actionLabel: _dataFimEvento == null
                          ? 'Data de fim'
                          : 'Alterar fim',
                      value: _dataFimEvento,
                      onPressed: () => _selecionarData(isEndDate: true),
                      onClear: _dataFimEvento == null
                          ? null
                          : () => setState(() => _dataFimEvento = null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                if (_isEditing &&
                    _imagensSelecionadas.isEmpty &&
                    (widget.eventoInicial?.imageUrl.trim().isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Imagem atual mantida. Selecione outra para substituir.',
                      style: _isIOS
                          ? CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              )
                          : Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                _isIOS
                    ? CupertinoButton(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                        onPressed: _selecionarImagens,
                        child: Text(imageActionLabel),
                      )
                    : TextButton.icon(
                        onPressed: _selecionarImagens,
                        icon: const Icon(Icons.image),
                        label: Text(imageActionLabel),
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
                        ? CupertinoGlassButton(
                            isProminent: true,
                            onPressed: () => _submitForm(context),
                            child: Text(saveLabel),
                          )
                        : FilledButton.icon(
                            onPressed: () => _submitForm(context),
                            icon: const Icon(Icons.save),
                            label: Text(saveLabel),
                          ),
              ],
            ),
          ),
        );

        if (_isIOS) {
          return CupertinoPageScaffold(
            navigationBar: cupertinoGlassNavigationBar(
              middle: Text(title),
            ),
            child: SafeArea(child: content),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(title: Text(title)),
          body: content,
        );
      },
    );
  }
}
