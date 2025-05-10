#!/usr/bin/perl
#
# Rhea/Phoebe Sorter v1.6
# Written by Derek Pascarella (ateam)
#
# SD card sorter for the Sega Saturn ODEs Rhea and Phoebe.

# Include necessary modules.
use utf8;
use strict;
use Encode;
use File::Copy;
use Fcntl 'SEEK_SET';

# Set version number.
my $version = "1.6";

# Set STDOUT encoding to UTF-8.
binmode(STDOUT, "encoding(UTF-8)");

# Initialize input variables.
my $sd_path_source = $ARGV[0];

# Declare/initialize variables.
my %game_list = ();
my %metadata = ();
my $game_count_found = 0;
my $game_count = 1;
my $invalid_count = 0;

# No valid SD card path specified.
if(!-d $sd_path_source || !-e $sd_path_source || $sd_path_source eq "")
{
	print "\nRhea/Phoebe Sorter v" . $version . "\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: No SD card path specified.\n\n";
	print "Example Usage: orbital_organizer H:\\\n\n";
	print "Press Enter to exit...\n";
	<STDIN>;

	exit;
}
# SD card path is unreadable.
elsif(!-R $sd_path_source)
{
	print "\nRhea/Phoebe Sorter v" . $version . "\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: Specified SD card path is unreadable.\n\n";
	print "Example Usage: orbital_organizer H:\\\n\n";
	print "Press Enter to exit...\n";
	<STDIN>;

	exit;
}

# Status message.
print "\nRhea/Phoebe Sorter v" . $version . "\n";
print "\"The Orbital Organizer\"\n";
print "Written by Derek Pascarella (ateam)\n\n";

# Warning message requiring user to press Enter before continuing.
print "WARNING: Before proceeding, ensure that no files or folders on SD card (" . $sd_path_source . ")\n";
print "         are open in File Explorer or any other program. Failure to do so\n";
print "         will result in data corruption!\n\n";
print "Press Enter to continue...\n";
<STDIN>;

# If RmenuKai is detected, prompt for virtual folder processing of multi-disc games.
my $multidisc_subfolders = 0;
my $rmenukai_detected = 0;

if(-e $sd_path_source . "\\01\\BIN\\RMENU\\0.BIN" && find_bytes($sd_path_source . "\\01\\BIN\\RMENU\\0.BIN", [0x70, 0x73, 0x6B, 0x61, 0x69]))
{
	$rmenukai_detected = 1;

	my $rmenukai_multidisc_prompt;

	print "RmenuKai has been detected on SD card. Process multi-disc games using\n";
	print "subfolders (i.e., \"Disc 1\")? (Y/N) ";

	while($rmenukai_multidisc_prompt ne "Y" && $rmenukai_multidisc_prompt ne "N")
	{
		chop($rmenukai_multidisc_prompt = uc(<STDIN>));
	}

	if($rmenukai_multidisc_prompt eq "Y")
	{
		$multidisc_subfolders = 1;
	}

	print "\n";
}

# Status message.
print "Processing SD card (" . $sd_path_source . "), this will take a few moments...\n\n";
print "WARNING: Do not close this program or remove SD card! Doing so will result in\n";
print "         data corruption. Please be patient.\n\n";

# Create temporary folder for purposes of sorting FAT filesystem.
mkdir($sd_path_source . "\\orbital_organizer_temp\\");

# Open SD card path for reading.
opendir(my $sd_path_source_handler, $sd_path_source);

