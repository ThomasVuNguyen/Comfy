import 'package:comfyssh_flutter/comfyScript/statemanagement.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../components/LoadingWidget.dart';
import '../components/custom_ui_components.dart';
import '../components/custom_widgets.dart';
import '../components/pop_up.dart';
import '../function.dart';
import '../main.dart';

String toggleBuzzer(String pinOut, bool isToggled){
  if(isToggled == true){
    print("true");
    //return 'raspi-gpio set $pinOut op && raspi-gpio set $pinOut dh';
    return'python3 comfyScript/buzzer/buzzer.py $pinOut 1';
  }
  else{
    //return 'raspi-gpio set $pinOut op && raspi-gpio set $pinOut dl';
    return'python3 comfyScript/buzzer/buzzer.py $pinOut 0';
  }
}

class BuzzerToggle extends StatefulWidget {
  const BuzzerToggle({super.key, required this.spaceName, required this.name, required this.pin, required this.id, required this.hostname, required this.username, required this.password, required this.terminal});
  final String name;
  final String pin;
  final int id;
  final String hostname; final String username; final String password; final String spaceName;
  final Terminal terminal;
  @override
  State<BuzzerToggle> createState() => _BuzzerToggleState();
}

class _BuzzerToggleState extends State<BuzzerToggle> {
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
              widget.terminal.write('\r\nBuzzer ${widget.pin} on ');
            }
            else{
              widget.terminal.write('\r\nBuzzer ${widget.pin} off ');
            }
            //HapticFeedback.vibrate();
            SystemSound.play(SystemSoundType.click);
            var command = await client.run(toggleBuzzer(widget.pin.toString(), toggleState));
            print(toggleState);
          },
          child: Padding(
            padding: const EdgeInsets.all(buttonPadding),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(24.0),
                    color: toggleState? Colors.white :Colors.black,
                  ),
                  child: Center(child: toggleState? Icon(Icons.campaign, size: 60,color: Colors.black,) :Icon(Icons.volume_off, size: 60,color: Colors.white,),),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('${widget.name} ',style: GoogleFonts.poppins( fontWeight: FontWeight.w400, fontSize: 18, color:!toggleState? Colors.white :Colors.black, )),
                ),
              ],

            ),
          )
      );}
    else{
      return const LoadingSpaceWidget();
    }
  }
}

class AddBuzzerButton extends StatefulWidget {
  const AddBuzzerButton({super.key, required this.spaceName});
  final String spaceName;
  @override
  State<AddBuzzerButton> createState() => _AddBuzzerButtonState();
}

class _AddBuzzerButtonState extends State<AddBuzzerButton> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SpaceEdit())
      ],
      child: ListTile(
        //leading: Image.asset('assets/speedDialIcons/buzzer.png'),
          title: Text('Buzzer', style: Theme.of(context).textTheme.titleMedium,),
          onTap: (){
            Scaffold.of(context).closeEndDrawer();
            late String pinOut;
            showDialog(context: context, builder: (BuildContext context){
              return ButtonAlertDialog(
                title: 'Buzzer',
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      comfyTextField(text: 'button name', onChanged: (btnName){
                        buttonName = btnName;
                      }),
                      const SizedBox(height: 32, width: double.infinity,),
                      comfyTextField(text: 'pin number',
                        onChanged: (pinNum){pinOut = pinNum;},
                        keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  comfyActionButton(onPressed: (){
                    addButton('comfySpace.db', widget.spaceName, buttonName, 1, 1, 1, pinOut,'Buzzer');
                    Navigator.pop(context);
                    Provider.of<SpaceEdit>(context, listen: false).ChangeSpaceEditState();
                  },)
                ],
              );
            });
          }
      ),
    );
  }
}