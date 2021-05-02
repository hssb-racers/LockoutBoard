package HSSB::LockoutBoard::API;
use Dancer2;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::Extensible;
set serializer => 'JSON';

get '/capture/:board/:objID' => require_login sub {
	my $board_id = param 'board';
	my $objID = param 'objID';
	my $player = logged_in_user->{'username'};

	send_error("non-teammates are not allowed to capture items",403) unless database->quick_count(
			'teammembers',
			{
				board => $board_id,
				player => $player,
			}
		);
	
	my $count = database->quick_count('boardobjectives', { board => $board_id, objective_index => int($objID) });
	error "found $count rows in table";
	send_error("board or objective not found", 400) unless $count == 1;

	my $result = database->quick_update('boardobjectives',
		{ board => $board_id, objective_index => $objID, captured_by => undef },
		{ captured_by => $player, capture_utctime => \'datetime("now")'}
	);

	if( defined $result ){
		return {state=>"OK"} if $result == 1;
		return {state=>"not OK"};
	}
	send_error "something went wrong in the DB";
};

get '/board/:board' => sub {
	my $board_id = param 'board';
	my $username;
	if( defined logged_in_user ){
		$username = logged_in_user->{'username'};
	}

	# this has a fallback to team 1, so non-players get defaulted there
	my $team = database->quick_lookup( 'teammembers', { board => $board_id, player => $username, }, "team") // '1';

	my @objectives = database->quick_select('scored_board', { board => $board_id }, { order_by => 'objective_index', columns => ['captured_by_team', 'objective_index']});
	foreach my $obj (@objectives){
		$obj->{capture_state} = defined $obj->{captured_by_team} ? $obj->{captured_by_team} == $team ? 'true' : 'false' : 'uncaptured';
	}

	my $our_score = grep { $_->{captured_by_team} == $team } @objectives;
	my $uncaptured_score = grep { !defined $_->{captured_by_team} } @objectives;
	my $their_score = (scalar @objectives) - $uncaptured_score - $our_score;

	return {
		board_state => database->quick_lookup( 'boards', { board => $board_id, }, 'state'),
		objectives => \@objectives,
		scores => {
			ours => $our_score,
			theirs => $their_score,
			nobodys => $uncaptured_score,
		}
	};
};



true;
