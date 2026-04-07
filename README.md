**AzeriteUI 6.0** is a custom World of Warcraft user interface for WoW Retail. 

Do to the enormous changes in the WoW API in the Midnight expansion from WoW Retail patch 12.0.0 and onwards, I have chosen to separate this from its predecessor AzeriteUI 5.x, which in turn only will support Classic versions of the game now. They are now both different addons and different projects on GitHub. These two addons are now far more different than simply supporting different versions of the game, as what they change and how they do it also is vastly different, thus a split into two separate addons was the only proper choice here. I've kept them similarly named do to their characteristic custom graphics which they still share.

If you choose to download and manually install directly from GitHub, you'll need to additionally install the Ace3 libraries and the oUF framework as addons:  
- [Ace3](https://www.curseforge.com/wow/addons/ace3)
- [oUF](https://www.curseforge.com/wow/addons/ouf)

## Configuring the UI
The full and proper graphical options menu is not yet ready! Until then we can configure the user interface with the chat commands listed below.  

### Chat Commands
- **/enablebar `n`** Enables action bar `n` *(replace `n` with `1`-`8`, `pet` or `stance`)*  
- **/disablebar `n`** Disables action bar `n` *(replace `n` with `1`-`8`, `pet` or `stance`)*  
- **/lock** Toggles the movable frame anchors for this user interface. *(Note that most of the default Blizzard elements are controlled by the game's own EditMode, so you need to enter it to move or scale these.)*  
  - `Mouse Wheel` to scale/size a frame.  
  - `Shift` + `Left Mouse Button` to return a frame to its previous position.  
  - `Shift` + `Right Mouse Button` to return a frame to its default position.  
- **/resetpositions** Resets all positions and sizes of our movable frames. Does not affect Blizzard's EditMode or frames controllable from it.  
- **/resetsettings** Resets all settings like visible/enabled unit frames and action bars.  

## Development Status
- 🔁 UnitFrames  
  - 🔁 Player  
    - ⛔ Absorb Bar *(texcoord operation blocked by secrets)*  
  - ✅ Pet  
  - 🔁 Target  
  - ✅ Target of Target  
  - ✅ Focus  
  - 🔳 Boss Frames  
  - 🔳 Party Frames   
  - 🚫 ~~Raid~~ *(will split into separate addon, or cancel)*  
  - 🚫 ~~Arena Enemy~~ *(will split into separate addon, or cancel)*  
  - ⛔ Incoming Heals *(texcoord operation blocked by secrets)*  
  - ✅ Movable/scalable UnitFrames  
- 🔁 ActionBars  
  - ✅ Primary Bar  
    - ✅ Page Switching *(Stance/Possess/Vehicle/Etc)*  
  - ✅ MultiBar 1  
  - ✅ MultiBar 2  
  - ✅ MultiBar 3  
  - ✅ MultiBar 4  
  - ✅ MultiBar 5  
  - ✅ MultiBar 6  
  - ✅ MultiBar 7  
  - 🔳 Stance Bar  
  - 🔁 Pet Action Bar  
  - 🔳 Extra Abilities Bar  
  - 🔳 Zone Abilities Bar  
  - 🔳 Encounter Bar  
  - 🚫 ~~Possess Bar~~ *(implemented through primary bar paging)*  
  - 🔳 Micro Menu  
  - ✅ Movable/scalable ActionBars  
- 🔳 Player Buffs & Debuffs  
- 🔳 Chat Frames *(styling)*  
  - 🔳 Background removal/transparency  
  - 🔳 Hover functionality for clutter  
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
  - ✅ Full positions reset
  - ✅ Full settings reset
- 🔳 Movable Frames Menu  
- 🔳 Options Menu  

✅ = Finished  
🔁 = In progress  
⛔ = Incompatible  
🚫 = Cancelled  

### Sponsor
Note the amount of people visibly and monthly pledging is directly equivalent to the amount of time and effort I put into investigating bugs and adding features that does not affect me personally. You're dedicated, I'm dedicated.
- **GitHub:** [github.com/sponsors/goldpawsstuff](https://github.com/sponsors/goldpawsstuff)
- **Patreon:** [patreon.com/goldpawsstuff](https://www.patreon.com/goldpawsstuff)
- **Paypal:** [paypal.me/goldpawsstuff](https://www.paypal.me/goldpawsstuff)

### Connect
- **X:** [@goldpawsstuff](https://x.com/goldpawsstuff)
- **Discord:** [discord.gg/RwcSm8V3Dy](https://discord.gg/RwcSm8V3Dy)
