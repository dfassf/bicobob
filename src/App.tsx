import { useState, useEffect, useCallback, useRef } from "react";
import { listen } from "@tauri-apps/api/event";
import { load } from "@tauri-apps/plugin-store";
import {
  isPermissionGranted,
  requestPermission,
  sendNotification,
} from "@tauri-apps/plugin-notification";
import { invoke } from "@tauri-apps/api/core";
import { useLunchMenu } from "./useLunchMenu";
import { getKSTDateStr, getNowKST } from "./dateUtils";
import type { TraySettings } from "./types";
import "./App.css";

const STORE_FILE = "tray-settings.json";
const SETTINGS_KEY = "tray_settings";

const DEFAULT_SETTINGS: TraySettings = {
  slackToken: import.meta.env.VITE_SLACK_TOKEN ?? "",
  channelName: import.meta.env.VITE_CHANNEL_NAME ?? "",
  username: import.meta.env.VITE_USERNAME ?? "",
  geminiApiKey: import.meta.env.VITE_GEMINI_API_KEY ?? "",
  notifyEnabled: true,
  notifyTime: "12:35",
};

type View = "menu" | "settings";

function MenuSection({
  title,
  items,
}: {
  title: string;
  items: string[];
}) {
  if (items.length === 0) return null;
  return (
    <div className="menu-section">
      <h3>{title}</h3>
      <ul>
        {items.map((item, i) => (
          <li key={`${title}-${i}`}>{item}</li>
        ))}
      </ul>
    </div>
  );
}

function MenuView({
  settings,
  onOpenSettings,
}: {
  settings: TraySettings;
  onOpenSettings: () => void;
}) {
  const {
    status,
    error,
    todayMenu,
    cache,
    dayOffset,
    isWeekendDay,
    canGoPrev,
    canGoNext,
    refresh,
    navigateDay,
  } = useLunchMenu(settings);

  const hasRefreshed = useRef(false);
  const notifyFired = useRef("");

  // 첫 로드 시 refresh
  useEffect(() => {
    if (settings.slackToken && !hasRefreshed.current) {
      hasRefreshed.current = true;
      refresh();
    }
  }, [settings.slackToken, refresh]);

  // 트레이 클릭 시 refresh (캐시 있으면 ts만 확인하므로 빠름)
  useEffect(() => {
    const unlisten = listen("tray-clicked", () => {
      if (settings.slackToken) refresh();
    });
    return () => {
      unlisten.then((fn) => fn());
    };
  }, [settings.slackToken, refresh]);

  // 점심시간 알림
  useEffect(() => {
    if (!settings.notifyEnabled || !todayMenu) return;

    const check = async () => {
      const now = getNowKST();
      const timeStr = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
      const todayKey = now.toDateString();

      if (timeStr === settings.notifyTime && notifyFired.current !== todayKey) {
        notifyFired.current = todayKey;

        let granted = await isPermissionGranted();
        if (!granted) {
          const perm = await requestPermission();
          granted = perm === "granted";
        }
        if (granted) {
          const menuText = todayMenu.lunch.slice(0, 3).join(", ");
          sendNotification({
            title: "점심시간이에요!",
            body: menuText
              ? `오늘 메뉴: ${menuText}`
              : "오늘의 메뉴를 확인하세요",
          });
        }
      }
    };

    check();
    const interval = setInterval(check, 30_000);
    return () => clearInterval(interval);
  }, [settings.notifyEnabled, settings.notifyTime, todayMenu]);

  return (
    <div className="menu-view">
      <div className="header">
        <div className="header-left">
          <span className="app-title">비코밥</span>
        </div>
        <button className="settings-btn" onClick={onOpenSettings}>
          설정
        </button>
      </div>

      <div className="date-nav">
        <button
          className="nav-btn"
          disabled={!canGoPrev}
          onClick={() => navigateDay(-1)}
        >
          &lt;
        </button>
        <div className="date-label">{getKSTDateStr(dayOffset)}</div>
        <button
          className="nav-btn"
          disabled={!canGoNext}
          onClick={() => navigateDay(1)}
        >
          &gt;
        </button>
      </div>

      <div className="content">
        {error && <div className="error-msg">{error}</div>}

        {(status === "fetching" || status === "analyzing") ? (
          <div className="loading">
            {status === "fetching" ? "메뉴 가져오는 중..." : "메뉴 분석 중..."}
          </div>
        ) : isWeekendDay ? (
          <div className="empty-msg">주말입니다</div>
        ) : todayMenu ? (
          <div className="menu-card">
            <MenuSection title="중식" items={todayMenu.lunch} />
            <MenuSection title="석식" items={todayMenu.dinner} />
          </div>
        ) : status === "done" && !error ? (
          <div className="empty-msg">해당 요일의 메뉴 정보가 없습니다.</div>
        ) : null}

        {status === "error" && (
          <button className="retry-btn" onClick={() => refresh()}>
            다시 시도
          </button>
        )}

        {cache?.imageUrl && status === "done" && (
          <button
            className="image-btn"
            onClick={() => invoke("open_image_viewer", { imageUrl: cache.imageUrl })}
          >
            메뉴 원본 이미지 보기
          </button>
        )}
      </div>
    </div>
  );
}

