package Parser;

# This module is used for parsing Yandex catalog

use LWP;
use File::Path(make_path);


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
