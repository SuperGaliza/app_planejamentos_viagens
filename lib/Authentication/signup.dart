import 'package:app_planejamentos_viagens/Authentication/login_screen.dart';
import 'package:app_planejamentos_viagens/JsonModels/users.dart';
import 'package:app_planejamentos_viagens/database/database_helper.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool isVisible = false;
  bool _isLoading = false; // Estado para o indicador de carregamento

  final db = DatabaseHelper();

  void _registerUser() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Inicia o carregamento
      });

      int? newUserId = await db.Signup(
        Users(usrName: username.text, usrPassword: password.text),
      );

      if (!mounted) return; 

      setState(() {
        _isLoading = false; // Finaliza o carregamento
      });

      if (newUserId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Conta criada com sucesso! Por favor, faça login."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Erro ao criar conta. Nome de usuário já existe ou ocorreu um problema.",
            ),
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
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Bloco de Título ANTIGO foi substituído por este NOVO ---
                  Image.asset(
                    "lib/assets/planago_logo.png", // Caminho para a logo
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Crie sua conta",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005A9C),
                    ),
                  ),
                   const SizedBox(height: 32),
                  // --- Fim do Bloco NOVO ---
                  
                  // Campo de Usuário (Estilo Original Mantido)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(.2),
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
                        icon: Icon(Icons.person),
                        border: InputBorder.none,
                        hintText: "Nome de usuário",
                      ),
                    ),
                  ),
                  // Campo de Senha (Estilo Original Mantido)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(.2),
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
                        icon: const Icon(Icons.lock),
                        border: InputBorder.none,
                        hintText: "Senha",
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isVisible = !isVisible;
                            });
                          },
                          icon: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Campo de Confirmação de Senha (Estilo Original Mantido)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(.2),
                    ),
                    child: TextFormField(
                      controller: confirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirme a senha";
                        } else if (password.text != confirmPassword.text) {
                          return "As senhas não coincidem";
                        }
                        return null;
                      },
                      obscureText: !isVisible,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock),
                        border: InputBorder.none,
                        hintText: "Confirmar Senha",
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isVisible = !isVisible;
                            });
                          },
                          icon: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Botão de Cadastro (Estilo Original Mantido)
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width * .9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue,
                    ),
                    child: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _registerUser, 
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "CADASTRAR",
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                  // Botão "Já tem uma conta?" (Estilo Original Mantido)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Já tem uma conta?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text("Login"),
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