function SettingsView({
  settings,
  onSave,
  onBack,
}: {
  settings: TraySettings;
  onSave: (s: TraySettings) => void;
  onBack: () => void;
}) {
  const [form, setForm] = useState(settings);

  const update = (key: keyof TraySettings, value: string | boolean) => {
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="settings-view">
      <div className="header">
        <button className="back-btn" onClick={onBack}>
          &lt; 뒤로
        </button>
        <span className="header-title">설정</span>
      </div>
      <div className="settings-form">
        <div className="field">
          <label>Slack Token</label>
          <input
            type="password"
            value={form.slackToken}
            onChange={(e) => update("slackToken", e.target.value)}
            placeholder="xoxp-..."
          />
        </div>
        <div className="field">
          <label>채널명</label>
          <input
            value={form.channelName}
            onChange={(e) => update("channelName", e.target.value)}
            placeholder="general"
          />
        </div>
        <div className="field">
          <label>Slack 사용자명</label>
          <input
            value={form.username}
            onChange={(e) => update("username", e.target.value)}
            placeholder="홍길동"
          />
        </div>
        <div className="field">
          <label>Gemini API Key</label>
          <input
            type="password"
            value={form.geminiApiKey}
            onChange={(e) => update("geminiApiKey", e.target.value)}
            placeholder="AIza..."
          />
        </div>
        <div className="field-row">
          <label>점심 알림</label>
          <div className="notify-row">
            <input
              type="checkbox"
              checked={form.notifyEnabled}
              onChange={(e) => update("notifyEnabled", e.target.checked)}
            />
            <input
              type="time"
              value={form.notifyTime}
              onChange={(e) => update("notifyTime", e.target.value)}
              disabled={!form.notifyEnabled}
            />
          </div>
        </div>
        <button
          className="save-btn"
          onClick={() => onSave(form)}
        >
          저장
        </button>
      </div>
    </div>
  );
}

export default function App() {
  const [settings, setSettings] = useState<TraySettings>(DEFAULT_SETTINGS);
  const [isLoaded, setIsLoaded] = useState(false);
  const [view, setView] = useState<View>("menu");

  useEffect(() => {
    (async () => {
      try {
        const store = await load(STORE_FILE);
        const saved = await store.get<TraySettings>(SETTINGS_KEY);
        if (saved) setSettings({ ...DEFAULT_SETTINGS, ...saved });
      } catch {
        // 첫 실행
      }
      setIsLoaded(true);
    })();
  }, []);

  const saveSettings = useCallback(async (newSettings: TraySettings) => {
    const store = await load(STORE_FILE);
    await store.set(SETTINGS_KEY, newSettings);
    await store.save();
    setSettings(newSettings);
    setView("menu");
  }, []);

  if (!isLoaded) return null;

  // 토큰 없으면 설정으로
  if (!settings.slackToken && view === "menu") {
    return (
      <div className="app">
        <div className="app-card">
          <SettingsView
            settings={settings}
            onSave={saveSettings}
            onBack={() => {}}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      <div className="app-arrow" />
      <div className="app-card">
        {view === "menu" ? (
          <MenuView
            settings={settings}
            onOpenSettings={() => setView("settings")}
          />
        ) : (
          <SettingsView
            settings={settings}
            onSave={saveSettings}
            onBack={() => setView("menu")}
          />
        )}
      </div>
    </div>
  );
}
