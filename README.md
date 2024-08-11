# broadcast_gemini

A broadcast Application that work by remote OBS via websocket plugin.

## Related Repository
1. OBS Fork https://github.com/streamini/my_obs_fork
2. Proxy Server https://github.com/streamini/proxy_server


## How to run
1. Using macOS
2. Already open "gemini proxy server"
3. Change API key in config.dart to your API key and change server address to your server address
4. have flutter, python3.12 with pip installed, xcode, brew installed
5. Have OBS-Stuido installed or install our fork of OBS-Studio we recommend to use OBS-Stuido official for stability but if you want feature auto close OBS when app close you can use our fork of OBS-Studio
6. open obs-studio websocket at port 4455 and disable authentication
7. run ```brew install portaudio```
8. install python interpreter and all dependency in ./application_components/python_interpreter you can find list of dependencies in ./application_component/requirements.txt
9. run flutter app by running ```flutter run -d macos```


### if you have any question or any problem with run or compile please contact me at "kittipos.lee@gmail.com"
