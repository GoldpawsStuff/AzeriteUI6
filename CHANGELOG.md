# AzeriteUI6 Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][1.0.32-Alpha] 2026-11-11
- Working on aura filters and nameplate options.

## [1.0.31-RC]2026-11-11
### Changed
- Reverted to using the ever bugged `bonusbar` conditional for druids, instead of the much better `form`, since the latter is based on order of learning and not fixed in place like bonusbar indices are. Why, oh why, Blizzard?
- The rested bonus XP bar is slightly darker than the rest of the XP bar now. 

### Fixed
- Worked around secrecy restrictions that lately have prevented the target unit frame castbar from showing.

## [1.0.29-RC] 2026-11-10
### Added
- Added Retail style flashing of repeat messages in the `UIErrorsFrame` to the Classics and Forever, instead of the old "repeat a message forever" style.

### Changed
- Changed the primary actionbar paging driver from using `bonusbar` to `form` conditionals to work around a known Forever bug where `bonusbar` sometimes reports 0, leaving the player with the wrong visible actionbar page.

### Fixed
- Fixed some XP bar color inconsistencies.
- Unitframes should now properly say "Ghost" when a player is dead and have released its spirit.

## [1.0.28-RC] 2026-11-08
### Added
- Added the command `/bind` to enter a hover mode to keybind action buttons. Click the exit button 

### Changed
- Slightly moved the default Chat Window position a bit up to make room for the focus frame. No forced reset of the EditMode preset this time, just a new default. People can always use `/resetlayout` if they so chooses.

### Fixed
- Fixed an issue where nearly all the actionbars accidentally had identical button names. This probably caused a few problems. It's like naming all your children the same name.

### Fixed
- Fixed an issue where actionbutton fading wouldn't get updated on button content changes like adding or removing spells until after a `/reload`.

## [1.0.27-Release] 2026-11-07
There are hints that there might be a Forever only problem related to Blizzard's not yet perfected gamepad handling. It taints everything, and that taint spreads to the actionbars from there. You can try the following commands to prevent the new gamepad UI from running any code:  
```Lua
/console GamepadEnable 0  
/console GamepadActionBarEnable 0  
```
### Changed
- Changed the actionbutton hiding code to minimize the chance of spellbook taint in Forever. Gamepads might still cause problems, but the above commands also might solve it.

## [1.0.26-RC] 2026-11-07
- Still bugging out.

### Changed
- Attempting yet another actionbutton hiding method to avoid the rare but sudden taint situations.

## [1.0.25-RC] 2026-11-06
### Changed
- Changed how actionbuttons are hidden in an attempt to battle the ever weirder taints. 
- Rewrote a lot of the EditMode integration as well as adjusted our the default layouts a bit. The idea is to match legacy AzeriteUI for our custom presets as much as possible. 

### Fixed
- EditMode preset creation and automatic switching on first run should be smoother now. The automatic switch might still fail now and then, but a simple `/reload` finishes the job.  

## [1.0.24-RC] 2026-11-05
### Added
- Added the Explorer Mode. This is a mode that fades out a lot of frames when out of combat and not having a target. 
- Added Exporer Mode to the options menu. 

### Changed
- Slightly reduced the height of the default chat frame size. 
- Loosened up the filter criteria for the Player/Target unitframe aura filter in Retail and Forever. 

### Fixed
- Fixed an issue with the fading library that would sometimes leave ActionButtons "stuck" even when empty, especially on Form/Stance changes or when moving spells and abilities around. 

## [1.0.21-RC] 2026-11-05
### Fixed 
- Fixed the Forever secrecy bug on regular combat feedback on the target frame. 

## [1.0.20-RC] 2026-11-05
### Fixed
- Fixed the neverending recreation loop of the Azerite UI EditMode presets. Auto switching to the new preset on first run still suddenly fails in Forever, though. 

## [1.0.19-RC] 2026-11-04
### Added
- Added a proper tracking menu to all the Classic minimaps. Currently testing.
- Added XP bar to the Classic Minimap.
- Added the forgotten Minimap backdrop texture to the Classics.
- Added a character specific GamePad layout to the EditMode in Forever, since GamePads are more officially supported there. If you wish to enable GamePad usage in non-Forever clients, use `/console GamePadEnable 1`. Note that a specific GamePad EditMode layout is not created for this UI in any other clients than Forever. 

### Changed
- Adjusted the default Classic Tooltip position to match Retail.
- The default EditMode preset created by this UI is now Character specific, not Account wide.

### Fixed
- Removed an annoying backdrop border that kept popping up on ActionButtons in TBC Anniversary amongst others.

### Removed
- Removed any existing Account wide EditMode presets created by this UI.

## [1.0.17-RC] 2026-10-26
### Added
- Added XP bar to the Retail/Forever Minimap.

### Changed
- Now fully disables our own Action Bars when a conflicting addon like `Bartender4` or `Dominos` is detected.
- May or may not make a few more Minimap icons fade out until moused over.

### Fixed
- Fixed an issue that caused a reset of the settings through the options menu to fail.

## [1.0.16-RC] 2026-10-22
### Added
- Now creates an EditMode preset named "Azerite UI Default" if it doesn't exist, and applies it. The preset is a work in progress, more will be added to it.
- Added the command `/resetlayout` to forcefully reset the aforementioned EditMode layout. Might change that command later. Or add a button. 

## [1.0.14-RC] 2026-10-21
### Added
- Added fading options to the Action Bar menus.
- Added simple toggle switches for Player, Pet, Focus, Target and Target of Target Unit Frames to the options menu.

### Changed
- Changed the options menu structure a bit, moved the module listing into the addon listing on the left.

### Fixed
- Fixed an issue where neither ours nor the default nameplates were shown.
- Fixed the detection of conflicting addons, since apparently the whole API for this had changed.

## [1.0.9-RC] 2026-10-18
- Fixed a bunch of things that magically broke.
- Updated a bunch of things that weren't previously updated.

## [1.0.8-Alpha] 2026-10-17
### Added
- Added a basic graphical options menu accessible with `/az` or through the Blizzard Options. Work in progress.

### Fixed
- Fixed an issue where Multi Action Bar 2-8 all displayed the contents of the Primary Action Bar.

## [1.0.7-Alpha] 2026-10-08
- Now embeds all libraries directly in our repository, no externals. All credits appropriately given in the pkgmeta to ensure author rewards.  
- Added basic support for all current versions of the game:  
  - Classic Era **1.15.9**.
  - Burning Crusade Anniversary **2.5.6**.
  - Mists of Pandaria Classic **5.5.4**.
  - Forever **1.60.1**.
  - Midnight **12.1.0**.

### Added
- Added a chat based system to configure action bars. Currently in Alpha mode, will post usage information later. Note that this is not meant to replace a GUI, it's simply an addition that was faster to write and will provide the functionality until then. The commands will remain even when the GUI is done.

## [1.0.5-RC] 2026-08-17
### Fixed
- Fixed a bug causing the addon to break when the library LibSharedMedia was loaded. This is used by a lot of addons include nearly every addon showing timer bars. 

## [1.0.4-RC] 2026-08-12
- Updated toc version for WoW Retail Client Patch **12.1.0**.
- Started fixing things for the WoW **12.1.0** API.
- Started updating for latest oUF changes

## [1.0.2-Alpha] 2026-07-19
- Updated toc version for WoW Retail Client Patch **12.0.7**.

## [1.0.1-Alpha] 2026-05-26
- First public commit.
