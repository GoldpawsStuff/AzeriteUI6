# AzeriteUI6 Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features are not yet available in the official tagged builds.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

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
