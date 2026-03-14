import type { ServerMessage } from "./types";
import type { ServerWebSocket } from "bun";

export interface WSData {
  visitorId: string;
}

const clients = new Set<ServerWebSocket<WSData>>();

export function addClient(ws: ServerWebSocket<WSData>): void {
  clients.add(ws);
  console.log(`Client connected (${clients.size} total)`);
}

export function removeClient(ws: ServerWebSocket<WSData>): void {
  clients.delete(ws);
  console.log(`Client disconnected (${clients.size} total)`);
}

export function broadcast(message: ServerMessage): void {
  const data = JSON.stringify(message);
  for (const ws of clients) {
    ws.send(data);
  }
}

export function send(ws: ServerWebSocket<WSData>, message: ServerMessage): void {
  ws.send(JSON.stringify(message));
}

export function getClientCount(): number {
  return clients.size;
}
