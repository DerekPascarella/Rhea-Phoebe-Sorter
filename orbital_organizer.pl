#!/usr/bin/perl
#
# Rhea/Phoebe Sorter v1.0
# Written by Derek Pascarella (ateam)
#
# SD card sorter for the Sega Saturn ODEs Rhea and Phoebe.

# Include necessary modules.
use utf8;
use strict;
use Encode;
use File::Find::Rule;
use Fcntl 'SEEK_SET';

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
	print "\nRhea/Phoebe Sorter v1.0\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: No SD card path specified.\n\n";
	print "Example Usage: orbital_organizer H:\\\n\n";
	print "Press Enter to exit.\n";
	<STDIN>;

	exit;
}
# SD card path is unreadable.
elsif(!-R $sd_path_source)
{
	print "\nRhea/Phoebe Sorter v1.0\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: Specified SD card path is unreadable.\n\n";
	print "Example Usage: orbital_organizer H:\\\n\n";
	print "Press Enter to exit.\n";
	<STDIN>;

	exit;
}

# Status message.
print "\nRhea/Phoebe Sorter v1.0\n";
print "Written by Derek Pascarella (ateam)\n\n";
print "Reading SD card...\n\n";

# Create temporary folder for purposes of sorting FAT filesystem.
mkdir($sd_path_source . "/orbital_organizer_temp/");

# Open SD card path for reading.
opendir(my $sd_path_source_handler, $sd_path_source);

