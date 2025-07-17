import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/ui/LoginScreen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../api/repository/api_repository.dart';
import '../api/responses/userLogin_h.dart';
import '../constants/constant.dart';
import '../customView/custom_button.dart';
import '../customView/custom_text_form_prefiex.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';
import '../utils/validators.dart';
import 'home_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  GlobalKey<FormState> _formKey = GlobalKey();
  late TextEditingController _PasswordController = TextEditingController();
  late TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureText = true;
  late UserLoginH userData;
  late SharedPreferences sharedPreferences;

  @override
  initState() {
    initVar();
    super.initState();
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.blue,
            // Cursor color
            selectionColor: Colors.blue.withOpacity(0.3),
            // Highlighted text background color
            selectionHandleColor: Colors.blue, // Selection handle color
          ),
        ),
        home: Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              backgroundColor: Colors.grey[100],
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // Goes back to the previous screen
                },
              ),
              actions: [],
            ),

            body: Container(
              margin: EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // SvgPicture.asset(
                      //   'assets/images/login-vector.svg',
                      //   width: 120,
                      //   height: 120,
                      //   fit: BoxFit.cover,
                      // ),
                      Transform.translate(
                        offset: Offset(-10, 25), // Move up by 10 pixels
                        child: Text(
                          "Reset Password!",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextFormPrefix(
                            keyboardType: TextInputType.text,
                            myLabelText: "Password...",
                            controller: _PasswordController,
                            icon: Icon(Icons.lock),
                            validate: (value) => validateFieldCustomText(
                                value, "Please enter password"),
                            valueChanged: (value) {},
                            obscureText: false),
                        CustomTextFormPrefix(
                          keyboardType: TextInputType.visiblePassword,
                          myLabelText: "Confirm Password...",
                          controller: _confirmPasswordController,
                          icon: Icon(Icons.lock),
                          validate: (value) => validateFieldCustomText(
                              value, "Please enter confirm password"),
                          valueChanged: (value) {},
                          obscureText: _obscureText,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  CustomButton(
                    onPressed: () async {
                      loginApi();
                    },
                    myText: "Reset Password",
                    color: Colors.black,
                    textColor: Colors.white,
                    fontSize: 17,
                    fontWeigt: FontWeight.w700,
                  ),
                ],
              ),
            )));
  }

  void loginApi() {
    final FormState? form = _formKey.currentState;
    //getHiveData();
    if (form!.validate()) {
      postResetPAssword(
          _PasswordController.text, _confirmPasswordController.text);
    } else {
      print('Form is invalid');
    }
    //if (validateData()) {}
  }

  Future<void> postloginData(
      String email, String password, String deviceToken) async {
    try {
      Get.dialog(
        Center(
            child: CupertinoActivityIndicator(
          radius: 20,
          color: Colors.orange,
        )),
        barrierDismissible: false,
      );
      final result = await ApiRepo().loginApi(email, password, deviceToken);
      Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      Get.back();
      if (result != null) {
        // Handle navigation or success here

        print("LoginData  " + result.role_id.toString());
        print("LoginDataaccess_token  " + result.access_token.toString());
        Get.to(() => LoginScreen());
      } else {
        showSnackbar("Error", "Error on login");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
      Get.back();
    }
  }

  Future<void> postResetPAssword(String email, String password) async {
    try {
      Get.dialog(
        Center(
            child: CupertinoActivityIndicator(
          radius: 20,
          color: Colors.orange,
        )),
        barrierDismissible: false,
      );
      final result = await ApiRepo().resetPasswordApi(email, password);
      Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      Get.back();
      if (result != null) {
        // Handle navigation or success here

        Get.to(() => LoginScreen());
      } else {
        showSnackbar("Error", "Error on login");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
      Get.back();
    }
  }
}
