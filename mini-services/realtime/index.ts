// ─────────────────────────────────────────────────────────────
// REALTIME SERVICE — خدمة الأحداث الفورية (socket.io)
// المنفذ 3002 — socket.io للعملاء (عبر البوابة ?XTransformPort=3002)
// المنفذ 3004 — HTTP داخلي (localhost فقط) ليستدعيه الـ Backend
// الغرف: stay:{id} | reception | admin
// الاستخدام من الـ Backend: POST http://localhost:3004/emit
// ─────────────────────────────────────────────────────────────
import { createServer, type IncomingMessage, type ServerResponse } from 'http'
import { Server } from 'socket.io'

const httpServer = createServer()

const io = new Server(httpServer, {
  // DO NOT change the path, it is used by Caddy to forward the request to the correct port
  path: '/',
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
})

const VALID_ROOM = /^(stay:[a-zA-Z0-9-]+|reception|admin)$/

io.on('connection', (socket) => {
  socket.on('join', (room: unknown) => {
    if (typeof room === 'string' && VALID_ROOM.test(room)) {
      socket.join(room)
    }
  })
  socket.on('leave', (room: unknown) => {
    if (typeof room === 'string' && VALID_ROOM.test(room)) {
      socket.leave(room)
    }
  })
})

// ── HTTP الداخلي للبث (المنفذ 3004 — للخادم فقط) ──
const emitServer = createServer(async (req: IncomingMessage, res: ServerResponse) => {
  const send = (status: number, body: Record<string, unknown>) => {
    res.writeHead(status, { 'content-type': 'application/json' })
    res.end(JSON.stringify(body))
  }
  if (req.method === 'GET' && req.url === '/health') {
    return send(200, { ok: true, service: 'realtime-emit' })
  }
  if (req.method === 'POST' && req.url === '/emit') {
    let body = ''
    for await (const chunk of req) body += chunk
    try {
      const { room, event, data } = JSON.parse(body)
      if (typeof room === 'string' && typeof event === 'string' && VALID_ROOM.test(room) && event.length < 60) {
        io.to(room).emit(event, data ?? null)
        return send(200, { ok: true, delivered: io.sockets.adapter.rooms.has(room) })
      }
      return send(400, { ok: false, error: 'invalid room or event' })
    } catch {
      return send(400, { ok: false, error: 'invalid json' })
    }
  }
  return send(404, { ok: false })
})

const SOCKET_PORT = 3002
const EMIT_PORT = 3004

httpServer.listen(SOCKET_PORT, () => {
  console.log(`Realtime socket service running on port ${SOCKET_PORT}`)
})

emitServer.listen(EMIT_PORT, '127.0.0.1', () => {
  console.log(`Realtime emit endpoint running on port ${EMIT_PORT} (localhost only)`)
})

process.on('SIGTERM', () => {
  httpServer.close()
  emitServer.close(() => process.exit(0))
})
process.on('SIGINT', () => {
  httpServer.close()
  emitServer.close(() => process.exit(0))
})
