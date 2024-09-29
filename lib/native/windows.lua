local native = {}

local ffi = require("ffi")
local dwmapi, shell32 = ffi.load("dwmapi"), ffi.load("shell32")

ffi.cdef [[
	void Sleep(int ms);

	typedef int BOOL;
	typedef long LONG;
	typedef uint32_t UINT;
	typedef uint32_t UINT_PTR;
	typedef int LRESULT;
	typedef int HRESULT;
	typedef unsigned int DWORD;
	typedef const void* PVOID;
	typedef const void* LPCVOID;
	typedef UINT_PTR WPARAM;
	typedef UINT_PTR LPARAM;
	typedef const char* LPCSTR;
	typedef DWORD HMENU;
	typedef void* HWND;
	typedef void* HANDLE;
	typedef void* HICON;
	typedef void* HMODULE;
	typedef HANDLE HCURSOR;

	typedef struct {int Data[4];} GUID;

	typedef struct {
		DWORD cbSize;
		HWND  hWnd;
		UINT  uID;
		UINT  uFlags;
		UINT  uCallbackMessage;
		HICON hIcon;
		char  szTip[128];
		DWORD dwState;
		DWORD dwStateMask;
		char  szInfo[256];
		union {
			UINT uTimeout;
			UINT uVersion;
		};
		char  szInfoTitle[64];
		DWORD dwInfoFlags;
		GUID  guidItem;
		HICON hBalloonIcon;
	} NOTIFYICONDATAA;

	typedef struct tagRECT {
		union{
			struct{
				LONG left;
				LONG top;
				LONG right;
				LONG bottom;
			};
			struct{
				LONG x1;
				LONG y1;
				LONG x2;
				LONG y2;
			};
			struct{
				LONG x;
				LONG y;
			};
		};
	} RECT, *PRECT,  *NPRECT,  *LPRECT;

	HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName);
	HWND FindWindowExA(HWND hwndParent, HWND hwndChildAfter, LPCSTR lpszClass, LPCSTR lpszWindow);
	HWND GetActiveWindow(void);
	LONG SetWindowLongA(HWND hWnd, int nIndex, LONG dwNewLong);
	BOOL ShowWindow(HWND hWnd, int nCmdShow);
	BOOL UpdateWindow(HWND hWnd);
	HWND SetFocus(HWND HWnd);
	HWND GetConsoleWindow();

	HRESULT DwmGetWindowAttribute(HWND hwnd, DWORD dwAttribute, PVOID pvAttribute, DWORD cbAttribute);
	HRESULT DwmSetWindowAttribute(HWND hwnd, DWORD dwAttribute, LPCVOID pvAttribute, DWORD cbAttribute);
	HRESULT DwmFlush();

	HMODULE GetModuleHandleA(LPCSTR lpModuleName);

	LRESULT SendMessageA(HWND hwnd, UINT Msg, WPARAM wParam, LPARAM lParam);

	HCURSOR LoadCursorA(HANDLE hInstance, const char* lpCursorName);
	HCURSOR SetCursor(HCURSOR hCursor);

	int GetSystemMetrics(int nIndex);
	HANDLE LoadImageA(HANDLE hInstance, LPCSTR name, UINT type, int cx, int Cy, UINT fuLoad);
	HANDLE LoadIconA(HANDLE hInstance, LPCSTR name);
	BOOL DestroyIcon(HANDLE hIcon);

	BOOL Shell_NotifyIconA(int dwMessage, NOTIFYICONDATAA * lpData);
	BOOL Shell_NotifyIconW(int dwMessage, NOTIFYICONDATAA * lpData);
]]

--local Rect = ffi.metatype("RECT", {})
local function toInt(v) return v and 1 or 0 end

local function getWindowHandle(title)
	local window = ffi.C.FindWindowA(nil, title)
	if window == nil then
		window = ffi.C.GetActiveWindow()
		window = ffi.C.FindWindowExA(window, nil, nil, title)
	end
	return window
end
local function getActiveWindow() return ffi.C.GetActiveWindow() or getWindowHandle(love.window.getTitle()) end

local function GetClassLongPtr(hWnd, nIndex)
	if ffi.sizeof(hWnd) > 4 then return ffi.C.GetClassLongPtrA(hWnd, nIndex)
	else return ffi.cast("UINT_PTR", ffi.C.GetClassLong(hWnd, nIndex)) end
