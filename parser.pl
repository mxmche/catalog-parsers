#!/usr/bin/perl -w
#
# Yandex Catalog (yaca) parser
#

use strict;
use warnings;

use POSIX;
use common::sense;
use LWP::Simple;
use File::Path qw(make_path);
use File::Slurp;
use YADA;
use Parser;

use Data::Dumper;

# TODO: config needed

my $yaca_url = "http://yaca.yandex.ru";
my $yaca_path = "/home/jester/freelance/parser";
my $rubrics_file = "/home/jester/freelance/parser/yaca-columns.txt";
my $yaca_urls_file = "/home/jester/freelance/parser/yaca-columns-urls.txt";
my $websites_file = "/home/jester/freelance/parser/websites.txt";
#my $logfile = "/home/jester/freelance/parser/parser.log";

my @yaca_site_urls;
my @columns_urls;
my $hosts = 2; # number of hosts processing
my $sites_number = 0;
my @rubric_urls;
my @websites;

sub main {
    #
    # Get all yandex catalog rubrics
    #
    @columns_urls = read_file($rubrics_file, chomp => 1);

    # check if file with yandex catalog rubric urls exists
    #
    unless (-e $yaca_urls_file) {
        print_to_log("Yandex catalog rubrics file not found, fetching ...");
        #warn "Yandex catalog rubrics file not found, fetching ...";

        get_and_store_yaca();

        warn "saving to $yaca_urls_file...";
        # save results with yandex catalog urls to disk
        #
        open(F, ">$yaca_urls_file") || die "";
        for my $url (@yaca_site_urls) {
           print F "$url\n";
        }
        close(F);
    }

    my @url = read_file("yandex_test_rubric.txt", chomp => 1);

    for my $rubric (@url) {
        $sites_number = get_sites_number( $rubric );

        # create list of all pages's urls to parse

        # 10 websites per page
        $sites_number = ceil( $sites_number / 10 );

        push @rubric_urls, $rubric;

        my $i = 0; # test

        for my $i (1 .. $sites_number-1) {
            last if $i++ == 10; # test
            push @rubric_urls, $rubric . "$i.html";
        }


    # making asynchronous downloads

    YADA->new($hosts)->append(
        \@rubric_urls => {
            retry   => 0,
            timeout => 10,
            opts    => {
                useragent => 'Opera/9.80 (Windows 7; U; en) Presto/2.9.168 Version/11.50',
                #verbose   => 1,
            },
        } => sub {
            my $self = shift;

            my $code = $self->getinfo('response_code');
            my $url = $self->final_url;
            #my $content = ${ $self->{data} };

            # extract urls

            parse_page( ${ $self->{data} } );

            my $msg = "fetching $url ... ";
            $msg .= ($code == 200)? "ok\n" : "no";
            print_to_log( $msg );
        },
    )->wait;

    }
}

&main;
