import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../components/LoadingWidget.dart';
import '../components/custom_widgets.dart';

String toggleLED(String pinOut, bool isToggled){
  if(isToggled == true){
    print("true");
    //return 'raspi-gpio set $pinOut op && raspi-gpio set $pinOut dh';
    return'python3 comfyScript/LED/led.py $pinOut 1';
  }
  else{
    //return 'raspi-gpio set $pinOut op && raspi-gpio set $pinOut dl';
    return'python3 comfyScript/LED/led.py $pinOut 0';
  }
}

class LedToggle extends StatefulWidget {
  const LedToggle({super.key, required this.spaceName, required this.name, required this.pin, required this.id, required this.hostname, required this.username, required this.password, required this.terminal});
  final String name;
  final String pin;
  final int id;
  final String hostname; final String username; final String password; final String spaceName;
  final Terminal terminal;
  @override
  State<LedToggle> createState() => _LedToggleState();
}

class _LedToggleState extends State<LedToggle> {
  bool toggleState=false; bool SSHLoadingFinished = false;
  late SSHClient client;
  @override
  void initState(){
    super.initState();
    initClient();
  }
  @override
  void dispose(){
    super.dispose();
    closeClient();
    print("closed");
  }
  Future<void> initClient() async{
    client = SSHClient(
      await SSHSocket.connect(widget.hostname, 22),
      username: widget.username,
      onPasswordRequest: () => widget.password,
    );
    print("initClient username: ${client.username}");
    setState(() {SSHLoadingFinished = true;});

  }
  Future<void> closeClient() async{
    final shell = await client.shell();
    await shell.done;
    client.close();

  }
  @override
  Widget build(BuildContext context) {
    if(SSHLoadingFinished == true){
      return GestureDetector(
        onTap: () async {
          setState((){
            toggleState = !toggleState;
            print(toggleState.toString());
          });
          if (toggleState == true){
            widget.terminal.write('LED ${widget.pin} on \r\n');
          }
          else{
            widget.terminal.write('LED ${widget.pin} off \r\n');
          }
          //HapticFeedback.vibrate();
          SystemSound.play(SystemSoundType.click);
          var command = await client.run(toggleLED(widget.pin.toString(), toggleState));
          print(toggleState);
        },
        child: Padding(
          padding: EdgeInsets.all(buttonPadding),
          child: Container(
            color: toggleState? Colors.black :Colors.white,
            child: Padding(
              padding: EdgeInsets.all(buttonPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity, alignment: AlignmentDirectional.center,
                    color: toggleState? Colors.white: Colors.black,
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: toggleState? Colors.black :Colors.white,
                      ),
                    ),
                  ),
                  Container(height: 2.0,
                    color: toggleState? Colors.black: Colors.white,
                  ),
                  Expanded(
                    child: Container(
                        width: double.infinity,
                        color: toggleState? Colors.white: Colors.black,
                        child: Icon(toggleState? Icons.lightbulb:Icons.emoji_objects, color: toggleState? Colors.grey.shade700 :Colors.white,)),
                  )
                ],
              ),
            ),
          ),
        ),
      );}
    else{
      return const LoadingSpaceWidget();
    }
  }
}