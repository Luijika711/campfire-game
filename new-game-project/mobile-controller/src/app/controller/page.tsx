"use client";

import { useEffect, useState, useCallback, useRef } from "react";
import { useSearchParams } from "next/navigation";
import VirtualJoystick from "@/components/VirtualJoystick";

const COLORS = [
  { name: "Red", value: "#FF4444", bg: "bg-red-500" },
  { name: "Blue", value: "#4444FF", bg: "bg-blue-500" },
  { name: "Green", value: "#44FF44", bg: "bg-green-500" },
  { name: "Yellow", value: "#FFFF44", bg: "bg-yellow-400" },
  { name: "Purple", value: "#FF44FF", bg: "bg-purple-500" },
  { name: "Orange", value: "#FF8844", bg: "bg-orange-500" },
  { name: "Cyan", value: "#44FFFF", bg: "bg-cyan-400" },
  { name: "Pink", value: "#FF88AA", bg: "bg-pink-400" },
];

const TEAMS = [
  { name: "Red Team", value: 1, bg: "bg-red-600", ring: "ring-red-300" },
  { name: "Blue Team", value: 2, bg: "bg-blue-600", ring: "ring-blue-300" },
];

export default function ControllerPage() {
  const searchParams = useSearchParams();
  const [wsUrl, setWsUrl] = useState<string>("");
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [connected, setConnected] = useState(false);
  const [connecting, setConnecting] = useState(false);
  const [error, setError] = useState<string>("");
  const [playerName, setPlayerName] = useState("");
  const [selectedColor, setSelectedColor] = useState(COLORS[0]);
  const [selectedTeam, setSelectedTeam] = useState(TEAMS[0]);
  const [joined, setJoined] = useState(false);

  // Input states
  const inputState = useRef({
    moveX: 0,
    moveY: 0,
    aimX: 0,
    aimY: 0,
    fire: false,
    jump: false,
    weapon: 0,
  });

  // Send input throttle
  const lastSentTime = useRef(0);
  const pendingInput = useRef(false);

  useEffect(() => {
    const ws = searchParams.get("ws");
    if (ws) {
      setWsUrl(ws);
    } else {
      setError("No WebSocket URL provided. Please scan the QR code.");
    }
  }, [searchParams]);

  const sendInput = useCallback(() => {
    if (socket?.readyState === WebSocket.OPEN) {
      socket.send(
        JSON.stringify({
          type: "input",
          move_x: inputState.current.moveX,
          move_y: inputState.current.moveY,
          aim_x: inputState.current.aimX,
          aim_y: inputState.current.aimY,
          fire: inputState.current.fire,
          jump: inputState.current.jump,
          weapon: inputState.current.weapon,
        })
      );
      pendingInput.current = false;
    }
  }, [socket]);

  // Throttled input sender (30fps)
  useEffect(() => {
    if (!joined) return;

    const interval = setInterval(() => {
      if (pendingInput.current) {
        sendInput();
      }
    }, 33); // ~30fps

    return () => clearInterval(interval);
  }, [joined, sendInput]);

  const connect = useCallback(() => {
    if (!wsUrl || !playerName.trim()) return;

    setConnecting(true);
    setError("");

    try {
      const ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        console.log("WebSocket connected");
        setConnected(true);
        setConnecting(false);
        ws.send(
          JSON.stringify({
            type: "join",
            name: playerName.trim(),
            color: selectedColor.name,
            team: selectedTeam.value,
          })
        );
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          console.log("Received:", data);

          if (data.type === "connected") {
            setJoined(true);
          } else if (data.type === "error") {
            setError(data.message || "Connection error");
            setJoined(false);
          }
        } catch (e) {
          console.error("Failed to parse message:", e);
        }
      };

      ws.onclose = (event) => {
        console.log("WebSocket closed:", event.code, event.reason);
        setConnected(false);
        setJoined(false);
        setConnecting(false);
        if (!event.wasClean) {
          setError("Connection lost. Please try again.");
        }
      };

      ws.onerror = () => {
        setConnected(false);
        setConnecting(false);
        setError("Failed to connect. Make sure you're on the same WiFi network.");
      };

      setSocket(ws);
    } catch (err) {
      console.error("Failed to create WebSocket:", err);
      setConnecting(false);
      setError("Failed to create connection");
    }
  }, [wsUrl, playerName, selectedColor, selectedTeam]);

  useEffect(() => {
    return () => {
      if (socket) {
        socket.close();
      }
    };
  }, [socket]);

  // Joystick handlers
  const handleMoveJoystick = useCallback((x: number, y: number) => {
    inputState.current.moveX = x;
    inputState.current.moveY = y;
    pendingInput.current = true;
  }, []);

  const handleAimJoystick = useCallback((x: number, y: number) => {
    inputState.current.aimX = x;
    inputState.current.aimY = y;
    pendingInput.current = true;
  }, []);

  // Weapon switching handler
  const [currentWeapon, setCurrentWeapon] = useState(0);

  const handleWeaponSwitch = useCallback((weaponIndex: number) => {
    inputState.current.weapon = weaponIndex;
    setCurrentWeapon(weaponIndex);
    pendingInput.current = true;
    sendInput();
  }, [sendInput]);

  // Button handlers
  const handleFirePress = useCallback(() => {
    inputState.current.fire = true;
    pendingInput.current = true;
    sendInput();
  }, [sendInput]);

  const handleFireRelease = useCallback(() => {
    inputState.current.fire = false;
    pendingInput.current = true;
    sendInput();
  }, [sendInput]);

  const handleJumpPress = useCallback(() => {
    inputState.current.jump = true;
    pendingInput.current = true;
    sendInput();
  }, [sendInput]);

  const handleJumpRelease = useCallback(() => {
    inputState.current.jump = false;
    pendingInput.current = true;
    sendInput();
  }, [sendInput]);

  if (!joined) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center p-6">
        <div className="w-full max-w-md space-y-6">
          <h1 className="text-3xl font-bold text-white text-center">
            Join Game
          </h1>

          {error && (
            <div className="p-4 bg-red-900/50 border border-red-500 rounded-lg">
              <p className="text-red-400 text-center text-sm">{error}</p>
            </div>
          )}

          <div className="space-y-2">
            <label className="text-gray-400 text-sm">Your Name</label>
            <input
              type="text"
              value={playerName}
              onChange={(e) => setPlayerName(e.target.value)}
              placeholder="Enter your name"
              className="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
              maxLength={12}
              disabled={connecting}
            />
          </div>

          <div className="space-y-2">
            <label className="text-gray-400 text-sm">Pick a Color</label>
            <div className="grid grid-cols-4 gap-3">
              {COLORS.map((color) => (
                <button
                  key={color.name}
                  onClick={() => setSelectedColor(color)}
                  disabled={connecting}
                  className={`w-full aspect-square rounded-lg ${color.bg} ${
                    selectedColor.name === color.name
                      ? "ring-4 ring-white"
                      : ""
                  } ${connecting ? "opacity-50 cursor-not-allowed" : ""}`}
                  title={color.name}
                />
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-gray-400 text-sm">Choose Team</label>
            <div className="grid grid-cols-2 gap-3">
              {TEAMS.map((team) => (
                <button
                  key={team.name}
                  onClick={() => setSelectedTeam(team)}
                  disabled={connecting}
                  className={`py-3 rounded-lg font-bold text-white ${team.bg} ${
                    selectedTeam.value === team.value
                      ? `ring-4 ${team.ring}`
                      : "opacity-60"
                  } ${connecting ? "opacity-50 cursor-not-allowed" : ""}`}
                >
                  {team.name}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={connect}
            disabled={!playerName.trim() || !wsUrl || connecting}
            className={`w-full py-4 rounded-lg font-bold text-lg transition-colors ${
              playerName.trim() && wsUrl && !connecting
                ? "bg-blue-600 hover:bg-blue-500 text-white"
                : "bg-gray-700 text-gray-500 cursor-not-allowed"
            }`}
          >
            {connecting ? "Connecting..." : connected ? "Connected!" : "Join Game"}
          </button>

          {!wsUrl && (
            <p className="text-yellow-400 text-center text-sm">
              Invalid connection URL. Please scan the QR code again.
            </p>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black flex flex-col select-none overflow-hidden touch-none">
      {/* Status Bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-gray-900">
        <div className="flex items-center gap-2">
          <div
            className={`w-3 h-3 rounded-full ${
              connected ? "bg-green-500" : "bg-red-500"
            }`}
          />
          <span className="text-white font-medium">{playerName}</span>
          <span className={`text-xs px-2 py-0.5 rounded ${selectedTeam.bg} text-white`}>
            {selectedTeam.name}
          </span>
        </div>
        <div
          className={`w-6 h-6 rounded-full ${selectedColor.bg}`}
          title={selectedColor.name}
        />
      </div>

      {/* Controller Layout */}
      <div className="flex-1 flex flex-col p-4">
        {/* Main Controls Row */}
        <div className="flex-1 flex items-center justify-between">
          {/* Move Joystick - Left Side */}
          <div className="flex flex-col items-center">
            <VirtualJoystick
              onChange={handleMoveJoystick}
              label="MOVE"
              color="bg-gray-700"
              size={180}
            />
          </div>

          {/* Aim Joystick - Right Side */}
          <div className="flex flex-col items-center">
            <VirtualJoystick
              onChange={handleAimJoystick}
              label="AIM"
              color="bg-gray-600"
              size={180}
            />
          </div>
        </div>

        {/* Action Buttons Row */}
        <div className="flex items-center justify-between px-4 pb-4">
          {/* Fire Button - Left */}
          <button
            onTouchStart={(e) => {
              e.preventDefault();
              handleFirePress();
            }}
            onTouchEnd={(e) => {
              e.preventDefault();
              handleFireRelease();
            }}
            onMouseDown={handleFirePress}
            onMouseUp={handleFireRelease}
            onMouseLeave={handleFireRelease}
            className="w-24 h-24 rounded-full font-bold text-xl bg-orange-600 text-white active:bg-orange-500 shadow-lg"
          >
            FIRE
          </button>

          {/* Jump Button - Right */}
          <button
            onTouchStart={(e) => {
              e.preventDefault();
              handleJumpPress();
            }}
            onTouchEnd={(e) => {
              e.preventDefault();
              handleJumpRelease();
            }}
            onMouseDown={handleJumpPress}
            onMouseUp={handleJumpRelease}
            onMouseLeave={handleJumpRelease}
            className="w-28 h-28 rounded-full font-bold text-xl bg-blue-600 text-white active:bg-blue-500 shadow-lg ring-4 ring-blue-300"
          >
            JUMP
          </button>
        </div>

        {/* Weapon Selection Row */}
        <div className="flex items-center justify-center gap-4 px-4 pb-4">
          <button
            onClick={() => handleWeaponSwitch(0)}
            className={`w-20 h-16 rounded-lg font-bold text-lg transition-colors ${
              currentWeapon === 0
                ? "bg-green-600 text-white ring-4 ring-green-300"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
          >
            SWORD
          </button>
          <button
            onClick={() => handleWeaponSwitch(1)}
            className={`w-20 h-16 rounded-lg font-bold text-lg transition-colors ${
              currentWeapon === 1
                ? "bg-green-600 text-white ring-4 ring-green-300"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
          >
            GUN
          </button>
          <button
            onClick={() => handleWeaponSwitch(2)}
            className={`w-20 h-16 rounded-lg font-bold text-lg transition-colors ${
              currentWeapon === 2
                ? "bg-green-600 text-white ring-4 ring-green-300"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
          >
            LASER
          </button>
        </div>
      </div>
    </div>
  );
}
