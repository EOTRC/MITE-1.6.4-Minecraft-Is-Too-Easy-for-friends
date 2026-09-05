  MITE 1.6.4 - Minecraft Is Too Easy
  Full pack for multiplayer
---------------------------------------

FOLDERS:
--------
Client/   - game client
Server/   - dedicated server
jre8/     - portable Java 8 (auto-downloaded)

QUICK START:
------------
1. Open folder "Client"
2. Run PLAY.bat
3. First run downloads Java 8 (~40 MB) into jre8/
4. Enter player name (or just press Enter)

SERVER (play with friend):
--------------------------
1. Open folder "Server"
2. Run START_SERVER.bat
3. Wait until server is fully started

CONNECT:
--------
Multiplayer -> Direct Connect
  localhost      - same PC
  192.168.x.x    - LAN (ipconfig)
  internet       - port forward 25565 or [playit.gg](https://playit.gg/), [tailscale.com](https://tailscale.com/).

Server settings: port 25565, online-mode=false (cracked OK)

IMPORTANT:
----------
- Disable sounds (Sounds not included)
- Folder names are Latin (Client/Server) on purpose.
  Cyrillic paths break lwjgl.dll on Windows.
- If natives error remains: install
  Visual C++ Redistributable 2015-2022 (x64)
  https://aka.ms/vs/17/release/vc_redist.x64.exe

Links:
  Java 8: https://adoptium.net/temurin/releases/?version=8
  MITE Discord: https://discord.gg/2tSuFhZxS8
