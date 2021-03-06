package Mailru;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(build_local_catalog get_urls_number get_pages parse_page2);

use strict;
use warnings;
use common::sense;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::DOM;
use File::Path qw(make_path);
use Data::Dumper;
use Text::Iconv;
use POSIX;

my $cat_url = "http://list.mail.ru";
my $cat = "list";
my $rubric_file = "list.mail.ru-rubrics.txt";

my @rubrics;
my @pages;
my %uniq;

my %r = (
    1001 => "Автомобили",
    10896 => "Бизнес и финансы",
    10897 => "Домашний очаг",
    10898 => "Интернет",
    10900 => "Компьютеры",
    10901 => "Культура и искусство",
    10993 => "Медицина и здоровье",
    10902 => "Наука и образование",
    10903 => "Непознанное",
    10906 => "Новости и СМИ",
    2 => "Общество и политика",
    10904 => "Отдых и развлечения",
    14249 => "Производство",
    10899 => "Работа и заработок",
    10907 => "Спорт",
    10908 => "Справки",
    14263 => "Товары и услуги",
    10909 => "Юмор"
);

my $ua = Mojo::UserAgent->new();

sub build_local_catalog {
    my $catalog = $ua->get($cat_url)->res->dom->find('.catalog');

    my $dom = Mojo::DOM->new($catalog);
    my @res = $dom->find('p')->each;
    my @h   = $dom->find('h2')->each;

    my $converter = Text::Iconv->new("cp1251", "utf8");

    open(F, ">$rubric_file") || die "$rubric_file: $!";

    for (0 .. $#res) {
        my $r_url = "http:" . $res[$_]->at('a')->{href};
        my $converted = $converter->convert( $h[$_]->at('h2')->text );
        my $path = "$cat/$converted";
        -d $path || make_path( $path, {error => \my $error} );
        print F "$r_url\n";
    }
    close(F);
}

# Returns list of urls of webpages
sub get_pages {
#warn "get_pages";
    my ($url, $number) = @_;
    $url =~ /^$cat_url\/(\d+)/;
    my $rubric = $1;
    my @pages;
    my $pages = ceil( ($number-10) / 20) + 1;
    for my $n (1 .. $pages) {
        push @pages, "$cat_url/$rubric/1/0_1_0_$n.html";
    }
    return @pages;
}

# Extracts number of websites in catalog's rubric
sub get_urls_number {
#warn "get_urls_number";
    my ($url) = @_;
    my $urls_number = 0;
    my @lines = $ua->get($url)->res->dom->find('b')->each;
    for my $e (@lines) {
        my $item = $e->text;
        if ($item =~ /Все сайты \((\d+)\)/) {
            $urls_number = $1;
            last;
        }
    }
    return $urls_number;
}

sub parse_page2 {
    my ($url, $content) = @_;

    # find urls in catalog
    my @links = ($content =~ /href=.+\<\/a\>/g);

    my @urls;
    for my $e (@links) {
        if ($e =~ /\>(http.+?)\<\/a\>$/) {
            #warn $1;
            push @urls, $1;
        }
    }

    $url =~ /^$cat_url\/(\d+)\//;
    my $r_name = $r{$1};
    my $file = "$cat/$r_name/urls.txt";
    #warn $url;
    
 #   warn "writing in $file...";

    open(F, ">>$file") || die "$file: $!";
    for my $e (@urls) {
        print F "$e\n";
    }
    close(F);
}

=comment
sub build_catalog_tree {
    my ($url) = @_;
    my @urls = $ua->get($url)->res->dom->find('a[name]')->each;

    foreach my $e (@urls) {
        next unless defined $e->{href};
        next unless $e->{name} =~ /^[0-1]$/;

        my $sub_url = $cat_url . $e->{href};
        next if ++$uniq{$sub_url} > 1;

        build_catalog_tree($sub_url);
    }
    unless (@urls) {
        warn $url;
        push @rubrics, $url;
    }
}
=cut

#say $_ for @res;
#my $converter = Text::Iconv->new("cp1251", "utf8");
#for (@h) {
   # my $converted = $converter->convert( $_->at('h2')->text );
    #say $converted;
    #say $_->at('h2')->text;
#}
#my $collection = $dom->children('div');
#say @res;
#die unless @catalog;
#open(F, ">list.mail.ru_rubrics") || die "$!";
#warn "here";
#for my $tag (@catalog) {
#    my $u = Mojo::URL->new($tag->{href});
#    say "http:$u";
    #print F "http:$u\n";
#}
#close(F);
