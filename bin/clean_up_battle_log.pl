use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;
my $date_ended = DateTime->now->subtract( days => 7 );

out('Loading DB');
our $db = Lacuna->db;

out('Deleting Old Battle Logs');
$mail->search({ date_stamp => { '<' => $date_ended }})->delete_all;

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

