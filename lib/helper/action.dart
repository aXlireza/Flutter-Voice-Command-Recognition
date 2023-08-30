import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

void processCommand(String theLabel) {
  switch(theLabel) {
    case 'call' || 'tamas': _callNumber(); break;
    // case 'enable' || 'faal': enable(); break;
    // case 'disable' || 'qeir_faal': disable(); break;
  }
}

_callNumber() async {
  const number = '+989939443754'; //set the number here
  bool? res = await FlutterPhoneDirectCaller.callNumber(number);
}