end

local function copyString(dest_array_ptr, str)
	ffi.copy(dest_array_ptr, (str or ""):sub(1, ffi.sizeof(dest_array_ptr) - 1))
end

function native.sleep(s)
	ffi.C.Sleep(s * 1000)
end

native.getWindowHandle, native.getActiveWindow = getWindowHandle, getActiveWindow

native.defaultCursorType = "ARROW"
native.cursorType = {
	ARROW = 32512,
	IBEAM = 32513,
	WAIT = 32514,
	CROSS = 32515,
	UPARROW = 32516,
	SIZENWSE = 32642,
	SIZENESW = 32643,
	SIZEWE = 32644,
	SIZENS = 32645,
	SIZEALL = 32646,
	NO = 32648,
	HAND = 32649,
	APPSTARTING = 32650,
	HELP = 32651,
	PIN = 32671,
	PERSON = 32672
}

native.defaultIconType = 32512
native.iconType = {
	APPLICATION = 32512,
	ERROR = 32513,
	QUESTION = 32514,
	WARNING = 32515,
	INFORMATION = 32516,
	WINLOGO = 32517,
	SHIELD = 32518
}

function native.setCursor(type)
	local cursorType = native.cursorType[type:upper()]
	if cursorType then
		ffi.C.SetCursor(ffi.C.LoadCursorA(nil, ffi.cast("const char*", cursorType)))
	end
end

function native.setDarkMode(title, enable, refresh)
	if type(title) == 'boolean' then enable, refresh, title = title, enable, nil end
	local window = title and getWindowHandle(title) or getActiveWindow()

	local darkMode = ffi.new("int[1]", toInt(enable))
	if dwmapi.DwmSetWindowAttribute(window, 19, darkMode, 4) ~= 0 then
		dwmapi.DwmSetWindowAttribute(window, 20, darkMode, 4)
		if refresh then
			ffi.C.ShowWindow(window, 0); ffi.C.ShowWindow(window, 1)
			ffi.C.SetFocus(window)
		end
	end
end

local IMAGE_ICON = 0x1
local LR_LOADFROMFILE = 0x10
local WM_SETICON, WM_GETICON = 0x80, 0x7f
local ICON_SMALL, ICON_BIG, ICON_SMALL2 = 0, 1, 2
local GCL_HICONSM, GCL_HICON = -34, -14
local SM_CXICON, SM_CYICON = 11, 12
local SM_CXSMICON, SM_CYSMICON = 49, 50

local function setIco(title, hIconBig, hIconSmall, noDestroy)
	local window = title and getWindowHandle(title) or getActiveWindow()

	if not noDestroy then
		local pIconBig, pIconSmall = native.getIcon(title)
		if pIconBig then ffi.C.DestroyIcon(pIconBig) end
		if pIconSmall then ffi.C.DestroyIcon(pIconSmall) end
	end

	ffi.C.SendMessageA(window, WM_SETICON, ICON_BIG, ffi.cast("LPARAM", hIconBig or nil))
	ffi.C.SendMessageA(window, WM_SETICON, ICON_SMALL, ffi.cast("LPARAM", hIconSmall or nil))
	return hIconBig, hIconSmall
end

function native.setIcon(title, ico, no_physfs, noDestroy)
	if type(ico) == 'cdata' or type(title) == "cdata" then
		return type(title) == "string" and setIco(title, ico, no_physfs) or setIco(nil, title, ico)
	end
	if type(ico) ~= 'string' then ico, no_physfs, noDestroy, title = title, ico, no_physfs, nil end

	local hIconBig, hIconSmall = native.loadIcon(ico, nil, no_physfs)
	return setIco(title, hIconBig, hIconSmall, noDestroy)
end

function native.getIcon(title, iconSize)
	if type(title) ~= 'string' then iconSize, title = title, nil end
	local window = title and getWindowHandle(title) or getActiveWindow()

	local hIconBig, hIconSmall
	if iconSize == 0 or iconSize == nil then
		hIconSmall = ffi.cast("HICON", ffi.C.SendMessageA(window, WM_GETICON, ICON_SMALL, 0) or GetClassLongPtr(window, GCL_HICONSM))
	end
	if iconSize == 1 or iconSize == nil then
		hIconBig = ffi.cast("HICON", ffi.C.SendMessageA(window, WM_GETICON, ICON_BIG, 0) or GetClassLongPtr(window, GCL_HICON))
	end

	if not hIconSmall and not hIconBig then return ffi.cast("HICON", ffi.C.SendMessageA(window, WM_GETICON, ICON_SMALL2, 0))
	elseif iconSize == 0 then return hIconSmall
	elseif iconSize == 1 then return hIconBig
	else return hIconBig, hIconSmall, ffi.cast("HICON", ffi.C.SendMessageA(window, WM_GETICON, ICON_SMALL2, 0)) end
