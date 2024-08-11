import 'dart:typed_data';
import 'package:broadcast_gemini/ai_feature/ai_presentation.dart';
import 'package:broadcast_gemini/ai_feature/generate_widget.dart';
import 'package:broadcast_gemini/backend/ObsAdaptorPro.dart';
import 'package:broadcast_gemini/backend/macos_audio_bridge.dart';
import 'package:broadcast_gemini/backend/terminal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

String filePath = '/Users/${Platform.environment['USER'] ?? Platform.environment['USERNAME']}/streaming_app/';

// if folder not exist, create one
void createFolder() {
  Directory directory = Directory(filePath);
  if (!directory.existsSync()) {
    directory.createSync();
  }
}

Future<void> showOptionsDialog(BuildContext context, String currentscene) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Option'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              _buildDialogOption(context, Icons.language, 'Ai Generated Widget', currentscene),
              _buildDialogOption(context, Icons.language, 'Browser', currentscene),
              _buildDialogOption(context, Icons.color_lens, 'Color Source', currentscene),
              _buildDialogOption(context, Icons.desktop_windows, 'Display Capture', currentscene),
              _buildDialogOption(context, Icons.image, 'Image', currentscene),
              _buildDialogOption(context, Icons.text_fields, 'Text (GDI+)', currentscene),
              _buildDialogOption(context, Icons.videocam, 'Video Capture Device', currentscene),
              _buildDialogOption(context, Icons.window, 'Window Capture', currentscene),
              _buildDialogOption(context, Icons.mic, "Audio Input", currentscene),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget _buildDialogOption(BuildContext context, IconData icon, String option, String currentscene) {
  return ListTile(
    leading: Icon(icon),
    title: Text(option),
    onTap: () {
      Navigator.of(context).pop();
      handleOption(option, context, currentscene);
    },
  );
}

void aiGeneratedWidgetAlert(BuildContext context, String scene) {
  createFolder();
  final nameController = TextEditingController();
  final aboutThisWidgetController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Enter Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Input Name"),
              ),
              TextField(
                controller: aboutThisWidgetController,
                decoration: const InputDecoration(labelText: "About This Widget"),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("OK"),
            onPressed: () async {
              String name = nameController.text;
              String aboutThisWidget = aboutThisWidgetController.text;

              if (name.isNotEmpty && aboutThisWidget.isNotEmpty) {
                String userNeed = aboutThisWidget;
                AiGenerateWidget().generateWidget(userNeed).then((value) {
                  String widgetCode = value;
                  // get list of file in the directory
                  Directory directory = Directory(filePath);
                  List<FileSystemEntity> files = [];

                  try {
                    files.addAll(directory.listSync());
                  } catch (e) {
                    print(e);
                  }

                  // name a new file
                  String fileName = name;
                  int fileNameNumber = 0;
                  while (files.contains(File('$filePath$fileName$fileNameNumber.html'))) {
                    fileNameNumber++;
                  }
                  fileName = '$fileName$fileNameNumber.html';

                  // write the code to the file
                  File file = File('$filePath$fileName');
                  file.writeAsStringSync(widgetCode);

                  // add the file to OBS
                  browserInput(
                    scene: scene,
                    name: nameController.text,
                    web: "file://$filePath$fileName",
                    px: 50,
                    py: 50,
                    sx: 800,
                    sy: 600,
                  );

                  Navigator.of(context).pop();
                });

                SnackBar(content: Text('Adding widget please wait...'));
              } else {
                // Handle error: either name or aboutThisWidget is empty
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name and a description for the widget.')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

Future<void> handleOption(String option, BuildContext context, String scene) async {
  // Example values, replace with actual ones as needed
  //String sceneName = 'DefaultScene';
  //String inputName = 'DefaultInputName';
  //Map<String, dynamic> inputSettings = {};
  //bool sceneItemEnabled = true;
  // Map<String, dynamic> sceneItemProperties = {};

  switch (option) {
    case "Ai Generated Widget":
      aiGeneratedWidgetAlert(context, scene);
      break;
    case 'Browser':
      browerInputAlert(context, scene);
      break;
    case 'Color Source':
      colorInputAlert(context, scene);
      break;
    case 'Display Capture':
      displayInputAlert(context, scene);
      break;
    case 'Image':
      imageSourceInputAlert(context, scene);
      break;
    case 'Text (GDI+)':
      textInputAlert(context, scene);
      break;
    case 'Video Capture Device':
      videoCaptureDeviceInputAlert(context, scene);
      break;
    case 'Window Capture':
      windowCaptureInputAlert(context, scene);
      break;
    case "Audio Input":
      addAudioInput(context, scene);
      break;
    default:
      print('Unknown option selected');
  }
}

void addAudioInput(BuildContext context, String scene) {
  final nameController = TextEditingController();
  AudioDeviceItem? selectedDevice;
  String warningText = "";
  Function(void Function())? setStateOut;

  Future<List<AudioDeviceItem>> deviceList = getDeviceListMacOS();

  showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          setStateOut = setState;
          return AlertDialog(
            title: const Text("Enter Values"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Input Name",
                    ),
                  ),
                  FutureBuilder(
                      future: deviceList,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Data is still being fetched, show a loading indicator
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          // An error occurred, show an error message
                          return Text('Error: ${snapshot.error}');
                        } else {
                          List<AudioDeviceItem> devices = snapshot.data ?? [];
                          return DropdownButtonFormField<AudioDeviceItem>(
                            value: selectedDevice,
                            decoration: const InputDecoration(labelText: "Select Device"),
                            items: devices.map<DropdownMenuItem<AudioDeviceItem>>((AudioDeviceItem device) {
                              return DropdownMenuItem<AudioDeviceItem>(
                                value: device,
                                child: Text(device.deviceName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedDevice = value;
                            },
                          );
                        }
                      }),
                  Text(
                    warningText,
                    style: const TextStyle(color: Colors.red, fontSize: 14.0),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("OK"),
                onPressed: () async {
                  String name = nameController.text;
                  if (selectedDevice == null) {
                    setStateOut!(() {
                      warningText = "Please select a device";
                    });
                  } else if (name.isEmpty) {
                    setStateOut!(() {
                      warningText = "Please enter a name";
                    });
                  } else {
                    setStateOut!(() {
                      warningText = "";

                      addAudioInputToOBS(scene: scene, name: name, deviceId: selectedDevice!.deviceId).then((value) {
                        int? responseCode = value?.requestStatus.code;
                        if (responseCode == 100) {
                          Navigator.of(context).pop();
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text((responseCode == 601) ? "Input name already exit" : "Error"),
                                content: (responseCode == 601) ? const SizedBox() : Text("Error code: $responseCode"),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("OK"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      });
                    });
                  }
                },
              ),
            ],
          );
        });
      });
}

