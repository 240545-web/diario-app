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
