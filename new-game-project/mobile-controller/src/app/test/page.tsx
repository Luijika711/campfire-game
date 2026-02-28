"use client";

import { useState } from "react";

export default function TestPage() {
  const [wsUrl, setWsUrl] = useState("ws://localhost:8080");
  const [status, setStatus] = useState("<not connected>");
  const [logs, setLogs] = useState<string[]>([]);

  const addLog = (msg: string) => {
    setLogs((prev) => [...prev.slice(-9), `${new Date().toLocaleTimeString()}: ${msg}`]);
  };

  const testConnection = () => {
    setStatus("Connecting...");
    addLog(`Attempting to connect to ${wsUrl}`);

    try {
      const ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        setStatus("Connected! ✅");
        addLog("WebSocket opened successfully");
        
        // Send a test join message
        ws.send(JSON.stringify({
          type: "join",
          name: "TestPlayer",
          color: "Red"
        }));
        addLog("Sent join message");
      };

      ws.onmessage = (event) => {
        addLog(`Received: ${event.data}`);
        try {
          const data = JSON.parse(event.data);
          if (data.type === "connected") {
            setStatus(`Connected as Player ${data.player_id} ✅`);
          } else if (data.type === "error") {
            setStatus(`Error: ${data.message} ❌`);
          }
        } catch (e) {
          addLog(`Raw message: ${event.data}`);
        }
      };

      ws.onclose = (event) => {
        setStatus(`Disconnected (code: ${event.code}) ❌`);
        addLog(`WebSocket closed - Code: ${event.code}, Reason: ${event.reason || "No reason"}`);
      };

      ws.onerror = (error) => {
        setStatus("Connection failed ❌");
        addLog("WebSocket error occurred");
        console.error(error);
      };

      // Auto-close after 5 seconds for testing
      setTimeout(() => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.close();
          addLog("Auto-closed after 5 seconds");
        }
      }, 5000);

    } catch (err) {
      setStatus("Failed to create WebSocket ❌");
      addLog(`Error: ${err}`);
    }
  };

  return (
    <div className="min-h-screen bg-black text-white p-8">
      <div className="max-w-2xl mx-auto space-y-6">
        <h1 className="text-3xl font-bold">Connection Test</h1>
        
        <div className="p-4 bg-gray-900 rounded-lg">
          <label className="block text-sm text-gray-400 mb-2">WebSocket URL</label>
          <div className="flex gap-2">
            <input
              type="text"
              value={wsUrl}
              onChange={(e) => setWsUrl(e.target.value)}
              className="flex-1 px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg"
              placeholder="ws://localhost:8080"
            />
            <button
              onClick={testConnection}
              className="px-6 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg font-medium"
            >
              Test
            </button>
          </div>
        </div>

        <div className="p-4 bg-gray-900 rounded-lg">
          <p className="text-sm text-gray-400">Status:</p>
          <p className={`text-lg font-medium ${status.includes("✅") ? "text-green-400" : status.includes("❌") ? "text-red-400" : "text-yellow-400"}`}>
            {status}
          </p>
        </div>

        <div className="p-4 bg-gray-900 rounded-lg">
          <p className="text-sm text-gray-400 mb-2">Logs:</p>
          <div className="space-y-1 font-mono text-sm">
            {logs.length === 0 ? (
              <p className="text-gray-600">No logs yet...</p>
            ) : (
              logs.map((log, i) => (
                <p key={i} className="text-gray-300">{log}</p>
              ))
            )}
          </div>
        </div>

        <div className="p-4 bg-yellow-900/30 border border-yellow-500/50 rounded-lg">
          <p className="text-yellow-400 font-medium">Troubleshooting:</p>
          <ul className="mt-2 space-y-1 text-gray-400 text-sm list-disc list-inside">
            <li>Make sure Godot is running (WebSocket server is in Godot)</li>
            <li>Check Godot console for "WebSocket server started"</li>
            <li>For phone connection, use your computer's local IP, not localhost</li>
            <li>Windows Firewall might block port 8080</li>
            <li>Phone and computer must be on the same WiFi</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
