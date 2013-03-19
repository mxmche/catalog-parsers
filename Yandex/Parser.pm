package Yandex::Parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_sites_number parse_page print_to_log update_local_yaca);

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
my $yr_urls      = $config->get("yaca-rubrics-urls");
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
#    $yaca_url

    my $file;
    if ($url =~ /$full_yaca\/(.+)\//) {
        $file = "$yaca/yca/cat/$1/urls.txt";
    }
     #   open(URLS, ">>$file") || die "$file: $!";
     #   for my $item (@urls) {
     #       print URLS "$item\n";
     #   }
     #   close(URLS);
    #}
    elsif ($url =~ /$yaca_url\/(.+)\//) {
#        warn "writing $file ...";
        $file = "$yaca/$1/urls.txt";
    }
#        warn "writing $file ...";
    open(URLS, ">>$file") || die "$file: $!";
    for my $item (@urls) {
        print URLS "$item\n";
    }
    close(URLS);
    #}
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

# checks yaca-rubric-urls file for new urls
# returns fresh urls that were not downloaded

sub update_local_yaca {
    my @yaca_site_urls;

    -d $yaca || make_path($yaca);

    if (-e $yr_urls) {
        unlink $yr_urls or die "Could not unlink $yr_urls: $!";
    }

=comment
    # checks $rubrics_file for new urls
    my @fresh;
    my @r_urls = read_file($yr_urls, chomp => 1);
    for my $url (@r_urls) {
        warn $url;
        if ($url =~ /^$yaca_url\/(.*)$/) {
            my $filepath = "$yaca/$1" . "urls.txt";
            #warn "$yaca/$1/urls.txt";
            unless (-e $filepath) {
                #warn $filepath;
                push @fresh, $url;
            }
        }
    }
    return @fresh if @fresh;
=cut

    # open file with yaca rubrics
    # check path to urls file
    # if file doesn't exist then
    # add url to list of downlads
    my @rubric_urls = read_file($rubrics_file, chomp => 1);

    my $ua = Mojo::UserAgent->new();

    warn "checking local catalog ...";

    for my $url (@rubric_urls) {
        next if $url =~ /^#/;
        warn "processing $url ...";
        my @sub_rubric_urls = $ua->get($url)->res->dom->find('.b-rubric__list__item__link')->each;
        for my $s_url (@sub_rubric_urls) {
            next unless defined $s_url->{href};
            my $path = Mojo::URL->new($s_url->{href});
            next if $path =~ /^http/;
            my $sub_rubric_url = $yaca_url . $path;

            my $dir = $yaca . $path;
            -d $dir || make_path($dir);

            my @ss_rubric_urls = $ua->get($sub_rubric_url)->res->dom->find('.b-rubric__list__item__link')->each;
            # two level rubric
            unless (@ss_rubric_urls) {
                write_to_file($sub_rubric_url);
                my $file = $dir . "urls.txt";
                unless (-e $file) {
                    push @yaca_site_urls, $sub_rubric_url;
                }
                next;
            }

            for my $ss_url (@ss_rubric_urls) {
                my $ppath = Mojo::URL->new($ss_url->{href});
                next if $ppath =~ /^http/;

                # add rubric url to list if it wasn't exist
                my $file = $yaca . $ppath . "urls.txt";
                my $long_url = $yaca_url . $ppath;
                unless (-e $file) {
                    #warn $long_url;
                    push @yaca_site_urls, $long_url;
                }
                write_to_file($long_url);
            }
        }
    }
    return @yaca_site_urls;
}

sub write_to_file {
    my ($url) = @_;
    open(F, ">>$yr_urls") || die "$yr_urls: $!";
    print F "$url\n";
    close(F);
}

1;
