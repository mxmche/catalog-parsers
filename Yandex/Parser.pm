package Yandex::Parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_sites_number parse_page print_to_log check_local_yaca);

use Config::JSON;
use Mojo::UserAgent;
use Mojo::URL;
use File::Slurp;
use File::Path qw(make_path);
use Data::Dumper;

my $path = "/home/jester/work/parser";

# read config
my $config = Config::JSON->new("config.json");

my $rubrics_file = $config->get("yaca-rubrics");
my $yaca_url     = $config->get("yaca-url");
my $yaca         = $config->get("yaca");

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
        open(URLS, ">$file") || die "$file: $!";
        for my $item (@urls) {
            print URLS "$item\n";
        }
        close(URLS);
    }
}

# Returns number of websites in yaca rubric
#
sub get_sites_number {
    my ($rubric_url) = @_;

    my $ua = Mojo::UserAgent->new();
    my $text = $ua->get($rubric_url)->res->dom->find('.b-site-counter__number')->pluck('text');

    if ($text =~ /(\d+)/) {
        return $1;
    }
    else {
        return "";
    }
}


sub check_local_yaca {
    my @yaca_site_urls;
    -d $yaca || make_path($yaca);

    # open file with yaca rubrics
    # check path to urls file
    # if file doesn't exist then
    # add url to list of downlads
    my @rubric_urls = read_file($rubrics_file, chomp => 1);

    my $ua = Mojo::UserAgent->new();

    warn "checking local catalog ...";

    for my $url (@rubric_urls) {
        warn "processing $url ...";

        my @dt_tags = $ua->get($url)->res->dom->find('.b-rubric__list__item__link')->each;

        for my $tag (@dt_tags) {
            my $path = Mojo::URL->new($tag->{href});

            next if $path =~ /^http/;
            my $sub_rubric_item = $yaca_url . $path;

            my $dir = $yaca . $path;
            -d $dir || make_path($dir);

            my @dd_tags = $ua->get($sub_rubric_item)->res->dom->find('.b-rubric__list__item__link')->each;

            for my $dtag (@dd_tags) {
                my $path = Mojo::URL->new($dtag->{href});

                next if $path =~ /^http/;
                my $full_yaca = $yaca . $path;
                -d $full_yaca || make_path($full_yaca);

                # add rubric url to list if it wasn't exist
                my $file = $full_yaca . "urls.txt";
                unless (-e $file) {
                    my $long_url = $yaca_url . $path;
                    warn "$long_url added to download list";
                    push @yaca_site_urls, $long_url;
                }
            }
        }
    }
    return @yaca_site_urls;
}

1;
