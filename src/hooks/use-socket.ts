// ─────────────────────────────────────────────────────────────
// USE SOCKET — اتصال Realtime عبر بوابة Caddy
// io("/?XTransformPort=3002") — المسار دائمًا "/"
// ─────────────────────────────────────────────────────────────
'use client'

import { useEffect, useRef } from 'react'
import { io, type Socket } from 'socket.io-client'

export type SocketHandlers = Record<string, (payload: unknown) => void>

export function useSocket(room: string | null | undefined, handlers: SocketHandlers) {
  const socketRef = useRef<Socket | null>(null)
  const handlersRef = useRef<SocketHandlers>(handlers)

  // تحديث مرجع المعالجات بعد كل رسم (وليس أثناء الرسم)
  useEffect(() => {
    handlersRef.current = handlers
  })

  useEffect(() => {
    if (!room) return
    const socket = io('/?XTransformPort=3002', {
      transports: ['websocket', 'polling'],
      reconnectionAttempts: 10,
      reconnectionDelay: 2000,
    })
    socketRef.current = socket

    socket.on('connect', () => {
      socket.emit('join', room)
    })

    const eventNames = new Set<string>()
    const current = handlersRef.current
    Object.keys(current).forEach((ev) => eventNames.add(ev))

    const register = () => {
      eventNames.forEach((ev) => {
        socket.on(ev, (payload: unknown) => handlersRef.current[ev]?.(payload))
      })
    }
    register()

    return () => {
      socket.removeAllListeners()
      socket.disconnect()
      socketRef.current = null
    }
  }, [room])

  return socketRef
}