void browerInputAlert(BuildContext context, String scene) {
  final nameController = TextEditingController();
  final webController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Input Name"),
              ),
              TextField(
                controller: webController,
                decoration: InputDecoration(labelText: "Web URL"),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              await browserInput(
                scene: scene,
                name: nameController.text,
                web: webController.text,
                px: 50,
                py: 50,
                sx: 800,
                sy: 600,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> colorInputAlert(BuildContext context, String scene) async {
  final nameController = TextEditingController();
  Color currentColor = Colors.blue; // Default color

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Input Name"),
              ),
              SizedBox(height: 20),
              Text("Pick a color:"),
              ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (Color color) {
                  currentColor = color;
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              int colorValue = currentColor.value; // ARGB format
              await colorSourceInput(
                scene: scene,
                name: nameController.text,
                color: colorValue,
                // Use the color value in ARGB format
                px: 50,
                py: 50,
                sx: 1920,
                sy: 1080,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void displayInputAlert(BuildContext context, String scene) {
  final nameController = TextEditingController();
  int displayIndex = 0;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Input Name"),
              ),
              SizedBox(height: 20),
              Text("Select Display Index:"),
              DropdownButton<int>(
                value: displayIndex,
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    displayIndex = newValue;
                  }
                },
                items: <int>[0, 1, 2, 3] // Adjust the number of displays as needed
                    .map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text((value + 1).toString()),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              await displayCaptureInput(
                scene: scene,
                name: nameController.text,
                displayIndex: displayIndex,
                px: 50,
                py: 50,
                sx: 1920,
                sy: 1080,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void imageSourceInputAlert(BuildContext context, String scene) {
  final nameController = TextEditingController();
  String filePath = '';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Input Name"),
              ),
              SizedBox(height: 20),
              Text("Select an Image:"),
              ElevatedButton(
                onPressed: () async {
                  // Use a file picker to select an image
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );

                  if (result != null && result.files.single.path != null) {
                    filePath = result.files.single.path!;
                  } else {
                    // User canceled the picker
                    filePath = '';
                  }
                },
                child: Text("Choose Image"),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              if (filePath.isNotEmpty && nameController.text.isNotEmpty) {
                // Get the dimensions of the selected image
                File imageFile = File(filePath);
                Uint8List imageBytes = await imageFile.readAsBytes();
                img.Image? image = img.decodeImage(imageBytes);
                if (image != null) {
                  double sx = 1000;
                  double sy = (1000 * image.height) / image.width;

                  // Escape backslashes in the file path
                  String escapedFilePath = filePath.replaceAll(r'\', r'\\');

                  await imageSourceInput(
                    scene: scene,
                    name: nameController.text,
                    filePath: escapedFilePath,
                    px: 50,
                    py: 50,
                    sx: sx,
                    sy: sy,
                  );
                  Navigator.of(context).pop();
                } else {
                  // Handle error: unable to decode image
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to decode the selected image.')),
                  );
                }
              } else {
                // Handle error: either file path or name is empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select an image and enter a name.')),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

void textInputAlert(BuildContext context, String scene) {
  final nameController = TextEditingController();
  final textController = TextEditingController();
  Color currentColor = Colors.black; // Default color

  String selectedFace = 'Arial'; // Default font face
  String selectedStyle = 'Normal'; // Default font style
  double fontSize = 100.0; // Default font size suitable for 1920x1080

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Text Input Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Input Name"),
              ),
              TextField(
                controller: textController,
                decoration: InputDecoration(labelText: "Text"),
              ),
              SizedBox(height: 20),
              Text("Select Font Face:"),
              DropdownButton<String>(
                value: selectedFace,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedFace = newValue;
                  }
                },
                items: <String>['Arial', 'Helvetica', 'Times New Roman', 'Courier New', 'Verdana']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text("Enter Font Size:"),
              TextField(
                controller: TextEditingController(text: fontSize.toString()),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Font Size"),
                onChanged: (String value) {
                  fontSize = double.tryParse(value) ?? fontSize;
                },
              ),
              SizedBox(height: 20),
              Text("Select Font Style:"),
              DropdownButton<String>(
                value: selectedStyle,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedStyle = newValue;
                  }
                },
                items: <String>['Normal', 'Italic', 'Bold', 'Bold Italic'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text("Pick a color:"),
              ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (Color color) {
                  currentColor = color;
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              int colorValue = currentColor.value; // ARGB format
              await textinput(
                scene: scene,
                name: nameController.text,
                text: textController.text,
                face: selectedFace,
                size: fontSize,
                style: selectedStyle,
                color: colorValue,
                // Use the color value in ARGB format
                px: 50.0,
                py: 50.0,
                sx: 200.0,
                sy: 50.0,
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void videoCaptureDeviceInputAlert(BuildContext context, String scene) {
  final nameController = TextEditingController();
  String? selectedModelId;
  String? selectedUniqueId;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Values"),
        content: FutureBuilder<List<dynamic>>(
          future: getCameraDevices2(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else {
              List<dynamic> cameras = snapshot.data ?? [];
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Input Name"),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedModelId,
                      onChanged: (String? newValue) {
                        selectedModelId = newValue;
                        selectedUniqueId = cameras.firstWhere((camera) => camera['model_id'] == newValue)['unique_id'];
                      },
                      items: cameras.map<DropdownMenuItem<String>>((dynamic camera) {
                        return DropdownMenuItem<String>(
                          value: camera['model_id'],
                          child: Text(camera['model_id']),
                        );
                      }).toList(),
                      decoration: InputDecoration(labelText: "Select Model ID"),
                    ),
                    SizedBox(height: 20),
                    if (selectedUniqueId != null) Text("Unique ID: $selectedUniqueId"),
                    SizedBox(height: 20),
                  ],
                ),
              );
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              await addVideoCaptureDeviceInput(
                scene: scene,
                name: nameController.text,
                deviceid: selectedUniqueId ?? '',
                px: 0,
                py: 0,
                sx: 1,
                sy: 1,
                inputKind: 'macos-avcapture',
                // Adjust based on your system
                devicename: selectedModelId ?? '',
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> windowCaptureInputAlert(BuildContext context, String scene) async {
  final nameController = TextEditingController();
  String? selectedWindowName; // Make selectedWindowName nullable

  double px = 50;
  double py = 50;
  double sx = 800;
  double sy = 600;

  // Use a parent context or save the context in a variable before the await
  final dialogContext = context;

  showDialog(
    context: dialogContext,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Values"),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Input Name"),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("OK"),
            onPressed: () async {
              // Fetch the list of open applications after OK is pressed
              List<dynamic> apps = await getListOpenApp();

              // Show a second dialog to select the window
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Select Window"),
                    content: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: "Select Window"),
                            items: apps.map<DropdownMenuItem<String>>((dynamic app) {
                              return DropdownMenuItem<String>(
                                value: app.toString(),
                                child: Text(app.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedWindowName = value;
                              print("value = $selectedWindowName");
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text("OK"),
                        onPressed: () async {
                          if (selectedWindowName != null) {
                            await windowCaptureInput(
                              scene: scene,
                              name: nameController.text,
                              windowName: selectedWindowName!,
                              px: px,
                              py: py,
                              sx: sx,
                              sy: sy,
                            );
                          }
                          Navigator.of(context).pop(); // Close the window selection dialog
                          Navigator.of(context).pop(); // Close the initial dialog
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      );
    },
  );
}
