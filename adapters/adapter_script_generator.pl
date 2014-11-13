use v5.10.0;
use strict;
use warnings;

my $RPI = "AATGATACGGCGACCACCGAGATCTACACGTTCAGAGTTCTACAGTCCGA";
my %indexseq;


my $count = 0;
open FILE1, "~/software/scripts/riboseq/adapters/adapter_indices_table.txt";
while (my $line = <FILE1>) {
	chomp $line;
	$count++;
	if ($count > 1) {
		my @tmp = split(/\t/, $line);
		my $number = $tmp[1];
		my $revcom = $tmp[3];
		$indexseq{$number} = $revcom;
	}	
}
close FILE1;


#read in sample info file
$count = 0;
open FILE, "sample_info.txt";
while (my $line = <FILE>) {
	chomp $line;
	$count++;
	if ($count > 1) {
		my @tmp = split(/\t/, $line);
	
		my $file = $tmp[1];
		my $index = $tmp[2];
		my $newname = $file;
		
		
		#$newname =~ s/\.gz//;  #optional - are you using compressed files or not? 
		$file =~ /(.+)\.fq/;
		my $out = $1."_trimmed.fq";
		
		print "cutadapt -O 3 -b $RPI -a $indexseq{$index} $newname -q 20 -m 5 > $out\n\n";
		
	}
}
close FILE;