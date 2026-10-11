import { useCallback, useEffect, useState } from 'react';
import { diaryStorage } from '../storage/diaryStorage';
import type { DiaryEntry } from '../types/entry';

export function useEntries() {
  const [entries, setEntries] = useState<DiaryEntry[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setEntries(await diaryStorage.getAll());
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  return { entries, loading, reload: load };
}
