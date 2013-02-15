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

# TODO: logfile needed

my $yaca_url = "http://yaca.yandex.ru";
my $yaca_path = "/home/jester/freelance/parser";
my $rubrics_file = "/home/jester/freelance/parser/yaca-columns.txt";
my $yaca_urls_file = "/home/jester/freelance/parser/yaca-columns-urls.txt";
my $websites_file = "/home/jester/freelance/parser/websites.txt";

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
        warn "Yandex catalog rubrics file not found, fetching ...";

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

        my $content = get $rubric;
        die "Couldn't get $rubric" unless defined $content;

        # parse number of pages in rubric
        if ($content =~ /b-site-counter__number\"\>(\d+) сайтов/) {
            $sites_number = $1;
        }

        # create list of all pages's urls to parse
        # TODO: first page is already fetched

        # 10 websites per page
        $sites_number = ceil( $sites_number / 10 );

        push @rubric_urls, $rubric;

        my $i = 0; # test

        for my $i (1 .. $sites_number-1) {
            last if $i++ == 10;
            push @rubric_urls, $rubric . "$i.html";
        }


    # making asynchronous downloads

    YADA->new($hosts)->append(
        \@rubric_urls => {
            retry   => 0,
            timeout => 5,
            opts    => {
                useragent => 'Opera/9.80 (Windows 7; U; en) Presto/2.9.168 Version/11.50',
                #verbose   => 1,
            },
        } => sub {
            my $self = shift;

            my $code = $self->getinfo('response_code');
            my $url = $self->final_url;

            my @www_urls = ($content =~ /href=\".+?\" class=\"b-result__name\"/g);

            for my $item (@www_urls) {
                if ($item =~ /^href=\"(.+?)\"/) {
                    push @websites, $1;
                }
            }

            save_urls( @websites );

            #exit;

            say "[+] $url - code: $code";

            #given ($code) {
            #when (200) {
            #    open my $fh, '>>', '200.txt';
            #    say {$fh} $url;
            #    close $fh;
            #} when (301) {
            #    open my $fh, '>>', '301.txt';
            #    say {$fh} $url;
            #    close $fh;
            #} default {
            #    open my $fh, '>>', 'else.txt';
            #    say {$fh} "$url code - $code";
            #    close $fh;
            #}
        },
    )->wait;

    }
}

# Save all extracted urls to disk
#
sub save_urls {

    my @urls = @_;

    open(F, ">>$websites_file") || die "$websites_file: $!";

    for my $item (@urls) {
        print F "$item\n";
    }

    close(F);
}

&main;
