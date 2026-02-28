"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import QRCode from "qrcode";

export default function QRCodePage() {
  const searchParams = useSearchParams();
  const [qrDataUrl, setQrDataUrl] = useState<string>("");
  const [controllerUrl, setControllerUrl] = useState<string>("");
  const [localIp, setLocalIp] = useState<string>("localhost");

  useEffect(() => {
    const ip = searchParams.get("ip") || "localhost";
    const port = searchParams.get("port") || "8080";
    const nextPort = searchParams.get("nextPort") || "3000";

    setLocalIp(ip);

    // URL that phone will open when scanning QR
    // This goes to the controller page with WebSocket info
    const url = `http://${ip}:${nextPort}/controller?ws=ws://${ip}:${port}`;
    setControllerUrl(url);

    // Generate QR code
    QRCode.toDataURL(url, {
      width: 400,
      margin: 2,
      color: {
        dark: "#000000",
        light: "#ffffff",
      },
    }).then(setQrDataUrl);
  }, [searchParams]);

  return (
    <div className="min-h-screen bg-black flex flex-col items-center justify-center p-8">
      <div className="text-center space-y-8">
        <h1 className="text-4xl font-bold text-white">
          Scan to Join Game
        </h1>

        {qrDataUrl ? (
          <div className="bg-white p-4 rounded-lg">
            <img
              src={qrDataUrl}
              alt="QR Code"
              className="w-80 h-80"
            />
          </div>
        ) : (
          <div className="w-80 h-80 bg-gray-800 rounded-lg flex items-center justify-center">
            <span className="text-gray-400">Generating QR code...</span>
          </div>
        )}

        <div className="space-y-2">
          <p className="text-gray-400 text-lg">
            Scan with your phone camera
          </p>
          <p className="text-yellow-400 text-sm font-medium">
            Make sure Godot is running first!
          </p>
          <p className="text-gray-500 text-sm break-all">
            {controllerUrl || "Loading..."}
          </p>
        </div>

        <div className="mt-8 p-4 bg-gray-900 rounded-lg max-w-md">
          <h2 className="text-lg font-semibold text-white mb-2">How to Play</h2>
          <ol className="text-gray-400 text-left space-y-2 text-sm list-decimal list-inside">
            <li><strong className="text-yellow-400">Start Godot</strong> (WebSocket server runs here)</li>
            <li>Start Next.js: <code className="bg-gray-800 px-2 py-1 rounded">npm run dev</code></li>
            <li>Scan the QR code with your phone</li>
            <li>Enter your name and pick a color</li>
            <li>Use the D-pad to move (8 directions)</li>
            <li>A, B, C buttons for actions</li>
            <li>D button to jump!</li>
          </ol>
        </div>

        <div className="mt-4 p-4 bg-red-900/30 border border-red-500/50 rounded-lg max-w-md">
          <p className="text-red-400 text-sm font-medium">
            ⚠️ Connection Issues?
          </p>
          <p className="text-gray-400 text-sm mt-1">
            Make sure Godot is running before connecting! The WebSocket server (port 8080) runs inside Godot, not Next.js.
          </p>
        </div>

        <div className="mt-4 text-gray-600 text-sm">
          Max 8 players + 1 host
        </div>
      </div>
    </div>
  );
}
