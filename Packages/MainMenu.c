/*
Main Menu Overlay
Author	: Altamurenza
*/

#include <dslpackage.h>
#include <shlobj.h>
#include <xinput.h>
#include <wincodec.h>
#include "lodepng.h"

#pragma comment(lib, "luacore")
#pragma comment(lib, "luastd")
#pragma comment(lib, "shell32")
#pragma comment(lib, "xinput")
#pragma comment(lib, "windowscodecs")

#pragma warning(disable: 4996)

#define BIT_COUNT 32
#define CLAMP(Value, Min, Max) (Value < Min ? Min : (Value > Max ? Max : Value))


static VOID DSLConsole_Print(lua_State *L, LPCSTR Message, INT Type) {
	LPCSTR Function[] = {
		[0] = "PrintOutput",
		[1] = "PrintWarning",
		[2] = "PrintError"
	};

	lua_pushstring(L, Function[CLAMP(Type, 0, 2)]);
	lua_gettable(L, LUA_GLOBALSINDEX);
	lua_pushstring(L, Message);
	lua_call(L, 1, 0);
}
static INT DSLConsole_SystemError(lua_State *L, DWORD Code) {
	LPSTR Description = NULL;

	FormatMessageA(
		FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL, Code == 0 ? GetLastError() : Code, 0, (LPSTR)&Description, 0, NULL
	);
	DSLConsole_Print(L, Description, 2);
	LocalFree(Description);

	return 0;
}
static BOOL GetSaveFilePath(lua_State *L, HANDLE *Token, PWSTR *User, WCHAR *Path) {
	if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, Token))
		return (BOOL)DSLConsole_SystemError(L, 0);

	HRESULT Result = SHGetKnownFolderPath(&FOLDERID_Documents, KF_FLAG_DEFAULT, *Token, User);
	if (Result == S_OK)
		swprintf(Path, MAX_PATH, L"%ls\\Bully Scholarship Edition\\", *User);
	else
		DSLConsole_Print(L, "failed to get KNOWNFOLDERID (FOLDERID_Documents)", 2);
	return (BOOL)(Result == S_OK);
}
static VOID OpenSaveFile(lua_State *L, FILE **File, WCHAR *Name) {
	HANDLE Token;
	PWSTR User;
	WCHAR Path[MAX_PATH];

	if (GetSaveFilePath(L, &Token, &User, Path)) {
		swprintf(Path, MAX_PATH, L"%ls%ls", Path, Name);
		*File = _wfopen(Path, L"rb");
	}
	CoTaskMemFree(User);
	CloseHandle(Token);
}

/* DISPLAY */

