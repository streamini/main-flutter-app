import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:process_run/process_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setPipAlreadyInstalled() async {
  // save to shared preference
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('pip_installed', true);
}

Future<bool> getPipAlreadyInstalled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('pip_installed') ?? false;
}

Future<bool> installPip(String rootPassword) {
  if (Platform.isMacOS) {
    // Python -m pip install requirements.txt
    return const MethodChannel('com.example/my_channel').invokeMethod('get_bundle_resource_path').then((bundleResourcePath) {
      String pythonInterpreterPath = '$bundleResourcePath/python_interpreter/bin/python3';
      String requirementsPath = '$bundleResourcePath/requirements.txt';
      String command = 'echo $rootPassword | sudo -S $pythonInterpreterPath -m pip install -r $requirementsPath';

      return Process.start('/bin/sh', ['-c', command]).then((process) async {
        process.stdout.transform(utf8.decoder).listen((data) {
          print(data);
        });

        process.stderr.transform(utf8.decoder).listen((data) {
          print('Error: $data');
        });

        return process.exitCode.then((exitCode) {
          if (exitCode != 0) {
            print('Error running command with exit code: $exitCode');
            return false;
          } else {
            setPipAlreadyInstalled();
            return true;
          }
        });
      });
    });
  } else {
    throw Exception('Unsupported platform');
  }
}

