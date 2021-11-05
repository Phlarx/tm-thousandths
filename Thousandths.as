[Setting name="Enabled"]
bool enabled = false;
bool errored = false;

uint64 ptr_template_fast = 0;
uint64 ptr_template_slow = 0;
uint64 ptr_ms_conversion = 0;
//uint64 ptr_string_consts = 0;
//uint64 ptr_hook_fmt_fast = 0;
//uint64 ptr_hook_fmt_slow = 0;

//Dev::HookInfo@ hook_fmt_fast = null;
//Dev::HookInfo@ hook_fmt_slow = null;

string bytes_template_fast = "";
string bytes_template_slow = "";
string bytes_ms_conversion = "";

#if !TURBO && !MP4
error_this_plugin_only_works_in_Turbo_and_MP4 _error;
#endif

#if TURBO
string fmt_ptr = "0x%016x";
#elif MP4
string fmt_ptr = "0x%016x";
#endif

/*
TODO:
- Separate MANIA64 and MANIA32
*/

void RenderMenu() {
  if(UI::MenuItem("Show Thousandths", "", enabled, !errored)) {
    enabled = !enabled;
    if(enabled) {
      startnew(enable);
    } else {
      startnew(disable);
    }
  }
}

void Main() {
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
  
  //ptr_hook_fmt_fast = Dev::BaseAddress() + 0x298e9e; // MP4! this is the mov eax,dword ptr ss:[rsp+80] after the lea that loads the fmt addr
  //ptr_hook_fmt_slow = Dev::BaseAddress() + 0x298ece; // MP4! this is the mov eax,dword ptr ss:[rsp+80] after the lea that loads the fmt addr
  
  //ptr_string_consts = Dev::Allocate(35, false);
  
  print(Text::Format(fmt_ptr, ptr_template_fast));
  print(Text::Format(fmt_ptr, ptr_template_slow));
  print(Text::Format(fmt_ptr, ptr_ms_conversion));
  //print(Text::Format(fmt_ptr, ptr_string_consts));
  //print(Text::Format(fmt_ptr, ptr_hook_fmt_fast));
  //print(Text::Format(fmt_ptr, ptr_hook_fmt_slow));
  
  if(ptr_template_fast == 0 || ptr_template_slow == 0 || ptr_ms_conversion == 0 /*|| ptr_string_consts == 0 || ptr_hook_fmt_fast == 0 || ptr_hook_fmt_slow == 0*/) {
    error("Unable to locate byte replacement patterns, cannot continue!");
    errored = true;
    return;
  }
  
  //Dev::WriteString(ptr_string_consts, "%s%d:%.2d.%.3d");
  //Dev::WriteString(ptr_string_consts+15, "%s%d:%.2d:%.2d.%.3d");
  
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
  //Dev::Free(ptr_string_consts);
}

void enable() {
  if(errored) return;
  
  //@hook_fmt_fast = Dev::Hook(ptr_hook_fmt_fast, 2, "replaceTimeFormat");
  //@hook_fmt_slow = Dev::Hook(ptr_hook_fmt_slow, 2, "replaceTimeFormat");
  
  bytes_template_fast = Dev::Patch(ptr_template_fast, "25 73 25 64 3A 25 2E 32 64 2E 25 2E 33 64 00");
  //bytes_template_slow = Dev::Patch(ptr_template_slow, "25 73 25 64 3A 25 2E 32 64 3A 25 2E 32 64 2E 25 2E 33 64 00");
#if TURBO
  bytes_ms_conversion = Dev::Patch(ptr_ms_conversion, "90 90 90 90 90 8B D7 8B 44 24 20 90 90 90");
#elif MP4
  bytes_ms_conversion = Dev::Patch(ptr_ms_conversion, "90 90 90 90 90 45 2B D0 41 8B D2 48 8B 44 24 30 90 90 90");
#endif
}

void disable() {
  //if(errored) return; // should be safe even if errored
  
  /*if(hook_fmt_fast !is null) {
    Dev::Unhook(hook_fmt_fast);
    hook_fmt_fast == null;
  }
  if(hook_fmt_slow !is null) {
    Dev::Unhook(hook_fmt_slow);
    hook_fmt_slow == null;
  }*/
  
  Dev::Patch(ptr_template_fast, bytes_template_fast);
  //Dev::Patch(ptr_template_slow, bytes_template_slow);
  Dev::Patch(ptr_ms_conversion, bytes_ms_conversion);
  
  string bytes_template_fast = "";
  string bytes_template_slow = "";
  string bytes_ms_conversion = "";
}

