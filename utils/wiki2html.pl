#!/usr/bin/env perl

use encoding 'utf8';
use strict;
use warnings;

use List::MoreUtils qw(first_index);
use Getopt::Std;

my @nums = qw(
   零 一 二 三 四 五 六 七 八 九
   十 十一 十二 十三 十四 十五 十六 十七 十八 十九
   二十
);

my %opts;
getopts('o:', \%opts) or usage();

my $outfile = $opts{o};

my $infile = shift or usage();

open my $in, "<:encoding(UTF-8)", $infile
    or die "Cannot open $infile for reading: $!\n";

my $ctx = {};
my $html = '';
while (<$in>) {
    #warn "line $.\n";
    if (/^\s+$/) {
        if ($ctx->{code}) {
            #warn "inserting br in code";
            $html .= "<br/>\n";
        }
        next;
    }

    if (/^\s+/) {
        $html .= fmt_code($_, $ctx);

    } elsif (/^\S/) {

        $html .= fmt_para($_, $ctx);
    }
}

close $in;

$html .= "    </body>\n</html>\n";

if ($outfile) {
    open my $out, ">:encoding(UTF-8)", $outfile
        or die "Cannot open $outfile for writing: $!\n";

    print $out $html;
    close $out;

} else {
    print $html;
}

sub fmt_para {
    my ($s, $ctx) = @_;
    if ($s =~ /^= (.*?) =$/) {
        my $title = $1;
        return <<"_EOC_";
<html>
    <head>
        <title>$title</title>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    </head>
    <body>
    <h3>$title</h3>
_EOC_
    }

    if (/^<geshi/) {
        $ctx->{code} = 1;
        return "<code>";
    }

    if (m{^</geshi>}) {
        $ctx->{code} = 0;
        return "</code>";
    }

    my $res;

    while (1) {
        #my $pos = pos $s;
        #warn "pos: $pos" if defined $pos;
        if ($s =~ /\G (\s*) \[ (http[^\]\s]+) \s+ ([^\]]+) \] /gcx) {
            my ($indent, $url, $label) = ($1, $2, $3);
            if ($label =~ m/（([一二三四五六七八九十]+)）/) {
                my $cn_num = $1;
                my $n = sprintf "%02d", first_index { $_ eq $cn_num } @nums;
                $res .= qq{$indent<a href="NginxVariables$n.html">$label</a>}

            } else {
                #warn "matched abs link $&\n";
                $label = fmt_html($label);
                $res .= qq{$indent<a href="$url" target="_blank">$label</a>};
            }

        } elsif ($s =~ /\G \s* \[\[ ([^\|\]]+) \| ([^\]]+) \]\]/gcx) {
            my ($url, $label) = ($1, $2);
            #warn "matched rel link $&\n";
            $url =~ s/\$/.24/g;
            $res .= qq{ <a href="http://wiki.nginx.org/$url" target="_blank">$label</a>};

        } elsif ($s =~ /\G [^\[]+ /gcx) {
            #warn "matched text $&\n";
            $res .= $&;

        } elsif ($s =~ /\G ./gcx) {
            #warn "unknown link $&\n";

        } else {
            #warn "breaking";
            last;
        }
    }

    return "<p>$res</p>\n";
}

sub fmt_html {
    my $s = shift;
    $s =~ s/\&/\&amp;/g;
    $s =~ s/"/\&quot;/g;
    $s =~ s/</\&lt;/g;
    $s =~ s/>/\&gt;/g;
    $s =~ s/ /\&nbsp;/g;
    $s;
}

sub fmt_code {
    my $s = shift;
    $s = fmt_html($s);
    $s =~ s{\n}{<br/>\n}sg;
    $s;
}

sub usage {
    die "Usage: $0 [-o <outfile>] <infile>\n";
}

