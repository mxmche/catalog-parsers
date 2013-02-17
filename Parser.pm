package Parser;

# This module is used for parsing Yandex catalog
#
# class: Parser, properties: LOGFILE, URLS_FILE
# methods: ExtractRubrics(), ParsePageForURLS(), PrintToLogfile(), GetNumberOfSitesInRubric()

use LWP;
use File::Path qw(make_path);

my $logfile = "/home/jester/freelance/parser/parser.log";
my $websites_file = "/home/jester/freelance/parser/websites.txt";

# Parses page for urls and saves result to disk
#
sub parse_page {
    my ($content) = @_;

    my @www_urls = ($content =~ /href=\".+?\" class=\"b-result__name\"/g);

    my @urls;
    for my $item (@www_urls) {
        if ($item =~ /^href=\"(.+?)\"/) {
            push @urls, $1;
        }
    }

    # save parsed urls to disk

    open(F, ">>$websites_file") || die "$websites_file: $!";

    for my $item (@urls) {
        print F "$item\n";
    }

    close(F);
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
    if ($content =~ /b-site-counter__number\"\>(\d+) сайтов/) {
        $sites_number = $1;
    }

    return $sites_number;
}

# Extract all yandex rubrics urls and save them to disk
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

1;
