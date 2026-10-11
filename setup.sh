#!/bin/bash
set -e

echo "==> Inicializando package.json"
npm init -y

echo "==> Instalando Expo y dependencias"
npm install expo
npx expo install react react-native expo-status-bar
npx expo install typescript @types/react
npx expo install @react-native-async-storage/async-storage
npx expo install @react-navigation/native @react-navigation/native-stack
npx expo install react-native-screens react-native-safe-area-context
npm install date-fns @expo/vector-icons

echo "==> Creando carpetas"
mkdir -p src/screens src/components src/navigation src/storage src/hooks src/utils src/types src/theme assets

echo "==> app.json"
cat > app.json << 'EOF_APPJSON'
{
  "expo": {
    "name": "aplicacion-diario",
    "slug": "aplicacion-diario",
    "version": "1.0.0",
    "orientation": "portrait",
    "userInterfaceStyle": "light",
    "ios": { "supportsTablet": true },
    "android": { "package": "com.diario.app" }
  }
}
EOF_APPJSON

echo "==> tsconfig.json"
cat > tsconfig.json << 'EOF_TSCONFIG'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": { "strict": true }
}
EOF_TSCONFIG

echo "==> babel.config.js"
cat > babel.config.js << 'EOF_BABEL'
module.exports = function (api) {
  api.cache(true);
  return { presets: ['babel-preset-expo'] };
};
EOF_BABEL

echo "==> index.js"
cat > index.js << 'EOF_INDEXJS'
import { registerRootComponent } from 'expo';
import App from './App';
registerRootComponent(App);
EOF_INDEXJS

echo "==> Actualizando package.json"
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json'));
pkg.main = 'index.js';
pkg.scripts = {
  start: 'expo start',
  android: 'expo start --android',
  ios: 'expo start --ios',
  web: 'expo start --web'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"

echo "==> App.tsx"
cat > App.tsx << 'EOF_APPTSX'
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import RootNavigator from './src/navigation/RootNavigator';

export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <RootNavigator />
    </SafeAreaProvider>
  );
}
EOF_APPTSX

echo "==> src/types/entry.ts"
cat > src/types/entry.ts << 'EOF_TYPES'
export interface DiaryEntry {
  id: string;
  title: string;
  content: string;
  mood: 'feliz' | 'neutral' | 'triste' | 'enojado';
  createdAt: string;
  updatedAt: string;
}
EOF_TYPES

echo "==> src/theme/colors.ts"
cat > src/theme/colors.ts << 'EOF_COLORS'
export const colors = {
  primary: '#7C3AED',
  background: '#F9FAFB',
  card: '#FFFFFF',
  text: '#111827',
  textMuted: '#6B7280',
  border: '#E5E7EB',
  danger: '#EF4444',
  success: '#10B981',
};
EOF_COLORS

echo "==> src/utils/formatDate.ts"
cat > src/utils/formatDate.ts << 'EOF_FORMATDATE'
import { format, formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';

export const formatFullDate = (iso: string) =>
  format(new Date(iso), "d 'de' MMMM 'de' yyyy, HH:mm", { locale: es });

export const formatRelative = (iso: string) =>
  formatDistanceToNow(new Date(iso), { addSuffix: true, locale: es });
EOF_FORMATDATE

echo "==> src/storage/diaryStorage.ts"
cat > src/storage/diaryStorage.ts << 'EOF_STORAGE'
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
EOF_STORAGE

echo "==> src/hooks/useEntries.ts"
cat > src/hooks/useEntries.ts << 'EOF_USEENTRIES'
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
EOF_USEENTRIES

echo "==> src/components/EntryCard.tsx"
cat > src/components/EntryCard.tsx << 'EOF_ENTRYCARD'
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
EOF_ENTRYCARD

echo "==> src/components/EmptyState.tsx"
cat > src/components/EmptyState.tsx << 'EOF_EMPTY'
import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../theme/colors';

export function EmptyState() {
  return (
    <View style={styles.container}>
      <Text style={styles.emoji}>📔</Text>
      <Text style={styles.title}>Aún no hay entradas</Text>
      <Text style={styles.subtitle}>Toca el botón + para escribir tu primera entrada</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  emoji: { fontSize: 64, marginBottom: 16 },
  title: { fontSize: 18, fontWeight: '700', color: colors.text, marginBottom: 8 },
  subtitle: { fontSize: 14, color: colors.textMuted, textAlign: 'center' },
});
EOF_EMPTY

echo "==> src/screens/HomeScreen.tsx"
cat > src/screens/HomeScreen.tsx << 'EOF_HOME'
import { FlatList, View, TouchableOpacity, StyleSheet, RefreshControl } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { useEntries } from '../hooks/useEntries';
import { EntryCard } from '../components/EntryCard';
import { EmptyState } from '../components/EmptyState';
import { colors } from '../theme/colors';
import type { RootStackParamList } from '../navigation/RootNavigator';

type Nav = NativeStackNavigationProp<RootStackParamList, 'Home'>;

export default function HomeScreen() {
  const nav = useNavigation<Nav>();
  const { entries, loading, reload } = useEntries();

  return (
    <View style={styles.container}>
      <FlatList
        data={entries}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16, paddingBottom: 100 }}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={reload} />}
        ListEmptyComponent={!loading ? <EmptyState /> : null}
        renderItem={({ item }) => (
          <EntryCard entry={item} onPress={() => nav.navigate('EntryDetail', { id: item.id })} />
        )}
      />
      <TouchableOpacity style={styles.fab} onPress={() => nav.navigate('EntryForm', {})}>
        <Ionicons name="add" size={28} color="#fff" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  fab: {
    position: 'absolute', right: 20, bottom: 30,
    width: 60, height: 60, borderRadius: 30,
    backgroundColor: colors.primary,
    alignItems: 'center', justifyContent: 'center',
  },
});
EOF_HOME

echo "==> src/screens/EntryDetailScreen.tsx"
cat > src/screens/EntryDetailScreen.tsx << 'EOF_DETAIL'
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
EOF_DETAIL

echo "==> src/screens/EntryFormScreen.tsx"
cat > src/screens/EntryFormScreen.tsx << 'EOF_FORM'
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
EOF_FORM

echo "==> src/navigation/RootNavigator.tsx"
cat > src/navigation/RootNavigator.tsx << 'EOF_NAV'
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import HomeScreen from '../screens/HomeScreen';
import EntryDetailScreen from '../screens/EntryDetailScreen';
import EntryFormScreen from '../screens/EntryFormScreen';
import { colors } from '../theme/colors';

export type RootStackParamList = {
  Home: undefined;
  EntryDetail: { id: string };
  EntryForm: { id?: string } | undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function RootNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: { backgroundColor: colors.primary },
          headerTintColor: 'white',
          headerTitleStyle: { fontWeight: '700' },
        }}
      >
        <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Mi Diario' }} />
        <Stack.Screen name="EntryDetail" component={EntryDetailScreen} options={{ title: 'Entrada' }} />
        <Stack.Screen name="EntryForm" component={EntryFormScreen} options={{ title: 'Nueva entrada' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
EOF_NAV

echo ""
echo "=========================================="
echo "  LISTO"
echo "=========================================="
echo "Ejecuta: npx expo start"