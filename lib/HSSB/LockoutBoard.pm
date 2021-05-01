package HSSB::LockoutBoard;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::Extensible;
use YAML ();
use List::Gen;
use String::Random qw(random_regex);

our $VERSION = '0.1';

our @possible_objectives = @{ YAML::LoadFile( 'data/objectives.yaml' ) };

get '/' => sub {
	template 'index' => { 'title' => 'HSSB::LockoutBoard' };
};

get '/board/generate/:size' => require_login sub {
	my $size = param 'size';
	send_error("Only sizes 9 and 25 are supported right now",400) unless grep { $size eq $_ } qw{9 25};

	# TODO: check for ID collisions
	my $board_id = random_regex('[A-Za-z0-9]{32}');

	my $stmt = database->prepare('insert into boardobjectives (board,objective,objective_index) values (?,?,?)');

	my $i = 0;
	foreach my $objective (List::Gen::makegen(@possible_objectives)->pick($size)){
		$stmt->execute($board_id, $objective->{objective}, $i++);
	}

	return redirect( "/board/$board_id" );
};

get '/board/:board' => require_login sub {
	my $board_id = param 'board';

	my @objectives = database->quick_select('scored_board', { board => $board_id }, { order_by => 'objective_index'});

	send_error("board not found", 404) unless scalar @objectives;

	my $team = database->quick_lookup('teammembers', { board => $board_id, player => logged_in_user->{'username'} }, 'team');

	template 'board' => {
		'title' => 'HSSB::LockoutBoard',
		objectives => \@objectives,
		board_id => $board_id,
		this_team => $team,
	};
};

get '/register' => sub {
	template 'register' => { title => "HSSB::LockoutBoard Sign-Up"};
};
post '/register' => sub {
	my $user = body_parameters->get('username');
	my $pass = body_parameters->get('password');
	my $rpwd = body_parameters->get('password-repeat');
	send_error "username required" unless $user;
	send_error "password required" unless $pass;
	send_error "repeated password doesn't match" unless $pass eq $rpwd;

	send_error "user already exists" if get_user_details $user;

	create_user username => $user;
	user_password username => $user, new_password => $pass;

	redirect '/';
};

get '/authtest' => require_login sub {
	return "Authenticated successfully!";
};


true;