end

function native.loadIcon(ico, iconSize, no_physfs)
	if iconSize ~= nil or ico:lower():endsWith('.ico') then
		if not no_physfs and love.filesystem then ico = love.filesystem.getRealDirectory(ico) .. '/' .. ico end

		local hIconBig, hIconSmall
		if iconSize == 0 or iconSize == nil then
			hIconSmall = ffi.C.LoadImageA(ffi.C.GetModuleHandleA(ffi.cast("const char*", "user32")), ffi.cast("const char*", ico),
				IMAGE_ICON, ffi.C.GetSystemMetrics(SM_CXSMICON), ffi.C.GetSystemMetrics(SM_CYSMICON), LR_LOADFROMFILE)
		end
		if iconSize == 1 or iconSize == nil then
			hIconBig = ffi.C.LoadImageA(ffi.C.GetModuleHandleA(ffi.cast("const char*", "user32")), ffi.cast("const char*", ico),
				IMAGE_ICON, ffi.C.GetSystemMetrics(SM_CXICON), ffi.C.GetSystemMetrics(SM_CYICON), LR_LOADFROMFILE)
		end

		if iconSize == 0 then return hIconSmall
		elseif iconSize == 1 then return hIconBig
		else return hIconBig, hIconSmall end
	else
		return ffi.C.LoadIconA(nil, ffi.cast("const char*", native.iconType[ico and ico:upper() or native.defaultIconType]))
	end
end

-- stolen from https://stackoverflow.com/questions/74952766/how-can-i-send-a-windows-notification-in-lua
function native.createNotifyData(handle, trayIcon, balloonIcon, timeout)
	if type(handle) == "cdata" then trayIcon, balloonIcon, handle = handle, trayIcon, nil end

	local notifyData = ffi.new"NOTIFYICONDATAA"
	notifyData.cbSize = ffi.sizeof(notifyData)
	notifyData.hWnd = handle or getActiveWindow()
	notifyData.uFlags = 1 + 2  -- NIF_MESSAGE | NIF_ICON
	notifyData.hIcon = trayIcon
	notifyData.uVersion = 4
	notifyData.uTimeout = timeout or 5
	notifyData.hBalloonIcon = balloonIcon
	shell32.Shell_NotifyIconA(0, notifyData)  -- NIM_ADD
	shell32.Shell_NotifyIconA(4, notifyData)  -- NIM_SETVERSION

	return notifyData
end

function native.destroyNotifyData(notifyData, dontDestroyIcons)
	if not dontDestroyIcons then
		if notifyData.hIcon ~= nil then ffi.C.DestroyIcon(notifyData.hIcon) end
		if notifyData.hBalloonIcon ~= nil then ffi.C.DestroyIcon(notifyData.hBalloonIcon) end
	end
	shell32.Shell_NotifyIconA(2, notifyData)  -- NIM_DELETE
end

function native.showNotifyData(notifyData, title, text)
	notifyData.uFlags = 1 + 2 + 16   -- NIF_MESSAGE | NIF_ICON | NIF_INFO
	notifyData.dwInfoFlags = 4 + 32  -- NIIF_USER | NIIF_LARGE_ICON
	copyString(notifyData.szInfoTitle, title)
	copyString(notifyData.szInfo, text)
	shell32.Shell_NotifyIconA(1, notifyData) -- NIM_MODIFY
end

function native.showNotification(handle, trayIcon, balloonIcon, title, text)
	if type(handle) == "cdata" then trayIcon, balloonIcon, title, text, dontDestroyIcons, handle = handle, trayIcon, balloonIcon, title, text, nil end
	if type(balloonIcon) == "string" then title, text, dontDestroyIcons, balloonIcon = balloonIcon, title, text, nil end

	local notifyData = native.createNotifyData(handle, trayIcon, balloonIcon)
	native.showNotifyData(notifyData, title, text)
	return notifyData
end

return native