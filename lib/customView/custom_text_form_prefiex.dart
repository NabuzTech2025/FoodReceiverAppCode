import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/constant.dart';

class CustomTextFormPrefix extends StatelessWidget {
  final TextInputType keyboardType;
  final String myLabelText;
  final TextEditingController controller;
  final Icon icon;
  final FormFieldValidator validate;
  final ValueChanged valueChanged;
  bool obscureText;

  CustomTextFormPrefix(
      {required this.myLabelText,
      required this.keyboardType,
      required this.controller,
      required this.icon,
      required this.validate,
      required this.valueChanged,
      required this.obscureText});

// const EdgeInsets.only(left: 33,right: 33, bottom: 13),
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 12, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        textAlign: TextAlign.start, // Start from left
        cursorColor: Colors.blue,
        controller: controller,
        validator: validate,
        onChanged: valueChanged,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: icon,
          prefixIconColor: MaterialStateColor.resolveWith((states) =>
          states.contains(MaterialState.focused)
              ? Colors.green
              : Colors.green),
          hintText: myLabelText,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          border: InputBorder.none,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontFamily: 'Montserrat',
          ),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}