static INT GetDisplayValues(lua_State *L) {
	LPCWSTR Path = L"SOFTWARE\\Rockstar Games\\Bully Scholarship Edition\\A0";
	LPCWSTR Name[] = { L"RESW", L"RESH", L"AA", L"VS", L"SHA" };
	
	HKEY Registry;
	LONG Code;
	
	Code = RegOpenKeyExW(HKEY_CURRENT_USER, Path, 0, KEY_READ, &Registry);
	if (Code != ERROR_SUCCESS)
		return DSLConsole_SystemError(L, Code);

	lua_newtable(L);
	for (INT Index = 0; Index < 5; Index++) {
		DWORD Type, DataSize = 0;
		
		Code = RegQueryValueExW(Registry, Name[Index], NULL, &Type, NULL, &DataSize);
		if (Code != ERROR_SUCCESS || Type != REG_DWORD || DataSize != sizeof(DWORD)) {
			if (Code != ERROR_SUCCESS)
				DSLConsole_SystemError(L, Code);
			else {
				CHAR RegPath[MAX_PATH];
				CHAR RegName[MAX_PATH];
				wcstombs(RegPath, Path, wcslen(Path) + 1);
				wcstombs(RegName, Name[Index], wcslen(Name[Index]) + 1);
				
				DSLConsole_Print(L, lua_pushfstring(L, "non-DWORD value: %s\\%s", RegPath, RegName), 1);
			}
			lua_pushnumber(L, -1);
			lua_rawseti(L, -2, Index + 1);

			continue;
		}
		DWORD Data;
		Code = RegQueryValueExW(Registry, Name[Index], NULL, &Type, (LPBYTE)&Data, &DataSize);
		lua_pushnumber(L, (Code == ERROR_SUCCESS && Type == REG_DWORD) ? (lua_Number)Data : -1);
		lua_rawseti(L, -2, Index + 1);
	}
	RegCloseKey(Registry);
	return 1;
}
static INT GetDisplayModes(lua_State *L) {
	DEVMODEW Device;
	DWORD Number = 0;
	ZeroMemory(&Device, sizeof(DEVMODEW));

	struct { INT Width; INT Height; } Resolution[100];
	INT Count = 0;
	lua_newtable(L);
	
	while (EnumDisplaySettingsW(NULL, Number, &Device)) {
		BOOL Already = FALSE;
		for (INT Index = 0; Index < 100; Index++) {
			if (Resolution[Index].Width == Device.dmPelsWidth && Resolution[Index].Height == Device.dmPelsHeight) {
				Already = TRUE;
				break;
			}
		}
		Number++;
		if (Already)
			continue;

		lua_pushfstring(L, "%dx%d", Device.dmPelsWidth, Device.dmPelsHeight);
		lua_rawseti(L, -2, Count + 1);
		Resolution[Count].Width = Device.dmPelsWidth;
		Resolution[Count].Height = Device.dmPelsHeight;

		Count++;
	}
	return 1;
}


/* INPUT */

static INT IsGamepadButtonPressed(lua_State *L) {
	luaL_checktype(L, 1, LUA_TNUMBER);

	// button map according to DSL's GetInputHardware function
	// similar to https://learn.microsoft.com/en-us/windows/win32/api/xinput/ns-xinput-xinput_gamepad
	INT Map[] = {
		[0] = XINPUT_GAMEPAD_DPAD_UP,
		[1] = XINPUT_GAMEPAD_DPAD_DOWN,
		[2] = XINPUT_GAMEPAD_DPAD_LEFT,
		[3] = XINPUT_GAMEPAD_DPAD_RIGHT,
		[4] = XINPUT_GAMEPAD_BACK,
		[5] = XINPUT_GAMEPAD_START,
		[6] = XINPUT_GAMEPAD_LEFT_THUMB,
		[7] = XINPUT_GAMEPAD_RIGHT_THUMB,
		[8] = XINPUT_GAMEPAD_LEFT_SHOULDER,
		[9] = XINPUT_GAMEPAD_RIGHT_SHOULDER,
		[12] = XINPUT_GAMEPAD_A,
		[13] = XINPUT_GAMEPAD_B,
		[14] = XINPUT_GAMEPAD_X,
		[15] = XINPUT_GAMEPAD_Y,
	};

	INT Button = (INT)lua_tonumber(L, 1);
	INT Controller = lua_type(L, 2) != LUA_TNUMBER ? 0 : (INT)lua_tonumber(L, 2);
	XINPUT_STATE State;
	DWORD IsConnected = XInputGetState(Controller, &State);

	if (IsConnected == ERROR_SUCCESS) {
		if (Button == 10 || Button == 11) {
			lua_pushboolean(L, Button == 10 ? State.Gamepad.bLeftTrigger > 0 : State.Gamepad.bRightTrigger > 0);
			return 1;
		}
		if (Button >= 0 && Button <= sizeof(Map) / sizeof(Map[0])) {
			lua_pushboolean(L, State.Gamepad.wButtons & Map[Button]);
			return 1;
		}
	}

	lua_pushboolean(L, 0);
	return 1;
}


/* SAVEDATA */