Future<void> runPythonCode(String pythonScriptFileName, Function(String) onOutput, BuildContext context) {
  if (Platform.isMacOS) {
    return getPipAlreadyInstalled().then((pipInstalled) {
      if (!pipInstalled) {
        // show dialog to ask for root password
        showDialog(
            context: context,
            barrierDismissible: false, // Prevents closing the dialog by tapping outside
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Root Password Required'),
                content: Column(
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  children: <Widget>[
                    const Text('Please enter your root password to install the required packages.'),
                    const SizedBox(height: 20), // Add some spacing
                    TextField(
                      decoration: const InputDecoration(hintText: 'Root Password'),
                      obscureText: true, // Hide the entered text
                      onSubmitted: (rootPassword) {
                        Navigator.of(context).pop(); // Close the dialog
                        installPip(rootPassword).then((pipInstalled) {
                          if (pipInstalled) {
                            runPythonCode(pythonScriptFileName, onOutput, context);
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Error'),
                                    content: const Text('Failed to install the required packages.'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                      ),
                                    ],
                                  );
                                });
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            });
      }

      // get bundle resource path
      return const MethodChannel('com.example/my_channel')
          .invokeMethod('get_bundle_resource_path')
          .then((bundleResourcePath) async {
        String pythonInterpreterPath = '$bundleResourcePath/python_interpreter/bin/python3';
        String pythonScriptPath = '$bundleResourcePath/python_code/$pythonScriptFileName';
        String command = '$pythonInterpreterPath $pythonScriptPath';

        try {
          Process process = await Process.start('/bin/sh', ['-c', command]);

          // Listen to stdout
          process.stdout.transform(utf8.decoder).listen((data) {
            print("data python: $data");
            onOutput(data);
          });

          // Listen to stderr
          process.stderr.transform(utf8.decoder).listen((data) {
            onOutput(data);
          });

          // Wait for the process to complete
          await process.exitCode;
          return;
        } catch (e) {
          print('Error running command: $e');
        }
      });
    });
  } else {
    throw Exception('Unsupported platform');
  }
}

Future<void> runObsCommand() async {
  if (Platform.isMacOS) {
    print("run obs command and platform is MacOS");
    const String checkCpuArchitecture = 'sysctl -n machdep.cpu.brand_string';

    final result = await Process.run('/bin/sh', ['-c', checkCpuArchitecture]);

    CpuArchitecture? cpuArchitecture;
    if (result.exitCode != 0) {
      print('Error running command: ${result.stderr}');
      // intel case
      cpuArchitecture = CpuArchitecture.intel;
    } else {
      final output = result.stdout.trim();
      if (output.contains('Apple')) {
        // apple case
        cpuArchitecture = CpuArchitecture.apple;
      } else {
        // intel case
        cpuArchitecture = CpuArchitecture.intel;
      }
    }

    print("run obs command : $cpuArchitecture");

    const MethodChannel('com.example/my_channel')
        .invokeMethod((cpuArchitecture == CpuArchitecture.apple) ? "get_obs_apple_path" : "get_obs_intel_path")
        .then((obsPath) async {
      // Define the command as a raw string to handle quotes properly
      print("recive obsPath: $obsPath");
      String startObsCommand =
          'nohup "${obsPath.toString()}/Contents/MacOS/OBS" --startvirtualcam --minimize-to-tray &> ~/obs.log &';
          // 'nohup "${obsPath.toString()}/Contents/MacOS/OBS"&> ~/obs.log &';

      print("startObsCommand: $startObsCommand");
      try {
        // Run the command using Process.run
        final result = await Process.run('/bin/sh', ['-c', startObsCommand]);

        // Check for errors
        if (result.exitCode != 0) {
          print('Error running command: ${result.stderr}');
        } else {
          print('Command ran successfully: ${result.stdout}');
        }
      } catch (e) {
        print('Exception: $e');
      }
    });
  } else if (Platform.isWindows) {
    // TODO: Implement the Windows command
  } else {
    throw Exception('Unsupported platform');
  }
}

void showAlertDialog(BuildContext context) {
  int countdown = 5; // Set the countdown duration
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents closing the dialog by tapping outside
    builder: (BuildContext context) {
      // Create a timer that updates the countdown and closes the dialog when it reaches 0
      Timer.periodic(Duration(seconds: 1), (Timer timer) {
        if (countdown <= 0) {
          Navigator.of(context).pop(); // Close the dialog
          timer.cancel(); // Stop the timer
        } else {
          countdown--; // Decrement the countdown
        }
      });

      return AlertDialog(
        title: Text('Connecting to OBS...'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space
          children: <Widget>[
            Text('Please select "Run Normally" in OBS to continue.'),
            SizedBox(height: 20), // Add some spacing
            CircularProgressIndicator(), // Show a progress indicator
            SizedBox(height: 20), // Add some spacing
            Text('Connection will complete shortly.'),
          ],
        ),
      );
    },
  );
}

Future<List<dynamic>> getListOpenApp() async {
  List<dynamic> openApps = [];

  if (Platform.isMacOS) {
    const String command =
        """osascript -e 'tell application "System Events" to get name of (every process whose background only is false)'""";

    try {
      final result = await Process.run('/bin/sh', ['-c', command]);

      if (result.exitCode != 0) {
        print('Error running command: ${result.stderr}');
      } else {
        // Split the result by comma and trim whitespace
        openApps = result.stdout.split(',').map((app) => app.trim()).toList();
        print('Command ran successfully: $openApps');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  return openApps;
}

Future<List<Map<String, String>>> getCameraDevices2() async {
  List<Map<String, String>> cameras = [];

  if (Platform.isMacOS) {
    const String command1 = 'system_profiler SPCameraDataType';

    final result1 = await Process.run('/bin/sh', ['-c', command1]);
    print("result1=${result1.stderr}");

    // Filter out the warning message from stderr and combine with stdout
    final cleanOutput = result1.stdout + (result1.stderr.contains('WARNING: AVCaptureDeviceTypeExternal') ? '' : result1.stderr);

    print("cleanOutput=$cleanOutput");

    // Process the result to extract camera details
    try {
      final cameraEntries =
          cleanOutput.split('\n\n').where((camera) => camera.contains('Model ID') && camera.contains('Unique ID'));

      for (var entry in cameraEntries) {
        final modelIdMatch = RegExp(r'Model ID:\s*(.*)').firstMatch(entry);
        final uniqueIdMatch = RegExp(r'Unique ID:\s*(.*)').firstMatch(entry);

        if (modelIdMatch != null && uniqueIdMatch != null) {
          cameras.add({
            'model_id': modelIdMatch.group(1)?.trim() ?? '',
            'unique_id': uniqueIdMatch.group(1)?.trim() ?? '',
          });
        }
      }

      print('Cameras found: $cameras');
    } catch (e) {
      print('Exception: $e');
    }
  }

  return cameras;
}

enum CpuArchitecture { intel, apple }

Future<void> runPythonScript() async {
  final shell = Shell();

  try {
    // await shell.run('cd /Users/panotpontreemas/Coding/streamini_backend');

    // await shell.run('source venv/bin/activate');

    // await shell.run('python main.py');
  } catch (e) {
    print(e);
  }
}
