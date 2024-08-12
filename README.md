# broadcast_gemini

A broadcast Application that work by remote OBS via websocket plugin.

## Related Repository

1. OBS Fork https://github.com/kittiposete/my_obs_fork
2. Proxy Server https://github.com/streamini/proxy_server

## How to run

1. Using macOS
2. Already open "gemini proxy server"
3. Change an API key in config.dart to your API key and change server address to your server address
4. have flutter, python3.12 with pip installed, xcode, brew installed
5. Have OBS-Stuido installed or install our fork of OBS-Studio we recommend to use OBS-Stuido official for stability but
   if you want feature auto close OBS when app close you can use our fork of OBS-Studio
6. open obs-studio websocket at port 4455 and disable authentication
7. run ```brew install portaudio```
8. install python interpreter and all dependency in ./application_components/python_interpreter you can find list of
   dependencies in ./application_component/requirements.txt
   by run following command in the terminal
    - go to application_component folder in project ```cd application_component```
    - create python venv using command ```python3 -m venv python_interpreter```
    - set current terminal to use venv ```source python_interpreter/bin/activate```
    - install all package and dependency ```pip install -r requirements.txt```
    - if install pip package error you may need
      to install with root permission by using ```sudo pip install -r requirements.txt```

9. run flutter app by running ```flutter run -d macos```
10. If build failed, you may need to build with xcode by open xcode and open project in ./macos/Runner.xcworkspace and
    run the project you may need to change a development team in xcode to your development team
11. If a problem still occur, you may need to run ```flutter clean``` and run ```flutter run -d macos``` again or back
    to step 10

## Use suggestion

1. Close and open project again if you want to reset the UI to default.
2. Feature Live assistant is an amazing feature that helps show an image related to your presentation in realtime.
   However, this feature may have a delay worst case it can up to a minute.
3. Feature AI Generated widget is work by using AI to write HTML code and display in webview as a widget.
   You may need to wait for a while after you click on the OK button.

### if you have any question or any problem with run or compile, please contact me at "kittipos.lee@gmail.com"
