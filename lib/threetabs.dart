// import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:mic_stream/mic_stream.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
import 'package:record/record.dart';
import 'audio_player.dart';
// import 'package:record_example/audio_player.dart';


void main() {
  runApp(const MyApp());
}

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop}) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => setState(() => _amplitude = amp));

    super.initState();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        // final devs = await _audioRecorder.listInputDevices();
        // final isRecording = await _audioRecorder.isRecording();

        await _audioRecorder.start();
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await _audioRecorder.stop();

    if (path != null) {
      widget.onStop(path);
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildRecordStopControl(),
                const SizedBox(width: 20),
                _buildPauseResumeControl(),
                const SizedBox(width: 20),
                _buildText(),
              ],
            ),
            if (_amplitude != null) ...[
              const SizedBox(height: 40),
              Text('Current: ${_amplitude?.current ?? 0.0}'),
              Text('Max: ${_amplitude?.max ?? 0.0}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange.shade300),
        useMaterial3: true,
      ),

      home: const MyHomePage(title: 'Smart Home Security System'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  //use this controller to et what the user typed
  final _textController1 = TextEditingController();
  final _textController2 = TextEditingController();

  // MIC
  bool showPlayer = false;
  String? audioPath;


  @override
  void initState() {
    super.initState();
    getData("No1");
    getData("No2");
    getData("SysStatus");

    // MIC
    showPlayer = false;
    super.initState();

  }


  void _sendSMS(String message, List<String> recipents) async {
    String result = await sendSMS(message: message, recipients: recipents, sendDirect:true )
        .catchError((onError) {
      print(onError);
    });
    print(result);
  }

  _callNumber() async{
    const number = '+989044558736'; //set the number here
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
  }



  List<String> recipents = ["+989044558736"];


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


  // MIC Controller ####################################################################################### MIC Controller

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
      length: 3,
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
        // floatingActionButton: FloatingActionButton(
        //     onPressed: _controlMicStream,
        //     child: _getIcon(),
        //     foregroundColor: _iconColor,
        //     backgroundColor: _getBgColor(),
        //     tooltip: (isRecording) ? "Stop recording" : "Start recording",
        //   ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.voice_chat, color: Colors.deepOrange),),
                  Tab(icon: Icon(Icons.home, color: Colors.deepOrange),),
                  Tab(icon: Icon(Icons.account_circle, color: Colors.deepOrange),),
                ],
              ),
              Expanded(
                child: TabBarView(children:[
                  Container(
                    child: Center(
                      child: showPlayer
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: AudioPlayer(
                            source: audioPath!,
                            onDelete: () {
                              setState(() => showPlayer = false);
                            },
                          ),
                        )
                      : AudioRecorder(
                          onStop: (path) {
                            if (kDebugMode) print('Recorded file path: $path');
                            setState(() {
                              audioPath = path;
                              showPlayer = true;
                            });
                          },
                        ),
                    ),
                  ),
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

// ############################### rest of the MIC STREAM
