#!/usr/bin/perl -w
#
# Yandex Catalog (yaca) parser
#

use strict;
use warnings;
use POSIX;
use common::sense;
use Config::JSON;
use File::Path qw(make_path);
use File::Slurp;
use YADA;
use Yandex::Parser;
use Nadmin::setup_logging;
use Data::Dumper;

# read config
my $config = Config::JSON->new("config.json");

my $yaca_url  = $config->get("yaca-url");
my $yaca_path = $config->get("path");
my $logfile   = $config->get("parserlog");
my $threads   = $config->get("threads");

my $rubrics_file   = $config->get("yaca-rubrics");
my $yaca_urls_file = $config->get("yaca-rubrics-urls");

my $full_yaca = "$yaca_url/yca/cat";
my $sites_number = 0;

my @yaca_site_urls;
my @main_rubrics_urls;
my @rubric_urls;
my @websites;
my $msg;

sub main {
    setup_logging($logfile);

    warn "Starting parser ...";

    my @url = check_local_yaca();
    print Dumper \@url;
    exit;

    for my $rubric (@url) {
        warn "fetching $rubric ...";

        $sites_number = get_sites_number( $rubric );

        # create list of all pages's urls to parse
        # 10 websites per page
        $sites_number = ceil( $sites_number / 10 );

        push @rubric_urls, $rubric;

        for my $i (1 .. $sites_number-1) {
            push @rubric_urls, $rubric . "$i.html";
        }

        warn scalar (@rubric_urls);

        # making asynchronous downloads

        YADA->new($threads)->append(
            \@rubric_urls => {
                retry   => 0,
                timeout => 20,
                opts    => {
                    useragent => 'Opera/9.80 (Windows 7; U; en) Presto/2.9.168 Version/11.50',
                    #verbose   => 1,
                },
            } => sub {
                my $self = shift;

                my $code = $self->getinfo('response_code');
                my $url = $self->final_url;

                parse_page( $url, ${ $self->{data} } );

                $msg = ($code == 200)? "DONE" : "NO";
            },
        )->wait;
        warn $msg;
        @rubric_urls = ();
        sleep(20);
        exit;
    }
}

&main;
