// ─────────────────────────────────────────────────────────────
// APP STORE — متجر الحالة العام (zustand + persist)
// ─────────────────────────────────────────────────────────────
'use client'

import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { AppSession } from '@/types'

export type AppMode = 'website' | 'login' | 'guest' | 'reception' | 'admin'

interface AppState {
  mode: AppMode
  session: AppSession | null
  hydrated: boolean
  setMode: (mode: AppMode) => void
  setSession: (session: AppSession | null) => void
  logout: () => void
  setHydrated: () => void
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      mode: 'website',
      session: null,
      hydrated: false,
      setMode: (mode) => set({ mode }),
      setSession: (session) => set({ session }),
      logout: () => set({ mode: 'website', session: null }),
      setHydrated: () => set({ hydrated: true }),
    }),
    {
      name: 'qalb-hotel-session',
      partialize: (state) => ({ mode: state.mode, session: state.session }),
      onRehydrateStorage: () => (state) => {
        state?.setHydrated()
      },
    }
  )
)
