import AsyncStorage from '@react-native-async-storage/async-storage';
import type { DiaryEntry } from '../types/entry';

const KEY = '@diario:entries';

export const diaryStorage = {
  getAll: async (): Promise<DiaryEntry[]> => {
    const raw = await AsyncStorage.getItem(KEY);
    if (!raw) return [];
    try {
      const parsed = JSON.parse(raw) as DiaryEntry[];
      return parsed.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    } catch {
      return [];
    }
  },

  getById: async (id: string): Promise<DiaryEntry | null> => {
    const all = await diaryStorage.getAll();
    return all.find((e) => e.id === id) ?? null;
  },

  save: async (entry: DiaryEntry): Promise<void> => {
    const all = await diaryStorage.getAll();
    const idx = all.findIndex((e) => e.id === entry.id);
    if (idx >= 0) {
      all[idx] = { ...entry, updatedAt: new Date().toISOString() };
    } else {
      all.unshift(entry);
    }
    await AsyncStorage.setItem(KEY, JSON.stringify(all));
  },

  remove: async (id: string): Promise<void> => {
    const all = await diaryStorage.getAll();
    await AsyncStorage.setItem(KEY, JSON.stringify(all.filter((e) => e.id !== id)));
  },
};
