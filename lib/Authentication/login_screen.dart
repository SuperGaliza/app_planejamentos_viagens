import 'package:app_planejamentos_viagens/Authentication/signup.dart';
import 'package:app_planejamentos_viagens/JsonModels/users.dart';
import 'package:app_planejamentos_viagens/database/database_helper.dart';
import 'package:app_planejamentos_viagens/screens/home_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //We need two text editing controller

  //TextEditing controller to control the text when we enter into it
  final username = TextEditingController();
  final password = TextEditingController();
  
  //A bool variable for show and hide password
  bool isVisible = false;

  //Here is our bool variable
  bool isLoginTrue = false;

  final db = DatabaseHelper();

  //How we should call this function in login button
  login()async {
    var response = 
     await db.login(Users(usrName: username.text, usrPassword: password.text));
    if(response == true) {
      //if login is correct, then goto notes
      if(!mounted) return;
      Navigator.push(
        context, MaterialPageRoute(builder: (context)=> const HomeScreen()));
    }else{
      //if not, true the bool value to show orror message
      setState(() {
        isLoginTrue = true; 
      });
    }
  }

  //We have to create global key for our form
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            //We put all our textfield to a form to be controlled and not allow as empty 
            child: Form(
              key: formKey,
              child: Column(
                children: [
              
                  //Username field
              
                  //Before we show the image, after we copied the image we need to define the location in pubspec.yaml
                  Image.asset("lib/assets/logincell.png",
                  width: 350,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: 
                      const EdgeInsets.symmetric(horizontal: 10, vertical:6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.withOpacity(.2)),
                    child: TextFormField(
                      controller: username,
                      validator: (value) {
                        if(value!.isEmpty){
                          return "username is required";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        border: InputBorder.none,
                        hintText: "Username",
                      ), 
                    ),
                  ),
              
                  //Password field
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: 
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.withOpacity(.2)),
                    child: TextFormField(
                      controller: password,
                      validator: (value) {
                        if(value!.isEmpty){
                          return "password is required";
                        }
                        return null;
                      },
                      obscureText: !isVisible,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock),
                        border: InputBorder.none,
                        hintText: "Password",
                        suffixIcon: IconButton(
                          onPressed: () {
                            //In here we will create a click to show and hide the password a toggle button
                            setState(() {
                              //toggle button
                              isVisible = !isVisible;
                            });
                          
                          }, icon: Icon(isVisible
                          ? Icons.visibility 
                          : Icons.visibility_off))), 
                    ),
                  ),
              
                  const SizedBox(height: 10),
                  //login button
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width * .9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue),
                    child: TextButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          //Login method will be here
                          login();

                          //Now we have as response from our sqlite method
                          //We are going to create a user
                        }
                      }, 
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.white),
                          )),
                  ),
              
                  //Sign up button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(onPressed: () {
                        //Navigate to sign up
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context)=>const SignUp()));
                      }, 
                      child: const Text("SIGN UP"))
                    ],
                  ),

                  //We will disable this message in default, when user and pass is incorrect we will trigger this message to users  
                  isLoginTrue? const Text(
                    "Username or password is incorrect",
                    style: TextStyle(color: Colors.red),
                  )
                  : const SizedBox(),
                ]
              ),
            ),
          ),
        ),
      ),
    );
  }
}