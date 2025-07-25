#!/usr/bin/perl
#
# Menu Migrator for Rhea/Phoebe Sorter v1.8
# Written by Derek Pascarella (ateam)
#
# SD card sorter for the Sega Saturn ODEs Rhea and Phoebe.

# Include necessary modules.
use strict;
use Win32 ();
use Errno ("EACCES", "EBUSY");

# Set version number.
my $version = "1.8";

# Set STDOUT encoding to UTF-8.
binmode(STDOUT, "encoding(UTF-8)");

# Initialize input variables.
my $sd_path_source = $ARGV[0];

# No valid SD card path specified.
if(!-d $sd_path_source || !-e $sd_path_source || $sd_path_source eq "")
{
	print "\nMenu Migrator for Rhea/Phoebe Sorter v" . $version . "\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: No SD card path specified.\n\n";
	print "Example Usage: orbital_shift H:\\\n\n";
	print "Press Enter to exit...\n";

	<STDIN>;

	exit;
}
# SD card path is unreadable.
elsif(!-R $sd_path_source)
{
	print "\nMenu Migrator for Rhea/Phoebe Sorter v" . $version . "\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: Specified SD card path is unreadable.\n\n";
	print "Example Usage: orbital_shift H:\\\n\n";
	print "Press Enter to exit...\n";

	<STDIN>;

	exit;
}
# Pre-existing RMENU list not found on SD card.
elsif(!-e $sd_path_source . "/01/BIN/RMENU/LIST.INI")
{
	print "\nMenu Migrator for Rhea/Phoebe Sorter v" . $version . "\n";
	print "Written by Derek Pascarella (ateam)\n\n";
	print "Error: No pre-existing RMENU list found on SD card.\n\n";
	print "Example Usage: orbital_shift H:\\\n\n";
	print "Press Enter to exit...\n";

	<STDIN>;

	exit;
}

# Status message.
print "\nMenu Migrator for Rhea/Phoebe Sorter v" . $version . "\n";
print "\"The Orbital Shift\"\n";
print "Written by Derek Pascarella (ateam)\n\n";

# Warning message requiring user to press Enter before continuing.
print "WARNING: Before proceeding, ensure that no files or folders on SD card (" . $sd_path_source . ")\n";
print "         are open in File Explorer or any other program. Failure to do so\n";
print "         will result in data corruption!\n\n";
print "Press Enter to continue...\n";

<STDIN>;

# Status message.
print "Reading existing menu data...\n\n";

# Detect presence of RmenuKai for purposes of processing virtual folder paths.
my $rmenukai_detected = 0;

if(-e $sd_path_source . "\\01\\BIN\\RMENU\\0.BIN" && find_bytes($sd_path_source . "\\01\\BIN\\RMENU\\0.BIN", [0x70, 0x73, 0x6B, 0x61, 0x69]))
{
	$rmenukai_detected = 1;

	# Status message.
	print "RmenuKai has been detected on SD card. Virtual folder paths will be honored\n";
	print "during migration process.\n\n";
}

# Initialize hash used to store folder number and game name.
my %game_list;

# Initialize hash used to store preserved virtual folder paths (strictly for status messages).
my %virtual_folders;

# Variables to store the folder number and title temporarily
my ($folder_number, $game_title);

