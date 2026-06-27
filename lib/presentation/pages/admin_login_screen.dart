import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/env.dart';
import '../../services/platform_info.dart';
import '../widgets/cupertino_glass.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();

  String? _errorMessage;

  bool get _isIOS => isCupertinoPlatform;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _submit() {
    final usuario = _usuarioController.text.trim();
    final senha = _senhaController.text;

    setState(() => _errorMessage = null);

    if (_isIOS) {
      if (usuario.isEmpty || senha.isEmpty) {
        setState(() => _errorMessage = 'Informe usuário e senha.');
        return;
      }
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    final isValid = usuario == Env.adminUsername && senha == Env.adminPassword;
    if (!isValid) {
      setState(() => _errorMessage = 'Usuário ou senha inválidos.');
      return;
    }

    Navigator.pop(context, true);
  }

  Widget _buildUsuarioField() {
    if (_isIOS) {
      return CupertinoTextField(
        controller: _usuarioController,
        placeholder: 'Usuário',
        padding: const EdgeInsets.all(12),
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
      );
    }

    return TextFormField(
      controller: _usuarioController,
      decoration: const InputDecoration(labelText: 'Usuário'),
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe o usuário';
        }
        return null;
      },
    );
  }

  Widget _buildSenhaField() {
    if (_isIOS) {
      return CupertinoTextField(
        controller: _senhaController,
        placeholder: 'Senha',
        padding: const EdgeInsets.all(12),
        obscureText: true,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _submit(),
      );
    }

    return TextFormField(
      controller: _senhaController,
      decoration: const InputDecoration(labelText: 'Senha'),
      obscureText: true,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => _submit(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe a senha';
        }
        return null;
      },
    );
  }

  Widget _buildErrorMessage() {
    final message = _errorMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final color = _isIOS ? CupertinoColors.systemRed : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: TextStyle(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = _isIOS
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
        : Theme.of(context).textTheme.titleLarge;

    final content = AutofillGroup(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Acesso administrativo',
                style: titleStyle,
              ),
              const SizedBox(height: 20),
              _buildUsuarioField(),
              const SizedBox(height: 12),
              _buildSenhaField(),
              _buildErrorMessage(),
              const SizedBox(height: 20),
              _isIOS
                  ? CupertinoGlassButton(
                      isProminent: true,
                      onPressed: _submit,
                      child: const Text('Entrar'),
                    )
                  : FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.login),
                      label: const Text('Entrar'),
                    ),
            ],
          ),
        ),
      ),
    );

    if (_isIOS) {
      return CupertinoPageScaffold(
        navigationBar: cupertinoGlassNavigationBar(
          middle: const Text('Login'),
        ),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: content,
    );
  }
}
