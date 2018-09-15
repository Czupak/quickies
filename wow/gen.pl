use warnings;
use strict;
use Sys::Hostname;
use Cwd;
use File::Basename;

# use LWP::UserAgent;
use WWW::Mechanize;
use DateTime;

# use HTML::TreeBuilder;
use JSON;
use Data::Dumper::Names;

$| = 1;

my $full_path = Cwd::abs_path($0);
my ( $script_name, $script_path ) = fileparse($full_path);

my @nicks;
if ( scalar @ARGV > 0 ) {
    @nicks = $ARGV[0];
} elsif ( -e "$script_path/.nicks" ) {
    local $/;    #Enable 'slurp' mode
    open my $fh, "<", "$script_path/.nicks";
    my $config = <$fh>;
    close $fh;
    @nicks = split( "\n", $config );

} else {
    die("No nicks file: $script_path/.nicks");
}

my $reps;
map { $reps->{$_} = 1 } (
    "Champions of Azeroth",
    "Talanji\'s Expedition",
    "The Honorbound",
    "Tortollan Seekers",
    "Voldunai",
    "Zandalari Empire"
);

my @files = glob "$script_path/rep.pl-*.json";

my $data = {};
for my $file (@files) {
    $file =~ /rep\.pl-(.*)-(.*)\.json/;
    my $nick = $1;
    my $dt   = $2;
    my $json;
    {
        local $/;    #Enable 'slurp' mode
        open my $fh, "<", $file;
        $json = <$fh>;
        close $fh;
    }

    # print Dumper $json;
    $json = decode_json($json);
    $data->{$nick}->{$dt} = $json;
}
print("<html>");
print <<END;
<head>
<title>LIH - LeDsplej Images Hosting (Darmowy Hosting Obrazkow)</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style type='text/css'>
body {
        font-family:Verdana;
        font-size: 12px;
}
table {
        border:1px solid;
}
td {
        border:1px dotted;
        border-color:gray;
        font-family:Verdana;
        font-size: 12px;
}
img {
        border:0px;
}
a {
        color:black;
        text-decoration:underline;
        font-weight:bold;
}
a:hover {
        color:gray;
        text-decoration:none;
        font-weight:bold;
}
textarea,input,select,button {
        color: gray;
        border:solid 1px #9B9A9A;
        font-family:Verdana,sans-serif;
        font-size: 9px;
        color:#3266A2;
        background:#D9E5F3;
}
.formularz {
        color: gray;
        border:solid 1px #9B9A9A;
        font-family:Verdana,sans-serif;
        font-size: 9px;
        color:#3266A2;
        background:#D9E5F3;
}
</style>
</head>
END
print("<body>");

for my $nick (@nicks) {
    my $mem;
    print("<h2>$nick</h2><table border=1>");
    my @headers = ( 'Date', sort keys %{$reps} );
    printf( "<tr><th>" . join( "</th><th>", @headers ) . "</th></tr>\n" );
    for my $dt ( sort keys %{ $data->{$nick} } ) {
        my @row = ($dt);
        for my $rep ( sort keys %{$reps} ) {
            my $r = sprintf( "%s/%s",
                $data->{$nick}->{$dt}->{$rep}->{progress},
                $data->{$nick}->{$dt}->{$rep}->{max} );
            my @tag = ( '', '' );
            if ( $mem->{$rep} && $mem->{$rep} ne $r ) {
                @tag = ( "<b>", "</b>" );
            }
            push @row, $tag[0] . $r . $tag[1];
            $mem->{$rep} = $r;
        }
        printf( "<tr><td>" . join( "</td><td>", @row ) . "</td></tr>\n" );
    }
    print("</table>");
}
print("</body></html>");
