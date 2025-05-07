# Rhea/Phoebe Sorter
SD card sorter for the Sega Saturn ODEs Rhea and Phoebe.

This utility is designed to streamline the process of adding/removing games from an SD card compared to the traditional RMENU rebuild process.

It can be used for both first-time SD card set-up, as well as for users with a pre-existing Rhea/Phoebe SD card.

Please note that whether one is setting up a first-time SD card or managing a pre-existing one, the `01` folder on the card must contain all of the necessary [RMENU](https://gdemu.wordpress.com/links/) or [RmenuKai](https://ppcenter.webou.net/pskai/readme_rmenukai.txt) files and folders.

With only this `01` folder present on a brand-new SD card, the card's structure should appear as follows (with the drive letter `F:` as an example).

```
F:\
└── 01
    ├── BIN
    │   ├── mkisofs.exe
    │   ├── mkisofs.txt
    │   └── RMENU
    │       ├── 0.BIN
    │       ├── ABS.TXT
    │       ├── BIB.TXT
    │       ├── CPY.TXT
    │       ├── IP.BIN
    │       └── Z.BIN
    ├── Rhea.ini (or Phoebe.ini)
    └── RMENU.exe
```

## Current Version
Rhea/Phoebe Sorter is currently at version [1.4](https://github.com/DerekPascarella/Rhea-Phoebe-Sorter/releases/download/1.4/Rhea-Phobe.Sorter.v1.4.zip).

## Changelog
- **Version 1.4 (2025-05-07)**
  * Added support for modifying game Product IDs.
  * Added support for a secondary instance of legacy RMENU to live alongside, and be accessible from, RmenuKai.
  * Added RmenuKai virtual folder path support during migration process.
  * Fixed issue preventing original game labels from being preserved during migration process if they contained characters that are restricted in file/folder names (thanks [privateye](https://segaxtreme.net/members/privateye.20804/#about)).
  * Added warnings and confirmation prompts to ensure users do not accidentally have files or folders on their SD card open in File Explorer or any other program during processing, as this will result in data corruption.
- **Version 1.3 (2025-05-03)**
  * Added support for automatic virtual subfolder processing of multi-disc games with RmenuKai.
- **Version 1.2 (2025-05-02)**
  * Added support for virtual folders with RmenuKai.
- **Version 1.1 (2025-02-28)**
  * Cleaned up status message output to be more compact and descriptive.
- **Version 1.0 (2024-10-18)**
    - Initial release.

## Basic Usage

![#f03c15](https://i.imgur.com/XsUAGA0.png) **IMPORTANT:** *Rhea/Phoebe users with a pre-existing SD card must first undergo a migration process described in the [Menu Migration for Pre-Existing Rhea/Phoebe SD Cards](#menu-migration-for-pre-existing-rheaphoebe-sd-cards) section.*

Using Rhea/Phoebe Sorter is simple, with each operation to be carried out according to the instructions below.
### Adding New Games

1. Create a folder on the root of the SD card, giving it whatever name should appear in the RMENU/RmenuKai game list.
   - Should a label be desired that contains characters that are restricted in file/folder names (i.e., `<`, `>`, `:`, `"`, `/`, `\`, `|`, `?`, and `*`), create a file named `Name.txt` inside of the game disc folder containing said label.
   - For multi-disc games, append ` - Disc X` to the end of the folder name (or to the end of the label stored in `Name.txt`). This format must be adhered to for proper processing of multi-disc games. See examples below.
     - `Policenauts (T-En) - Disc 1`
     - `Enemy Zero - Disc 2`
   - If wishing to present the disc image inside of a virtual folder path with RmenuKai, create a file named `Folder.txt` inside of the game folder, storing within it the full path (e.g., `Games/Action/Platformers`).
3. Copy the disc image (in a [supported format](https://gdemu.wordpress.com/details/rhea-details/)) to the newly created game folder.
4. Drag the SD card onto `orbital_organizer.exe` and watch the status messages until processing is complete.
   - Rhea/Phoebe Sorter will alphanumerically sort all numbered folders based on game name (and virtual folder path if using RmenuKai), as well as automatically extract metadata (i.e., disc number, release date, version, and region) from each disc image so that RMENU/RmenuKai can display it. It's worth mentioning that Rhea/Phoebe Sorter's method for extracting said metadata is more reliable and accurate than that of the traditional REMENU rebuild process.

### Removing Existing Games

1. Open `GameList.txt` in the root of the SD card and then identify the numbered folder containing the disc image to be removed.
2. Remove the identified numbered folder from the SD card.
3. Drag the SD card onto `orbital_organizer.exe` and watch the status messages until processing is complete.

### Changing Game Label, Virtual Folder Paths, and Other Metadata

1. Open `GameList.txt` in the root of the SD card and then identify the numbered folder containing the disc image with metadata to be edited.
2. Open the identified numbered folder, then open and make changes to the appropriate text file.
   - `Date.txt` - The game's release date
   - `Disc.txt` - The game's disc number
   - `Folder.txt` - Optional virtual folder path for RmenuKai
   - `Name.txt` - The game name as it appears in the menu list
   - `ProductID.txt` - Optional new Product ID (see the [Modifying Product ID](https://github.com/DerekPascarella/Rhea-Phoebe-Sorter#modifying-product-id) section)
   - `Region.txt` - The game's region code
   - `Version.txt` - The game's version as specified by publisher
3. Drag the SD card onto `orbital_organizer.exe` and watch the status messages until processing is complete.

### Modifying Product ID

The Product ID is a piece of metadata associated with Sega Saturn games which ties a piece of software to a unique identifier. There are cases where users may wish to populate a missing Product ID for homebrew software, or fix incorrect Product IDs like that of the Japanese version of "Virtua Fighter Kids" where `GS-9079` is stored on the disc but the correct ID is `GS-9098`.

If desired, Rhea/Phoebe Sorter allows users to modify this ID by directly patching the disc image's `IP.BIN` header.

1. Open `GameList.txt` in the root of the SD card and then identify the numbered folder containing the disc image for which the Product ID should be modified.
2. Open the identified numbered folder, then create a file inside of it named `ProductID.txt` containing a new ten-character ID. Fewer than ten characters is acceptable, but any ID exceeding ten characters will be trimmed.
3. Drag the SD card onto `orbital_organizer.exe` and watch the status messages until processing is complete.

Note that after adding a `ProductID.txt` file to a game folder and processing the SD card, it will be automatically removed so that its disc image won't be unnecessarily patched again during future SD card processing.

### Multi-Disc Games with RmenuKai

If Rhea/Phoebe Sorter detects RmenuKai on the SD card, the user will be asked if they'd like to use virtual folders when processing multi-disc games. If the user says "yes", multi-disc games will only consume one entry on the RmenuKai game list. Upon selecting one of these multi-disc games, a subfolder will be displayed where each separate disc appears as a selectable entry.

For organizational purposes, it's highly recommended that those using RmenuKai allow Rhea/Phoebe Sorter to undergo this intelligent processing of multi-disc games.

### Adding an Instance of Legacy RMENU Alongside RmenuKai

Users of RmenuKai may wish to preserve an instance of legacy RMENU for certain niche use-cases (e.g., use cheats for a JHL loader game).

While users of a [Gamer's Cartridge](https://ppcenter.webou.net/satcart/) can achieve this by leaving legacy RMENU on their SD card while RmenuKai resides only on the cartridge, most Gamer's Cartridge users prefer to keep RmenuKai on their SD card in addition to their cartridge. This is useful for several reasons beyond the scope of this documentation.

Whether using RmenuKai strictly via SD card, or using it via SD card coupled with a Gamer's Cartridge, Rhea/Phoebe Sorter supports an instance of legacy RMENU that can live alongside RmenuKai and be launched directly from the game list menu.

1. Create a folder on the root of the SD card, giving it whatever name should appear in the RmenuKai game list (e.g., `RMENU`).
3. Drag the SD card onto `orbital_organizer.exe` and watch the status messages until processing is complete.
   - A message will appear informing the user that a secondary instance of RMENU was detected on their SD card, at which time they'll be asked if they'd like to update said instance with the latest game list data. Choosing to do so will result in that instance of legacy RMENU containing an up-to-date list of disc images for selection.

Note that this secondary instance of RMENU (in this case, legacy RMENU) will not reside in folder `01`. Instead, it will occupy a different folder number based on its place in the disc image list.

It is suggested to leverage RmenuKai's virtual folder path support, keeping legacy RMENU in a folder named `Utilities and Applications` or similar. To achieve this, create a file named `Folder.txt` inside of the legacy RMENU folder containing the desired virtual folder path before dragging the SD card onto `orbital_organizer.exe` for processing.

## Menu Migration for Pre-Existing Rhea/Phoebe SD Cards
For those with a pre-existing SD card who wish to use Rhea/Phoebe Sorter moving forward, a one-time migration step must be taken. Note that this migration process fully honors virtual folder paths as defined in an RmenuKai-formatted SD card.

Before undergoing this migration, consider the following example Rhea/Phoebe SD card.

```
F:\
├── 01
│   ├── BIN
│   │   ├── mkisofs.exe
│   │   ├── mkisofs.txt
│   │   ├── RMENU
│   │   │   ├── 0.BIN
│   │   │   ├── ABS.TXT
│   │   │   ├── BIB.TXT
│   │   │   ├── CPY.TXT
│   │   │   ├── IP.BIN
│   │   │   ├── LIST.INI
│   │   │   └── Z.BIN
│   │   └── titles.db
│   ├── RMENU.exe
│   └── RMENU.iso
├── 02
│   ├── JungRhythmEnglishSegaSaturn.ccd
│   ├── JungRhythmEnglishSegaSaturn.img
│   └── JungRhythmEnglishSegaSaturn.sub
├── 03
│   ├── POLICENAUTS_D1.ccd
│   ├── POLICENAUTS_D1.img
│   └── POLICENAUTS_D1.sub
├── 04
│   ├── POLICENAUTS_D2.ccd
│   ├── POLICENAUTS_D2.img
│   └── POLICENAUTS_D2.sub
├── 05
│   ├── POLICENAUTS_D3.ccd
│   ├── POLICENAUTS_D3.img
│   └── POLICENAUTS_D3.sub
└── Rhea.ini
```

To perform migration, drag the SD card onto `orbital_shift.exe`. It will produce output similar to the below.

```

Menu Migrator for Rhea/Phoebe Sorter v1.1
Written by Derek Pascarella (ateam)

Reading existing menu data...

4 disc image folder(s) found on SD card.

Renaming numbered folders...

-> Renamed folder "02" to "Jung Rhythm (English)".
-> Renamed folder "03" to "Policenauts (English) - Disc 1".
-> Renamed folder "04" to "Policenauts (English) - Disc 2".
-> Renamed folder "05" to "Policenauts (English) - Disc 3".

First phase of menu migration is complete!

Next, drag SD card onto "orbital_organizer.exe" to rebuild RMENU.

Press Enter to exit.

```

Afterwards, the structure of the SD card will change. Notice how games are now stored in folders named after the game itself. This is how new games will be added to the SD card in the future before being processed by Rhea/Phoebe Sorter.

```
F:\
├── 01
│   ├── BIN
│   │   ├── mkisofs.exe
│   │   ├── mkisofs.txt
│   │   ├── RMENU
│   │   │   ├── 0.BIN
│   │   │   ├── ABS.TXT
│   │   │   ├── BIB.TXT
│   │   │   ├── CPY.TXT
│   │   │   ├── IP.BIN
│   │   │   ├── LIST.INI
│   │   │   └── Z.BIN
│   │   └── titles.db
│   ├── RMENU.exe
│   └── RMENU.iso
├── Jung Rhythm (English)
│   ├── JungRhythmEnglishSegaSaturn.ccd
│   ├── JungRhythmEnglishSegaSaturn.img
│   └── JungRhythmEnglishSegaSaturn.sub
├── Policenauts (English) - Disc 1
│   ├── POLICENAUTS_D1.ccd
│   ├── POLICENAUTS_D1.img
│   └── POLICENAUTS_D1.sub
├── Policenauts (English) - Disc 2
│   ├── POLICENAUTS_D2.ccd
│   ├── POLICENAUTS_D2.img
│   └── POLICENAUTS_D2.sub
├── Policenauts (English) - Disc 3
│   ├── POLICENAUTS_D3.ccd
│   ├── POLICENAUTS_D3.img
│   └── POLICENAUTS_D3.sub
└── Rhea.ini
```

Next, drag the SD card onto `orbital_organizer.exe`, which will produce output similar to the below.

```

Rhea/Phoebe Sorter 1.1
Written by Derek Pascarella (ateam)

Processing SD card (F:), this will take a few moments...

9 disc image(s) found on SD card.

  -> Folder 02 (unchanged: 240p Test Suite)
  -> Folder 03 (unchanged: 3D Baseball)
  -> Folder 04 (unchanged: Advanced V.G. (JAP))
  -> Folder 05 (unchanged: Albert Odyssey - Legend of Eldean)
  -> Folder 06 (unchanged: Alien Trilogy)
  -> Folder 07 (unchanged: Alone in the Dark - One-Eyed Jack's Revenge)
  -> Folder 08 (new: Amok)
  -> Folder 09 (previously 08: Arcade Gears Vol. 1 - Pu-Li-Ru-La (JAP))
  -> Folder 10 (previously 09: Assault Suit Leynos 2 (JAP))

9 disc image(s) processed!

Rebuidling RMENU...

RMENU rebuild complete!

A list of games can be found in the "Game_List.txt" file in the root of the SD card.

Press Enter to exit.

```

After this process completes, the SD card structure changes yet again, this time to the unique format used by Rhea/Phoebe Sorter. The standard numbered folders are present, however metadata (i.e., disc number, release date, version, and region) is now explicitly stored directly within each game folder.

```
F:\
├── 01
│   ├── BIN
│   │   ├── mkisofs.exe
│   │   ├── mkisofs.txt
│   │   ├── RMENU
│   │   │   ├── 0.BIN
│   │   │   ├── ABS.TXT
│   │   │   ├── BIB.TXT
│   │   │   ├── CPY.TXT
│   │   │   ├── IP.BIN
│   │   │   ├── LIST.INI
│   │   │   └── Z.BIN
│   │   └── titles.db
│   ├── RMENU.exe
│   └── RMENU.iso
├── 02
│   ├── Date.txt
│   ├── Disc.txt
│   ├── JungRhythmEnglishSegaSaturn.ccd
│   ├── JungRhythmEnglishSegaSaturn.img
│   ├── JungRhythmEnglishSegaSaturn.sub
│   ├── Name.txt
│   ├── Region.txt
│   └── Version.txt
├── 03
│   ├── Date.txt
│   ├── Disc.txt
│   ├── Name.txt
│   ├── POLICENAUTS_D1.ccd
│   ├── POLICENAUTS_D1.img
│   ├── POLICENAUTS_D1.sub
│   ├── Region.txt
│   └── Version.txt
├── 04
│   ├── Date.txt
│   ├── Disc.txt
│   ├── Name.txt
│   ├── POLICENAUTS_D2.ccd
│   ├── POLICENAUTS_D2.img
│   ├── POLICENAUTS_D2.sub
│   ├── Region.txt
│   └── Version.txt
├── 05
│   ├── Date.txt
│   ├── Disc.txt
│   ├── Name.txt
│   ├── POLICENAUTS_D3.ccd
│   ├── POLICENAUTS_D3.img
│   ├── POLICENAUTS_D3.sub
│   ├── Region.txt
│   └── Version.txt
├── Game_List.txt
└── Rhea.ini
```

At this stage, the SD card is now ready for use. To add new games or remove existing games, simply follow the steps in the [Basic Usage](#basic-usage) section.
