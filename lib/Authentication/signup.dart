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

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      //SingledChildScrollView to have an scroll in the screen
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //We will copy the previous textfield we design to avoid time consuming
                  
                  const ListTile(
                    title: Text(
                      "Register New Account",
                      style: 
                          TextStyle(fontSize: 53, fontWeight: FontWeight.bold),
                    ),
                  ),

                  //As we assigned our controller to the textformfields 

                  Container(
                        margin: EdgeInsets.all(8),
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

                  //Confirm Password field
                  //Now we check wheter password matches or not 
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: 
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.withOpacity(.2)),
                    child: TextFormField(
                      controller: confirmPassword,
                      validator: (value) {
                        if(value!.isEmpty){
                          return "password is required";
                        }else if(password.text != confirmPassword.text){
                          return "Passwords don't match";
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

                          final db = DatabaseHelper();
                          db
                            .Signup(Users(
                              usrName: username.text, 
                              usrPassword: password.text))
                            .whenComplete((){
                            //After success user creation go to login screen
                           Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context)=>
                                const LoginScreen()));   
                          });
                        }
                      }, 
                        child: const Text(
                          "SIGN UP",
                          style: TextStyle(color: Colors.white),
                          )),
                  ),
              
                  //Sign up button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(onPressed: () {
                        //Navigate to sign up
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                      }, 
                      child: const Text("Login"))
                    ],
                  )
                

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}