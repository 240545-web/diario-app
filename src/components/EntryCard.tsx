import { TouchableOpacity, View, Text, StyleSheet } from 'react-native';
import type { DiaryEntry } from '../types/entry';
import { colors } from '../theme/colors';
import { formatRelative } from '../utils/formatDate';

const EMOJI: Record<DiaryEntry['mood'], string> = {
  feliz: '😊', neutral: '😐', triste: '😢', enojado: '😠',
};

export function EntryCard({ entry, onPress }: { entry: DiaryEntry; onPress: () => void }) {
  return (
    <TouchableOpacity onPress={onPress} style={styles.card} activeOpacity={0.7}>
      <View style={styles.header}>
        <Text style={styles.title} numberOfLines={1}>{entry.title}</Text>
        <Text style={styles.emoji}>{EMOJI[entry.mood]}</Text>
      </View>
      <Text style={styles.content} numberOfLines={2}>{entry.content}</Text>
      <Text style={styles.date}>{formatRelative(entry.createdAt)}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.card, borderRadius: 12, padding: 16, marginBottom: 12,
    borderWidth: 1, borderColor: colors.border },
  header: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
  title: { fontSize: 16, fontWeight: '700', color: colors.text, flex: 1 },
  emoji: { fontSize: 20, marginLeft: 8 },
  content: { fontSize: 14, color: colors.textMuted, marginBottom: 8 },
  date: { fontSize: 12, color: colors.textMuted },
});
