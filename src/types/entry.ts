export interface DiaryEntry {
  id: string;
  title: string;
  content: string;
  mood: 'feliz' | 'neutral' | 'triste' | 'enojado';
  createdAt: string;
  updatedAt: string;
}