# Iterate through contents of SD card in alphanumeric order.
foreach my $sd_subfolder (sort { 'numeric'; $a <=> $b } readdir($sd_path_source_handler))
{
	# Skip folders starting with a period.
	next if($sd_subfolder =~ /^\./);
	
	# Skip all non-folders (e.g., files like "Rhea.ini" or "Phoebe.ini").
	next if(!-d $sd_path_source . "\\" . $sd_subfolder);
	
	# Skip folder "01" containing GDMenu.
	next if($sd_subfolder eq "01");

	# Ignore Windows system folder.
	next if($sd_subfolder eq "System Volume Information");

	# Skip Recycling Bin folder.
	next if($sd_subfolder =~ /RECYCLE\.BIN/);

	# Store list of all files in subfolder.
	my @sd_subfolder_files = folder_list($sd_path_source . "\\" . $sd_subfolder);

	# Set game-found flag to false.
	my $game_found = 0;

	# Consider folder as storing a game if "Name.txt" is found.
	if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Name.txt")
	{
		$game_found = 1;
	}
	# Otherwise, iterate through each file to locate valid disc image.
	else
	{
		foreach(@sd_subfolder_files)
		{
			if($_ =~ /\.(cdi|mdf|img|iso)$/i)
			{
				# Set game-found flag to true.
				$game_found = 1;
			}
		}
	}

	# To prevent folder name conflicts, rename invalid folder for user to process manually.
	if(!$game_found && $sd_subfolder ne "orbital_organizer_temp")
	{
		$invalid_count ++;

		rename($sd_path_source . "\\" . $sd_subfolder, $sd_path_source . "\\INVALID_" . $invalid_count);
	}

	# If folder contains no game disc image, skip it.
	next if(!$game_found);

	# Declare game name variable.
	my $game_name;

	# Store game name from "Name.txt".
	if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Name.txt")
	{
		# Store name and normalize whitespace.
		$game_name = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Name.txt");
		$game_name =~ s/^\s+|\s+$//g;
		$game_name =~ s/\s+/ /g;

		# Folder contains a duplicate entry migration tag, so append it to game name in order
		# to keep unique hash keys for all disc image entries (to be stripped later).
		if($sd_subfolder =~ /\[UNIQUE-/)
		{
			my ($migration_tag) = $sd_subfolder =~ /(\[UNIQUE-[^\]]+\])/;

			$game_name .= " " . $migration_tag;
		}
		 # Otherwise, check for existence of an equivalent key by comparing base names.
		else
		{
			# Convert " - Disc X" to "/Disc X" so every multi-disc label is processed the
			# same way.
			$game_name =~ s{
				\s*-\s*                # space-dash-space
				(?:Disc|Disk|CD)       # the word
				\s*0*([1-9][0-9]*)     # the number we will keep
				\s*$                   # to end of string
			}{/Disc $1}ix;

			# Remove leading virtual-folder path only.
			(my $base_name = $game_name) =~ s{^.*/}{};

			# Normalize whitespace.
			$base_name =~ s/^\s+|\s+$//g;
			$base_name =~ s/\s+/ /g;

			# Set duplicate found flag to false.
			my $duplicate_found = 0;

			# Iterate through each existing key in the game list and metadata hashes.
			foreach my $existing_key (keys %game_list, keys %metadata)
			{
				# Remove leading virtual-folder path only.
				(my $existing_base = $existing_key) =~ s{^.*/}{};				
				
				# Normalize whitespace.
				$existing_base =~ s/^\s+|\s+$//g;
				$existing_base =~ s/\s+/ /g;

				if(lc $existing_base eq lc $base_name)
				{
					$duplicate_found = 1;

					last;
				}
			}

			# Duplicate entry found.
			if($duplicate_found)
			{
				# Generate random six-character ID.
				my @random_character_bank = ("A" .. "Z", "0" .. "9");
				my $random_id = join("", map { $random_character_bank[int(rand(@random_character_bank))] } 1 .. 6);

				# Try to insert before "/Disc N", and if that substitution fails, append at the end.
				$game_name =~ s{(/Disc\s*0*[1-9][0-9]*\s*$)}{ [UNIQUE-$random_id]$1}i
							  or $game_name .= " [UNIQUE-$random_id]";
			}
		}
	}
	# Store folder name as game name if it's not a numbered folder (e.g., 07).
	elsif($sd_subfolder !~ /^[+-]?\d+(\.\d+)?$/)
	{
		$game_name = $sd_subfolder;
		$game_name =~ s/^\s+|\s+$//g;
		$game_name =~ s/\s+/ /g;

		# Write "Name.txt" file.
		write_file($sd_path_source . "\\" . $sd_subfolder . "\\Name.txt", $game_name);
	}

	# If metadata text files don't exist for current game, extract data from image file.
	if(!-e $sd_path_source . "\\" . $sd_subfolder . "\\Name.txt" || !-e $sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt" ||
	   !-e $sd_path_source . "\\" . $sd_subfolder . "\\Region.txt" || !-e $sd_path_source . "\\" . $sd_subfolder . "\\Version.txt" ||
	   !-e $sd_path_source . "\\" . $sd_subfolder . "\\Date.txt")
	{
		# Declare image file variable used to store full path to ISO, IMG, MDF, or CDI.
		my $image_file;

		# Iterate through entire subfolder until target image file is found.
		foreach(@sd_subfolder_files)
		{
			if($_ =~ /\.(cdi|mdf|img|iso)$/i)
			{
				$image_file = $_;

				last;
			}
		}

		# Search for start of IP.BIN in any valid disc image file.
		my $offset_found = find_ip_bin_start(@sd_subfolder_files);

		# If no metadata header was found, use defaults while being sure to honor any existing metadata
		# text files provided in the folder.
		if($offset_found eq "")
		{
			# Use folder name as game name if not defined by "Name.txt" (i.e., variable would be been
			# previously defined).
			$game_name = $sd_subfolder if($game_name eq "");

			# Store key for optional folder path.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt")
			{
				# Read folder path from text file.
				my $folder = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt");
				
				# Remove trailing/leading whitespace and normalize forward slashes.
				$folder =~ s/^\s+|\s+$//g;
				$folder =~ s/^\/*/\//;
				$folder =~ s/\/*$/\//;

				# Prepend virtual folder path to game name.
				$game_name = $folder . $game_name;
			}

			$metadata{$game_name}->{'Title'} = $game_name;

			# Store disc number from "Disc.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt")
			{
				$metadata{$game_name}->{'Disc'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt");
				$metadata{$game_name}->{'Disc'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, use default.
			else
			{
				$metadata{$game_name}->{'Disc'} = "1/1";

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt", $metadata{$game_name}->{'Disc'});
			}

			# Store region from "Region.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Region.txt")
			{
				$metadata{$game_name}->{'Region'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Region.txt");
				$metadata{$game_name}->{'Region'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, use default.
			else
			{
				$metadata{$game_name}->{'Region'} = "NA";

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Region.txt", $metadata{$game_name}->{'Region'});
			}

			# Store version from "Version.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Version.txt")
			{
				$metadata{$game_name}->{'Version'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Version.txt");
				$metadata{$game_name}->{'Version'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, use default.
			else
			{
				$metadata{$game_name}->{'Version'} = "NA";

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Version.txt", $metadata{$game_name}->{'Version'});
			}

			# Store date from "Date.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Date.txt")
			{
				$metadata{$game_name}->{'Date'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Date.txt");
				$metadata{$game_name}->{'Date'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, use default.
			else
			{
				$metadata{$game_name}->{'Date'} = "NA";

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Date.txt", $metadata{$game_name}->{'Date'});
			}
		}
		# Extract metadata from header.
		else
		{
			# Extract and store game name if original folder did not contain "Name.txt" and it
			# only had a numbered folder.
			if($game_name eq "")
			{
				$game_name = decode('ASCII', pack('H*', read_bytes_at_offset($image_file, 112, $offset_found + 96)));
				$game_name =~ s/^\s+|\s+$//g;

				# Write previously missing "Name.txt" file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Name.txt", $game_name);

				# Store key for optional folder path.
				if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt")
				{
					# Read folder path from text file.
					my $folder = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt");
					
					# Remove trailing/leading whitespace and normalize forward slashes.
					$folder =~ s/^\s+|\s+$//g;
					$folder =~ s/^\/*/\//;
					$folder =~ s/\/*$/\//;

					# Prepend virtual folder path to game name.
					$game_name = $folder . $game_name;
				}
			}
			# Otherwise, just look for and store optional folder path key.
			else
			{
				# Store key for optional folder path.
				if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt")
				{
					# Read folder path from text file.
					my $folder = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt");
					
					# Remove trailing/leading whitespace and normalize forward slashes.
					$folder =~ s/^\s+|\s+$//g;
					$folder =~ s/^\/*/\//;
					$folder =~ s/\/*$/\//;

					# Prepend virtual folder path to game name.
					$game_name = $folder . $game_name;
				}
			}

			# Store game name.
			$metadata{$game_name}->{'Title'} = $game_name;

			# Store disc number from "Disc.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt")
			{
				$metadata{$game_name}->{'Disc'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt");
				$metadata{$game_name}->{'Disc'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, extract from header.
			else
			{
				$metadata{$game_name}->{'Disc'} = decode('ASCII', pack('H*', read_bytes_at_offset($image_file, 8, $offset_found + 56)));
				$metadata{$game_name}->{'Disc'} =~ s/.*?CD-//;
				$metadata{$game_name}->{'Disc'} =~ s/^\s+|\s+$//g;
				
				# Perform fixes for incorrectly formatted disc numbers.
				$metadata{$game_name}->{'Disc'} = "1/1" if($metadata{$game_name}->{'Disc'} eq "");
				$metadata{$game_name}->{'Disc'} = "1/1" if($metadata{$game_name}->{'Disc'} =~ /CART/);

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt", $metadata{$game_name}->{'Disc'});
			}

			# Store region from "Region.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Region.txt")
			{
				$metadata{$game_name}->{'Region'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Region.txt");
				$metadata{$game_name}->{'Region'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, extract from header.
			else
			{
				$metadata{$game_name}->{'Region'} = decode('ASCII', pack('H*', read_bytes_at_offset($image_file, 16, $offset_found + 64)));
				$metadata{$game_name}->{'Region'} =~ s/^\s+|\s+$//g;

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Region.txt", $metadata{$game_name}->{'Region'});
			}

			# Store version from "Version.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Version.txt")
			{
				$metadata{$game_name}->{'Version'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Version.txt");
				$metadata{$game_name}->{'Version'} =~ s/^\s+|\s+$//g;
				$metadata{$game_name}->{'Version'} =~ s/.*?V//;
			}
			# Otherwise, extract from header.
			else
			{
				$metadata{$game_name}->{'Version'} = decode('ASCII', pack('H*', read_bytes_at_offset($image_file, 8, $offset_found + 40)));
				$metadata{$game_name}->{'Version'} =~ s/^\s+|\s+$//g;
				$metadata{$game_name}->{'Version'} =~ s/.*?V//;

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Version.txt", $metadata{$game_name}->{'Version'});
			}

			# Store date from "Date.txt" if it exists.
			if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Date.txt")
			{
				$metadata{$game_name}->{'Date'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Date.txt");
				$metadata{$game_name}->{'Date'} =~ s/^\s+|\s+$//g;
			}
			# Otherwise, extract from header.
			else
			{
				$metadata{$game_name}->{'Date'} = decode('ASCII', pack('H*', read_bytes_at_offset($image_file, 16, $offset_found + 48)));
				$metadata{$game_name}->{'Date'} = substr($metadata{$game_name}->{'Date'}, 0, 8);
				$metadata{$game_name}->{'Date'} =~ s/^\s+|\s+$//g;

				# Write metadata text file.
				write_file($sd_path_source . "\\" . $sd_subfolder . "\\Date.txt", $metadata{$game_name}->{'Date'});
			}
		}
	}
	# Otherwise, store metadata in hash.
	else
	{
		# Store key for optional folder path.
		if(-e $sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt")
		{
			# Read folder path from text file.
			my $folder = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Folder.txt");
			
			# Remove trailing/leading whitespace and normalize forward slashes.
			$folder =~ s/^\s+|\s+$//g;
			$folder =~ s/^\/*/\//;
			$folder =~ s/\/*$/\//;

			# Prepend virtual folder path to game name.
			$game_name = $folder . $game_name;
		}

		# Store game name.
		$metadata{$game_name}->{'Title'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Name.txt");
		$metadata{$game_name}->{'Title'} =~ s/^\s+|\s+$//g;

		# Store disc number.
		$metadata{$game_name}->{'Disc'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Disc.txt");
		$metadata{$game_name}->{'Disc'} =~ s/^\s+|\s+$//g;

		# Store publish date.
		$metadata{$game_name}->{'Date'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Date.txt");
		$metadata{$game_name}->{'Date'} =~ s/^\s+|\s+$//g;

		# Store region flags.
		$metadata{$game_name}->{'Region'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Region.txt");
		$metadata{$game_name}->{'Region'} =~ s/^\s+|\s+$//g;

		# Store build version.
		$metadata{$game_name}->{'Version'} = read_file($sd_path_source . "\\" . $sd_subfolder . "\\Version.txt");
		$metadata{$game_name}->{'Version'} =~ s/^\s+|\s+$//g;
	}

	# Add game to hash.
	$game_list{$game_name} = $sd_subfolder;

	# Increase detected game count by one.
	$game_count_found ++;

	# For purposes of FAT sorting, create temporary folder for game.
	mkdir($sd_path_source . "\\orbital_organizer_temp\\" . $sd_subfolder);
	
	# Open game folder for reading.
	opendir(my $game_folder_handler, $sd_path_source . "\\" . $sd_subfolder);

	# Iterate through contents of game folder.
	foreach my $game_folder_file (readdir($game_folder_handler))
	{
		# Move each file into temporary folder.
		rename($sd_path_source . "\\" . $sd_subfolder . "\\" . $game_folder_file,
			   $sd_path_source . "\\orbital_organizer_temp\\" . $sd_subfolder . "\\" . $game_folder_file);
	}

	# Close game folder.
	closedir($game_folder_handler);

	# Remove original game folder.
	rmdir($sd_path_source . "\\" . $sd_subfolder);
}

# Close SD card path.
closedir($sd_path_source_handler);

# No games found on target SD card.
if(!$game_count_found)
{
	print "No disc image(s) detected on SD card.\n\n";
	print "Press Enter to exit...\n";
	<STDIN>;

	exit;
}

# Prompt before continuing.
print $game_count_found . " disc image(s) found on SD card.\n\n";

# Sleep for three seconds before proceeding.
sleep(3);

# Iterate through each key in game list hash, processing each folder move/rename while also
# ignoring "[UNIQUE]" tags for duplicate entries.
foreach my $game_name (
	sort {
		(my $left  = $a) =~ s/\s*\[UNIQUE-[^\]]+\]//i;
		(my $right = $b) =~ s/\s*\[UNIQUE-[^\]]+\]//i;
		lc($left) cmp lc($right)
	}
	keys %game_list
)
{
	# Increase game count by one.
	$game_count ++;

	# Generate game folder's new name.
	my $sd_subfolder_new = $game_count;
	
	if($game_count < 10)
	{
		$sd_subfolder_new = "0" . $sd_subfolder_new;
	}
	
	# For display purposes, remove unique ID from game name and display disc number in a
	# neater format.
	my $game_name_display = ($game_name =~ s/\s*\[UNIQUE-[^\]]+\]//r) =~ s/\/Disc/ - Disc/r;

	# Status message.
	print "  -> Folder " . $sd_subfolder_new . " ";

	if($game_list{$game_name} eq $sd_subfolder_new)
	{
		print "(unchanged: ";
	}
	elsif($game_list{$game_name} ne $game_name && $game_list{$game_name} =~ /^\d+$/)
	{
		print "(previously " . $game_list{$game_name} . ": ";
	}
	else
	{
		print "(new: ";
	}

	print $game_name_display . ")\n";
	
	# Add folder name entry to metadata hash for current game, used later to rebuild RMENU.
	$metadata{$game_name}->{'Folder'} = $sd_subfolder_new;

	# Create game folder based on new sorted name.
	mkdir($sd_path_source . "\\" . $sd_subfolder_new);
	
	# Open temporary game folder for reading.
	opendir(my $game_folder_handler, $sd_path_source . "\\orbital_organizer_temp\\" . $game_list{$game_name});

	# Iterate through contents of temporary game folder.
	foreach my $game_folder_file (readdir($game_folder_handler))
	{
		# Move each file back from temporay game folder.
		rename($sd_path_source . "\\orbital_organizer_temp\\" . $game_list{$game_name} . "\\" . $game_folder_file,
			   $sd_path_source . "\\" . $sd_subfolder_new . "\\" . $game_folder_file);
	}

	# Check for custom Product ID metadata file.
	if(-e $sd_path_source . "\\" . $sd_subfolder_new . "\\ProductID.txt")
	{
		# Store list of all files in subfolder.
		my @sd_subfolder_files = folder_list($sd_path_source . "\\" . $sd_subfolder_new);

		# Search for start of IP.BIN in any valid disc image file.
		my $offset_found = find_ip_bin_start(@sd_subfolder_files);

		# IP.BIN found.
		if($offset_found ne "")
		{
			# Store product ID.
			my $product_id = read_file($sd_path_source . "\\" . $sd_subfolder_new . "\\ProductID.txt");
			$product_id =~ s/^\s+|\s+$//g;

			# Truncate or pad Product ID to 10 characters.
			$product_id = substr(sprintf("%-10s", $product_id), 0, 10);

			# Convert to hex.
			my $product_id_hex = unpack("H*", $product_id);

			# Declare image file variable used to store full path to ISO, IMG, MDF, or CDI.
			my $image_file;

			# Iterate through entire subfolder until target image file is found.
			foreach(@sd_subfolder_files)
			{
				if($_ =~ /\.(cdi|mdf|img|iso)$/i)
				{
					$image_file = $_;

					last;
				}
			}

			# Patch disc image with new product ID.
			patch_bytes($image_file, $product_id_hex, $offset_found + 32);

			# Remove custom product ID metadata file.
			unlink($sd_path_source . "\\" . $sd_subfolder_new . "\\ProductID.txt");

			# Status message.
			for(1 .. length("  -> Folder " . $sd_subfolder_new . " "))
			{
				print " ";
			}

			print "(product ID patched: " . $product_id . ")\n";
		}
	}

	# Close game folder.
	closedir($game_folder_handler);

	# Remove temporary game folder.
	rmdir($sd_path_source . "\\orbital_organizer_temp\\" . $game_list{$game_name});
}

# Remove temporary folder.
rmdir($sd_path_source . "\\orbital_organizer_temp\\");

# Status message.
print "\n" . $game_count_found . " disc image(s) processed!\n\n";

# If invalid game folders were found, list them along with a message.
if($invalid_count)
{
	print $invalid_count . " invalid folder(s) found. To avoid naming conflicts,\n";
	print "they've been renamed to:\n";

	for(1 .. $invalid_count)
	{
		print "   -> INVALID_" . $_ . "\n";
	}

	print "\n";
}

# RMENU's "mkisofs.exe" utility is present, proceed with rebuilding RMENU.
if(-e $sd_path_source . "\\01\\BIN\\mkisofs.exe")
{
	# Status message.
	print "Rebuidling RMENU...\n\n";

	# Begin constructing "LIST.INI" file contents.
	my $list_file_contents = "01.title=RMENU\n01.disc=1/1\n01.region=JTUE\n01.version=V0.2.0\n01.date=20170228\n";

	# Begin constructing separate game list, which will be written to root of SD card for user
	# convenience.
	my $game_list = "01 - RMENU\n";

	# Initialize list count to one.
	my $list_count = 1;

	# Iterate through metadata hash, using folder number for sorting.
	foreach my $game_name (sort { $metadata{$a}->{'Folder'} <=> $metadata{$b}->{'Folder'} } keys %metadata)
	{
		# Increase list count by one.
		$list_count ++;

		# Store clean version of game name (i.e., stripped of disc number) and, if applicable,
		# extract and store disc number.
		my ($game_name_clean, $game_disc_number) = $game_name =~ /^(.*?)(?:\s*[\/\-]\s*Disc\s+(\d+))?$/;

		# Additionally, remove migration tag from clean version of game name.
		$game_name_clean =~ s/\s*\[UNIQUE-[^\]]+\]//;

		# Continue adding to separate game list, which will be written to root of SD card.
		$game_list .= sprintf("%02d", $list_count) . " - " . $game_name_clean;

		if($metadata{$game_name}->{'Disc'} ne "1/1")
		{
			$game_list .= " (Disc " . $metadata{$game_name}->{'Disc'} . ")";
		}

		$game_list .= "\n";

		# Append current game's metadata, with special treatment for multi-disc games if user
		# specified in prompt.
		if($multidisc_subfolders && defined $game_disc_number)
		{
			# Prepend forward-slash to game name path if one isn't already present.
			$game_name_clean = "/" . $game_name_clean unless($game_name_clean =~ /^\//);

			$list_file_contents .= sprintf("%02d", $list_count) . ".title=" . $game_name_clean . "/Disc " . $game_disc_number . "\n";
		}
		# Game is not multi-disc.
		else
		{
			$list_file_contents .= sprintf("%02d", $list_count) . ".title=" . $game_name_clean . "\n";
		}

		# Append the rest of the current game's metadata.
		$list_file_contents .= sprintf("%02d", $list_count) . ".disc=" . $metadata{$game_name}->{'Disc'} . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".region=" . $metadata{$game_name}->{'Region'} . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".date=" . $metadata{$game_name}->{'Date'} . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".version=";	

		$list_file_contents .= "V" if($metadata{$game_name}->{'Version'} ne "NA");

		$list_file_contents .= $metadata{$game_name}->{'Version'} . "\n";
	}

	# Write "LIST.INI" file.
	write_file($sd_path_source . "\\01\\BIN\\RMENU\\LIST.INI", $list_file_contents);

	# Write separate game list to root of SD card for user convenience.
	write_file($sd_path_source . "\\GameList.txt", $game_list);

	# Change to "01" folder and build RMENU ISO.
	chdir($sd_path_source . "\\01\\");
	system("BIN\\mkisofs.exe -quiet -sysid \"SEGA SATURN\" -volid \"RMENU\" -volset \"RMENU\" -publisher \"SEGA ENTERPRISES, LTD.\" -preparer \"SEGA ENTERPRISES, LTD.\" -appid \"RMENU\" -abstract \"ABS.TXT\" -copyright \"CPY.TXT\" -biblio \"BIB.TXT\" -generic-boot BIN\\RMENU\\IP.BIN -full-iso9660-filenames -o RMENU.iso BIN\\RMENU");

	# Status message.
	print "RMENU rebuild complete!\n\n";

	# RmenuKai was detected, but an additional RMENU entry was found on the SD card, so treat it
	# like an instance of legacy
	if($rmenukai_detected == 1 && grep { /rmenu/i && $metadata{$_}{'Folder'} ne '01' } keys %metadata)
	{
		# Status message.
		print "In addition to RmenuKai, a second instance of RMENU was detected on SD card.\n";
		print "It's assumed this instance is present to allow legacy RMENU to exist alongside\n";
		print "RmenuKai. Would you like to update this instance of RMENU with the latest game\n";
		print "list? (Y/N) ";

		# Prompt for updating secondary legacy instance of RMENU's game list.
		my $rmenu_legacy_prompt;

		while($rmenu_legacy_prompt ne "Y" && $rmenu_legacy_prompt ne "N")
		{
			chop($rmenu_legacy_prompt = uc(<STDIN>));
		}

		# Update game list.
		if($rmenu_legacy_prompt eq "Y")
		{
			# Store folder name for secondary instance of RMENU.
			my ($rmenu_legacy_folder) = map { $metadata{$_}{'Folder'} }
										grep { /rmenu/i && $metadata{$_}{'Folder'} ne '01' }
										keys %metadata;
			
			# Status message.
			print "\nLegacy RMENU detected in folder \"" . $rmenu_legacy_folder . "\".\n\n";
			print "Rebuidling secondary RMENU...\n\n";

			# RMENU's "mkisofs.exe" utility is present, proceed with rebuilding RMENU.
			if(-e $sd_path_source . "\\" . $rmenu_legacy_folder . "\\BIN\\mkisofs.exe")
			{
				# Copy newly generated LIST.INI file.
				copy($sd_path_source . "\\01\\BIN\\RMENU\\LIST.INI",
					 $sd_path_source . "\\" . $rmenu_legacy_folder . "\\BIN\\RMENU\\");

				# Change to appropriate folder.
				chdir($sd_path_source . "\\" . $rmenu_legacy_folder . "\\");
				
				# Rebuild RMENU ISO.
				system("BIN\\mkisofs.exe -quiet -sysid \"SEGA SATURN\" -volid \"RMENU\" -volset \"RMENU\" -publisher \"SEGA ENTERPRISES, LTD.\" -preparer \"SEGA ENTERPRISES, LTD.\" -appid \"RMENU\" -abstract \"ABS.TXT\" -copyright \"CPY.TXT\" -biblio \"BIB.TXT\" -generic-boot BIN\\RMENU\\IP.BIN -full-iso9660-filenames -o RMENU.iso BIN\\RMENU");
			
				# Status message.
				print "Secondary RMENU rebuild complete!\n\n";
			}
			# Otherwise, return an error.
			else
			{
				print "The \"mkisofs.exe\" utility was not found at the following path:\n\n";
				print $sd_path_source . "\\" . $rmenu_legacy_folder . "\\BIN\\mkisofs.exe\n\n";
				print "Without all RMENU files in folder \"" . $rmenu_legacy_folder . "\" on the SD card, no menu data can be\n";
				print "rebuilt. Correct this error and then run this utility again.\n\n";
			}
		}
	}

	# Status message.
	print "A list of disc images can be found in the \"GameList.txt\" file in the root of\n";
	print "the SD card.\n\n";
}
# Otherwise, return an error.
else
{
	print "The \"mkisofs.exe\" utility was not found at the following path:\n\n";
	print $sd_path_source . "\\01\\BIN\\mkisofs.exe\n\n";
	print "Without RMENU in folder \"01\" on the SD card, no menu data can be\n";
	print "rebuilt. Correct this error and then run this utility again.\n\n";
}

# Final status message.
print "Press Enter to exit...\n";
<STDIN>;

# Subroutine to read a specified file.
#
# 1st parameter - File to read.
sub read_file
{
	my $input_file = $_[0];

	open(my $filehandle, '<:encoding(UTF-8)', $input_file) or die $!;
	local $/ = undef;
	my $all = <$filehandle>;
	close($filehandle);

	return $all;
}

# Subroutine to write UTF-8-encoded string data to a file.
#
# 1st parameter - Full path of file to write.
# 2nd parameter - File content to write.
sub write_file
{
	my $output_file = $_[0];
	my $content = $_[1];

	open(my $filehandle, '>:encoding(UTF-8)', $output_file) or die $!;
	print $filehandle $content;
	close($filehandle);
}

# Subroutine to read a specified number of bytes, starting at a specific offset (in decimal
# format), of a specified file, returning hexadecimal representation of data.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Number of bytes to read.
# 3rd parameter - Offset at which to read.
sub read_bytes_at_offset
{
	my $input_file = $_[0];
	my $byte_count = $_[1];
	my $read_offset = $_[2];

	if((stat $input_file)[7] < $read_offset + $byte_count)
	{
		die "Offset for read_bytes_at_offset is outside of valid range.\n";
	}

	open(my $filehandle, '<:raw', $input_file) or die $!;
	seek($filehandle, $read_offset, 0);
	read($filehandle, my $bytes, $byte_count);
	close($filehandle);
	
	return unpack("H*", $bytes);
}

# Subroutine to write a sequence of hexadecimal values at a specified offset (in decimal format) into
# a specified file, as to patch the existing data at that offset.
#
# 1st parameter - Full path of file in which to insert patch data.
# 2nd parameter - Hexadecimal representation of data to be inserted.
# 3rd parameter - Offset at which to patch.
sub patch_bytes
{
	my $output_file = $_[0];
	(my $hex_data = $_[1]) =~ s/\s+//g;
	my @hex_data_array = split(//, $hex_data);
	my $patch_offset = $_[2];

	if((stat $output_file)[7] < $patch_offset + (scalar(@hex_data_array) / 2))
	{
		die "Offset for patch_bytes is outside of valid range.\n";
	}

	open(my $filehandle, '+<:raw', $output_file) or die $!;
	binmode($filehandle);
	seek($filehandle, $patch_offset, 0);

	for(my $i = 0; $i < scalar(@hex_data_array); $i += 2)
	{
		my($high, $low) = @hex_data_array[$i, $i + 1];
		print $filehandle pack("H*", $high . $low);
	}

	close($filehandle);
}

# Subroutine to return true if a specified byte pattern is found in a specified file.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Arrayref of byte values (e.g., [0x53, 0x45, ...]).
sub find_bytes
{
	my $input_file = $_[0];
	my $byte_array = $_[1];

	my $target_bytes = pack('C*', @$byte_array);

	open(my $filehandle, '<:raw', $input_file) or die $!;

	my $buffer;
	my $chunk_size = 1024 * 1024;

	while(read($filehandle, $buffer, $chunk_size))
	{
		return 1 if(index($buffer, $target_bytes) != -1);
	}

	close($filehandle);

	return 0;
}

# Subroutine to identify the starting position of IP.BIN in a SEGA Saturn disc image.
#
# 1st parameter - Array containing list of full file paths to check.
sub find_ip_bin_start
{
	# Define input parameters.
	my @sd_subfolder_files = @_;

	# Define beginning of IP.BIN header for seeking out metadata.
	my @pattern = (0x53, 0x45, 0x47, 0x41, 0x20, 0x53, 0x45, 0x47, 0x41, 0x53, 0x41, 0x54, 0x55, 0x52, 0x4E, 0x20);
	my $pattern = pack('C*', @pattern);

	# Declare image file variable used to store full path to ISO, IMG, MDF, or CDI.
	my $image_file;

	# Iterate through entire subfolder until target image file is found.
	foreach(@sd_subfolder_files)
	{
		if($_ =~ /\.(cdi|mdf|img|iso)$/i)
		{
			$image_file = $_;

			last;
		}
	}

	# Open image file.
	open(my $filehandle, '<:raw', $image_file) or die $!;

	# Set buffer size and other defaults.
	my $buffer_size = 1024 * 1024;
	my $buffer;
	my $offset = 0;
	my $offset_found;
	my $pattern_length = length($pattern);

	# Seek through image file until pattern is found.
	while(read($filehandle, $buffer, $buffer_size))
	{
		my $pos = index($buffer, $pattern);
		
		if($pos >= 0)
		{
			$offset_found = $offset + $pos;
			
			last;
		}

		$offset += $buffer_size - $pattern_length + 1;

		seek($filehandle, $offset, SEEK_SET);
	}

	# Close image file.
	close($filehandle);

	# Return found offset, or empty variable.
	return $offset_found;
}

# Subrouting to return an array of all files in a specified folder.
#
# 1st parameter - Full path of folder to list.
sub folder_list
{
	my $folder = $_[0];

	opendir(my $folder_handle, $folder) or die $!;
	my @files = grep { !/^\./ && -f "$folder\\$_" } readdir($folder_handle);
	closedir($folder_handle);

	return map { "$folder\\$_" } @files;
}