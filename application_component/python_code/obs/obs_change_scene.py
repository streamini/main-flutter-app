import asyncio
import websockets
import json
import time

async def change_scene_on_audio_playback(scene_data):
    uri = "ws://localhost:4455"
    async with websockets.connect(uri) as websocket:
        # Wait for the server to send the initial handshake response
        initial_response = await websocket.recv()
        print("Connected to OBS WebSocket:", initial_response)
        
        # Send Identify message
        await identify(websocket)
        
        for scene in scene_data:
            scene_name = scene["Scene"]
            duration = scene["duration"]
            await change_scene(websocket, scene_name)
            await asyncio.sleep(duration)

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
    print("Identify response:", response_data)

async def change_scene(websocket, scene_name):
    payload = {
        "op": 6,
        "d": {
            "requestType": "SetCurrentProgramScene",
            "requestId": "request_6",
            "requestData": {
                "sceneName": scene_name
            }
        }
    }
    await websocket.send(json.dumps(payload))
    response = await websocket.recv()
    response_data = json.loads(response)
    print("Change scene response:", response_data)

async def main():
    with open('data.json') as f:
        scene_data = json.load(f)
    
    await change_scene_on_audio_playback(scene_data)

if __name__ == "__main__":
    asyncio.run(main())