# Iterate through contents of SD card in alphanumeric order.
foreach my $sd_subfolder (sort { 'numeric'; $a <=> $b }  readdir($sd_path_source_handler))
{
	# Skip folders starting with a period.
	next if($sd_subfolder =~ /^\./);
	
	# Skip all non-folders (e.g., files like "Rhea.ini" or "Phoebe.ini").
	next if(!-d $sd_path_source . "/" . $sd_subfolder);
	
	# Skip folder "01" containing GDMenu.
	next if($sd_subfolder eq "01");

	# Ignore Windows system folder.
	next if($sd_subfolder eq "System Volume Information");

	# Skip Recycling Bin folder.
	next if($sd_subfolder =~ /RECYCLE\.BIN/);

	# Store list of all files in subfolder.
	my $sd_subfolder_rule = File::Find::Rule->new;
	$sd_subfolder_rule->file;
	$sd_subfolder_rule->maxdepth(1);
	my @sd_subfolder_files = $sd_subfolder_rule->in($sd_path_source . "/" . $sd_subfolder);

	# Set game-found flag to zero.
	my $game_found = 0;

	# Consider folder as storing a game if "Name.txt" is found.
	if(-e $sd_path_source . "/" . $sd_subfolder . "/Name.txt")
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
				$game_found = 1;
			}
		}
	}

	# To prevent folder name conflicts, rename invalid folder for user to process manually.
	if(!$game_found && $sd_subfolder ne "orbital_organizer_temp")
	{
		$invalid_count ++;

		rename($sd_path_source . "/" . $sd_subfolder, $sd_path_source . "/INVALID_" . $invalid_count);
	}

	# If folder contains no game disc image, skip it.
	next if(!$game_found);

	# Declare game name variable.
	my $game_name;

	# Store game name from "Name.txt".
	if(-e $sd_path_source . "/" . $sd_subfolder . "/" . "Name.txt")
	{
		$game_name = &read_file($sd_path_source . "/" . $sd_subfolder . "/" . "Name.txt");
		$game_name =~ s/^\s+|\s+$//g;
	}
	# Store folder name as game name if it's not a numbered folder (e.g., 07).
	elsif($sd_subfolder !~ /^[+-]?\d+(\.\d+)?$/)
	{
		$game_name = $sd_subfolder;
		$game_name =~ s/^\s+|\s+$//g;
		$game_name =~ s/\s+/ /g;

		# Write "Name.txt" file.
		&write_file($sd_path_source . "/" . $sd_subfolder . "/" . "Name.txt", $game_name);
	}

	# If metadata text files don't exist for current game, extract data from image file.
	if(!-e $sd_path_source . "/" . $sd_subfolder . "/Name.txt" || !-e $sd_path_source . "/" . $sd_subfolder . "/Disc.txt" ||
	   !-e $sd_path_source . "/" . $sd_subfolder . "/Region.txt" || !-e $sd_path_source . "/" . $sd_subfolder . "/Version.txt" ||
	   !-e $sd_path_source . "/" . $sd_subfolder . "/Date.txt")
	{
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
			if(my $pos = index($buffer, $pattern))
			{
				if($pos >= 0)
				{
					$offset_found = $offset + $pos;
					
					last;
				}
			}

			$offset += $buffer_size - $pattern_length + 1;
			
			seek($filehandle, $offset, SEEK_SET);
		}

		# Close image file.
		close $filehandle;

		# Use folder name as game name, as well as placeholders for metadata since no valid header
		# was found.
		if($offset_found eq "")
		{
			$game_name = $sd_subfolder;
			$metadata{$game_name}->{'Title'} = $game_name;
			$metadata{$game_name}->{'Disc'} = "1/1";
			$metadata{$game_name}->{'Region'} = "NA";
			$metadata{$game_name}->{'Version'} = "NA";
			$metadata{$game_name}->{'Date'} = "NA";
		}
		# Extract metadata from header.
		else
		{
			# Extract and store game name if original folder did not contain "Name.txt" and it
			# only had a numbered folder.
			if($game_name eq "")
			{
				$game_name = decode('ASCII', pack('H*', &read_bytes_at_offset($image_file, 112, $offset_found + 96)));
				$game_name =~ s/^\s+|\s+$//g;

				# Write previously missing "Name.txt" file.
				&write_file($sd_path_source . "/" . $sd_subfolder . "/" . "Name.txt", $game_name);
			}

			# Store game name.
			$metadata{$game_name}->{'Title'} = $game_name;

			# Extract disc number.
			$metadata{$game_name}->{'Disc'} = decode('ASCII', pack('H*', &read_bytes_at_offset($image_file, 8, $offset_found + 56)));
			$metadata{$game_name}->{'Disc'} =~ s/.*?CD-//;
			$metadata{$game_name}->{'Disc'} =~ s/^\s+|\s+$//g;

			# Extract publish date.
			$metadata{$game_name}->{'Date'} = decode('ASCII', pack('H*', &read_bytes_at_offset($image_file, 16, $offset_found + 48)));
			$metadata{$game_name}->{'Date'} =~ s/CD-.*//;
			$metadata{$game_name}->{'Date'} =~ s/^\s+|\s+$//g;

			# Extract region flags.
			$metadata{$game_name}->{'Region'} = decode('ASCII', pack('H*', &read_bytes_at_offset($image_file, 16, $offset_found + 64)));
			$metadata{$game_name}->{'Region'} =~ s/^\s+|\s+$//g;

			# Extract build version.
			$metadata{$game_name}->{'Version'} = decode('ASCII', pack('H*', &read_bytes_at_offset($image_file, 8, $offset_found + 40)));
			
			if($metadata{$game_name}->{'Version'} =~ /V/)
			{
				$metadata{$game_name}->{'Version'} =~ s/.*?V//;
				$metadata{$game_name}->{'Version'} =~ s/^\s+|\s+$//g;
			}
			else
			{
				$metadata{$game_name}->{'Version'} = "NA";
			}
		}

		# Write metadata text files.
		&write_file($sd_path_source . "/" . $sd_subfolder . "/" . "Disc.txt", $metadata{$game_name}->{'Disc'});
		&write_file($sd_path_source . "/" . $sd_subfolder . "/" . "Date.txt", $metadata{$game_name}->{'Date'});
		&write_file($sd_path_source . "/" . $sd_subfolder . "/" . "Region.txt", $metadata{$game_name}->{'Region'});
		&write_file($sd_path_source . "/" . $sd_subfolder . "/" . "Version.txt", $metadata{$game_name}->{'Version'});
	}
	# Otherwise, store metadata in hash.
	else
	{
		# Store game name.
		$metadata{$game_name}->{'Title'} = &read_file($sd_path_source . "/" . $sd_subfolder . "/" . "Name.txt");
		$metadata{$game_name}->{'Title'} =~ s/^\s+|\s+$//g;

		# Store disc number.
		$metadata{$game_name}->{'Disc'} = &read_file($sd_path_source . "/" . $sd_subfolder . "/" . "Disc.txt");
		$metadata{$game_name}->{'Disc'} =~ s/^\s+|\s+$//g;

		# Store publish date.
		$metadata{$game_name}->{'Date'} = &read_file($sd_path_source . "/" . $sd_subfolder . "/" . "Date.txt");
		$metadata{$game_name}->{'Date'} =~ s/^\s+|\s+$//g;

		# Store region flags.
		$metadata{$game_name}->{'Region'} = &read_file($sd_path_source . "/" . $sd_subfolder . "/" . "Region.txt");
		$metadata{$game_name}->{'Region'} =~ s/^\s+|\s+$//g;

		# Store build version.
		$metadata{$game_name}->{'Version'} = &read_file($sd_path_source . "/" . $sd_subfolder . "/" . "Version.txt");
		$metadata{$game_name}->{'Version'} =~ s/^\s+|\s+$//g;
	}

	# Add game to hash.
	$game_list{$game_name} = $sd_subfolder;

	# Increase detected game count by one.
	$game_count_found ++;

	# For purposes of FAT sorting, create temporary folder for game.
	mkdir($sd_path_source . "/orbital_organizer_temp/" . $sd_subfolder);
	
	# Open game folder for reading.
	opendir(my $game_folder_handler, $sd_path_source . "/" . $sd_subfolder);

	# Iterate through contents of game folder.
	foreach my $game_folder_file (readdir($game_folder_handler))
	{
		# Move each file into temporary folder.
		rename($sd_path_source . "/" . $sd_subfolder . "/" . $game_folder_file,
		       $sd_path_source . "/orbital_organizer_temp/" . $sd_subfolder . "/" . $game_folder_file);
	}

	# Close game folder.
	closedir($game_folder_handler);

	# Remove original game folder.
	rmdir($sd_path_source . "/" . $sd_subfolder);
}

