import { useState, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { useFocusEffect, useRoute, useNavigation, type RouteProp } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { diaryStorage } from '../storage/diaryStorage';
import { colors } from '../theme/colors';
import { formatFullDate } from '../utils/formatDate';
import type { DiaryEntry } from '../types/entry';
import type { RootStackParamList } from '../navigation/RootNavigator';

export default function EntryDetailScreen() {
  const route = useRoute<RouteProp<RootStackParamList, 'EntryDetail'>>();
  const nav = useNavigation<any>();
  const [entry, setEntry] = useState<DiaryEntry | null>(null);

  useFocusEffect(
    useCallback(() => {
      diaryStorage.getById(route.params.id).then(setEntry);
    }, [route.params.id])
  );

  if (!entry) return null;

  const confirmDelete = () => {
    Alert.alert('Eliminar entrada', '¿Estás seguro?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Eliminar',
        style: 'destructive',
        onPress: async () => {
          await diaryStorage.remove(entry.id);
          nav.goBack();
        },
      },
    ]);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={{ padding: 20 }}>
      <View style={styles.actions}>
        <TouchableOpacity onPress={() => nav.navigate('EntryForm', { id: entry.id })}>
          <Ionicons name="pencil" size={22} color={colors.primary} />
        </TouchableOpacity>
        <TouchableOpacity onPress={confirmDelete} style={{ marginLeft: 20 }}>
          <Ionicons name="trash" size={22} color={colors.danger} />
        </TouchableOpacity>
      </View>
      <Text style={styles.title}>{entry.title}</Text>
      <Text style={styles.date}>{formatFullDate(entry.createdAt)}</Text>
      <View style={styles.divider} />
      <Text style={styles.content}>{entry.content}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  actions: { flexDirection: 'row', justifyContent: 'flex-end', marginBottom: 16 },
  title: { fontSize: 24, fontWeight: '800', color: colors.text, marginBottom: 6 },
  date: { fontSize: 13, color: colors.textMuted, marginBottom: 16 },
  divider: { height: 1, backgroundColor: colors.border, marginBottom: 16 },
  content: { fontSize: 16, lineHeight: 24, color: colors.text },
});
