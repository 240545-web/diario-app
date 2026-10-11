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
