use v5.10.0;
use strict;
use warnings;

open FILE, $ARGV[0];
while (my $line = <FILE>) {
	chomp $line;
	if ($line =~ /^@/ || $line =~ /NH:i:1\s/ || $line =~ /NH:i:1$/) {
		say $line;
	}
}
close FILE;