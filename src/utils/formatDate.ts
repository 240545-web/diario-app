import { format, formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';

export const formatFullDate = (iso: string) =>
  format(new Date(iso), "d 'de' MMMM 'de' yyyy, HH:mm", { locale: es });

export const formatRelative = (iso: string) =>
  formatDistanceToNow(new Date(iso), { addSuffix: true, locale: es });
