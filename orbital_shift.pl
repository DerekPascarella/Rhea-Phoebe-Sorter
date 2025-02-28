#!/usr/bin/perl
#
# Menu Migrator for Rhea/Phoebe Sorter v1.1
# Written by Derek Pascarella (ateam)
#
# SD card sorter for the Sega Saturn ODEs Rhea and Phoebe.

# Include necessary modules.
use utf8;
use strict;
use Encode;

# Set version number.
my $version = "1.1";

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
	print "Press Enter to exit.\n";
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
	print "Press Enter to exit.\n";
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
	print "Press Enter to exit.\n";
	<STDIN>;

	exit;
}

# Status message.
print "\nMenu Migrator for Rhea/Phoebe Sorter v" . $version . "\n";
print "Written by Derek Pascarella (ateam)\n\n";
print "Reading existing menu data...\n\n";

# Initialize hash used to store folder number and game name.
my %game_list;

# Variables to store the folder number and title temporarily
my ($folder_num, $game_title);

# Iterate through RMENU game list for parsing.
foreach my $line (&read_file($sd_path_source . "/01/BIN/RMENU/LIST.INI"))
{
	# Game title found (except "01" folder).
	if($line =~ /^(\d{2})\.title=(.+)/ && $1 ne '01')
	{
		# Capture the folder number and game title.
		$folder_num = $1;
		$game_title = $2;
	}

	# Disc number found.
	if($line =~ /^(\d{2})\.disc=(\d+)\/(\d+)/ && $1 ne '01')
	{
		# Capture disc number and total number of discs.
		my $disc_number = $2;
		my $total_discs = $3;
		
		# If total discs is more than one, append disc number to the title.
		if($total_discs > 1)
		{
			$game_list{$folder_num} = $game_title . " - Disc " . $disc_number;
		}
		else
		{
			# Otherwise, just store the game title.
			$game_list{$folder_num} = $game_title;
		}
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
	# Status message.
	print "-> Renamed folder \"" . $folder_name . "\" to \"" . $game_list{$folder_name} . "\".\n";

	# Rename folder.
	rename($sd_path_source . "//" . $folder_name, $sd_path_source . "//" . $game_list{$folder_name});
}

# Status message.
print "\nFirst phase of menu migration is complete!\n\n";
print "Next, drag SD card onto \"orbital_organizer.exe\" to rebuild RMENU.\n\n";

# Final status message.
print "Press Enter to exit.\n";
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