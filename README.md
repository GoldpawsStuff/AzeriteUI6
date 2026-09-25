**AzeriteUI 6.0** is a custom World of Warcraft user interface for WoW Retail. 

**Update:** Currently in the process of unifying all current WoW versions into this addon. Elements and features that are blocked in Retail and Forever will not be included in the Classic versions either. This is not a bug, it's intentional to provide a unified user interface experience across versions again. Note that the addon currently **ONLY** works for WoW Retail, and I advice people to not attempt it in other flavors yet.  

If you choose to download and manually install directly from GitHub - which I can't express strongly enough how much I DON'T recommend, you'll need to additionally install the following as standalone addons:  
- [Ace3](https://www.curseforge.com/wow/addons/ace3)  
- [LibActionButton-1.0](https://www.curseforge.com/wow/addons/libactionbutton-1-0)  
- [oUF](https://www.curseforge.com/wow/addons/ouf) *(WoW Retail & WoW: Forever)*  

## Configuring the UI
The full and proper graphical options menu is not yet ready! Until then we can configure the user interface with the chat commands listed below. Note that the maximm number of bars is `8` for Retail and Midnight, but `5` for all the Classic versions of the game.  
- **/enablebar `n`** Enables action bar `n` *(replace `n` with `1-8`, `pet` or `stance`)*  
- **/disablebar `n`** Disables action bar `n` *(replace `n` with `1-8`, `pet` or `stance`)*  
- **/resetpositions** Resets all positions and sizes of our movable frames. Does not affect Blizzard's EditMode or frames controllable from it.  
- **/resetsettings** Resets all settings like visible/enabled unit frames and action bars.  

### /lock  
Toggles the movable frame anchors for this user interface. *(Note that most of the default Blizzard elements are controlled by the game's own EditMode, so you need to enter it to move or scale these.)* 
  - `Mouse Wheel` to scale/size a frame.  
  - `Shift` + `Left Mouse Button` to return a frame to its previous position.  
  - `Shift` + `Right Mouse Button` to return a frame to its default position.  

### /setbar  
This command is used to configure a visible actionbar. It controls layout and number of buttons. Note that though these commands always will remain in the UI to allow macros to switch layouts out of combat, they are not meant as the primary configuration option. I _will_ make a graphical menu where it's much easier to understand the setup. I simply wrote these first because it was faster!  
```Lua
/setbar barID (layoutType) (keywordPair, keywordPair, ...)  
```
- **barID** *(Required)* The ID of the bar. This is `1-8` in Retail and Forever, `1-5` in other versions.  
- **layoutType** *(Optional)* The layout type of the bar. This is either `grid` or `zigzag`, where grid is a standard bartender-like layout, and zigzag is the kind of layout the primary action bar by default has from button 9.  
- **keywordPair** *(Optional)* Pairs of keywords and numbers to configure the bar:  
  - `max` **`n`** Maximum number of buttons on the bar, where **n** can range from `1-12`. Applies to all layoutTypes.   
  - `size` **`n`** The maximum length/width of a bar in number of buttons before a new row of buttons begin. Only applies to layoutType `grid`.  
  - `from` **`n`** The first button of the second row in a zigzag pattern when the layoutType is `zigzag`. The primary actionbar starts it default zigzag from button `9`.
  - `right` `left` `up` `down` 
    - These are keywords that need to come as a pair, one horizontal, one vertical. These decide the growth of the bar. If you start with `up` or `down`, the bar will grow vertically first, typically a sidebar. If you start with `right` or `left`, the bar will grow horizontally first. To grow the bar right, then start a new row beneath it, you should use `right down`. 

### Example Layout Commands
Setup the primary action bar as a `4x2` grid with max `8` buttons:  
```
/setbar 1 grid max 8 size 4
```  
Setup the second actionbar as a vertical grid of `2x6`, where the first button is place at the top left, the last button at the bottom right:  
```
/setbar 2 grid max 12 size 6 down right
```  
Setup the primary action bar as the default AzeriteUI layout:  
```
/setbar 1 zigzag from 9 max 12
```  


## Development Status
- 🔁 UnitFrames  
  - 🔁 Player  
  - ✅ Pet  
  - 🔁 Target  
  - ✅ Target of Target  
  - ✅ Focus *(Not in Classic Era)*  
  - 🔳 Boss Frames  
  - 🔳 Party Frames   
  - 🚫 ~~Raid~~ *(will split into separate addon, or cancel)*  
  - 🚫 ~~Arena Enemy~~ *(will split into separate addon, or cancel)*  
- 🔁 ActionBars  
  - ✅ Primary Bar  
  - ✅ MultiBar 1  
  - ✅ MultiBar 2  
  - ✅ MultiBar 3  
  - ✅ MultiBar 4  
  - ✅ MultiBar 5 *(Retail/Forever Only)*  
  - ✅ MultiBar 6 *(Retail/Forever Only)*  
  - ✅ MultiBar 7 *(Retail/Forever Only)*  
  - 🔳 Stance Bar  
  - 🔁 Pet Action Bar  
  - 🔳 Extra Abilities Bar  
  - 🔳 Zone Abilities Bar  
  - 🔳 Encounter Bar  
  - 🔳 Micro Menu  
- 🔳 Player Buffs & Debuffs  
- 🔁 Chat Frames *(styling)*  
  - ✅ Background removal/transparency  
  - ✅ Hover functionality for clutter  
- 🔁 Minimap  
  - ✅ Border  
  - 🔳 Compass North tag  
  - 🔳 Groupfinder eye  
  - 🔳 Grouptype banners  
  - 🔳 Mail Frame
  - 🔳 Exit Flight Button  
- 🔁 Chat Commands  
  - ✅ ActionBar toggles  
  - 🔳 UnitFrame toggles  
  - ✅ Full positions reset ***/resetpositions***  
  - ✅ Full settings reset ***/resetsettings***  
- 🔳 Explorer Mode  
  - 🔳 Chat Frames  
  - 🔳 ActionBars  
  - 🔳 UnitFrames  
    - 🔳 Player UnitFrame  
    - 🔳 Pet UnitFrame  
	- 🔳 Group/Raid Tool  
- 🔳 Options Menu  

✅ = Finished  
🔁 = In progress  
⛔ = Incompatible  
🚫 = Cancelled  

### Sponsor Me
- **GitHub:** [github.com/sponsors/goldpawsstuff](https://github.com/sponsors/goldpawsstuff)  
- **Patreon:** [patreon.com/goldpawsstuff](https://www.patreon.com/goldpawsstuff)  
- **Paypal:** [paypal.me/goldpawsstuff](https://www.paypal.me/goldpawsstuff)  

## Connect With Us
- **X:** [@goldpawsstuff](https://x.com/goldpawsstuff)  
- **Discord:** [discord.gg/RwcSm8V3Dy](https://discord.gg/RwcSm8V3Dy)  
