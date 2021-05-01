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

true;
