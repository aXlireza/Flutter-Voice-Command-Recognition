
class Action {
  // final callRef;
  // final enableRef;
  // final disableRef;

  // const Action({
  //   required this.callRef,
  //   required this.enableRef,
  //   required this.disableRef,
  // });

  void processCommand(String theLabel) {
    switch(theLabel) {
      case 'call' || 'tamas': call(); break;
      case 'enable' || 'faal': enable(); break;
      case 'disable' || 'qeir_faal': disable(); break;
    }
  }

  // void call() {
  //   callRef();
  // }
  // void enable() {
  //   enableRef();
  // }
  // void disable() {
  //   disableRef();
  // }
}