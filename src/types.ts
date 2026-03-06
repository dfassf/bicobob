export interface LunchImage {
  url: string;
  filename: string;
  timestamp: string;
  message_text: string;
}

export type Weekday = "월" | "화" | "수" | "목" | "금";

export interface DayMenu {
  day: Weekday;
  lunch: string[];
  dinner: string[];
}

export interface WeeklyMenuCache {
  slackTs: string;
  cachedAt: string;
  weekKey: string;
  menus: DayMenu[];
  imageUrl: string;
  messageText: string;
}

export interface TraySettings {
  slackToken: string;
  channelName: string;
  username: string;
  geminiApiKey: string;
  notifyEnabled: boolean;
  notifyTime: string; // "HH:mm"
}
