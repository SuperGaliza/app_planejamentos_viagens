import 'package:app_planejamentos_viagens/Authentication/signup.dart';
import 'package:app_planejamentos_viagens/JsonModels/users.dart';
import 'package:app_planejamentos_viagens/database/database_helper.dart';
import 'package:app_planejamentos_viagens/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_planejamentos_viagens/utils/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool isVisible = false;
  bool _isLoading = false;

  final db = DatabaseHelper();
  final formKey = GlobalKey<FormState>();

  void _loginUser() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Users? loggedInUser = await db.login(
        Users(usrName: username.text, usrPassword: password.text),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (loggedInUser != null) {
        await SessionManager.saveLoggedInUser(loggedInUser);
        if (!mounted) return;
        Navigator.pushReplacement( // Usar pushReplacement para não poder voltar
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nome de usuário ou senha incorretos."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Aumentando o padding geral
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- NOVA SEÇÃO DA LOGO E NOME DO APP ---
                  Image.asset(
                    "lib/assets/planago_logo.png", // Caminho para a nova logo
                    height: 140,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "PlanaGo",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005A9C), // Um tom de azul escuro
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // --- CAMPOS DE LOGIN ---
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.withOpacity(.15),
                    ),
                    child: TextFormField(
                      controller: username,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Nome de usuário é obrigatório";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person_outline),
                        border: InputBorder.none,
                        hintText: "Nome de usuário",
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.withOpacity(.15),
                    ),
                    child: TextFormField(
                      controller: password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Senha é obrigatória";
                        }
                        return null;
                      },
                      obscureText: !isVisible,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock_outline),
                        border: InputBorder.none,
                        hintText: "Senha",
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => isVisible = !isVisible),
                          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BOTÃO DE LOGIN ---
                  Container(
                    height: 55,
                    width: double.infinity, // Ocupa toda a largura
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue,
                    ),
                    child: TextButton(
                      onPressed: _isLoading ? null : _loginUser,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "LOGIN",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  
                  // --- LINK PARA CADASTRO ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Não tem uma conta?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUp()),
                          );
                        },
                        child: const Text("CADASTRAR"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}