# Close SD card path.
closedir($sd_path_source_handler);

# No games found on target SD card.
if(!$game_count_found)
{
	print "No games detected on SD card.\n\n";
	print "Press Enter to exit.\n";
	<STDIN>;

	exit;
}

# Prompt before continuing.
print $game_count_found . " game(s) found on SD card.\n\n";

# Sleep for three seconds before proceeding.
sleep(3);

# Iterate through each key in game list hash, processing each folder move/rename.
foreach my $game_name (sort {lc $a cmp lc $b} keys %game_list)
{
	# Increase game count by one.
	$game_count ++;

	# Generate game folder's new name.
	my $sd_subfolder_new = $game_count;
	
	if($game_count < 10)
	{
		$sd_subfolder_new = "0" . $sd_subfolder_new;
	}
	
	# Print status message.
	print "[" . $game_name . "]\n";
	print "   -> Moved \"" . $game_list{$game_name} . "\" -> \"" . $sd_subfolder_new . "\"\n\n";
	
	# Add folder name entry to metadata hash for current game, used later to rebuild RMENU.
	$metadata{$game_name}->{'Folder'} = $sd_subfolder_new;

	# Create game folder based on new sorted name.
	mkdir($sd_path_source . "/" . $sd_subfolder_new);
	
	# Open temporary game folder for reading.
	opendir(my $game_folder_handler, $sd_path_source . "/orbital_organizer_temp/" . $game_list{$game_name});

	# Iterate through contents of temporary game folder.
	foreach my $game_folder_file (readdir($game_folder_handler))
	{
		# Move each file back from temporay game folder.
		rename($sd_path_source . "/orbital_organizer_temp/" . $game_list{$game_name} . "/" . $game_folder_file,
		       $sd_path_source . "/" . $sd_subfolder_new . "/" . $game_folder_file);
	}

	# Close game folder.
	closedir($game_folder_handler);

	# Remove temporary game folder.
	rmdir($sd_path_source . "/orbital_organizer_temp/" . $game_list{$game_name});
}

