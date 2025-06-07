import 'package:app_planejamentos_viagens/Authentication/signup.dart';
import 'package:app_planejamentos_viagens/JsonModels/users.dart';
import 'package:app_planejamentos_viagens/database/database_helper.dart';
import 'package:app_planejamentos_viagens/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_planejamentos_viagens/utils/session_manager.dart'; // <<< Importar SessionManager

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool isVisible = false;
  bool _isLoading = false; // Estado para o indicador de carregamento

  final db = DatabaseHelper();

  void _loginUser() async {
    // Renomeado de 'login' para _loginUser por convenção
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Inicia o carregamento
      });

      // Chama o método login do DatabaseHelper, que agora retorna Users? ou null
      Users? loggedInUser = await db.login(
        Users(usrName: username.text, usrPassword: password.text),
      );

      if (!mounted)
        return; // Verifica se o widget ainda está na árvore antes de setState

      setState(() {
        _isLoading = false; // Finaliza o carregamento
      });

      if (loggedInUser != null) {
        // Se o login for bem-sucedido, salva o ID do usuário na sessão
        await SessionManager.saveLoggedInUser(loggedInUser);
        if (!mounted) return;
        // Navega para a HomeScreen, removendo todas as rotas anteriores (impede voltar para o login)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Se o login falhar, exibe uma SnackBar com a mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nome de usuário ou senha incorretos."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating, // Para um visual mais moderno
          ),
        );
      }
    }
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Image.asset("lib/assets/logincell.png", width: 350),
                  const SizedBox(height: 15),
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
                          // Correção para aceitar null
                          return "Nome de usuário é obrigatório";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        border: InputBorder.none,
                        hintText: "Nome de usuário", // Ajustado para português
                      ),
                    ),
                  ),
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
                          // Correção para aceitar null
                          return "Senha é obrigatória"; // Ajustado para português
                        }
                        return null;
                      },
                      obscureText: !isVisible,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock),
                        border: InputBorder.none,
                        hintText: "Senha", // Ajustado para português
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
                              : _loginUser, // Desabilita o botão enquanto carrega
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "LOGIN",
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Não tem uma conta?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUp(),
                            ),
                          );
                        },
                        child: const Text("CADASTRAR"),
                      ),
                    ],
                  ),
                  // Remover a mensagem de erro antiga, pois agora usamos SnackBar
                  // isLoginTrue ? const Text("Username or password is incorrect", style: TextStyle(color: Colors.red)) : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
