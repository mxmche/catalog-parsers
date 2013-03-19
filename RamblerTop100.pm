package RamblerTop100;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(init get_sites_number parse_page get_categories get_url_description);

use strict;
use common::sense;
use Config::JSON;
use Mojo::UserAgent;
use Mojo::URL;
use File::Slurp;
use File::Path qw(make_path);
use Data::Dumper;

# read config
my $config = Config::JSON->new("config.json");

my $rambler_url  = $config->get("rambler-url");
my $rambler_navi = $config->get("rambler-navi");
my $rambler_cat  = $config->get("rambler-local");
my $categories   = $config->get("rambler-cat");
my $full_cat     = $config->get("rambler-full");
my $search_up    = $config->get("search-upper");
my $search_cat   = $config->get("search-cat");
#my $search_page  = $config->get("search-page");

my @res;  # contains all urls
my %uniq; # contains all urls and description

my $ua = Mojo::UserAgent->new();

sub init {
    unless (-e $categories) {
        &get_categories;
    }

    # call recursive fetching of categories
    # build local catalog
    my @cat_urls = read_file($categories, chomp => 1);
    for my $u (@cat_urls) {
        warn "fetching $u...";

        make_tree($u);

        my $c = scalar(@res);
        warn "finishing with $c categories...";
        save_them_all(@res);

        @res = ();
        %uniq = ();
    }
    warn "Everything is DONE.";
}

sub save_them_all {
    my @data = @_;
    my @saved;

    for my $url (@data) {
        my $desc = get_url_description($url);
        push @saved, "$url $desc";
        my $path = "$rambler_cat/$desc";
        -e $path || make_path($path);
    }

    open(F, ">>$full_cat") || die "$full_cat: $!";
    for my $s (@saved) {
        print F "$s\n";
    }
    close(F);
}

sub make_tree {
    my ($url) = @_;

    my @urls = $ua->get($url)->res->dom->find($search_cat)->each;

    foreach my $e (@urls) {
        next unless defined $e->{href};

        my $sub_url = $rambler_navi . $e->{href};
        my $text = $e->text;

        $text =~ s/,//g;
        $text =~ s/\s+/\_/g;

        next if ++$uniq{$text}{$sub_url} > 1;

        make_tree($sub_url);
    }

    push @res, $url unless @urls;
}

# Parses page for urls and saves result to disk
#
sub parse_page {
    my ($url, $desc, $content) = @_;

    my @www_urls = ($content =~ /class=\"rt\" href=\".+?\"/g);

    my @urls;
    my %uniq;

    for my $item (@www_urls) {
        # skip addreses with the same domain
        if ($item =~ /href=\"(http:\/\/.+?\/)/) {
            next if ++$uniq{$1} > 1;
        }
    }

    my @saved = map {"$_\n"} keys %uniq;

    # TODO: resolve path with catalog categories
    my $file = "$rambler_cat/$desc/urls.txt";

    append_file($file, @saved);
}

# parses page for description
sub get_url_description {
    my ($url) = @_;
    my $ua = Mojo::UserAgent->new();
    my $text = $ua->get($url)->res->dom->find('.forindex index')->pluck('text');
    $text =~ s/\s+/_/g;
    my @titles = split(/,/, $text);
    my $res = join("/", @titles);
    return $res;
}

# Returns number of websites category

sub get_sites_number {
    my ($rubric_url) = @_;

    my $ua = Mojo::UserAgent->new();
    my $text = $ua->get($rubric_url)->res->dom->find('.result b')->pluck('text');

    if ($text =~ /(\d+)/) {
        return $1;
    }
    else {
        return "";
    }
}

# Get first level categories and save them into file

sub get_categories {
    my $ua = Mojo::UserAgent->new();
    my @content = $ua->get($rambler_url)->res->dom->find($search_up)->each;

    my @urls;
    foreach my $e (@content) {
        my $title = $e->text;

        # skip all websites category
        next if $e->{href} =~ /\/$/;

        $title =~ s/,//g;
        $title =~ s/\s+/\_/g;

        push @urls, $rambler_url . $e->{href} . "\n";
    }

    write_file($categories, @urls);
}

1;