# Iterate through RMENU game list for parsing.
foreach my $line (read_file($sd_path_source . "\\01\\BIN\\RMENU\\LIST.INI"))
{
	# Initialize RmenuKai virtual folder path variable.
	my $virtual_folder_path;

	# Game title found (except "01" folder).
	if($line =~ /^(\d{2,})\.title=(.+)/ && $1 ne "01")
	{
		# Capture the folder number and game title.
		$folder_number = $1;
		$game_title = $2;

		# If RmenuKai was detected and game title starts with a forward slashes, process current
		# game title accounting for virtual folder path.
		if($rmenukai_detected && $game_title =~ /^\//)
		{
			# Remove leading forward slash.
			$game_title =~ s/^\///;
			
			# Split path by forward slash into elements of array.
			my @virtual_folder_parts = split("/", $game_title);

			# Final part of path is a disc number identifier, so remove it from array.
			if($virtual_folder_parts[-1] =~ /^\s*(disc|disk|cd)\s*0*([1-9][0-9]*)\s*$/i)
			{
				pop(@virtual_folder_parts);
			}

			# Store last portion of path as game title.
			$game_title = $virtual_folder_parts[-1];

			# If more than just a base game name remains, treat it as a virtual folder path.
			if(scalar(@virtual_folder_parts) > 1)
			{
				# Construct full virtual folder path.
				$virtual_folder_path = join("/", @virtual_folder_parts[0 .. $#virtual_folder_parts - 1]);

				# Trim leading/trailing forward slashes if somehow still present after processing.
				$virtual_folder_path =~ s/^\///;
				$virtual_folder_path =~ s/\/$//;

				# Write virtual folder path to "Folder.txt" in respective numbered folder.
				write_file($sd_path_source . "\\" . $folder_number . "\\Folder.txt", $virtual_folder_path);

				# Add virtual folder path to hash key.
				$virtual_folders{$folder_number} = $virtual_folder_path;
			}
		}
	}

	# Disc number found.
	if($line =~ /^(\d{2,})\.disc=(\d+)\/(\d+)/ && $1 ne "01")
	{
		# Capture disc number and total number of discs.
		my $disc_number = $2;
		my $total_discs = $3;
		
		# If total discs is more than one, append disc number to the title.
		if($total_discs > 1)
		{
			$game_list{$folder_number} = $game_title . " - Disc " . $disc_number;
		}
		# Otherwise, just store the game title.
		else
		{
			$game_list{$folder_number} = $game_title;
		}
	}
	# Non-standard disc number descriptor found, just store the game title.
	elsif($line =~ /^(\d{2,})\.disc=([^\/]+)/ && $1 ne "01" && $line !~ /^(\d{2,})\.disc=\d+\/\d+/)
	{
		$game_list{$folder_number} = $game_title;
	}
}

# Status message.
print scalar(keys %game_list) . " disc image folder(s) found on SD card.\n\n";

# Sleep for three seconds before proceeding.
sleep(3);

# Status message.
print "Renaming numbered folders...\n\n";

# Sleep for three seconds before proceeding.
sleep(3);

# Iterate through each key in game list hash, processing each folder rename.
foreach my $folder_name (sort {lc $a cmp lc $b} keys %game_list)
{
	# Check for and clean-up illegal file name characters.
	my $original_name;

	if($game_list{$folder_name} =~ /[:<>\/\\\"|?*]/)
	{
		# Backup original game name from RmenuKai.
		$original_name = $game_list{$folder_name};

		# Perform clean up.
		$game_list{$folder_name} =~ s/:/ -/g;
		$game_list{$folder_name} =~ s/</(/g;
		$game_list{$folder_name} =~ s/>/)/g;
		$game_list{$folder_name} =~ s{[\\/]}{-}g;
		$game_list{$folder_name} =~ s/"/'/g;
		$game_list{$folder_name} =~ s/[|?*]//g;

		# Write original disc image title to "Name.txt" in respective folder.
		write_file($sd_path_source . "\\" . $folder_name . "\\Name.txt", $original_name);
	}

	# If folder already exists with the same name, preserve the original name by processing it
	# specially.
	my @random_character_bank = ("A" .. "Z", "0" .. "9");
	my $random_id;

	if(-e $sd_path_source . "\\" . $game_list{$folder_name})
	{
		# If not done already, write original disc image title to "Name.txt" in respective folder.
		if($original_name eq "")
		{
			write_file($sd_path_source . "\\" . $folder_name . "\\Name.txt", $game_list{$folder_name});
		}

		# Generate random six-character ID for duplicate entries.
		$random_id = join("", map { $random_character_bank[int(rand(@random_character_bank))] } 1 .. 6);

		# Append random six-character ID to the end of the game name.
		$game_list{$folder_name} = $game_list{$folder_name} . " [UNIQUE-" . $random_id . "]";
	}

	# Status message.
	print "-> Renamed folder \"" . $folder_name . "\" to \"" . $game_list{$folder_name} . "\"\n";

	if($original_name ne "")
	{
		print "   Original title preserved in \"Name.txt\" file (" . $original_name . ")\n";
	}

	if($random_id ne "")
	{
		print "   Unique ID appended to folder name to avoid duplicate\n";
	}

	# Display additional message about virtual folder path preservation, if applicable.
	if(exists $virtual_folders{$folder_name})
	{
		print "   Original virtual folder path preserved in \"Folder.txt\" file (" . $virtual_folders{$folder_name} . ")\n";
	}

	# Rename folder.
	rename_until_free($sd_path_source . "\\" . $folder_name, $sd_path_source . "\\" . $game_list{$folder_name});
}

# Status message.
print "\nFirst phase of menu migration is complete!\n\n";
print "Next, drag SD card onto \"orbital_organizer.exe\" to rebuild RMENU.\n\n";

# Final status message.
print "Press Enter to exit...\n";

<STDIN>;

# A subroutine to read a text file into an array.
#
# 1st parameter - Full path of file to read.
sub read_file
{
	my $input_file = $_[0];
	my @lines;

	open my $filehandle, "<:encoding(UTF-8)", $input_file or die $!;
	
	while(my $line = <$filehandle>)
	{
		chomp $line;
		push(@lines, $line);
	}

	close $filehandle;

	return @lines;
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

# Subroutine to return true if a specified byte pattern is found in a specified file.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Arrayref of byte values (e.g., [0x53, 0x45, ...]).
sub find_bytes
{
	my $input_file = $_[0];
	my $byte_array = $_[1];

	my $target_bytes = pack('C*', @$byte_array);

	open my $fh, '<:raw', $input_file or die $!;

	my $buffer;
	my $chunk_size = 1024 * 1024;

	while(read($fh, $buffer, $chunk_size))
	{
		return 1 if(index($buffer, $target_bytes) != -1);
	}

	close $fh;

	return 0;
}

# Subroutine to attempt file move/rename with prompt to close any processes preventing access to
# it.
#
# 1st parameter - Full path of source file/folder.
# 2nd parameter - Full path to destination file/folder.
sub rename_until_free
{
	my $source = ($_[0] =~ s/\\{2,}/\\/gr);
	my $destination = $_[1];

	while(1)
	{
		return 1 if(rename $source, $destination);

		my $code = Win32::GetLastError();

		if($code == 32 || $code == 5 || $!{EACCES} || $!{EBUSY})
		{
			print "\nThe following folder is open in one or more other programs:\n";
			print "   -> " . $source . "\n";
			print "Please terminate any processes preventing access and then press Enter.";

			<STDIN>;

			next;
		}

		die "Fatal error trying to move \"$source\" to \"$destination\":\n$!\n";
	}
}