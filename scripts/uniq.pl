#!/usr/bin/perl -w

use strict;
use warnings;

my $file = "urls.log";
my @urls;
my %t;

open(F, $file) or die "$!";
while (<F>) {
    chomp;
    push @urls, $_;
}
close(F);

my @uniq = grep {! $t{$_}++ } @urls;

open(F, ">>uniq-urls.log") or die "$!";
for my $url (@uniq) {
    print F "$url\n";
}
close(F);
