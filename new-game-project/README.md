# Multiplayer Phone Controller Game

A 2D platformer game where up to 8 players can connect using their phones as controllers via a WebSocket connection over local WiFi.

## Features

- **Host Player**: The Godot window player (keyboard controls)
- **8 Networked Players**: Connect via phones using QR code
- **8-Directional D-Pad**: Full directional control on phone
- **4 Action Buttons**: A, B, C, D (D is jump)
- **Random Colors**: Each player gets a unique random color
- **Nametags**: Player names displayed above characters
- **120Hz Physics**: Low-latency gameplay

## IMPORTANT: Startup Order

**You MUST start Godot FIRST, then the Next.js app:**

1. **Start Godot** - The WebSocket server runs inside Godot
2. **Start Next.js** - Provides the controller web interface
3. **Connect phones** - Scan QR code to join

## Quick Start

### Step 1: Start Godot (FIRST!)
```bash
# Open Godot 4.x
# Open this project (game_godot/)
# Run the main scene (F5 or Play button)
```

**Important**: You should see in the Godot console:
```
WebSocket server started on port 8080
Connect phones to: ws://192.168.x.x:8080
```

### Step 2: Start Next.js App
```bash
cd mobile-controller
npm install  # First time only
npm run dev
```

### Step 3: Connect Phones
1. In Godot, click **"Show QR Code"** button (or press **Tab**)
2. Scan the QR code with your phone camera
3. Enter your name and pick a color
4. Tap **"Join Game"**
5. Play!

## Troubleshooting

### "Firefox can't establish a connection to ws://localhost:8080"

**This means Godot is not running!**

1. **Make sure Godot is running** - The WebSocket server is part of Godot, not Next.js
2. Check the Godot console for "WebSocket server started on port 8080"
3. If you see errors about port 8080, another app might be using it

### "Connection lost" or "Failed to connect"

1. **Check order**: Godot must be started BEFORE trying to connect
2. **Same network**: Phone and computer must be on the same WiFi
3. **Firewall**: Windows Firewall might be blocking port 8080
   - Allow Godot through Windows Firewall
   - Or temporarily disable firewall for testing
4. **Port already in use**: Change port in `scripts/network_manager.gd`:
   ```gdscript
   @export var port: int = 8081  # Try a different port
   ```

### Phone shows "Invalid connection URL"

The QR code might have the wrong IP. Try:
1. Check your computer's local IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Manually enter the URL: `http://[YOUR_IP]:3000/controller?ws=ws://[YOUR_IP]:8080`
3. Replace [YOUR_IP] with your actual local IP (e.g., 192.168.1.100)

### WebSocket works but inputs don't respond

1. Check Godot console for "Player X joined" messages
2. Make sure you're using the controller page, not the QR page
3. Try refreshing the phone browser

## Project Structure

```
game_godot/
├── scripts/
│   ├── network_manager.gd      # WebSocket server (runs in Godot)
│   ├── player_manager.gd       # Spawn/manage networked players
│   ├── player_networked.gd     # Networked player controller
│   ├── qr_display.gd          # QR code display logic
│   ├── main.gd                # Main game logic
│   └── player.gd              # Host player (keyboard)
├── scenes/
│   ├── main.tscn              # Main game scene
│   ├── player.tscn            # Host player scene
│   ├── player_networked.tscn  # Networked player with nametag
│   └── qr_display.tscn        # QR code display UI
└── mobile-controller/          # Next.js mobile controller app
    ├── src/app/
    │   ├── qrcode/page.tsx    # QR code display
    │   └── controller/page.tsx # Mobile controller UI
    └── package.json
```

## Controls

### Host (Godot Window)
- **WASD** or **Arrow Keys** = Move
- **Space** or **W** = Jump
- **S** or **Down** = Fast fall
- **Double-tap A/D** or **Left/Right** = Dash
- **Tab** = Toggle QR display

### Phone (Touch)
- **D-Pad** = 8-directional movement (supports diagonals)
- **D button** (big red) = Jump
- **A, B, C buttons** = Actions (customizable)

## How It Works

```
Godot Starts
    ↓
WebSocket Server starts on port 8080
    ↓
User clicks "Show QR Code"
    ↓
QR displays URL: http://[LOCAL_IP]:3000/controller?ws=ws://[LOCAL_IP]:8080
    ↓
Phone scans QR → Opens controller page
    ↓
Phone connects via WebSocket to Godot
    ↓
Player spawns with nametag and color
```

## Technical Details

### Network Protocol
- **Transport**: WebSocket (TCP)
- **Port**: 8080 (Godot WebSocket server)
- **Max Players**: 8 phone players + 1 host

### Message Format

**Phone → Godot:**
```json
// Join game
{"type": "join", "name": "Player1", "color": "Blue"}

// Button press
{"type": "input", "action": "press", "button": "UP"}

// Button release
{"type": "input", "action": "release", "button": "UP"}

// Keep-alive
{"type": "ping"}
```

**Godot → Phone:**
```json
// Connection accepted
{"type": "connected", "player_id": 1, "color": "Blue"}

// Connection rejected
{"type": "error", "message": "Lobby full"}

// Heartbeat response
{"type": "pong"}
```

### Button Mapping

| Button | Action |
|--------|--------|
| UP | Jump / Move up |
| DOWN | Fast fall / Move down |
| LEFT | Move left |
| RIGHT | Move right |
| UP_LEFT | Diagonal jump left |
| UP_RIGHT | Diagonal jump right |
| DOWN_LEFT | Diagonal down-left |
| DOWN_RIGHT | Diagonal down-right |
| A | Action A |
| B | Action B |
| C | Action C |
| D | Jump (dedicated) |

### Player Colors

1. Red `#FF4444`
2. Blue `#4444FF`
3. Green `#44FF44`
4. Yellow `#FFFF44`
5. Purple `#FF44FF`
6. Orange `#FF8844`
7. Cyan `#44FFFF`
8. Pink `#FF88AA`

## Development

### Testing Locally (Same Machine)

If you want to test on the same computer without a phone:

1. Start Godot
2. Start Next.js
3. Open browser to: `http://localhost:3000/controller?ws=ws://localhost:8080`
4. Enter name and join

**Note**: This only works if Godot is running! The WebSocket at ws://localhost:8080 is served by Godot, not Next.js.

### Adding Custom Actions

To make buttons A, B, C do something:

1. Edit `scripts/player_networked.gd`
2. Add logic in `_physics_process`:

```gdscript
if input_a:
    # Do something when A is pressed
    perform_attack()

if input_b:
    # Do something when B is pressed
    perform_special()

if input_c:
    # Do something when C is pressed
    perform_shield()
```

### Changing Physics Settings

Edit `project.godot`:

```ini
[physics]
common/physics_ticks_per_second=120  # Change tick rate
```

### Modifying Spawn Points

Edit `scripts/player_manager.gd`:

```gdscript
@export var spawn_points: Array[Vector2] = [
    Vector2(100, 400),
    Vector2(200, 400),
    # Add more spawn points
]
```

## Common Issues

### "Failed to start WebSocket server"
- Port 8080 is in use by another application
- Try changing the port in `scripts/network_manager.gd`
- Run as administrator if firewall is blocking

### Phone can't connect but same machine works
- Phone and computer are on different networks
- Check WiFi settings on both devices
- Try using mobile hotspot from the computer

### High latency
- Close other network-heavy applications
- Move closer to the WiFi router
- Check for interference from other devices

### Players not spawning
- Check Godot console for error messages
- Verify WebSocket connection is established
- Ensure max players limit (8) hasn't been reached

## License

MIT License - Feel free to use and modify!
