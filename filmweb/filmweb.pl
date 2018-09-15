use warnings;
use strict;
use Sys::Hostname;
use Cwd;
use File::Basename;
use LWP::UserAgent;
use WWW::Mechanize;
use DateTime;

# use HTML::TreeBuilder;
use JSON;
use Data::Dumper::Names;

$| = 1;

my $full_path = Cwd::abs_path($0);
my $date      = DateTime->now()->strftime('%Y%m%dT%H%M');
my ( $script_name, $script_path ) = fileparse($full_path);

my @creds = [ 'login', 'pass' ];
my $credfile;
if ( -e "$script_path/.creds" ) {
    local $/;    #Enable 'slurp' mode
    open my $fh, "<", "$script_path/.creds";
    $credfile = <$fh>;
    close $fh;
    @creds = split( "\n", $credfile );

} else {
    die("No crefile: $script_path/.creds");
}

my $agent = LWP::UserAgent->new();
my $mech  = WWW::Mechanize->new();

# my $html        = HTML::TreeBuilder->new();
my $cookie_file = sprintf( "%s/filmweb_cookies.%s.txt", $script_path, $$ );
print "Cookie location: $cookie_file\n";
$mech->cookie_jar(
    {
        file => $cookie_file
    }
);

my $rp = $mech->get('https://www.filmweb.pl/login');
my $content;
if ( $rp->is_success ) {
    $content = $rp->decoded_content;
}

$mech->form_number(2);
my $form_response = $mech->submit_form(
    fields => {
        j_username => $creds[0],
        j_password => $creds[1],
    }
);

my %map = (
    rate => qr/<span class="rateBox__rate">(.*?)<\/span>/,
    prob => qr/<span class="recommendBox__level">(.*?)%<\/span>/,
);
my $data;

my $page = 0;
while (1) {
    print( "Page " . ( $page + 1 ) . "...\n" );
    $rp = $mech->get(
        'https://www.filmweb.pl/user/Czupakobra/wantToSee?page=' . $page );
    if ( !$rp->is_success ) {
        print 'ERR';
        exit;
    }

    $content = $rp->decoded_content;
    if ( $content
        =~ /<script>IRI\.globals\.waitingModule\.setPartLoaded\("USER_VOTES_RESULTS"\);<\/script>(.*?)<div class="userVotesPage__paginator/
      ) {
        $content = $1;
        if ( !$content ) {
            print "Total Pages: " . ( $page + 1 ) . "\n";
            last;
        }
    } else {
        print "Total Pages: " . ( $page + 1 ) . "\n";
        last;
    }

    for my $rec (
        split(
            "<div class=\"voteBoxes__box userVotesPage__result __FiltersResult animatedPopList__item\"",
            $content
        )
      ) {

        if ( $rec =~ /<div class="filmPreview__originalTitle">(.*?)<\/div>/ ) {
            my $title = $1;
            $data->{$title} = {};
            for my $key ( keys %map ) {
                if ( $rec =~ $map{$key} ) {
                    $data->{$title}->{$key} = $1;
                }
            }
        }
    }
    $page++;
}
printf( "Summary [ToSee: %d]\n", scalar keys %{$data}, );

open my $fh, q{>}, "$script_path/filmweb-$date.json"
  or die("Cannot open: $script_path/filmweb-$date.json");
print $fh JSON->new->utf8->pretty->canonical->encode($data);
close $fh;
