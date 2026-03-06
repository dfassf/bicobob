mod commands;

use tauri::{
    tray::{MouseButton, MouseButtonState, TrayIconEvent},
    webview::WebviewWindowBuilder,
    Emitter, Manager,
};

#[tauri::command]
fn open_image_viewer(app: tauri::AppHandle, image_url: String) {
    // 기존 뷰어가 있으면 닫기
    if let Some(w) = app.get_webview_window("image-viewer") {
        let _ = w.close();
    }

    let html = format!(
        r#"<!DOCTYPE html><html><head><style>
*{{margin:0;padding:0}}
body{{background:#000;display:flex;align-items:center;justify-content:center;height:100vh;overflow:auto}}
img{{max-width:95vw;max-height:95vh;object-fit:contain;border-radius:8px;cursor:zoom-in;transition:transform .2s}}
img.zoomed{{max-width:none;max-height:none;width:200%;cursor:zoom-out}}
</style></head><body>
<img id="img" src="{}" onclick="this.classList.toggle('zoomed')"/>
</body></html>"#,
        image_url
    );

    // 임시 파일에 HTML 작성 후 file:// URL로 로드
    let temp_dir = std::env::temp_dir();
    let html_path = temp_dir.join("biconote_image_viewer.html");
    let _ = std::fs::write(&html_path, &html);

    let file_url = format!("file://{}", html_path.display());

    let _ = WebviewWindowBuilder::new(&app, "image-viewer", tauri::WebviewUrl::External(file_url.parse().unwrap()))
        .title("메뉴 원본 이미지")
        .inner_size(800.0, 600.0)
        .center()
        .resizable(true)
        .build();
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            // 독에서 숨기기 (Accessory 모드 = 트레이 전용 앱)
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            // 시작 시 트레이 아이콘 아래에 팝업 표시
            let tray = app.tray_by_id("main").expect("tray not found");
            if let Some(window) = app.get_webview_window("main") {
                if let Ok(Some(rect)) = tray.rect() {
                    let (px, py) = match rect.position {
                        tauri::Position::Physical(p) => (p.x, p.y),
                        tauri::Position::Logical(l) => (l.x as i32, l.y as i32),
                    };
                    let ph = match rect.size {
                        tauri::Size::Physical(s) => s.height as i32,
                        tauri::Size::Logical(l) => l.height as i32,
                    };
                    let _ = window.set_position(tauri::PhysicalPosition::new(
                        px - 160,
                        py + ph + 4,
                    ));
                }
                let _ = window.show();
                let _ = window.set_focus();
            }
            let app_handle = app.handle().clone();
            tray.on_tray_icon_event(move |_tray, event| {
                // 왼클릭 릴리즈 시 토글
                if let TrayIconEvent::Click {
                    button: MouseButton::Left,
                    button_state: MouseButtonState::Up,
                    ..
                } = event
                {
                    let _ = app_handle.emit("tray-clicked", ());
                    if let Some(window) = app_handle.get_webview_window("main") {
                        if window.is_visible().unwrap_or(false) {
                            let _ = window.hide();
                        } else {
                            if let Ok(Some(rect)) = _tray.rect() {
                                let (px, py) = match rect.position {
                                    tauri::Position::Physical(p) => (p.x, p.y),
                                    tauri::Position::Logical(l) => (l.x as i32, l.y as i32),
                                };
                                let ph = match rect.size {
                                    tauri::Size::Physical(s) => s.height as i32,
                                    tauri::Size::Logical(l) => l.height as i32,
                                };
                                let _ = window.set_position(tauri::PhysicalPosition::new(
                                    px - 160,
                                    py + ph + 4,
                                ));
                            }
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                }
            });

            // 윈도우 포커스 잃으면 자동 숨김
            let app_handle2 = app.handle().clone();
            if let Some(window) = app.get_webview_window("main") {
                window.on_window_event(move |event| {
                    if let tauri::WindowEvent::Focused(false) = event {
                        if let Some(w) = app_handle2.get_webview_window("main") {
                            let _ = w.hide();
                        }
                    }
                });
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::slack::fetch_lunch_images,
            commands::slack::check_lunch_message_ts,
            commands::gemini::analyze_menu_with_gemini,
            open_image_viewer,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
