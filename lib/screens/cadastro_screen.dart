import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../database/database_helper.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final dbHelper = DatabaseHelper();

  // Validador de e-mail com regex
  bool _emailValido(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _cadastrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _mostrarDialogo('Erro', 'Preencha todos os campos.');
      return;
    }

    if (!_emailValido(email)) {
      _mostrarDialogo('Erro', 'Formato de e-mail inválido.');
      return;
    }

    try {
      final usuarioExistente = await dbHelper.autenticarUsuario(email, senha);

      if (usuarioExistente != null) {
        _mostrarDialogo('Erro', 'Usuário já cadastrado.');
        return;
      }

      final novoUsuario = Usuario(email: email, senha: senha);
      await dbHelper.inserirUsuario(novoUsuario);

      _mostrarDialogo(
        'Sucesso',
        'Cadastro realizado com sucesso!',
        redirecionarLogin: true,
      );
    } catch (e) {
      _mostrarDialogo('Erro', 'Ocorreu um erro ao cadastrar. Tente novamente.');
    }
  }

  void _mostrarDialogo(
    String titulo,
    String mensagem, {
    bool redirecionarLogin = false,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(titulo),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // fecha o diálogo
                  if (redirecionarLogin) {
                    Navigator.pop(context); // volta para tela de login
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cadastrar,
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
