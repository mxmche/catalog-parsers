package YandexParser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_sites_number parse_page print_to_log get_and_store_yaca);

# This module is used for parsing Yandex catalog
#
# class: Parser, properties: LOGFILE, URLS_FILE
# methods: ExtractRubrics(), ParsePageForURLS(), PrintToLogfile(), GetNumberOfSitesInRubric()

# use Mojo instead of these ones
use LWP;
use LWP::Simple;

use Mojo::UserAgent;
use Mojo::URL;

use File::Path qw(make_path);

use Data::Dumper;

my $path          = "/home/jester/work/parser";
my $yaca_url      = "http://yaca.yandex.ru";
#my $yaca_path = "/home/jester/work/parser";
my $logfile       = "$path/parser.log";
my $websites_file = "$path/websites.txt";
my $yaca_path     = "$path/yaca";
my $full_yaca = "$yaca_url/yca/cat";

# Parses page for urls and saves result to disk
#
sub parse_page {
    my ($url, $content) = @_;

    my @www_urls = ($content =~ /href=\".+?\" class=\"b-result__name\"/g);

    my @urls;
    for my $item (@www_urls) {
        if ($item =~ /^href=\"(.+?)\"/) {
            push @urls, $1;
        }
    }

    # get urls from http://yaca.yandex.ru/yca/cat/Computers/Computers/hardware/84.html
    # and save to Computers/Computers/hardware/urls.txt
    if ($url =~ /$full_yaca\/(.+)\//) {
        my $file = "$yaca_path/yca/cat/$1/urls.txt";
        open(URLS, ">>$file") || die "$file: $!";
        for my $item (@urls) {
            print URLS "$item\n";
        }
        close(URLS);
    }
}

sub print_to_log {

    my ($message) = @_;

    my $date = scalar(gmtime);

    open(LOG, ">>$logfile") || die "$logfile: $!";
    print LOG "[$date] $message\n";
    close(LOG);
}

# Returns number of websites in yaca rubric
#
sub get_sites_number {
    my ($rubric_url) = @_;

    my $ua = Mojo::UserAgent->new();
    my $text = $ua->get($rubric_url)->res->dom->find('.b-site-counter__number')->pluck('text');

    return ($text =~ /(\d+)/)? $1 : "";
}

# Extract all yandex rubrics urls and save them to disk
#
sub get_and_store_yaca {
    my @rubric_urls  = @_;
    my $ua = Mojo::UserAgent->new();

    for my $url (@rubric_urls) {
        my @dt_tags = $ua->get($url)->res->dom->find('.b-rubric__list__item__link')->each;

        for my $tag (@dt_tags) {
            my $path = Mojo::URL->new($tag->{href});

            next if $path =~ /^http/;
            my $sub_rubric_item = $yaca_url . $path;

            my $yaca = $yaca_path . $path;
            make_path($yaca);

            my @dd_tags = $ua->get($sub_rubric_item)->res->dom->find('.b-rubric__list__item__link')->each;

            for my $dtag (@dd_tags) {
                my $path = Mojo::URL->new($dtag->{href});

                next if $path =~ /^http/;
                my $yaca = $yaca_path . $path;
                make_path($yaca);
                push @yaca_site_urls, $yaca_url . $path;
            }
        }
    }
    return @yaca_site_urls;
}

1;
