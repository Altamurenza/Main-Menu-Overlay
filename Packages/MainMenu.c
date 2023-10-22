/*
Main Menu Overlay C Package
Author	: Altamurenza

Credit goes to derpy54320 for sharing her knowledges on FileTableBully.
*/

#include <windows.h>
#include <stdio.h>
#include <XInput.h>
#include <dslpackage.h>

#pragma comment(lib, "luacore")
#pragma comment(lib, "luastd")
#pragma comment(lib, "XInput")
#pragma warning(disable: 4996)

#define USER_PATH getenv("USERPROFILE")
#define SAVE_PATH "\\Documents\\Bully Scholarship Edition\\"


// DISPLAY //

static int GetRawDisplaySettings(lua_State* L) {
	HKEY Registry;
	LONG Code;
	const wchar_t* Path = L"SOFTWARE\\Rockstar Games\\Bully Scholarship Edition\\A0";
	const wchar_t* Name[] = { L"RESW", L"RESH", L"AA", L"VS", L"SHA" };

	Code = RegOpenKeyExW(HKEY_CURRENT_USER, Path, 0, KEY_READ, &Registry);
	if (Code != ERROR_SUCCESS) {
		LPTSTR ErrorMessage;
		FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, NULL, Code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR)&ErrorMessage, 0, NULL);

		int Size = WideCharToMultiByte(CP_UTF8, 0, ErrorMessage, -1, NULL, 0, NULL, NULL);
		char* FinalMessage = (char*)malloc(Size);
		WideCharToMultiByte(CP_UTF8, 0, ErrorMessage, -1, FinalMessage, Size, NULL, NULL);

		luaL_error(L, "an error occurred while opening registry (%s)", FinalMessage);
		LocalFree(ErrorMessage);
		free(FinalMessage);

		return 0;
	}

	lua_newtable(L);
	for (int Index = 0; Index < 5; Index++) {
		DWORD Type, DataSize = 0;
		Code = RegQueryValueExW(Registry, Name[Index], NULL, &Type, NULL, &DataSize);

		if (Code == ERROR_SUCCESS && Type == REG_DWORD && DataSize == sizeof(DWORD)) {
			DWORD Data;
			Code = RegQueryValueExW(Registry, Name[Index], NULL, &Type, (LPBYTE)&Data, &DataSize);
			lua_pushnumber(L, (Code == ERROR_SUCCESS && Type == REG_DWORD) ? (lua_Number)Data : -1);
		}
		else
			lua_pushnumber(L, -1);
		lua_rawseti(L, -2, Index + 1);
	}

	RegCloseKey(Registry);
	return 1;
}
static int GetDisplayModes(lua_State* L) {
	DEVMODE Device;
	int Number = 0;
	ZeroMemory(&Device, sizeof(DEVMODE));

	size_t Size = 512;
	char* List = (char*)malloc(Size);
	if (!List) {
		luaL_error(L, "an error occurred while allocating memory for display resolutions");
		return 0;
	}
	List[0] = '\0';
	int Index = 0;

	lua_newtable(L);
	while (EnumDisplaySettings(NULL, Number, &Device)) {
		char Resolution[50];
		sprintf(Resolution, "%dx%d", Device.dmPelsWidth, Device.dmPelsHeight);

		if (strlen(List) + strlen(Resolution) + 1 > Size) {
			Size = (size_t)(Size * 1.5);
			char* ExtendedList = (char*)realloc(List, Size);
			if (Size > 1 << 10 || !ExtendedList) {
				free(List);
				luaL_error(L, "an error occurred while reallocating memory for display resolutions");
				return 0;
			}
			List = ExtendedList;
		}

		if (!strstr(List, Resolution)) {
			Index++;
			lua_pushstring(L, Resolution);
			lua_rawseti(L, -2, Index);
			sprintf(List, "%s%s ", List, Resolution);
		}
		Number++;
	}

	free(List);
	return 1;
}


// INPUT //

