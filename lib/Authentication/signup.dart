import 'package:app_planejamentos_viagens/Authentication/login_screen.dart';
import 'package:app_planejamentos_viagens/JsonModels/users.dart';
import 'package:app_planejamentos_viagens/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:app_planejamentos_viagens/utils/session_manager.dart'; // <<< Importar SessionManager
import 'package:app_planejamentos_viagens/screens/home_screen.dart'; // Importar HomeScreen se for logar direto

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
    // Renomeado de 'Signup' para _registerUser por convenção
    if (formKey.currentState!.validate()) {
      // Validação extra para destino vazio pode ser ajustada ou removida se não for o caso aqui
      // if (_destinoController.text.trim().isEmpty) { ScaffoldMessenger... return; }

      setState(() {
        _isLoading = true; // Inicia o carregamento
      });

      // Chama o método Signup do DatabaseHelper, que agora retorna int? (o ID do novo usuário) ou null
      int? newUserId = await db.Signup(
        Users(usrName: username.text, usrPassword: password.text),
      );

      if (!mounted)
        return; // Verifica se o widget ainda está na árvore antes de setState

      setState(() {
        _isLoading = false; // Finaliza o carregamento
      });

      if (newUserId != null) {
        // Se o cadastro for bem-sucedido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Conta criada com sucesso! Por favor, faça login."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Redireciona para a tela de login (usando pushReplacement para limpar a pilha)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        // Opcional: Se quiser logar o usuário automaticamente após o cadastro, descomente e ajuste:
        // await SessionManager.saveLoggedInUser(Users(usrId: newUserId, usrName: username.text, usrPassword: password.text));
        // if (!mounted) return;
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        // Se o cadastro falhou (ex: nome de usuário já existe)
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
                  const ListTile(
                    title: Text(
                      "Criar Nova Conta", // Título mais adequado para cadastro
                      style: TextStyle(
                        fontSize: 53,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Campo de Usuário
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
                  // Campo de Senha
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
                  // Campo de Confirmação de Senha
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
                  // Botão de Cadastro
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
                              : _registerUser, // Desabilita o botão enquanto carrega
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
                  // Botão "Já tem uma conta?"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Já tem uma conta?"),
                      TextButton(
                        onPressed: () {
                          // Navega para a tela de Login, removendo a tela de cadastro da pilha
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
