# Ultimate2C-FixDuplicates

A small, portable Windows utility that removes duplicate **8BitDo Ultimate 2C Wireless Controller** entries from the Game Controllers list (`joy.cpl`) by disabling two auxiliary HID interfaces. Supports the controller's **USB cable and 2.4 GHz receiver** connections.

[Download v0.1](https://github.com/MatyMeatBoy/Ultimate2C-FixDuplicates/releases/tag/v0.1) · [MIT license](LICENSE)

## The problem

On the system where this workaround was developed, Windows listed one Ultimate 2C as **three controllers with the same name**. It happened both over USB and through the included 2.4 GHz receiver. The gamepad worked, but selecting another controller in some games was troublesome.

DirectInput enumeration identified three interfaces:

| Interface | HID usage page / usage | Action |
| --- | --- | --- |
| Actual gamepad | `0001:0005` | Kept enabled |
| Consumer controls | `000C:0001` | Disabled by Repair |
| 8BitDo private interface | `FF7A:0001` | Disabled by Repair |

XInput detected only **one** controller, even while `joy.cpl` showed three entries. These extra entries are auxiliary interfaces, not three independent XInput gamepads. L4/R4 are not separate controllers.

Disabling the two auxiliary HID nodes reduced DirectInput enumeration to one Ultimate 2C while preserving the XInput gamepad. The user confirmed the workaround resolved their controller issue. The exact cause of game-specific controller selection problems has not been established; this utility does not set player order.

## Download and use

1. Download `Ultimate2CFix.exe` or the portable ZIP from [Releases](https://github.com/MatyMeatBoy/Ultimate2C-FixDuplicates/releases).
2. Run the EXE. **Check** reads the connected interfaces without changing them.
3. Connect the controller with its USB cable, click **Repair**, and approve the Windows administrator prompt.
4. Disconnect the cable, connect the 2.4 GHz receiver, set the controller to **2.4G**, and turn it on. Click **Repair** again.
5. Close and reopen `joy.cpl` or your game to refresh the controller list.

Apply the workaround separately on each PC. You can copy the single EXE to another PC; source files are not required at runtime.

Windows stores disabled state **per device instance**. It normally persists for that instance, but switching USB ports, reinstalling a device, or creating another instance can require running Repair again. The tool only changes currently connected instances. It does not install a background service or automatically handle future connections.

## Restore the original interfaces

Connect the cable or receiver you want to restore and click **Restore**. Repeat for the other connection if needed. Restore enables the matching auxiliary interfaces, including ones previously disabled manually or by another tool.

The private interface may be needed by configuration or firmware tools. Restore before using those tools, then apply Repair again if desired. Check buttons, vibration, and any L4/R4 mappings after making changes; all possible configurations have not been tested.

## Compatibility and scope

- Intended for Windows 10/11 with Windows PowerShell 5.1, the `PnpDevice` module, and .NET Framework 4.5 or later available.
- Supports the **Ultimate 2C Wireless** hardware ID `VID_2DC8&PID_310A`, observed with both USB and its included receiver.
- Device instance suffixes are discovered at runtime; no serial number, PC-specific path, or USB port is hardcoded.
- Other models, PIDs, the Ultimate 2C Bluetooth/Switch edition, and Bluetooth connections are not supported.
- Verified on one Windows PC with cable and receiver. The tool is designed to run on other PCs, but broader hardware/Windows compatibility has not yet been independently verified.
- No driver uninstallation, firmware flashing, registry edits, game configuration changes, or network access.
- No player 1/player 2 reassignment or conversion of DirectInput controllers to XInput.
- Not an official 8BitDo application. Release binaries are not digitally signed.

## What changes

Repair calls Windows `Disable-PnpDevice` only for connected HID nodes matching these patterns:

```text
HID\VID_2DC8&PID_310A&MI_01&COL02\<instance>
HID\VID_2DC8&PID_310A&MI_02\<instance>
```

The gamepad/XInput node, keyboard collection, mouse collection, parent USB device, and other controllers are excluded. Repair skips already-disabled nodes and verifies the resulting Windows problem code (`22`, disabled). Restore uses `Enable-PnpDevice` and verifies normal status. On failure, the utility attempts to roll back changes made during that operation and reports rollback failures.

Reports are stored locally in `%LOCALAPPDATA%\Ultimate2CFix`. They contain local device instance IDs and paths; review them before sharing.

## Build and test

No NuGet packages or downloaded build dependencies are required. On Windows, from the repository directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Selection.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -Package
```

The build uses the .NET Framework C# compiler installed with Windows. Output is written to `dist/`: EXE, portable ZIP, and `SHA256SUMS.txt`.

The selection tests cover supported instances, changing ports, case-insensitive IDs, the actual gamepad, keyboard/mouse collections, USB parents, another controller, other products, and malformed IDs. They do not modify hardware. CI builds and runs these tests on Windows; it cannot test a physical controller.

For a read-only command-line scan:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\Fix.ps1 -Action Scan
```

For manual validation with hardware, test Repair, reopen `joy.cpl`, check the gamepad and other controllers, test Restore, then repeat for the other connection. Administrator permission is needed for Repair and Restore.

## License

[MIT](LICENSE).
