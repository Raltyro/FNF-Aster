local Native = {}

local ffi = require("ffi")
local dwmapi = ffi.load("dwmapi")

ffi.cdef [[
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
	typedef void* HMODULE;
	typedef HANDLE HCURSOR;

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

Native.defaultCursorType = "ARROW"
Native.cursorType = {
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

function Native.setCursor(type)
	local cursorType = Native.cursorType[type:upper()]
	if cursorType then
		ffi.C.SetCursor(ffi.C.LoadCursorA(nil, ffi.cast("const char*", cursorType)))
	end
end

function Native.setDarkMode(enable)
	local window = getActiveWindow()

	local darkMode = ffi.new("int[1]", toInt(enable))
	if dwmapi.DwmSetWindowAttribute(window, 19, darkMode, 4) ~= 0 then
		dwmapi.DwmSetWindowAttribute(window, 20, darkMode, 4)
	end
end


function Native.setIcon(ico, no_physfs)
	if not no_physfs and love.filesystem then ico = love.filesystem.getRealDirectory(ico) .. '\\' .. ico end
	local window = getActiveWindow()

	local hIconBig = ffi.C.LoadImageA(ffi.C.GetModuleHandleA(ffi.cast("const char*", "user32")), ffi.cast("const char*", ico), 0x1 --[[IMAGE_ICON]],
		ffi.C.GetSystemMetrics(11 --[[SM_CXICON]]), ffi.C.GetSystemMetrics(12 --[[SM_CYICON]]), 0x10 --[[LR_LOADFROMFILE]])
	local hIconSmall = ffi.C.LoadImageA(ffi.C.GetModuleHandleA(ffi.cast("const char*", "user32")), ffi.cast("const char*", ico), 0x1 --[[IMAGE_ICON]],
		ffi.C.GetSystemMetrics(49 --[[SM_CxSMICON]]), ffi.C.GetSystemMetrics(50 --[[SM_CYSMICON]]), 0x10 --[[LR_LOADFROMFILE]])

	ffi.C.SendMessageA(window, 0x80 --[[WM_SETICON]], 1 --[[ICON_BIG]], ffi.cast("LPARAM", hIconBig))
	ffi.C.SendMessageA(window, 0x80 --[[WM_SETICON]], 0 --[[ICON_SMALL]], ffi.cast("LPARAM", hIconSmall))
end

return Native