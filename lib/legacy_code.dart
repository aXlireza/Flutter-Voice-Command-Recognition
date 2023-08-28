import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange.shade300),
        useMaterial3: true,
      ),

      home: const MyHomePage(title: 'Smart Home Security System'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //use this controller to et what the user typed
  final _textController1 = TextEditingController();
  final _textController2 = TextEditingController();


  @override
  void initState() {
    super.initState();
    getData("No1");
    getData("No2");
    getData("SysStatus");

  }


  void _sendSMS(String message, List<String> recipents) async {
    String result = await sendSMS(message: message, recipients: recipents, sendDirect:true )
        .catchError((onError) {
      print(onError);
    });
    print(result);
  }

  _callNumber() async{
    const number = '+989939443754'; //set the number here
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
  }



  List<String> recipents = ["+989939443754"];


  //********************************
  String? phoneValue1;
  String? phoneValue2;
  String? SysStatus;

  Future<void> setData(Key,Value) async{
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString(Key, Value);
  }

  void getData(Key) async{
    final SharedPreferences pref = await SharedPreferences.getInstance();
    if(Key=="No1") {
      phoneValue1 = pref.getString(Key);
    }
    if(Key=="No2") {
      phoneValue2 = pref.getString(Key);
    }
    if(Key=="SysStatus") {
      SysStatus = pref.getString(Key);
    }
    setState(() {

    });
  }

  void deleteData(Key) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(Key);
  }

  //*********************************************************

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title,style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.home, color: Colors.deepOrange),),
                  Tab(icon: Icon(Icons.account_circle, color: Colors.deepOrange),),
                ],
              ),
              Expanded(
                child: TabBarView(children:[

                  //1st tab
                  Container(
                    child: Center(
                      //child: Text('1ST TAB'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[

                          const Text('Current system status is',
                            style: TextStyle(fontSize: 17,
                                color:Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$SysStatus',
                            //style: Theme.of(context).textTheme.headlineMedium,
                            style: const TextStyle(fontSize: 30,
                                color:Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 70,),

                          ElevatedButton(
                            onPressed: (){
                              setState(() {
                                _sendSMS("!ENABLE#", recipents);
                                setData("SysStatus", "Enabled!");
                                getData("SysStatus");
                              });
                            },


                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.orangeAccent,
                                padding: const EdgeInsets.fromLTRB(40, 10, 40, 10)
                            ),child: const Text("Enable",style: TextStyle(fontSize: 20),),
                          ),

                          const SizedBox(height: 30,),

                          ElevatedButton(
                            onPressed: (){
                              setState(() {
                                _sendSMS("!DISABLE#", recipents);
                                setData("SysStatus", "Disabled!");
                                getData("SysStatus");
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.orangeAccent,
                                padding: const EdgeInsets.fromLTRB(36, 10, 36, 10)
                            ),child: const Text("Disable",style: TextStyle(fontSize: 20),),
                          ),

                          const SizedBox(height: 30,),

                          ElevatedButton(
                            onPressed: (){
                              setState(() {
                                _callNumber();
                                SysStatus = "Enabled!";
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.orangeAccent,
                                padding: const EdgeInsets.fromLTRB(24, 10, 24, 10)
                            ),
                            child: const Text("Make Call",style: TextStyle(fontSize: 20),),
                          ),

                          //const SizedBox(height: 30,),

                        ],
                      ),
                    ),
                  ),

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2nd tab

                  Container(
                    child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            //display text

                            // const Text('Before adding or deleting a number, first please restart the system using the button',
                            //   style: TextStyle(fontSize: 17,
                            //       color:Colors.black,
                            //       fontWeight: FontWeight.bold),
                            // ),

                            // Padding(
                            //    padding: const EdgeInsets.all(16.0),
                            const SizedBox(height: 30,),
                            TextField(
                              controller: _textController1,
                              decoration: const InputDecoration(
                                  hintText: 'Enter the first phone number',
                                  border: OutlineInputBorder()
                              ),
                            ),

                            const SizedBox(height: 20,),

                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //submit button
                                  ElevatedButton(
                                    onPressed: (){
                                      setState(() {
                                        _sendSMS('!${_textController1.text}#', recipents);
                                        setData("No1", _textController1.text);
                                        getData("No1");
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: Colors.lightGreen,
                                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),// foreground
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5), // <-- Radius
                                      ),

                                    ),

                                    child: const Text("Submit"),
                                  ),

                                  const SizedBox(width: 30,),

                                  ElevatedButton(
                                    onPressed: (){
                                      setState(() {
                                        _sendSMS("!D1#", recipents);
                                        deleteData("No1");
                                        getData("No1");
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: Colors.red, // foreground
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5), // <-- Radius
                                      ),

                                    ),


                                    child: const Text("Delete"),
                                  ),
                                ]
                            ),

                            Expanded(
                              child: Container(
                                child: Center(
                                  child: phoneValue1 == null ? const Text("No number 1 avilable") : Text(phoneValue1!),
                                ),
                              ),
                            ),
//********************2nd********************
                            TextField(
                              controller: _textController2,
                              decoration: const InputDecoration(
                                  hintText: 'Enter the second phone number',
                                  border: OutlineInputBorder()
                              ),
                            ),

                            const SizedBox(height: 20,),

                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //submit button
                                  ElevatedButton(
                                    onPressed: (){
                                      setState(() {
                                        _sendSMS('!${_textController2.text}#', recipents);
                                        setData("No2", _textController2.text);
                                        getData("No2");
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: Colors.lightGreen, // foreground
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5), // <-- Radius
                                      ),

                                    ),


                                    child: const Text("Submit"),
                                  ),

                                  const SizedBox(width: 30,),

                                  ElevatedButton(
                                    onPressed: (){
                                      setState(() {
                                        _sendSMS("!D2#", recipents);
                                        deleteData("No2");
                                        getData("No2");
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: Colors.red, // foreground
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5), // <-- Radius
                                      ),

                                    ),


                                    child: const Text("Delete"),
                                  ),
                                ]
                            ),

                            Expanded(
                              child: Container(
                                child: Center(
                                  child: phoneValue2 == null ? const Text("No number 2 avilable") : Text(phoneValue2!),
                                ),
                              ),
                            ),
//********************2nd********************
                            ElevatedButton(
                              onPressed: (){
                                setState(() {
                                  _sendSMS("!RESET#", recipents);
                                  SysStatus = "Enabled!";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.orangeAccent, // foreground
                                padding: const EdgeInsets.fromLTRB(76, 6, 76, 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5), // <-- Radius
                                ),

                              ),


                              child: const Text("RESET",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                            ),

                          ]
                      ),
                    ),
                  ),


                ] ),
              )

            ],
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            //
            // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
            // action in the IDE, or press "p" in the console), to see the
            // wireframe for each widget.

          ),
        ),
      ),
    );
  }
}