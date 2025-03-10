# Rhea/Phoebe Sorter
SD card sorter for the Sega Saturn ODEs Rhea and Phoebe.

This utility is designed to streamline the process of adding/removing games from an SD card compared to the traditional RMENU rebuild process.

It can be used for both first-time SD card set-up, as well as for users with a pre-existing Rhea/Phoebe SD card.

Please note that whether one is setting up a first-time SD card or managing a pre-existing one, the `01` folder on the card must contain all of the necessary [RMENU](https://gdemu.wordpress.com/links/) files and folders. With only this `01` folder present on a brand-new SD card, the card's structure should appear as follows (with the drive letter `F:` as an example).

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
Rhea/Phoebe Sorter is currently at version [1.1](https://github.com/DerekPascarella/Rhea-Phoebe-Sorter/releases/download/1.1/Rhea-Phobe.Sorter.v1.1.zip).

## Changelog
* **Version 1.1 (2025-02-28)**
  * Cleaned up status message output to be more compact and descriptive.
- **Version 1.0 (2024-10-18)**
    - Initial release.

## Basic Usage

![#f03c15](https://i.imgur.com/XsUAGA0.png) **IMPORTANT:** *Rhea/Phoebe users with a pre-existing SD card must first undergo a migration process described in the [Menu Migration for Pre-Existing Rhea/Phoebe SD Cards](#menu-migration-for-pre-existing-rheaphoebe-sd-cards) section.*

Using Rhea/Phoebe Sorter is simple. To add a new game to an SD card, create a new folder on the root of that card. Next, rename the folder according to whichever name should be displayed in RMENU.

For multi-disc games, simply append ` - Disc X` to the end of the folder name. For example, `Policenauts (English) - Disc 1`, `D - Disc 2`, or `Phantasmagoria (English) - Disc 6`. Please note that this format must be adhered to for proper processing of multi-disc games.

Once all new game folders have been created on the card (and their disc images reside in their respective folders), simply drag the SD card onto `orbital_organizer.exe` for processing.

Rhea/Phoebe Sorter will alphanumerically sort all numbered folders based on game name, as well as automatically extract metadata (i.e., disc number, release date, version, and region) from each disc image so that RMENU can display it. It's worth mentioning that Rhea/Phoebe Sorter's method for extracting said metadata is more reliable and accurate than that of the traditional REMENU rebuild process.

Please note that in order to change any metadata associated with a game in the future (e.g., game name, region), simply edit the corresponding `.txt` file inside of its respective numbered folder (e.g., `Name.txt`, `Region.txt`). Then, process the SD card again by dragging it onto `orbital_organizer.exe`.

Lastly, Rhea/Phoebe Sorter will rebuild RMENU based on all of the processed game list data, rendering the SD card ready for use. It will also place a text file named `Game_List.txt` in the root of the SD card so users can easily find which numbered folders contain which games.

The process for removing games merely involves deleting the numbered folder(s) containing the game(s) to be removed, then dragging the SD card onto `orbital_organizer.exe` for processing. All folder sorting/renaming and RMENU rebuilding will be handled automatically.

## Menu Migration for Pre-Existing Rhea/Phoebe SD Cards
For those with a pre-existing SD card who wish to use Rhea/Phoebe Sorter moving forward, a one-time migration step must be taken.

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
