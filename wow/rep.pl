use warnings;
use strict;
use Sys::Hostname;     # hostname
use Cwd;               # abs_path
use File::Basename;    # fileparse

# use LWP::UserAgent;
use WWW::Mechanize;
use DateTime;

# use HTML::TreeBuilder;
use JSON;
use Data::Dumper::Names;

$| = 1;

my $full_path = Cwd::abs_path($0);
my $date      = DateTime->now()->strftime('%Y%m%dT%H%M');
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

my $mech = WWW::Mechanize->new();
my $cookie_file =
  sprintf( "%s/%s_cookies.%s.txt", $script_path, $script_name, $$ );
print "Cookie location: $cookie_file\n";
$mech->cookie_jar(
    {
        file => $cookie_file
    }
);

my $reps;
map { $reps->{$_} = 1 } (
    "Champions of Azeroth",
    "Talanji\'s Expedition",
    "The Honorbound",
    "Tortollan Seekers",
    "Voldunai",
    "Zandalari Empire"
);

for my $nick (@nicks) {
    my $rp = $mech->get(
        sprintf(
            'https://worldofwarcraft.com/en-gb/character/burning-legion/%s/reputation',
            $nick )
    );
    my $content;
    if ( $rp->is_success ) {
        $content = $rp->decoded_content;
    }
    my $data;

    my $page = 0;
    $content = join( "", split( "\n", $content ) );
    while ( $content
        =~ /<div class="Reputation-name">(.*?)<\/div><div class="Reputation-standing">(.*?)<\/div><\/div><div class="Reputation-progress"><div class="Progressbar Progressbar--.*?"><div class="Progressbar-border"><\/div><div class="Progressbar-progress" style="width:.*?" data-progressLevel=".*?"><\/div><div class="Progressbar-content"><div class="Progressbar-body">((\d+) \/ (\d+))?<\/div><\/div><\/div><\/div><div class="Reputation-standing hide" media-large="!hide">.*?<\/div><\/div>/g
      ) {
        my $match = [ $1, $2, $4, $5 ];
        if ( $reps->{ $match->[0] } ) {
            $data->{ $match->[0] } = {
                standing => $match->[1],
                progress => $match->[2] || "21000",
                max      => $match->[3] || "21000",
            };
        }
    }

    open my $fh, q{>}, "$script_path/$script_name-$nick-$date.json"
      or die("Cannot open: $script_path/$script_name-$nick-$date.json");
    print $fh JSON->new->utf8->pretty->canonical->encode($data);
    close $fh;
}