const int GamepadButtonID[] = {
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

static int IsGamepadButtonPressed(lua_State* L) {
	if (lua_type(L, 1) != LUA_TNUMBER) {
		luaL_argerror(L, 1, lua_pushfstring(L, "expected number, got %s", lua_typename(L, lua_type(L, 1))));
		return 0;
	}

	int Button = (int)lua_tonumber(L, 1);
	int Controller = lua_type(L, 2) != LUA_TNUMBER ? 0 : (int)lua_tonumber(L, 2);
	XINPUT_STATE State;
	DWORD IsConnected = XInputGetState(Controller, &State);

	if (IsConnected == ERROR_SUCCESS) {
		if (Button == 10 || Button == 11) {
			lua_pushboolean(L, Button == 10 ? State.Gamepad.bLeftTrigger > 0 : State.Gamepad.bRightTrigger > 0);
			return 1;
		}
		if (Button >= 0 && Button <= sizeof(GamepadButtonID) / sizeof(GamepadButtonID[0])) {
			lua_pushboolean(L, State.Gamepad.wButtons & GamepadButtonID[Button]);
			return 1;
		}
	}

	lua_pushboolean(L, 0);
	return 1;
}


// SAVEDATA //

struct Outline {
	int Valid;
	float GameCompletion;
	int LastChapter;
	int LastArea;
	int LastMission;
	int PlayHour;
	int PlayMinute;
	int PlaySecond;
	int SaveYear;
	int SaveMonth;
	int SaveDay;
	int SaveHour;
	int SaveMinute;
	int SaveSecond;
}Outlines[6];

static int GetSaveDataOutlines(lua_State* L) {
	char Path[MAX_PATH];
	sprintf(Path, "%s%s%s", USER_PATH, SAVE_PATH, "FileTableBully");
	FILE* File = fopen(Path, "rb");

	if (!File) {
		luaL_error(L, "an error occurred while opening FileTableBully (%s)", strerror(errno));
		return 0;
	}

	if (!fread(Outlines, sizeof(struct Outline), 6, File)) {
		fclose(File);
		luaL_error(L, "an error occurred while reading FileTableBully (%s)", strerror(errno));
		return 0;
	}
	fclose(File);

	lua_newtable(L);
	for (int Slot = 0; Slot < 6; Slot++) {
		if (Outlines[Slot].Valid) {
			struct Mapping {
				const char* Name;
				void* Value;
			}Mappings[] = {
				{ "GameCompletion", &Outlines[Slot].GameCompletion },
				{ "LastChapter", &Outlines[Slot].LastChapter },
				{ "LastArea", &Outlines[Slot].LastArea },
				{ "LastMission", &Outlines[Slot].LastMission },
				{ "PlayHour", &Outlines[Slot].PlayHour },
				{ "PlayMinute", &Outlines[Slot].PlayMinute },
				{ "PlaySecond", &Outlines[Slot].PlaySecond },
				{ "SaveYear", &Outlines[Slot].SaveYear },
				{ "SaveMonth", &Outlines[Slot].SaveMonth },
				{ "SaveDay", &Outlines[Slot].SaveDay },
				{ "SaveHour", &Outlines[Slot].SaveHour },
				{ "SaveMinute", &Outlines[Slot].SaveMinute },
				{ "SaveSecond", &Outlines[Slot].SaveSecond }
			};
			lua_newtable(L);

			for (int Index = 0; Index < sizeof(Mappings) / sizeof(Mappings[0]); Index++) {
				lua_pushstring(L, Mappings[Index].Name);
				lua_pushnumber(L, (strcmp(Mappings[Index].Name, "GameCompletion") == 0) ? (lua_Number)*(float*)Mappings[Index].Value : (lua_Number)*(int*)Mappings[Index].Value);
				lua_rawset(L, -3);
			}
			lua_rawseti(L, -2, Slot + 1);
		}
	}
	return 1;
}
static int GetSaveLastID(lua_State* L) {
	char Path[MAX_PATH];
	sprintf(Path, "%s%s%s", USER_PATH, SAVE_PATH, "FileTableBully");
	FILE *File = fopen(Path, "rb");

	if (!File) {
		luaL_error(L, "an error occurred while opening FileTableBully (%s)", strerror(errno));
		return 0;
	}

	struct Save {
		char Other[56 * 6];
		unsigned Index;
	}Stat;
	if (!fread(&Stat, sizeof(struct Save), 1, File)) {
		fclose(File);
		luaL_error(L, "an error occurred while reading FileTableBully (%s)", strerror(errno));
		return 0;
	}

	fclose(File);
	lua_pushnumber(L, (lua_Number)Stat.Index + 1);
	return 1;
}
static int SetProxyFiles(lua_State* L) {
	if (lua_type(L, 1) != LUA_TBOOLEAN) {
		luaL_argerror(L, 1, lua_pushfstring(L, "expected boolean, got %s", lua_typename(L, lua_type(L, 1))));
		return 0;
	}
	char Path[MAX_PATH];
	sprintf(Path, "%s%s%s", USER_PATH, SAVE_PATH, "BullyFile");

	BOOL Proxied = FALSE;
	for (int Index = 1; Index <= 6; Index++) {
		char Name[MAX_PATH];
		sprintf(Name, "%s%d-tmp", Path, Index);
		FILE *File = fopen(Name, "rb");

		if (File) {
			fclose(File);
			Proxied = TRUE;
			break;
		}
	}

	if (!lua_toboolean(L, 1)) {
		if (Proxied) {
			for (int Index = 1; Index <= 6; Index++) {
				char RealName[MAX_PATH];
				char FakeName[MAX_PATH];

				sprintf(RealName, "%s%d-tmp", Path, Index);
				sprintf(FakeName, "%s%d", Path, Index);

				remove(FakeName);
				FILE *RealFile = fopen(RealName, "rb");
				if (RealFile) {
					fclose(RealFile);
					rename(RealName, FakeName);
				}
			}
		}
		lua_pushboolean(L, 1);
		return 1;
	}
	if (Proxied) {
		lua_pushboolean(L, 1);
		return 1;
	}

	if (lua_type(L, 2) != LUA_TNUMBER) {
		luaL_argerror(L, 2, lua_pushfstring(L, "expected number, got %s", lua_typename(L, lua_type(L, 2))));
		return 0;
	}

	const int SaveID = (int)lua_tonumber(L, 2);
	char TargetName[MAX_PATH];
	sprintf(TargetName, "%s%d", Path, SaveID);
	FILE *TargetFile = fopen(TargetName, "rb");
	if (!TargetFile) {
		luaL_error(L, "an error occurred while opening BullyFile%d (%s)", SaveID, strerror(errno));
		return 0;
	}

	fseek(TargetFile, 0, SEEK_END);
	LONG TargetSize = ftell(TargetFile);
	fseek(TargetFile, 0, SEEK_SET);
	char* TargetData = (char*)malloc(TargetSize);
	fread(TargetData, 1, TargetSize, TargetFile);

	fclose(TargetFile);
	for (int Index = 1; Index <= 6; Index++) {
		char RealName[MAX_PATH];
		sprintf(RealName, "%s%d", Path, Index);

		FILE *RealFile = fopen(RealName, "rb");
		if (RealFile) {
			fclose(RealFile);
			char TemporaryName[MAX_PATH];
			sprintf(TemporaryName, "%s-tmp", RealName);
			rename(RealName, TemporaryName);
		}

		FILE *FakeFile = fopen(RealName, "wb");
		if (FakeFile) {
			fwrite(TargetData, 1, TargetSize, FakeFile);
			fclose(FakeFile);
		}
	}
	free(TargetData);

	lua_pushboolean(L, 1);
	return 1;
}


// MISCELLANEOUS //

static int RunCFunction(lua_State* L) {
	if (lua_type(L, 1) != LUA_TSTRING) {
		luaL_argerror(L, 1, lua_pushfstring(L, "expected string, got %s", lua_typename(L, lua_type(L, 1))));
		return 0;
	}

	const char* String = lua_tostring(L, 1);
	char* EndPtr;
	unsigned long Address = strtoul(String, &EndPtr, 16);
	if (*EndPtr != '\0' || String == EndPtr) {
		luaL_argerror(L, 1, "expected hexadecimal in string");
		return 0;
	}

	lua_remove(L, 1);
	return (*(lua_CFunction)Address)(L);
}


// EXPORT //

__declspec(dllexport) int open_mainmenu(lua_State* L) {
	initDslDll();

	lua_register(L, "GetRawDisplaySettings", &GetRawDisplaySettings);
	lua_register(L, "GetDisplayModes", &GetDisplayModes);
	lua_register(L, "IsGamepadButtonPressed", &IsGamepadButtonPressed);
	lua_register(L, "GetSaveDataOutlines", &GetSaveDataOutlines);
	lua_register(L, "GetSaveLastID", &GetSaveLastID);
	lua_register(L, "SetProxyFiles", &SetProxyFiles);
	lua_register(L, "RunCFunction", &RunCFunction);

	return 0;
}
