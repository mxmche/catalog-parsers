#!/usr/bin/perl -w
#
# Yandex Catalog (yaca) parser
#

use strict;
use warnings;
#use AnyEvent;
use LWP::Simple;
use File::Path qw(make_path);
use Data::Dumper;

# TODO: logfile needed

my $yaca_url = "http://yaca.yandex.ru";
my $yaca_path = "/home/jester/freelance/parser";
my $columns_file = "/home/jester/freelance/parser/yaca-columns.txt";
my $yaca_urls_file = "/home/jester/freelance/parser/yaca-columns-urls.txt";
my @yaca_site_urls;
my @columns_urls;

sub main {
    #
    # Get all yaca columns
    #
    open(F, $columns_file) || die "$columns_file: $!";
    while (<F>) {
        chomp;
        push @columns_urls, $_;
    }
    close(F);

    # check if file with yaca column urls exists
    #
    unless (-e $yaca_urls_file) {
        warn "Yaca columns file not found, downloading...";

        get_and_store_yaca();

        warn "saving to $yaca_urls_file...";
        # save results with yaca urls to disk
        #
        open(F, ">$yaca_urls_file") || die "";
        for my $url (@yaca_site_urls) {
           print F "$url\n";
        }
        close(F);
    }

    # parsing yaca columns urls in order to extract websites urls
    print Dumper \@yaca_site_urls;
}

# extract urls to yaca columns and save them to disk
#
sub get_and_store_yaca {

    for my $url (@columns_urls) {
        my $content = get $url;
        die "Couldn't get $url" unless defined $content;

        my @dt_tags = ($content =~ /b-rubric__list__item\"\>\<a href=\".+?\"/g);

        for my $tag (@dt_tags) {
            if ($tag =~ /href=\"(\S+)\"/) {
                my $path = $1;
                next if $path =~ /^http\:/;
                my $sub_rubric_item = $yaca_url . $path;

                my $yaca = $yaca_path . $path;
                make_path($yaca);

                
                my $con = get $sub_rubric_item;
                die "Couldn't get $sub_rubric_item" unless defined $con;
                # TODO: avoid such urls: http://yaca.yandex.ruhttp://market.yandex.ru/catalog.xml?hid=90402

                my @dd_tags = ($con =~ /b-rubric__list__loopitem\"\>\<a href=\".+?\"/g);

                for my $dtag (@dd_tags) {
                    if ($dtag =~ /href=\"(\S+)\"/) {
                        my $path = $1;
                        my $yaca = $yaca_path . $path;
                        make_path($yaca);
                        push @yaca_site_urls, $yaca_url . $path;
                    }
                }
            }
        }
    }
}

=comment
# this url contains all websites of column
my $url = "http://yaca.yandex.ru/yca/ungrp/cat/Automobiles/";

my $content = get $url;
die "Couldn't get $url" unless defined $content;

# <a href="http://auto.ru/" class="b-result__name" ... </a>
# extract all urls

my @urls = ($content =~ /\<a .+?b-result__name.+?\>/g);

# <a href="http://www.autonews.ru/" class="b-result__name" onmousedown="r(this,'ctya')" target="_blank">

for my $tag (@urls) {
    if ($tag =~ /href=\"(\S+)\"/) {
        print "$1\n";
    }
}

# move to next page in catalog
# <a class="b-pager__next" href="/yca/ungrp/cat/Automobiles/1.html">следующая</a>

=cut

&main;