static INT GetSaveDataOutlines(lua_State *L) {
	struct FTB {
		INT Valid;
		FLOAT GameCompletion;
		INT LastChapter;
		INT LastArea;
		INT LastMission;
		INT PlayHour;
		INT PlayMinute;
		INT PlaySecond;
		INT SaveYear;
		INT SaveMonth;
		INT SaveDay;
		INT SaveHour;
		INT SaveMinute;
		INT SaveSecond;
	} Save[6];

	FILE *File;
	OpenSaveFile(L, &File, L"FileTableBully");

	if (!File || !fread(Save, sizeof(struct FTB), 6, File)) {
		if (File)
			fclose(File);
		DSLConsole_Print(L, lua_pushfstring(L, "failed to read FileTableBully: %s", strerror(errno)), 2);
		return 0;
	}

	fclose(File);
	lua_newtable(L);

	for (INT Slot = 0; Slot < 6; Slot++) {
		if (Save[Slot].Valid) {
			struct Mapping {
				LPCSTR Name;
				LPVOID Value;
			} Mappings[] = {
				{ "GameCompletion", &Save[Slot].GameCompletion },
				{ "LastChapter", &Save[Slot].LastChapter },
				{ "LastArea", &Save[Slot].LastArea },
				{ "LastMission", &Save[Slot].LastMission },
				{ "PlayHour", &Save[Slot].PlayHour },
				{ "PlayMinute", &Save[Slot].PlayMinute },
				{ "PlaySecond", &Save[Slot].PlaySecond },
				{ "SaveYear", &Save[Slot].SaveYear },
				{ "SaveMonth", &Save[Slot].SaveMonth },
				{ "SaveDay", &Save[Slot].SaveDay },
				{ "SaveHour", &Save[Slot].SaveHour },
				{ "SaveMinute", &Save[Slot].SaveMinute },
				{ "SaveSecond", &Save[Slot].SaveSecond }
			};
			lua_newtable(L);

			for (INT Index = 0; Index < sizeof(Mappings) / sizeof(Mappings[0]); Index++) {
				lua_pushstring(L, Mappings[Index].Name);
				lua_pushnumber(L, (strcmp(Mappings[Index].Name, "GameCompletion") == 0) ? (lua_Number)*(FLOAT*)Mappings[Index].Value : (lua_Number)*(INT*)Mappings[Index].Value);
				lua_rawset(L, -3);
			}
			lua_rawseti(L, -2, Slot + 1);
		}
	}
	return 1;
}
static INT GetSaveLastID(lua_State *L) {
	struct FTB { CHAR SaveGame[56 * 6]; UINT LastSave; } Data;
	FILE *File;
	OpenSaveFile(L, &File, L"FileTableBully");

	if (!File || !fread(&Data, sizeof(struct FTB), 1, File)) {
		if (File)
			fclose(File);
		DSLConsole_Print(L, lua_pushfstring(L, "failed to read FileTableBully: %s", strerror(errno)), 2);
		return 0;
	}

	fclose(File);
	lua_pushnumber(L, (lua_Number)Data.LastSave + 1);
	return 1;
}
static INT IsSaveFileAvailable(lua_State *L) {
	luaL_checktype(L, 1, LUA_TSTRING);

	LPCSTR Input = lua_tostring(L, 1);
	WCHAR Name[MAX_PATH];
	mbstowcs(Name, Input, strlen(Input) + 1);

	FILE *File;
	OpenSaveFile(L, &File, Name);

	lua_pushboolean(L, File ? 1 : 0);
	if (File)
		fclose(File);
	return 1;
}
static INT SetProxyFiles(lua_State *L) {
	luaL_checktype(L, 1, LUA_TBOOLEAN);

	HANDLE Token;
	PWSTR User;
	WCHAR Path[MAX_PATH];
	if (!GetSaveFilePath(L, &Token, &User, Path))
		return 0;

	swprintf(Path, MAX_PATH, L"%ls%ls", Path, L"BullyFile");
	BOOL Proxied = FALSE;

	for (INT Index = 1; Index <= 6; Index++) {
		WCHAR Name[MAX_PATH];
		swprintf(Name, MAX_PATH, L"%ls%d-tmp", Path, Index);
		FILE *File = _wfopen(Name, L"rb");

		if (File) {
			fclose(File);
			Proxied = TRUE;
			break;
		}
	}

	if (!lua_toboolean(L, 1)) {
		if (Proxied) {
			for (INT Index = 1; Index <= 6; Index++) {
				WCHAR RealName[MAX_PATH];
				WCHAR FakeName[MAX_PATH];

				swprintf(RealName, MAX_PATH, L"%ls%d-tmp", Path, Index);
				swprintf(FakeName, MAX_PATH, L"%ls%d", Path, Index);

				DeleteFileW(FakeName);
				FILE *RealFile = _wfopen(RealName, L"rb");
				if (RealFile) {
					fclose(RealFile);
					MoveFileW(RealName, FakeName);
				}
			}
		}

		CoTaskMemFree(User);
		CloseHandle(Token);

		lua_pushboolean(L, 1);
		return 1;
	}
	if (Proxied) {
		CoTaskMemFree(User);
		CloseHandle(Token);

		lua_pushboolean(L, 1);
		return 1;
	}

	if (lua_type(L, 2) != LUA_TNUMBER) {
		CoTaskMemFree(User);
		CloseHandle(Token);
		
		luaL_argerror(L, 2, lua_pushfstring(L, "expected number, got %s", lua_typename(L, lua_type(L, 2))));
		return 0;
	}

	INT SaveID = (INT)lua_tonumber(L, 2);
	WCHAR TargetName[MAX_PATH];
	swprintf(TargetName, MAX_PATH, L"%ls%d", Path, SaveID);
	
	FILE *TargetFile = _wfopen(TargetName, L"rb");
	if (!TargetFile) {
		CoTaskMemFree(User);
		CloseHandle(Token);
		return 0;
	}

	fseek(TargetFile, 0, SEEK_END);
	LONG TargetSize = ftell(TargetFile);
	fseek(TargetFile, 0, SEEK_SET);
	PSTR TargetData = (PSTR)malloc(TargetSize);
	fread(TargetData, 1, TargetSize, TargetFile);

	fclose(TargetFile);
	for (INT Index = 1; Index <= 6; Index++) {
		WCHAR RealName[MAX_PATH];
		swprintf(RealName, MAX_PATH, L"%ls%d", Path, Index);

		FILE *RealFile = _wfopen(RealName, L"rb");
		if (RealFile) {
			fclose(RealFile);
			WCHAR TemporaryName[MAX_PATH];
			swprintf(TemporaryName, MAX_PATH, L"%ls-tmp", RealName);
			MoveFileW(RealName, TemporaryName);
		}

		FILE *FakeFile = _wfopen(RealName, L"wb");
		if (FakeFile) {
			fwrite(TargetData, 1, TargetSize, FakeFile);
			fclose(FakeFile);
		}
	}
	free(TargetData);

	CoTaskMemFree(User);
	CloseHandle(Token);

	lua_pushboolean(L, 1);
	return 1;
}


