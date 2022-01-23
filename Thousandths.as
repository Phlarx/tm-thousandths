[Setting name="Enabled"]
bool enabled = true;

#if MP4
[Setting name="Force enable on servers" description="Most servers will already display thousandths; enabling this might duplicate the last digit"]
bool serverOverride = false;
#endif

bool errored = false;

uint64 ptr_template_fast = 0;
uint64 ptr_template_slow = 0;
uint64 ptr_ms_conversion = 0;
string bytes_template_fast = "";
string bytes_template_slow = "";
string bytes_ms_conversion = "";

string fmt_ptr = "0x%016x";

void RenderMenu() {
	if(UI::MenuItem("\\$f0f" + Icons::ClockO + "\\$z Show Thousandths", "", enabled && !errored, !errored)) {
		enabled = !enabled;
		if(enabled) {
			enable();
		} else {
			disable();
		}
	}
}

void Main() {
#if TURBO && MANIA32 || MP41 && MANIA64
	
	// String literal "%s%d:%.2d.%.2d" used for M:Ss.Cc
	ptr_template_fast = Dev::FindPattern("25 73 25 64 3A 25 2E 32 64 2E 25 2E 32 64 00");
	// String literal "%s%d:%.2d:%.2d.%.2d" used for H:Mm:Ss.Cc
	ptr_template_slow = Dev::FindPattern("25 73 25 64 3A 25 2E 32 64 3A 25 2E 32 64 2E 25 2E 32 64 00");
#if TURBO
	// Code to calculate hundredths from raw time
	ptr_ms_conversion = Dev::FindPattern("B8 CD CC CC CC F7 E7 8B 44 24 20 C1 EA 03");
#elif MP4
	// Code to calculate hundredths from raw time
	ptr_ms_conversion = Dev::FindPattern("B8 CD CC CC CC 45 2B D0 41 F7 E2 48 8B 44 24 30 C1 EA 03");
#endif
	
	print("Thousandths fast ptr: " + Text::Format(fmt_ptr, ptr_template_fast));
	print("Thousandths slow ptr: " + Text::Format(fmt_ptr, ptr_template_slow));
	print("Thousandths conv ptr: " + Text::Format(fmt_ptr, ptr_ms_conversion));
	
	if(ptr_template_fast == 0 || ptr_template_slow == 0 || ptr_ms_conversion == 0) {
		error("Thousandths: ERROR unable to locate byte replacement patterns, cannot continue!");
		errored = true;
		return;
	}
	
	if(enabled) {
		enable();
	}
	
#else
	error("Thousandths plugin only works for 32-bit Turbo and 64-bit Maniaplanet 4.1");
	errored = true;
#endif
}

void OnEnabled() {
	if(enabled) {
		enable();
	}
}

void OnDisabled() {
	if(enabled) {
		disable();
	}
}

void OnDestroyed() {
	if(enabled) {
		disable();
	}
}

void enable() {
	if(errored) return;
	
	bytes_template_fast = Dev::Patch(ptr_template_fast, "25 73 25 64 3A 25 2E 32 64 2E 25 2E 33 64 00");
	bytes_template_slow = Dev::Patch(ptr_template_slow, "25 73 25 64 3A 25 2E 32 64 3A 25 2E 32 64 2E 25 2E 33 64 00");
#if TURBO
	bytes_ms_conversion = Dev::Patch(ptr_ms_conversion, "90 90 90 90 90 8B D7 8B 44 24 20 90 90 90");
#elif MP4
	bytes_ms_conversion = Dev::Patch(ptr_ms_conversion, "90 90 90 90 90 45 2B D0 41 8B D2 48 8B 44 24 30 90 90 90");
#endif
	
	trace("Thousandths: patch applied");
}

void disable() {
	if(errored) return;
	
	Dev::Patch(ptr_template_fast, bytes_template_fast);
	Dev::Patch(ptr_template_slow, bytes_template_slow);
	Dev::Patch(ptr_ms_conversion, bytes_ms_conversion);
	
	string bytes_template_fast = "";
	string bytes_template_slow = "";
	string bytes_ms_conversion = "";
	
	trace("Thousandths: patch removed");
}


#if TURBO
void Update(float dt) {
	if(!enabled) return;
	
	FixUI::Turbo();
}
#elif MP4
/*
This is ugly, but required, since MP4 menus add the extra digit on already.
This would cause the last digit to be duplicated: 1:23.456 -> 1:23.4566

See: https://github.com/Phlarx/tm-thousandths/issues/1
*/

bool inGame = true;

void Update(float dt) {
	if(!enabled) return;
	
	bool nextInGame = true;
	
	auto playground = cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
	if(playground is null
		|| playground.GameTerminals.Length <= 0
		|| cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
		nextInGame = false;
	} else {
		auto scriptPlayer = cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;
		if(scriptPlayer is null
			|| scriptPlayer.RaceState != CTrackManiaPlayer::ERaceState::Running) {
			nextInGame = false;
		}
		auto serverInfo = GetApp().Network is null ? null : cast<CGameCtnNetServerInfo>(GetApp().Network.ServerInfo);
		if(serverInfo !is null
			&& serverInfo.ServerLogin.Length > 0) {
			nextInGame = serverOverride;
		}
	}
	
	if(inGame != nextInGame) {
		inGame = nextInGame;
		if(inGame) {
			enable();
		} else {
			disable();
		}
	}
}
#endif
