"use client";

import { useRef, useState, useCallback, TouchEvent, MouseEvent } from "react";

interface VirtualJoystickProps {
  onChange: (x: number, y: number) => void;
  label?: string;
  color?: string;
  size?: number;
}

export default function VirtualJoystick({
  onChange,
  label,
  color = "bg-gray-600",
  size = 160,
}: VirtualJoystickProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);

  const maxDistance = size * 0.35;
  const stickSize = size * 0.4;

  const calculateJoystickPosition = useCallback(
    (clientX: number, clientY: number) => {
      if (!containerRef.current) return { x: 0, y: 0 };

      const rect = containerRef.current.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;

      const deltaX = clientX - centerX;
      const deltaY = clientY - centerY;

      const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
      const angle = Math.atan2(deltaY, deltaX);

      const clampedDistance = Math.min(distance, maxDistance);

      return {
        x: Math.cos(angle) * clampedDistance,
        y: Math.sin(angle) * clampedDistance,
      };
    },
    [maxDistance]
  );

  const updateJoystick = useCallback(
    (clientX: number, clientY: number) => {
      const newPosition = calculateJoystickPosition(clientX, clientY);
      setPosition(newPosition);

      // Normalize values to -1 to 1 range
      const normalizedX = newPosition.x / maxDistance;
      const normalizedY = newPosition.y / maxDistance;
      onChange(normalizedX, normalizedY);
    },
    [calculateJoystickPosition, maxDistance, onChange]
  );

  const handleTouchStart = (e: TouchEvent) => {
    e.preventDefault();
    setIsDragging(true);
    const touch = e.touches[0];
    updateJoystick(touch.clientX, touch.clientY);
  };

  const handleTouchMove = (e: TouchEvent) => {
    e.preventDefault();
    if (!isDragging) return;
    const touch = e.touches[0];
    updateJoystick(touch.clientX, touch.clientY);
  };

  const handleTouchEnd = (e: TouchEvent) => {
    e.preventDefault();
    setIsDragging(false);
    setPosition({ x: 0, y: 0 });
    onChange(0, 0);
  };

  const handleMouseDown = (e: MouseEvent) => {
    e.preventDefault();
    setIsDragging(true);
    updateJoystick(e.clientX, e.clientY);
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging) return;
    updateJoystick(e.clientX, e.clientY);
  };

  const handleMouseUp = () => {
    setIsDragging(false);
    setPosition({ x: 0, y: 0 });
    onChange(0, 0);
  };

  const handleMouseLeave = () => {
    if (isDragging) {
      setIsDragging(false);
      setPosition({ x: 0, y: 0 });
      onChange(0, 0);
    }
  };

  return (
    <div className="relative">
      {label && (
        <div className="text-center text-gray-400 text-sm mb-2">{label}</div>
      )}
      <div
        ref={containerRef}
        className={`rounded-full ${color} relative cursor-pointer select-none`}
        style={{
          width: size,
          height: size,
          opacity: isDragging ? 0.8 : 0.6,
          transition: "opacity 0.15s ease",
        }}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
        onTouchCancel={handleTouchEnd}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseLeave}
      >
        {/* Joystick Stick */}
        <div
          className="absolute rounded-full bg-white shadow-lg pointer-events-none"
          style={{
            width: stickSize,
            height: stickSize,
            left: "50%",
            top: "50%",
            transform: `translate(calc(-50% + ${position.x}px), calc(-50% + ${position.y}px))`,
            transition: isDragging ? "none" : "transform 0.15s ease-out",
          }}
        />

        {/* Center indicator */}
        <div
          className="absolute rounded-full bg-white/20 pointer-events-none"
          style={{
            width: size * 0.15,
            height: size * 0.15,
            left: "50%",
            top: "50%",
            transform: "translate(-50%, -50%)",
          }}
        />
      </div>
    </div>
  );
}
