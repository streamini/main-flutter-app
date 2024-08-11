import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menu_bar/menu_bar.dart';
// Function to show the popup dialog
// Function to show the popup dialog
void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('About'),
        content: Text('StreaMini is a software that run on top of OBS and have great AI Gemini Functionallity such as Changing UI however you wish and much more! . Created by Kittipos, Panotpon, Bhira.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}


List<BarButton> menuBarButtons(BuildContext context) {
  return [
    BarButton(
      text: const Text(
        'File',
        style: TextStyle(color: Colors.white),
      ),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            onTap: () => print('Save'),
            text: const Text('Save'),
            shortcutText: 'Ctrl+S',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyS, control: true),
          ),
          MenuButton(
            onTap: () {},
            text: const Text('Save as'),
            shortcutText: 'Ctrl+Shift+S',
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            text: const Text('Open File'),
          ),
          MenuButton(
            onTap: () {},
            text: const Text('Open Folder'),
          ),
          const MenuDivider(),
          MenuButton(
            text: const Text('Preferences'),
            icon: const Icon(Icons.settings),
            submenu: SubMenu(
              menuItems: [
                MenuButton(
                  onTap: () {},
                  icon: const Icon(Icons.keyboard),
                  text: const Text('Shortcuts'),
                ),
                const MenuDivider(),
                MenuButton(
                  onTap: () {},
                  icon: const Icon(Icons.extension),
                  text: const Text('Extensions'),
                ),
                const MenuDivider(),
                MenuButton(
                  icon: const Icon(Icons.looks),
                  text: const Text('Change theme'),
                  submenu: SubMenu(
                    menuItems: [
                      MenuButton(
                        onTap: () {},
                        icon: const Icon(Icons.light_mode),
                        text: const Text('Light theme'),
                      ),
                      const MenuDivider(),
                      MenuButton(
                        onTap: () {},
                        icon: const Icon(Icons.dark_mode),
                        text: const Text('Dark theme'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    BarButton(
      text: const Text(
        'Edit',
        style: TextStyle(color: Colors.white),
      ),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            onTap: () {},
            text: const Text('Undo'),
            shortcutText: 'Ctrl+Z',
          ),
          const MenuDivider(),
        ],
      ),
    ),
    BarButton(
      text: const Text(
        'Help',
        style: TextStyle(color: Colors.white),
      ),
      submenu: SubMenu(
        menuItems: [
          MenuButton(
            onTap: () {},
            text: const Text('Check for updates'),
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {},
            text: const Text('View License'),
          ),
          const MenuDivider(),
          MenuButton(
            onTap: () {
              _showAboutDialog(context);
            },
            icon: const Icon(Icons.info),
            text: const Text('About'),
          ),
        ],
      ),
    ),
  ];
}
