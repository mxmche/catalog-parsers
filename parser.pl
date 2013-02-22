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

use YandexParser;
use Nadmin::setup_logging;

use Data::Dumper;

# TODO: config needed

#my $path = "/home/jester/word/parser";

my $yaca_url = "http://yaca.yandex.ru";
my $full_yaca = "$yaca_url/yca/cat";
my $yaca_path = "/home/jester/work/parser";
my $logfile = "$yaca_path/parser.log";
my $rubrics_file = "$yaca_path/yaca-rubrics.txt";
my $yaca_urls_file = "$yaca_path/yaca-rubrics-urls.txt";
my $websites_file = "$yaca_path/websites.txt";

#my $logfile = "/home/jester/freelance/parser/parser.log";

my @yaca_site_urls;
my @main_rubrics_urls; # @columns_urls
my $hosts = 20; # number of hosts processing
my $sites_number = 0;
my @rubric_urls;
my @websites;

sub main {
    setup_logging($logfile);

    warn "Starting parser ...";

    # Get all yandex catalog rubrics
    #
    @main_rubrics_urls = read_file($rubrics_file, chomp => 1);

    # check if file with yandex catalog rubric urls exists
    #
    unless (-e $yaca_urls_file) {
        warn "$yaca_urls_file not found, fetching ...";

        @yaca_site_urls = get_and_store_yaca(@main_rubrics_urls);

        warn "saving to $yaca_urls_file...";
        # save results with yandex catalog urls to disk
        #
        open(F, ">$yaca_urls_file") || die "";
        for my $url (@yaca_site_urls) {
           print F "$url\n";
        }
        close(F);
    }

    if (-e $yaca_urls_file && ! -d "$yaca_path/yaca") {
        get_and_store_yaca(@main_rubrics_urls);
    }
#exit;

    # test mode
    my @url = read_file($yaca_urls_file, chomp => 1);

    for my $rubric (@url) {
        $sites_number = get_sites_number( $rubric );

        # create list of all pages's urls to parse

        # 10 websites per page
        $sites_number = ceil( $sites_number / 10 );

        push @rubric_urls, $rubric;

        #my $i = 0; # test

        for my $i (1 .. $sites_number-1) {
            #last if $i++ == 10; # test
            push @rubric_urls, $rubric . "$i.html";
        }
#print Dumper \@rubric_urls;
#exit;

    # making asynchronous downloads

    YADA->new($hosts)->append(
        \@rubric_urls => {
            retry   => 0,
            timeout => 15,
            opts    => {
                useragent => 'Opera/9.80 (Windows 7; U; en) Presto/2.9.168 Version/11.50',
                #verbose   => 1,
            },
        } => sub {
            my $self = shift;

            my $code = $self->getinfo('response_code');
            my $url = $self->final_url;

            # extract urls

            parse_page( $url, ${ $self->{data} } );

            my $msg = "fetching $url ... ";
            $msg .= ($code == 200)? "ok" : "no";
            warn $msg;
        },
    )->wait;

    @rubric_urls = ();

    }
}

&main;