# Remove temporary folder.
rmdir($sd_path_source . "/orbital_organizer_temp/");

# Print status message.
print $game_count_found . " game(s) processed!\n\n";

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
if(-e $sd_path_source . "/01/BIN/mkisofs.exe")
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

		# For multi-disc games, remove " - Disc X" for purposes of writing the menu list, as RMENU
		# already automatically displays disc numbers.
		my $game_name_clean = $game_name =~ s/ - Disc \d+//r;

		# Continue adding to separate game list, which will be written to root of SD card.
		$game_list .= sprintf("%02d", $list_count) . " - " . $game_name_clean;

		if($metadata{$game_name}->{'Disc'} ne "1/1")
		{
			$game_list .= " (Disc " . $metadata{$game_name}->{'Disc'} . ")";
		}

		$game_list .= "\n";

		# Append current game's metadata.
		$list_file_contents .= sprintf("%02d", $list_count) . ".title=" . $game_name_clean . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".disc=" . $metadata{$game_name}->{'Disc'} . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".region=" . $metadata{$game_name}->{'Region'} . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".date=" . $metadata{$game_name}->{'Date'} . "\n";
		$list_file_contents .= sprintf("%02d", $list_count) . ".version=";	

		if($metadata{$game_name}->{'Version'} ne "NA")
		{
			$list_file_contents .= "V";
		}

		$list_file_contents .= $metadata{$game_name}->{'Version'} . "\n";
	}

	# Write "LIST.INI" file.
	&write_file($sd_path_source . "/01/BIN/RMENU/LIST.INI", $list_file_contents);

	# Write separate game list to root of SD card for user convenience.
	&write_file($sd_path_source . "/Game_List.txt", $game_list);

	# Change to "01" folder and build RMENU iso.
	chdir($sd_path_source . "/01/");
	system("BIN\\mkisofs.exe -quiet -sysid \"SEGA SATURN\" -volid \"RMENU\" -volset \"RMENU\" -publisher \"SEGA ENTERPRISES, LTD.\" -preparer \"SEGA ENTERPRISES, LTD.\" -appid \"RMENU\" -abstract \"ABS.TXT\" -copyright \"CPY.TXT\" -biblio \"BIB.TXT\" -generic-boot BIN\\RMENU\\IP.BIN -full-iso9660-filenames -o RMENU.iso BIN\\RMENU");

	# Status message.
	print "RMENU rebuild complete!\n\n";
	print "A list of games can be found in the \"Game_List.txt\" file in the root of the SD card.\n\n";
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
print "Press Enter to exit.\n";
<STDIN>;

# Subroutine to read a specified file.
#
# 1st parameter - File to read.
sub read_file
{
	my $input_file = $_[0];

	open my $filehandle, '<:encoding(UTF-8)', $input_file or die $!;
	local $/ = undef;
	my $all = <$filehandle>;
	close $filehandle;

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

	open my $filehandle, '>:encoding(UTF-8)', $output_file or die $!;
	print $filehandle $content;
	close $filehandle;
}

# Subroutine to read a specified number of bytes, starting at a specific offset (in decimal format), of
# a specified file, returning hexadecimal representation of data.
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

	open my $filehandle, '<:raw', $input_file or die $!;
	seek $filehandle, $read_offset, 0;
	read $filehandle, my $bytes, $byte_count;
	close $filehandle;
	
	return unpack 'H*', $bytes;
}
