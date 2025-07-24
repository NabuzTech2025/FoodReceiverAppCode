import 'package:flutter/material.dart';
import 'package:food_app/customView/CustomAppBar.dart';
import 'package:food_app/customView/custom_button.dart';
import 'package:food_app/customView/custom_text_form_prefiex.dart';
import 'package:food_app/utils/validators.dart';
import 'package:hive/hive.dart';

class CreateDriver extends StatefulWidget {
  const CreateDriver({super.key});

  @override
  State<CreateDriver> createState() => _CreateDriverState();
}

class _CreateDriverState extends State<CreateDriver> {
  final TextEditingController emailController=TextEditingController();
  final TextEditingController phoneNumberController=TextEditingController();
  final TextEditingController passwordController=TextEditingController();
  bool _obscureText = true;
  bool isPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  height: 48,width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffE25454)
                  ),
                  child: Icon(Icons.close,color: Colors.white,),
                ),
              ),
              Image.asset('assets/images/driverProfile.png',height: 80,width: 80,),
              SizedBox(height: 10,),
              const Text('Create New Driver',style: TextStyle(
                  fontSize: 28,fontFamily: 'Mulish',fontWeight: FontWeight.bold),),
              CustomTextFormPrefix(
                  myLabelText: 'User Email', 
                  keyboardType: TextInputType.emailAddress, 
                  controller: emailController, 
                  icon: Icon(Icons.email,color: Colors.black,),
                  validate: (value) => validateFieldCustomText(
                      value, "Please enter username"),
                  valueChanged: (value){}, 
                  obscureText: false
              ),
              CustomTextFormPrefix(
                  myLabelText: 'Phone Number',
                  keyboardType: TextInputType.number,
                  controller: phoneNumberController,
                  icon: Icon(Icons.phone,color: Colors.black,),
                  validate: (value) => validateFieldCustomText(
                      value, "Please enter Phone Number"),
                  valueChanged: (value){},
                  obscureText: false
              ),
              CustomTextFormPrefix(
                  myLabelText: 'Password',
                  keyboardType: TextInputType.visiblePassword,
                  controller: passwordController,
                  icon: Icon(Icons.password,color: Colors.black,),
                  validate: (value) => validateFieldCustomText(
                      value, "Please enter Password"),
                  valueChanged: (value){},
                obscureText: !isPasswordVisible,
                isPasswordVisible: isPasswordVisible,
                isPasswordField: true,
                onTogglePassword: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              ),
              CustomButton(
                  myText: 'Submit',
                  onPressed: (){},
                  fontSize: 20,
                  color: Colors.black,
                  textColor: Colors.white,
                  fontWeigt: FontWeight.w700)
            ],
          ),
        ),
      ),
    );
  }
}
