import 'package:broadcast_gemini/backend/ObsAdaptorPro.dart';
import 'package:flutter/material.dart';

Future<void> showAddSceneDialog(BuildContext context) async {
  TextEditingController sceneNameController = TextEditingController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter Scene Name'),
        content: TextField(
          controller: sceneNameController,
          decoration: InputDecoration(hintText: "Scene Name"),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Add'),
            onPressed: () async {
              String sceneName = sceneNameController.text;
              if (sceneName.isNotEmpty) {
                await handleAddScene(sceneName);
                Navigator.of(context)
                    .pop(); // Optionally, pass a value here if you need to indicate success
              } else {
                Navigator.of(context)
                    .pop(); // Optionally, pass a value here if you need to indicate cancellation or failure
              }
            },
          ),
        ],
      );
    },
  );
}

Future<void> showDeleteConfirmationDialog(
    BuildContext context, String currentScene) async {
  bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm'),
            content: Text('Are you sure you want to remove $currentScene?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Dismiss the dialog and return false
                },
              ),
              TextButton(
                child: Text('Delete'),
                onPressed: () {
                  Navigator.of(context)
                      .pop(true); // Dismiss the dialog and return true
                },
              ),
            ],
          );
        },
      ) ??
      false; // Handle null (e.g., if the dialog is dismissed)

  if (confirm) {
    await handleRemoveScene(currentScene);
    // Optionally, add code here to update the UI or state after deletion
  }
}
