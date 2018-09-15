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

my @files = glob "$script_path/filmweb-*.json";

#print Dumper \@files;

my $data = {};
for my $file (@files) {
    $file =~ /filmweb-(.*)\.json/;
    my $dt = $1;
    my $json;
    {
        local $/;    #Enable 'slurp' mode
        open my $fh, "<", $file;
        $json = <$fh>;
        close $fh;
    }

    # print Dumper $json;
    $json = decode_json($json);
    $data->{$dt} = $json;
}
print("<html>");
print <<END;
<head>
<title>FilmWeb - Perl ToWatch Parser</title>
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

print("<h2>Filmweb ToWatch Changes</h2><table border=1>");
my @headers = qw/Date Change/;
printf( "<tr><th>" . join( "</th><th>", @headers ) . "</th></tr>\n" );

my $mem;
for my $dt ( sort keys %{$data} ) {
    my @changes;
    my @row  = ($dt);
    my $json = $data->{$dt};
    for my $movie ( sort keys %{$json} ) {
        if ( $mem->{$movie} ) {
            if ( $mem->{$movie}->{prob} ne $json->{$movie}->{prob} ) {
                my $diff = $json->{$movie}->{prob} - $mem->{$movie}->{prob};
                push @changes,
                  sprintf(
                    "[CHG] %s [%s] (%s => %s)",
                    $movie, $diff,
                    $mem->{$movie}->{prob},
                    $json->{$movie}->{prob}
                  );
            }
            delete $mem->{$movie};
        } else {
            push @changes, sprintf( "[NEW] %s", $movie );
        }
    }
    for my $movie ( keys %{$mem} ) {
        push @changes, sprintf( "[DEL] %s", $movie );
    }
    $mem = $json;
    push @row, join( "<br/>\n", @changes );
    printf( "<tr><td>" . join( "</td><td>", @row ) . "</td></tr>\n" );
}
print("</table>");
print("</body></html>");
