import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../cubits/cadastro_evento/cadastro_evento_cubit.dart';
import '../../cubits/cadastro_evento/cadastro_evento_state.dart';

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

  /// Abre o seletor de imagens e adiciona ao estado
  Future<void> _selecionarImagens() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final imagens = pickedFiles.map((xfile) => File(xfile.path)).toList();
      setState(() => _imagensSelecionadas = imagens);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma imagem foi selecionada.')),
      );
    }
  }

  /// Envia os dados para o Cubit de cadastro
  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios")),
      );
      return;
    }

    if (_dataEvento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data do evento.")),
      );
      return;
    }

    if (_imagensSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione pelo menos uma imagem.")),
      );
      return;
    }

    context.read<CadastroEventoCubit>().cadastrarEvento(
          titulo: _tituloController.text.trim(),
          cidade: _cidadeController.text.trim(),
          dataEvento: _dataEvento!,
          imagens: _imagensSelecionadas,
          // comentarios: _comentariosController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CadastroEventoCubit, CadastroEventoState>(
      listener: (context, state) {
        if (state is CadastroEventoSucesso) {
          Navigator.pop(context, true); // IMPORTANTE!
        } else if (state is CadastroEventoErro) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${state.mensagem}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadastrar Evento')),
        body: BlocBuilder<CadastroEventoCubit, CadastroEventoState>(
          builder: (context, state) {
            final carregando = state is CadastroEventoLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe o título'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cidadeController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe a cidade'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dataEvento == null
                                ? 'Selecione a data do evento'
                                : 'Data: ${_dataEvento!.day}/${_dataEvento!.month}/${_dataEvento!.year}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final data = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (data != null) {
                              setState(() => _dataEvento = data);
                            }
                          },
                          child: const Text('Selecionar Data'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Imagens selecionadas
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _imagensSelecionadas.asMap().entries.map((entry) {
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
                              top: -8,
                              right: -8,
                              child: IconButton(
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
                    TextButton.icon(
                      onPressed: _selecionarImagens,
                      icon: const Icon(Icons.image),
                      label: const Text('Selecionar Imagens'),
                    ),

                    const SizedBox(height: 12),

                    // Comentários
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: TextFormField(
                            controller: _comentariosController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Comentários (opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    carregando
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: () => _submitForm(context),
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar Evento'),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
