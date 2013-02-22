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
    my ($rubric) = @_;

    my $content = get $rubric;
    die "Couldn't get $rubric" unless defined $content;

    # parse number of pages in rubric

    my $sites_number = "";
    if ($content =~ /b-site-counter__number\"\>(\d+)/) {
        $sites_number = $1;
    }

    return $sites_number;
}

# Extract all yandex rubrics urls and save them to disk
#
sub get_and_store_yaca {
    my @rubric_urls  = @_;

    # check yandex rubrics path
    -d $yaca_path || make_path($yaca_path) || die "$yaca_path: $!";

    for my $url (@rubric_urls) {
        my $content = get $url;
        die "Couldn't get $url" unless defined $content;

        my @dt_tags = ($content =~ /b-rubric__list__item\"\>\<a href=\".+?\"/g);

        for my $tag (@dt_tags) {
            if ($tag =~ /href=\"(\S+)\"/) {
                my $path = $1;
                next if $path =~ /http\:/;
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
                        next if $path =~ /http\:/;
                        my $yaca = $yaca_path . $path;
                        make_path($yaca);
                        push @yaca_site_urls, $yaca_url . $path;
                    }
                }
            }
        }
    }
    return @yaca_site_urls;
}

1;
