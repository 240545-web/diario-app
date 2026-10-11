import { useEffect, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert, KeyboardAvoidingView, Platform } from 'react-native';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import { diaryStorage } from '../storage/diaryStorage';
import { colors } from '../theme/colors';
import type { DiaryEntry } from '../types/entry';
import type { RootStackParamList } from '../navigation/RootNavigator';

const MOODS: { key: DiaryEntry['mood']; emoji: string; label: string }[] = [
  { key: 'feliz', emoji: '😊', label: 'Feliz' },
  { key: 'neutral', emoji: '😐', label: 'Neutral' },
  { key: 'triste', emoji: '😢', label: 'Triste' },
  { key: 'enojado', emoji: '😠', label: 'Enojado' },
];

export default function EntryFormScreen() {
  const nav = useNavigation<any>();
  const route = useRoute<RouteProp<RootStackParamList, 'EntryForm'>>();
  const editingId = route.params?.id;

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [mood, setMood] = useState<DiaryEntry['mood']>('neutral');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (editingId) {
      diaryStorage.getById(editingId).then((e) => {
        if (e) {
          setTitle(e.title);
          setContent(e.content);
          setMood(e.mood);
        }
      });
    }
  }, [editingId]);

  const handleSave = async () => {
    if (!title.trim()) return Alert.alert('Falta el título');
    if (!content.trim()) return Alert.alert('Falta el contenido');

    setSaving(true);
    const now = new Date().toISOString();
    const existing = editingId ? await diaryStorage.getById(editingId) : null;
    const entry: DiaryEntry = {
      id: editingId ?? `${Date.now()}`,
      title: title.trim(),
      content: content.trim(),
      mood,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };
    await diaryStorage.save(entry);
    setSaving(false);
    nav.goBack();
  };

  return (
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView style={styles.container} contentContainerStyle={{ padding: 20 }}>
        <Text style={styles.label}>Título</Text>
        <TextInput
          style={styles.input}
          value={title}
          onChangeText={setTitle}
          placeholder="Un título para tu entrada"
          placeholderTextColor={colors.textMuted}
        />

        <Text style={styles.label}>¿Cómo te sientes?</Text>
        <View style={styles.moods}>
          {MOODS.map((m) => (
            <TouchableOpacity
              key={m.key}
              onPress={() => setMood(m.key)}
              style={[styles.mood, mood === m.key && styles.moodActive]}
            >
              <Text style={styles.moodEmoji}>{m.emoji}</Text>
              <Text style={[styles.moodLabel, mood === m.key && { color: colors.primary }]}>
                {m.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.label}>Contenido</Text>
        <TextInput
          style={[styles.input, styles.textarea]}
          value={content}
          onChangeText={setContent}
          placeholder="Escribe lo que pasó hoy..."
          placeholderTextColor={colors.textMuted}
          multiline
          textAlignVertical="top"
        />

        <TouchableOpacity
          style={[styles.saveBtn, saving && { opacity: 0.6 }]}
          onPress={handleSave}
          disabled={saving}
        >
          <Text style={styles.saveText}>{saving ? 'Guardando...' : editingId ? 'Actualizar' : 'Guardar'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  label: { fontSize: 13, fontWeight: '700', color: colors.textMuted, marginBottom: 8, textTransform: 'uppercase' },
  input: {
    backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border,
    borderRadius: 10, padding: 14, fontSize: 16, color: colors.text, marginBottom: 20,
  },
  textarea: { height: 180 },
  moods: { flexDirection: 'row', marginBottom: 20, gap: 8 },
  mood: {
    flex: 1, alignItems: 'center', padding: 10, borderRadius: 10,
    borderWidth: 1, borderColor: colors.border, backgroundColor: colors.card,
  },
  moodActive: { borderColor: colors.primary, backgroundColor: '#EDE9FE' },
  moodEmoji: { fontSize: 26, marginBottom: 4 },
  moodLabel: { fontSize: 11, color: colors.textMuted, fontWeight: '600' },
  saveBtn: { backgroundColor: colors.primary, padding: 16, borderRadius: 12, alignItems: 'center', marginTop: 8 },
  saveText: { color: 'white', fontWeight: '700', fontSize: 16 },
});
