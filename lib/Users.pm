package Users;
use Dancer ':syntax';
use DBICSugar;

my %tmpl_params;

prefix '/users' => sub {
   # -- CRUD --
   get '/?:id?' => sub {
      if ( param 'id' ) {
         $tmpl_params{user} = Users->find(param 'id');
         template 'user/user_read', \%tmpl_params;
      } else {
         $tmpl_params{users} = \@{[User->search({},{
            order_by => {
               -asc => [qw/last_name first_name/],
            }
         })->all]};
         template 'user/user_list', \%tmpl_params;
      }
   };
   put '/?' => sub {
      my %params = params;
      my $user = Users->find(param 'id')->update(\%params);
      return { success => [ { success => "user updated Successfully" }  ]  };
   };
   # -- Views --
   get '/login' => sub {
      template 'users/login';
   };
   
};
1;

#fajskdlfjlasdf
#
