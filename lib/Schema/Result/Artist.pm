package Schema::Result::Artist;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
   'id' => {
      data_type => 'integer',
   },
   'name' => {
      data_type => 'varchar',
      size => '96',
   }
);

__PACKAGE__->set_primary_key('id');
 1;
