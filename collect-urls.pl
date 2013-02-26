#!/usr/bun/perl -w

use strict;
use warnings;

use Config::JSON;
use File::Slurp;
#use Nadmin::setup_logging;
#use YADA;

use Data::Dumper;

#my $path = Config::JSON->new("path");
my $config = Config::JSON->new("config");

my $rubric_file  = $config->get("yaca-rubrics-urls");
my $path         = $config->get("path");

my @rubrics = read_file($rubric_file, chomp => 1);

for my $url (@rubrics) {
    $url =~ /ru(.+)$/;
    my $path_cat = "$path/yaca" . $1;
    my $file = $path_cat . "urls.txt";

    if (-e $file) {
        warn "$file was found";
        my @a = read_file($file, chomp => 1);

        open(F, ">>urls.log") or die "urls.log";
        for (@a) {
            print F "$_\n";
        }
        close(F);
    }
}

