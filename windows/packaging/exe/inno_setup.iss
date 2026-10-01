[Setup]
AppId=B9F6E402-0CAE-4045-BDE6-14BD6C39C4EA
AppVersion=1.12.2+27
AppName=MDLovFi Music
AppPublisher=Merrmist
AppPublisherURL=https://github.com/Merrmist/MDLovFi-Music
AppSupportURL=https://github.com/Merrmist/MDLovFi-Music
AppUpdatesURL=https://github.com/Merrmist/MDLovFi-Music
DefaultDirName={autopf}\mdlovfimusic
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=mdlovfimusic-1.12.2
Compression=lzma
SolidCompression=yes
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=lowest
LicenseFile=..\..\LICENSE
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\mdlovfimusic.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\MDLovFi Music"; Filename: "{app}\mdlovfimusic.exe"
Name: "{autodesktop}\MDLovFi Music"; Filename: "{app}\mdlovfimusic.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\mdlovfimusic.exe"; Description: "{cm:LaunchProgram,{#StringChange('MDLovFi Music', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
