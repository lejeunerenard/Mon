package DBICSugar;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

use Dancer::Plugin::DBIC;
use Data::Dumper;

my $source_registrations = schema->source_registrations;
foreach my $source ( keys %{ $source_registrations } ) {
   print "[DBICSugar] Registerd Result : ".$source_registrations->{$source}->source_name."\n";
   register $source_registrations->{$source}->source_name => sub {
      return $source_registrations->{$source}->resultset;
   }
}

register_plugin;
1;

__END__