/*
// Nope, hooks like this are read-only
void replaceTimeFormat(uint64 rdx) {
  print(Text::Format(fmt_ptr, rdx));
  if(rdx == ptr_template_fast) {
    rdx = ptr_string_consts;
  } else if(rdx == ptr_template_slow) {
    rdx = ptr_string_consts+15;
  }
  print(Text::Format(fmt_ptr, rdx));
}*/

/*
Labels
Address          Disassembly                   Label                             
0000000140298DA0 mov eax,ecx                   sub_140298DA0:func_explodeTime
0000000140298E30 sub rsp,68                    sub_140298E30:func_formatTime
000000014014ACF0 mov qword ptr ss:[rsp+10],rdx sub_14014ACF0:func_printfMaybe
000000014054AD60 mov qword ptr ss:[rsp+18],rbx sub_14054AD60:func_halp
000000014052EC20 mov rax,rsp                   sub_14052EC20:func_nevermind
0000000140145650 mov qword ptr ss:[rsp+10],rbx sub_140145650:func_stringToWstring
0000000140143790 mov qword ptr ss:[rsp+8],rbx  sub_140143790:func_concatWstring

Bookmarks
Address          Disassembly                                     Label                          Comment
0000000140298E0B mov eax,CCCCCCCD                                                               
0000000140298DA0 mov eax,ecx                                     sub_140298DA0:func_explodeTime 
0000000140298E30 sub rsp,68                                      sub_140298E30:func_formatTime  
000000014054AEF0 call <maniaplanet.sub_14052EC20:func_nevermind>                                

Functions
Start             End               Size   Label                                               Disassembly (Start)                                 
0000000140143790  000000014014383D  AD     sub_140143790:func_concatWstring                    mov qword ptr ss:[rsp+8],rbx                        
0000000140145650  00000001401456FD  AD     sub_140145650:func_stringToWstring                  mov qword ptr ss:[rsp+10],rbx                       
000000014014ACF0  000000014014AD19  29     sub_14014ACF0:func_printfMaybe                      mov qword ptr ss:[rsp+10],rdx                       
0000000140298DA0  0000000140298E20  80     sub_140298DA0:func_explodeTime                      mov eax,ecx                                         
0000000140298E30  0000000140298F26  F6     sub_140298E30:func_formatTime                       sub rsp,68                                          
000000014052EC20  000000014052EC65  45     sub_14052EC20:func_nevermind                        mov rax,rsp                                         
000000014054AD60  000000014054AF2F  1CF    sub_14054AD60:func_halp                             mov qword ptr ss:[rsp+18],rbx                       

Breakpoints
Type     Address          Module/Label/Exception                               State    Disassembly                                     Hit Summary                
         0000000140298E30 <maniaplanet.exe.sub_140298E30:func_formatTime>      Disabled sub rsp,68                                      1   
         0000000140145650 <maniaplanet.exe.sub_140145650:func_stringToWstring> Enabled  mov qword ptr ss:[rsp+10],rbx                   0   
         0000000140298DA0 <maniaplanet.exe.sub_140298DA0:func_explodeTime>     Enabled  mov eax,ecx                                     110 breakif(ecx == 0x372FB)
         000000014054AD60 <maniaplanet.exe.sub_14054AD60:func_halp>            Enabled  mov qword ptr ss:[rsp+18],rbx                   3   
         000000014054ADA0 maniaplanet.exe                                      Enabled  test eax,eax                                    5   
         000000014054AE91 maniaplanet.exe                                      Enabled  test ebx,ebx                                    3   
         000000014054AEF0 maniaplanet.exe                                      Enabled  call <maniaplanet.sub_14052EC20:func_nevermind> 5   
         000000014054AEF5 maniaplanet.exe                                      Enabled  inc edi                                         5   

0000000140298E84 | 45:85C9                  | test r9d,r9d                                                                    |
0000000140298E87 | 75 35                    | jne maniaplanet.140298EBE                                                       |
0000000140298E89 | 44:394C24 70             | cmp dword ptr ss:[rsp+70],r9d                                                   |
0000000140298E8E | 48:8D15 03933D01         | lea rdx,qword ptr ds:[141672198]                                                | 0000000141672198:"%s%d:%.2d.%.2d"
0000000140298E95 | 44:8B4C24 40             | mov r9d,dword ptr ss:[rsp+40]                                                   |
0000000140298E9A | 4C:0F45C0                | cmovne r8,rax                                                                   |
0000000140298E9E | 8B8424 80000000          | mov eax,dword ptr ss:[rsp+80]                                                   |
0000000140298EA5 | 894424 28                | mov dword ptr ss:[rsp+28],eax                                                   |
0000000140298EA9 | 8B8424 88000000          | mov eax,dword ptr ss:[rsp+88]                                                   |
0000000140298EB0 | 894424 20                | mov dword ptr ss:[rsp+20],eax                                                   |
0000000140298EB4 | E8 371EEBFF              | call <maniaplanet.sub_14014ACF0:func_printfMaybe>                               |
0000000140298EB9 | 48:83C4 68               | add rsp,68                                                                      |
0000000140298EBD | C3                       | ret                                                                             |
0000000140298EBE | 837C24 70 00             | cmp dword ptr ss:[rsp+70],0                                                     |
0000000140298EC3 | 48:8D15 F6923D01         | lea rdx,qword ptr ds:[1416721C0]                                                | 00000001416721C0:"%s%d:%.2d:%.2d.%.2d"
0000000140298ECA | 4C:0F45C0                | cmovne r8,rax                                                                   |
0000000140298ECE | 8B8424 80000000          | mov eax,dword ptr ss:[rsp+80]                                                   |
0000000140298ED5 | 894424 30                | mov dword ptr ss:[rsp+30],eax                                                   |
0000000140298ED9 | 8B8424 88000000          | mov eax,dword ptr ss:[rsp+88]                                                   |
0000000140298EE0 | 894424 28                | mov dword ptr ss:[rsp+28],eax                                                   |
0000000140298EE4 | 8B4424 40                | mov eax,dword ptr ss:[rsp+40]                                                   |
0000000140298EE8 | 894424 20                | mov dword ptr ss:[rsp+20],eax                                                   |
0000000140298EEC | E8 FF1DEBFF              | call <maniaplanet.sub_14014ACF0:func_printfMaybe>                               |
0000000140298EF1 | 48:83C4 68               | add rsp,68                                                                      |
0000000140298EF5 | C3                       | ret                                                                             |


0000000140298E84 | 45:85C9                  | test r9d,r9d                                                                    |
0000000140298E87 | 75 35                    | jne maniaplanet.140298EBE                                                       |
0000000140298E89 | 44:394C24 70             | cmp dword ptr ss:[rsp+70],r9d                                                   |
0000000140298E8E | 48:8D15 03933D01         | lea rdx,qword ptr ds:[141672198]                                                | 0000000141672198:"%s%d:%.2d.%.2d"
0000000140298E95 | 44:8B4C24 40             | mov r9d,dword ptr ss:[rsp+40]                                                   |
0000000140298E9A | E9 9072D6BF              | jmp 10000012F                                                                   |
0000000140298E9F | 842480                   | test byte ptr ds:[rax+rax*4],ah                                                 |
0000000140298EA2 | 0000                     | add byte ptr ds:[rax],al                                                        |
0000000140298EA4 | 0089 4424288B            | add byte ptr ds:[rcx-74D7DBBC],cl                                               |
0000000140298EAA | 842488                   | test byte ptr ds:[rax+rcx*4],ah                                                 |
0000000140298EAD | 0000                     | add byte ptr ds:[rax],al                                                        |
0000000140298EAF | 0089 442420E8            | add byte ptr ds:[rcx-17DFDBBC],cl                                               |
0000000140298EB5 | 37                       | ???                                                                             |
0000000140298EB6 | 1E                       | ???                                                                             |
0000000140298EB7 | EB FF                    | jmp maniaplanet.140298EB8                                                       |
0000000140298EB9 | 48:83C4 68               | add rsp,68                                                                      |
0000000140298EBD | C3                       | ret                                                                             |
0000000140298EBE | 837C24 70 00             | cmp dword ptr ss:[rsp+70],0                                                     |
0000000140298EC3 | 48:8D15 F6923D01         | lea rdx,qword ptr ds:[1416721C0]                                                | 00000001416721C0:"%s%d:%.2d:%.2d.%.2d"
0000000140298ECA | E9 8472D6BF              | jmp 100000153                                                                   |
0000000140298ECF | 842480                   | test byte ptr ds:[rax+rax*4],ah                                                 |
0000000140298ED2 | 0000                     | add byte ptr ds:[rax],al                                                        |
0000000140298ED4 | 0089 4424308B            | add byte ptr ds:[rcx-74CFDBBC],cl                                               |
0000000140298EDA | 842488                   | test byte ptr ds:[rax+rcx*4],ah                                                 |
0000000140298EDD | 0000                     | add byte ptr ds:[rax],al                                                        |
0000000140298EDF | 0089 4424288B            | add byte ptr ds:[rcx-74D7DBBC],cl                                               |
0000000140298EE5 | 44:24 40                 | and al,40                                                                       |
0000000140298EE8 | 894424 20                | mov dword ptr ss:[rsp+20],eax                                                   |
0000000140298EEC | E8 FF1DEBFF              | call <maniaplanet.sub_14014ACF0:func_printfMaybe>                               |
0000000140298EF1 | 48:83C4 68               | add rsp,68                                                                      |
0000000140298EF5 | C3                       | ret                                                                             |

















*/
