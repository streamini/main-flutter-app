import asyncio
import websockets
import json
import time

index = 0

async def connect_to_obs(scene_data):
    global index
    index += 1
    uri = "ws://localhost:4455"
    async with websockets.connect(uri) as websocket:
        # Wait for the server to send the initial handshake response
        initial_response = await websocket.recv()
        print("Connected to OBS WebSocket:", initial_response)
        
        # Send Identify message
        await identify(websocket)

        scene_name = scene_data["Scene"]
        url = scene_data["url"]
        audio_path = scene_data["audiopath"]

        await create_new_scene(websocket, scene_name)

        await create_browser_source(websocket, url, f"generate{index}", scene_name)

        # Create a media source for audio
        await create_media_source(websocket, audio_path, scene_name, f"audio{index}")

        time.sleep(1)
        
        # Optionally, get scene item ID and set position
        scene_item_id = await get_scene_item_id(websocket, scene_name, f"generate{index}")

        await set_position(websocket, scene_item_id, scene_name)

async def identify(websocket):
    payload = {
        "op": 1,
        "d": {
            "rpcVersion": 1
        }
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)

async def create_new_scene(websocket, scene_name):
    payload = {
        "op": 6,
        "d": {
            "requestType": "CreateScene",
            "requestId": "request_1",
            "requestData": {
                "sceneName": scene_name
            }
        }
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)
    print("Create new scene response:", response_data)

async def create_browser_source(websocket, url, source, scene):
    payload = {
        "op": 6,
        "d": {
            "requestType": "CreateInput",
            "requestId": "request_2",
            "requestData": {
                "sceneName": scene,
                "inputName": source,
                "inputKind": "browser_source",
                "inputSettings": {
                    "url": url,
                },
                "sceneItemEnabled": True,
            }
        }
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)
    print("Browser source creation response:", response_data)
    return source

async def create_media_source(websocket, audio, scene, audioname):
    payload = {
        "op": 6,
        "d": {
            "requestType": "CreateInput",
            "requestId": "request_3",
            "requestData": {
                "sceneName": scene,
                "inputName": audioname,
                "inputKind": "ffmpeg_source",
                "inputSettings": {
                    "local_file": audio,
                },
                "sceneItemEnabled": True,
            }
        }
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)
    print("Media source creation response:", response_data)

async def get_scene_item_id(websocket, scene_name, source_name):
    payload = {
        "op": 6,
        "d": {
            "requestType": "GetSceneItemId",
            "requestId": "request_4",
            "requestData": {
                "sceneName": scene_name,
                "sourceName": source_name
            }
        }
    }
    await websocket.send(json.dumps(payload))
    while True:
        response = await websocket.recv()
        response_data = json.loads(response)
        if response_data.get("op") == 7 and response_data['d'].get('requestId') == "request_4":
            print("Get scene item ID response:", response_data)
            scene_item_id = response_data['d']['responseData']['sceneItemId']
            print(scene_item_id)
            return scene_item_id
        

async def set_position(websocket, scene_item_id, scene):
    print(scene_item_id)
    if scene_item_id is None:
        print("Scene item ID is None. Skipping position set.")
        return
    
    payload = {
        "op": 6,
        "d": {
            "requestType": "SetSceneItemTransform",
            "requestId": "request_5",
            "requestData": {
                "sceneName": scene,
                "sceneItemId": scene_item_id,
                "sceneItemTransform": {
                    "positionX": 160,
                    "positionY": 0,
                    "rotation": 0,
                    "scaleX": 2.0,
                    "scaleY": 2.0,
                    "cropTop": 0.0,
                    "cropBottom": 0.0,
                    "cropLeft": 0.0,
                    "cropRight": 0.0
                }
            }
        }
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)
    print("Set position response:", response_data)

async def main():
    with open('data.json') as f:
        scenes = json.load(f)
    
    for scene_data in scenes:
        await connect_to_obs(scene_data)
        time.sleep(3)  # Wait for 3 seconds before processing the next scene

if __name__ == "__main__":
    asyncio.run(main())