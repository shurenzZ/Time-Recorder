"""Time Recorder - Windows desktop wrapper (pywebview + WebView2).

Loads the bundled HTML via a stable file:// URL so localStorage works
(Chromium/WebView2 blocks localStorage on data: URLs, causing
'Access is denied for this document'). The HTML is staged into a
fixed %APPDATA% directory and the WebView2 user-data folder is pinned,
so the cache (localStorage, cookies) persists across launches.

In addition to the in-app toast(), a Windows system toast is fired
via PowerShell + Windows.UI.Notifications (no third-party deps).
"""
import os
import pathlib
import shutil
import subprocess
import sys
import time
import threading
import ctypes

import webview


APP_DIR_NAME = "TimeRecorder"
HTML_FILE = "Time Recorder.html"

# Windows Credential Manager (advapi32) resource/username for the auth session.
# The stored "password" is a JSON blob: {access_token, refresh_token, expires_at, user_id, savedAt}
VAULT_RESOURCE = "TimeRecorder.Auth"
VAULT_USERNAME = "session"


def resource_path(filename):
    """Return the path to a bundled resource (PyInstaller _MEIPASS or dev dir)."""
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, filename)


def _exe_dir():
    """Directory that hosts the executable (frozen) or the script (dev)."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.abspath(__file__))


def portable_mode():
    """Portable mode when a `portable.ini` marker file sits next to the exe.
    In portable mode all data (staged HTML, localStorage, WebView cache) is
    kept in a `Data/` folder beside the exe, so the whole folder can be
    carried on a USB stick. Without the marker, data goes to %APPDATA%."""
    try:
        return os.path.isfile(os.path.join(_exe_dir(), "portable.ini"))
    except Exception:
        return False


def app_data_dir():
    """%APPDATA%\\TimeRecorder (Roaming) — or `<exe_dir>/Data` in portable mode."""
    if portable_mode():
        p = pathlib.Path(_exe_dir()) / "Data"
    else:
        base = os.environ.get("APPDATA") or os.path.expanduser("~")
        p = pathlib.Path(base) / APP_DIR_NAME
    p.mkdir(parents=True, exist_ok=True)
    return p


def stage_html():
    """Copy the bundled HTML to a stable appdata path so the file:// origin
    is identical across launches (required for localStorage persistence)."""
    app = app_data_dir() / "app"
    app.mkdir(parents=True, exist_ok=True)
    src = pathlib.Path(resource_path(HTML_FILE))
    dst = app / "index.html"
    # Always refresh from the bundled resource so version updates take effect.
    shutil.copyfile(src, dst)
    return dst


def webview_data_dir():
    d = app_data_dir() / "webview"
    d.mkdir(parents=True, exist_ok=True)
    return d


# Windows system toast via PowerShell + WinRT (Win10/11, no extra packages).
PS_TOAST = r"""
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
$appId = 'TimeRecorder.Desktop'
$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$texts = $template.GetElementsByTagName('text')
$texts.Item(0).AppendChild($template.CreateTextNode($args[0])) | Out-Null
$texts.Item(1).AppendChild($template.CreateTextNode($args[1])) | Out-Null
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
$notifier.Show($template)
"""


# ---------- Windows Credential Manager (Win32 advapi32) helpers ----------
# Stores the Supabase session JSON in the OS credential vault via the native
# CredWrite/CredRead/CredDelete Win32 API. OS-encrypted, tied to the current
# Windows user, visible in Control Panel -> Credential Manager -> Windows
# Credentials. Works on all Win10/11 without PowerShell-version dependency.
if sys.platform == "win32":
    advapi32 = ctypes.WinDLL("advapi32.dll")

    CRED_TYPE_GENERIC = 1
    CRED_PERSIST_LOCAL_MACHINE = 2

    class CREDENTIAL(ctypes.Structure):
        _fields_ = [
            ("Flags", ctypes.c_uint32),
            ("Type", ctypes.c_uint32),
            ("TargetName", ctypes.c_wchar_p),
            ("Comment", ctypes.c_wchar_p),
            ("LastWritten", ctypes.c_uint64),  # FILETIME (8 bytes)
            ("CredentialBlobSize", ctypes.c_uint32),
            ("CredentialBlob", ctypes.POINTER(ctypes.c_byte)),
            ("Persist", ctypes.c_uint32),
            ("AttributeCount", ctypes.c_uint32),
            ("Attributes", ctypes.c_void_p),
            ("TargetAlias", ctypes.c_wchar_p),
            ("UserName", ctypes.c_wchar_p),
        ]

    advapi32.CredWriteW.argtypes = [ctypes.POINTER(CREDENTIAL), ctypes.c_uint32]
    advapi32.CredWriteW.restype = ctypes.c_bool

    advapi32.CredReadW.argtypes = [
        ctypes.c_wchar_p,
        ctypes.c_uint32,
        ctypes.c_uint32,
        ctypes.POINTER(ctypes.POINTER(CREDENTIAL)),
    ]
    advapi32.CredReadW.restype = ctypes.c_bool

    advapi32.CredDeleteW.argtypes = [
        ctypes.c_wchar_p,
        ctypes.c_uint32,
        ctypes.c_uint32,
    ]
    advapi32.CredDeleteW.restype = ctypes.c_bool

    advapi32.CredFree.argtypes = [ctypes.c_void_p]
    advapi32.CredFree.restype = None


    def _vault_write(target, username, blob_str):
        """Write a generic credential. Returns True on success."""
        blob_bytes = blob_str.encode("utf-16-le")
        blob_buf = (ctypes.c_byte * len(blob_bytes))(*blob_bytes)
        cred = CREDENTIAL()
        cred.Flags = 0
        cred.Type = CRED_TYPE_GENERIC
        cred.TargetName = target
        cred.UserName = username
        cred.CredentialBlob = blob_buf
        cred.CredentialBlobSize = len(blob_bytes)
        cred.Persist = CRED_PERSIST_LOCAL_MACHINE
        return bool(advapi32.CredWriteW(ctypes.byref(cred), 0))


    def _vault_read(target):
        """Return (username, blob_str) or (None, None) if absent."""
        cred_ptr = ctypes.POINTER(CREDENTIAL)()
        if not advapi32.CredReadW(target, CRED_TYPE_GENERIC, 0, ctypes.byref(cred_ptr)):
            return None, None
        try:
            cred = cred_ptr.contents
            n = cred.CredentialBlobSize
            blob = ctypes.string_at(cred.CredentialBlob, n).decode("utf-16-le")
            return cred.UserName, blob
        finally:
            advapi32.CredFree(cred_ptr)


    def _vault_delete(target):
        """Delete a credential; True if removed or already absent."""
        if advapi32.CredDeleteW(target, CRED_TYPE_GENERIC, 0):
            return True
        return ctypes.get_last_error() == 1168  # ERROR_NOT_FOUND = already gone
else:
    def _vault_write(target, username, blob_str): return False
    def _vault_read(target): return None, None
    def _vault_delete(target): return True


class Bridge:
    """Exposed to the page as window.pywebview.api.*."""

    def notify(self, title, message):
        try:
            subprocess.Popen(
                ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
                 "& { " + PS_TOAST + " }", str(title or "Time Recorder"),
                 str(message or "")],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=0x08000000,  # CREATE_NO_WINDOW
            )
        except Exception:
            pass

    def getStoredSession(self):
        """Return the stored session JSON string, or None if absent/invalid."""
        try:
            user, blob = _vault_read(VAULT_RESOURCE)
            if blob and user == VAULT_USERNAME:
                return blob
        except Exception:
            pass
        return None

    def saveSession(self, session_json):
        """Persist the session JSON string into the OS credential vault."""
        if not session_json:
            return
        try:
            _vault_write(VAULT_RESOURCE, VAULT_USERNAME, str(session_json))
        except Exception:
            pass

    def clearSession(self):
        """Delete the stored session from the OS credential vault."""
        try:
            _vault_delete(VAULT_RESOURCE)
        except Exception:
            pass


# Wrap the page's toast() so it also fires a Windows system toast.
PATCH_SCRIPT = """
(function () {
  if (window.__trPatched) return;
  window.__trPatched = true;
  var _toast = window.toast;
  window.toast = function (msg) {
    try {
      if (window.pywebview && window.pywebview.api) {
        window.pywebview.api.notify('Time Recorder', String(msg));
      }
    } catch (e) {}
    if (_toast) {
      try { return _toast.apply(this, arguments); } catch (e) {}
    }
  };
})();
"""


def show_error(msg):
    try:
        import tkinter as tk
        from tkinter import messagebox
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror("Time Recorder", msg)
        root.destroy()
    except Exception:
        sys.stderr.write(msg + "\n")


def _start_lock_monitor(window):
    """(已停用) 原锁屏强制重新认证已移除：登录态持久保存，用户不点「退出」就一直保持。
    保留函数体为空以兼容历史调用方。"""
    return


def main():
    try:
        html_path = stage_html()
        url = html_path.resolve().as_uri()  # file:///C:/Users/.../index.html
    except Exception as e:
        show_error(
            "Time Recorder 启动失败：无法准备应用数据。\n\n"
            "错误信息：%s\n\n"
            "建议：请检查磁盘空间是否充足，或尝试重新安装本应用。" % e
        )
        return

    api = Bridge()
    window = webview.create_window(
        "Time Recorder",
        url=url,
        js_api=api,
        width=1100,
        height=760,
        min_size=(900, 600),
    )

    # 启动后台锁屏监听：检测到系统锁屏即要求重新认证
    threading.Thread(target=_start_lock_monitor, args=(window,), daemon=True).start()

    def on_loaded():
        try:
            window.evaluate_js(PATCH_SCRIPT)
        except Exception:
            pass

    try:
        window.events.loaded += on_loaded
    except Exception:
        pass

    storage = str(webview_data_dir())
    try:
        webview.start(storage_path=storage)
    except TypeError:
        # Older pywebview without storage_path; data won't persist but app runs.
        webview.start()
    except Exception as e:
        show_error(
            "Time Recorder 无法启动窗口。\n\n"
            "错误信息：%s\n\n"
            "最常见原因：未安装 Microsoft Edge WebView2 运行时。\n"
            "解决方法：到微软官网下载并安装 WebView2 运行时后重试。\n"
            "下载地址：https://developer.microsoft.com/microsoft-edge/webview2/" % e
        )


if __name__ == "__main__":
    main()
