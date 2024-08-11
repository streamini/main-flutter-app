import asyncio
import time
import websockets
import json

async def connect_to_obs(url):
    uri = "ws://localhost:4455"
    async with websockets.connect(uri) as websocket:
        # Wait for the server to send the initial handshake response
        initial_response = await websocket.recv()
        print("Connected to OBS WebSocket:", initial_response)
        
        # Send Identify message
        await identify(websocket)
        await remove(websocket)
        time.sleep(0.5)
        await create_browser_source(websocket, url, "generate", "Scene")
        time.sleep(0.5)
         # Optionally, get scene item ID and set position
        scene_item_id = await get_scene_item_id(websocket, "Scene", "generate")
        time.sleep(0.5)

        await set_position(websocket, scene_item_id, "Scene")


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
    print("Identification response:", response_data)


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

async def remove(websocket):
    payload = {
        "op": 6,
        "d": {
  "requestType": "RemoveInput",
  "requestId": "request_2",
  "requestData": {
    "inputName": "generate"
  }
}
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)

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


# Running the connect_to_obs coroutine
#asyncio.run(connect_to_obs("https://www.youtube.com"))