import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
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
import 'ResetPasswordScreen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  GlobalKey<FormState> _formKey = GlobalKey();
  late TextEditingController _EmailController = TextEditingController();
  late TextEditingController _PasswordController = TextEditingController();
  bool _obscureText = true;
  late UserLoginH userData;
  late SharedPreferences sharedPreferences;
  String? token;
  String? userName;
  String? password;
  String selectedEnvironment = 'Prod'; // Default
  // At the top of your _LoginScreenState class
  final supportedLocales = ['en', 'de', 'hi', 'ch'];

  String getValidatedLocale() {
    final currentLocale = Get.locale?.languageCode ?? 'en';
    return supportedLocales.contains(currentLocale) ? currentLocale : 'en';
  }

  @override
  initState() {
    initVar();
    getDeviceToken();
    super.initState();
  }

  Future<void> getDeviceToken() async {
    token = await FirebaseMessaging.instance.getToken();
    print("DeviceToken " + token.toString());
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    userName = sharedPreferences.getString(valueShared_USERNAME_KEY);
    password = sharedPreferences.getString(valueShared_PASSWORD_KEY);
    if (userName != null) {
      _EmailController.text = userName!;
      _PasswordController.text = password!;
    }
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
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  child: DropdownButton<String>(
                    value: selectedEnvironment,
                    underline: const SizedBox(),
                    icon:
                        const Icon(Icons.security_rounded, color: Colors.black),
                    isDense: true,
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        Text('Prod', style: TextStyle(fontSize: 16,color: Colors.black)),
                        Text('Test', style: const TextStyle(fontSize: 16,color: Colors.black)),
                      ];
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'Prod',
                        child: Text('Prod',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'Test',
                        child:
                            Text('Test', style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) enviroment(value);
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  child: DropdownButton<String>(
                    value: getValidatedLocale(),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language, color: Colors.black),
                    isDense: true,
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        Text('English', style: const TextStyle(fontSize: 16)),
                        Text('German', style: const TextStyle(fontSize: 16)),
                        Text('India', style: const TextStyle(fontSize: 16)),
                        Text('CHF', style: const TextStyle(fontSize: 16)),
                      ];
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'de',
                        child: Text('German',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'hi',
                        child:
                            Text('India', style: const TextStyle(fontSize: 16)),
                      ),
                      DropdownMenuItem(
                        value: 'ch',
                        child:
                            Text('CHF', style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) changeLanguage(value);
                    },
                  ),
                ),
              ],
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
                          "Login!",
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
                            keyboardType: TextInputType.emailAddress,
                            myLabelText: "Username...",
                            controller: _EmailController,
                            icon: Icon(Icons.person,color: Colors.black,),
                            validate: (value) => validateFieldCustomText(
                                value, "Please enter username"),
                            valueChanged: (value) {},
                            obscureText: false),
                        CustomTextFormPrefix(
                          keyboardType: TextInputType.visiblePassword,
                          myLabelText: "Password...",
                          controller: _PasswordController,
                          icon: Icon(Icons.lock,color: Colors.black,),
                          validate: (value) => validateFieldCustomText(
                              value, "Please enter password"),
                          valueChanged: (value) {},
                          obscureText: _obscureText,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(onTap:(){
                     showPasswordResetDialog(context);
                    /*Get.to(() => ResetPasswordScreen());*/
                  },child:
                  Text(
                    "Forget Password",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationStyle:
                          TextDecorationStyle.solid, // Underline the text
                    ),
                  ),),
                  SizedBox(
                    height: 20,
                  ),
                  CustomButton(
                    onPressed: () async {
                      loginApi();
                    },
                    myText: "Login",
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
      print('Form is valid ' + _EmailController.text);
      postloginData(_EmailController.text, _PasswordController.text, token!);
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
            child:  Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true, )
        //     CupertinoActivityIndicator(
        //   radius: 20,
        //   color: Colors.orange,
        // )
        ),
        barrierDismissible: false,
      );
      final result = await ApiRepo().loginApi(email, password, deviceToken);
      Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      Get.back();
      if (result != null) {
        // Handle navigation or success here
        sharedPreferences.setString(
            valueShared_BEARER_KEY, result.access_token!);
        sharedPreferences.setString(
            valueShared_USERNAME_KEY, _EmailController.text.toString());
        sharedPreferences.setString(
            valueShared_PASSWORD_KEY, _PasswordController.text.toString());
        print("LoginData  " + result.role_id.toString());
        print("LoginDataaccess_token  " + result.access_token.toString());
        Get.to(() => HomeScreen());
      } else {
        showSnackbar("Error", "Error on login");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
      Get.back();
    }
  }

  Future<void> changeLanguage(String langCode) async {
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
    await sharedPreferences.setString(valueShared_LANGUAGE, langCode);
  }

  Future<void> enviroment(String value) async {
    if (value == "Prod") {
      sharedPreferences.setString(valueShared_BASEURL, "https://magskr.com/");
    } else if (value == "Test") {
      sharedPreferences.setString(valueShared_BASEURL, "https://magskr.de/");
    } else {
      sharedPreferences.setString(valueShared_BASEURL, "https://magskr.com/");
    }
    setState(() {
      selectedEnvironment = value;
    });
    await Api.init();
  }


  void showPasswordResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Password Reset',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
              ),
              children: [
                TextSpan(text: 'For password reset assistance, please contact our support team at '),
                TextSpan(
                  text: 'support@magskr.com',
                  style: TextStyle(color: Colors.blue),
                ),
                TextSpan(text: ' with your registered email address.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }


}
