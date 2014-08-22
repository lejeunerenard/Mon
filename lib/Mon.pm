package Mon;
use Dancer ':syntax';
use DBICSugar;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
print STDERR "Artists: ".Dumper(Artist)."\n";
Artist->create({
      name => 'Arnold',
   });
print STDERR "Artists: ".Dumper(Artist)."\n";
    template 'index';
};

load 'Users.pm';

true;
