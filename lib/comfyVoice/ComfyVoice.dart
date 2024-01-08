import 'package:comfyssh_flutter/comfyScript/ComfyToggleButton.dart';
import 'package:comfyssh_flutter/comfyScript/statemanagement.dart';
import 'package:comfyssh_flutter/components/pop_up.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:xterm/xterm.dart';

import '../function.dart';
import 'ComfyVoiceDB.dart';

class ComfyVoice extends StatefulWidget {
  const ComfyVoice({super.key, required this.spaceName,
    required this.hostname, required this.username, required this.password,
 required this.terminal
  });
  final String spaceName;
  final String hostname; final String username; final String password;
  final Terminal terminal;
  @override
  State<ComfyVoice> createState() => _ComfyVoiceState();
}

class _ComfyVoiceState extends State<ComfyVoice> {
  late Map<String, String> Command;
  bool SSHLoaded = false;
  late SSHClient client;
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState(){
    super.initState();
    initClient();
    ExtractVoiceCommand();
    _initSpeech();
  }
  @override
  void dispose(){
    super.dispose();
    closeClient();
    _stopListening();
    print("closed");
  }
  Future<void> ExtractVoiceCommand() async{
    Command = await  VoiceCommandExtracted('comfySpace.db', widget.spaceName);
  }
  Future<void> initClient() async{
    client = SSHClient(
      await SSHSocket.connect('10.0.0.85', 22),
      username: 'tung',
      onPasswordRequest: () => 'tung',
    );

  }
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }
  Future<void> _startListening() async {
    print('listening');
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }
  Future<void> closeClient() async{
    final shell = await client.shell();
    await shell.done;
    client.close();
  }
  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }
  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    print(result.recognizedWords);
    if(Command[result.recognizedWords] == null){
      widget.terminal.write('${result.recognizedWords} not found');
    }
    else{
      await client.run(Command[result.recognizedWords]!);
    }
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SpaceEdit())
      ],
      child: FloatingActionButton(onPressed: (){
        _speechToText.isNotListening?
        _startListening()
            : _stopListening();
      },
          child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),),
    );
  }
}


class AddComfyVoiceButton extends StatefulWidget {
  const AddComfyVoiceButton({super.key, required this.spaceName});
  final String spaceName;
  @override
  State<AddComfyVoiceButton> createState() => _AddComfyVoiceButtonState();
}

class _AddComfyVoiceButtonState extends State<AddComfyVoiceButton> {
  @override
  Widget build(BuildContext context) {
    bool Expanded  = false;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SpaceEdit())
      ],
      child: IconButton(
          icon: Icon(Icons.mic),
          onPressed: () {
            //var VoiceTable = await VoiceCommandExtracted('comfySpace.db', widget.spaceName);
            //var VoiceTable = await CheckVoiceTable('comfySpace.db');
            //print(VoiceTable);
            Scaffold.of(context).closeEndDrawer();
            showDialog(context: context, builder: (BuildContext context){
              String buttonCommand = '';
              String buttonPrompt = '';
              return ButtonAlertDialog(
                width: MediaQuery.of(context).size.width,
                padding: 8.0,
                  title: 'Voice',
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder(
                            future: VoiceCommandExtractedList('comfySpace.db', widget.spaceName),
                            builder: (context, snapshot){
                              if(snapshot.connectionState == ConnectionState.done){
                                return ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Text('Voice prompt list'),
                                  children: [SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxHeight: double.infinity,
                                          minHeight: 100,
                                        ),
                                        height: 300,
                                        //height: 500,
                                        width: MediaQuery.of(context).size.width - 40,
                                        child:
                                        ListView.builder(
                                            padding: EdgeInsets.all(12.0),
                                            itemCount: snapshot.data?.length,
                                            itemBuilder: (context, index){
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      snapshot.data?[index]['prompt'],
                                                      overflow: TextOverflow.ellipsis,
                                                      softWrap: true,),
                                                  ),
                                                  Icon(Icons.arrow_right),
                                                  Flexible(
                                                    child: Text(
                                                        snapshot.data?[index]['command'],
                                                      overflow: TextOverflow.ellipsis,
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  IconButton(onPressed: (){
                                                    showDialog(context: context, builder: (BuildContext context){
                                                      String NewPrompt = snapshot.data?[index]['prompt'];
                                                      String NewCommand = snapshot.data?[index]['command'];
                                                      return ButtonAlertDialog(
                                                          title: 'Edit voice prompt'+context.watch<SpaceEdit>().EditSpaceState.toString(),
                                                          content:
                                                            Column(
                                                              children: [
                                                                TextFormField(
                                                                  keyboardType: TextInputType.multiline,
                                                                  initialValue: snapshot.data?[index]['prompt'],
                                                                  onChanged: (text){
                                                                    NewPrompt = text;
                                                                  },
                                                                ),
                                                                SizedBox(height: 10,),
                                                                TextFormField(
                                                                  keyboardType: TextInputType.multiline,
                                                                  initialValue: snapshot.data?[index]['command'],
                                                                  onChanged: (text){
                                                                    NewCommand = text;
                                                                  },
                                                                )
                                                              ],
                                                            ),

                                                          actions: [
                                                            TextButton(
                                                                onPressed: (){
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Text('Cancel')),
                                                            TextButton(
                                                                onPressed: () async {
                                                                  await EditVoicePrompt('comfySpace.db', widget.spaceName, snapshot.data?[index]['prompt'], snapshot.data?[index]['command'], NewPrompt, NewCommand, context);
                                                                  Provider.of<SpaceEdit>(context, listen: false).ChangeSpaceEditState();
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Text('Save')),
                                                            TextButton(
                                                                onPressed: () async {
                                                                  await DeleteVoicePrompt('comfySpace.db', widget.spaceName, snapshot.data?[index]['prompt'], snapshot.data?[index]['command']);
                                                                  Provider.of<SpaceEdit>(context, listen: false).ChangeSpaceEditState();
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Text('Delete')),
                                                          ]
                                                      );
                                                    });
                                                  }, icon: Icon(Icons.edit))
                                                ],
                                              );
                                            }),
                                      ),
                                    ),
                                  ),]
                                );
                              }
                              else{
                                return Text('loading');
                              }

                            }),
                        ExpansionTile(
                          childrenPadding: EdgeInsets.all(8.0),
                          onExpansionChanged: (expanded){
                            setState(() {
                              Expanded = expanded;
                              print(Expanded.toString());
                            });
                          },
                            title: Text('Add a voice prompt'),
                          children: [
                            comfyTextField(onChanged: (prompt){
                              buttonPrompt =prompt;
                            }, text: 'prompt'),
                            const SizedBox(height: 32, width: double.infinity,),
                            comfyTextField(onChanged: (btnCommand){
                              buttonCommand = btnCommand;
                            }, text: 'command', keyboardType: TextInputType.multiline,),
                            comfyActionButton(
                              onPressed: () async {
                                await addVoicePrompt('comfySpace.db', widget.spaceName, buttonPrompt, buttonCommand, context);
                                Provider.of<SpaceEdit>(context, listen: false).ChangeSpaceEditState();
                                //Navigator.pop(context);
                              },
                            ),
                          ],
                        )

                      ],
                    ),
                  ),
                  actions: [
                  ]);
            });
          }
      ),
    );
  }
}