/* MISCELLANEOUS */

static BOOL ExportAsBMP(lua_State *L, HDC DC, HBITMAP BM, INT Width, INT Height, INT Size, LPCSTR Name) {
	FILE *Output = fopen(Name, "wb");
	if (!Output) {
		DSLConsole_Print(L, lua_pushfstring(L, "failed to create %s", Name), 2);
		return FALSE;
	}

	BITMAPINFOHEADER IH;
	IH.biSize = sizeof(BITMAPINFOHEADER);
	IH.biWidth = Width;
	IH.biHeight = -Height; // positive value is bottom-up
	IH.biPlanes = 1;
	IH.biBitCount = BIT_COUNT;
	IH.biCompression = BI_RGB;
	IH.biSizeImage = Size;
	IH.biXPelsPerMeter = 0;
	IH.biYPelsPerMeter = 0;
	IH.biClrUsed = 0;
	IH.biClrImportant = 0;

	BITMAPFILEHEADER FH;
	FH.bfType = 0x4D42;
	FH.bfSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + Size;
	FH.bfReserved1 = 0;
	FH.bfReserved2 = 0;
	FH.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);

	// copy the captured bitmap to buffer and write the file
	UINT CopiedLines;
	BYTE *Bits = (BYTE*)malloc(Size);
	if (Bits) {
		CopiedLines = GetDIBits(DC, BM, 0, Height, Bits, (BITMAPINFO*)&IH, DIB_RGB_COLORS);
		if (!CopiedLines)
			DSLConsole_SystemError(L, 0);

		fwrite(&FH, sizeof(BITMAPFILEHEADER), 1, Output); // write header
		fwrite(&IH, sizeof(BITMAPINFOHEADER), 1, Output); // write file information
		fwrite(Bits, 1, Size, Output); // write pixels
		free(Bits);
	}
	else
		DSLConsole_Print(L, "failed to allocate memory for Bits", 2);

	fclose(Output);
	return (!Bits || !CopiedLines) ? FALSE : TRUE;
}
static BOOL ExportAsPNG(lua_State *L, HDC DC, HBITMAP BM, INT Width, INT Height, INT Size, LPCSTR Name) {
	BITMAPINFO BI;
	ZeroMemory(&BI, sizeof(BI));
	BI.bmiHeader.biSize = sizeof(BI.bmiHeader);
	BI.bmiHeader.biWidth = Width;
	BI.bmiHeader.biHeight = -Height; // positive value is bottom-up
	BI.bmiHeader.biPlanes = 1;
	BI.bmiHeader.biBitCount = BIT_COUNT;
	BI.bmiHeader.biCompression = BI_RGB;

	// copy the captured bitmap to buffer
	BYTE *Bits = (BYTE*)malloc(Size);
	if (!Bits) {
		DSLConsole_Print(L, "failed to allocate memory for Bits", 2);
		return FALSE;
	}
	if (!GetDIBits(DC, BM, 0, Height, Bits, &BI, DIB_RGB_COLORS)) {
		DSLConsole_SystemError(L, 0);
		free(Bits);
		return FALSE;
	}

	// reformat the image colors from BGR to RGBA (or RGB if 24 bit)
	for (INT Index = 0; Index < Size; Index += (BIT_COUNT == 32 ? 4 : 3)) {
		BYTE Blue = Bits[Index];
		Bits[Index] = Bits[Index + 2]; // swap blue to red
		Bits[Index + 2] = Blue; // swap red to blue

		if (BIT_COUNT == 32)
			Bits[Index + 3] = 255; // set alpha
	}

	// encode and write the file
	UINT Code;
	if (BIT_COUNT == 32)
		Code = lodepng_encode32_file(Name, Bits, Width, Height);
	else
		Code = lodepng_encode24_file(Name, Bits, Width, Height);

	if (Code)
		DSLConsole_Print(L, lodepng_error_text(Code), 2);
	free(Bits);
	return Code ? FALSE : TRUE;
}
static INT CaptureScreen(lua_State *L) {
	luaL_checktype(L, 1, LUA_TSTRING);
	if (BIT_COUNT != 32 && BIT_COUNT != 24) {
		DSLConsole_Print(L, "unsupported BIT_COUNT (must be 32 or 24 bit)", 1);
		return 0;
	}

	LPCSTR Name = lua_tostring(L, 1);
	LPSTR Extension = strrchr(Name, '.');
	if (!Extension || (strcmp(Extension, ".bmp") != 0 && strcmp(Extension, ".png") != 0)) {
		DSLConsole_Print(L, "file extension must be .bmp or .png", 1);
		return 0;
	}

	HWND Window = GetActiveWindow();
	RECT Rectangle;
	if (!Window || !GetClientRect(Window, &Rectangle))
		return DSLConsole_SystemError(L, 0);
	INT WindowW = Rectangle.right - Rectangle.left;
	INT WindowH = Rectangle.bottom - Rectangle.top;
	INT ImageW = lua_type(L, 2) != LUA_TNUMBER ? WindowW : (INT)lua_tonumber(L, 2);
	INT ImageH = lua_type(L, 3) != LUA_TNUMBER ? WindowH : (INT)lua_tonumber(L, 3);
	INT SurfaceStride = ((ImageW * BIT_COUNT + 31) & ~31) / 8;
	INT ImageSize = SurfaceStride * ImageH;

	HDC ScreenDC = GetDC(Window);
	HDC MemoryDC = CreateCompatibleDC(ScreenDC);
	HBITMAP MemoryBM = CreateCompatibleBitmap(ScreenDC, ImageW, ImageH);
	HBITMAP ReplacedObj = (HBITMAP)SelectObject(MemoryDC, MemoryBM);

	BOOL Dithering = lua_type(L, 4) != LUA_TBOOLEAN ? TRUE : (BOOL)lua_toboolean(L, 4);
	if (!Dithering)
		SetStretchBltMode(MemoryDC, COLORONCOLOR);
	else {
		SetStretchBltMode(MemoryDC, HALFTONE);
		POINT BrushOrigin = { 0, 0 };
		SetBrushOrgEx(MemoryDC, BrushOrigin.x, BrushOrigin.y, NULL);
	}

	BOOL Result = FALSE;
	if (!StretchBlt(MemoryDC, 0, 0, ImageW, ImageH, ScreenDC, 0, 0, WindowW, WindowH, SRCCOPY))
		DSLConsole_SystemError(L, 0);
	else {
		if (strcmp(Extension, ".bmp") == 0)
			Result = ExportAsBMP(L, ScreenDC, MemoryBM, ImageW, ImageH, ImageSize, Name);
		else
			Result = ExportAsPNG(L, ScreenDC, MemoryBM, ImageW, ImageH, ImageSize, Name);
	}

	SelectObject(MemoryDC, ReplacedObj);
	DeleteObject(MemoryBM);
	DeleteDC(MemoryDC);
	ReleaseDC(NULL, ScreenDC);

	lua_pushboolean(L, Result);
	return 1;
}
static INT RunCFunction(lua_State *L) {
	luaL_checktype(L, 1, LUA_TSTRING);

	LPCSTR String = lua_tostring(L, 1);
	PSTR EndPtr;
	ULONG Address = strtoul(String, &EndPtr, 16);
	if (*EndPtr != '\0' || String == EndPtr) {
		luaL_argerror(L, 1, "expected hexadecimal in string");
		return 0;
	}

	lua_remove(L, 1);
	return (*(lua_CFunction)Address)(L);
}


/* EXPORT */

__declspec(dllexport) INT MainMenu(lua_State *L) {
	initDslDll();

	lua_register(L, "GetDisplayValues", &GetDisplayValues);
	lua_register(L, "GetDisplayModes", &GetDisplayModes);
	lua_register(L, "IsGamepadButtonPressed", &IsGamepadButtonPressed);
	lua_register(L, "GetSaveDataOutlines", &GetSaveDataOutlines);
	lua_register(L, "GetSaveLastID", &GetSaveLastID);
	lua_register(L, "IsSaveFileAvailable", &IsSaveFileAvailable);
	lua_register(L, "SetProxyFiles", &SetProxyFiles);
	lua_register(L, "CaptureScreen", &CaptureScreen);
	lua_register(L, "RunCFunction", &RunCFunction);

	return 0;
}
