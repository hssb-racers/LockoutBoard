function CaptureQuest(){
	var quest = $(this)
	var board_id = quest.closest('[data-boardid]').data('boardid');
	var quest_id = quest.attr('id').replace('quest-','');

	console.log("board id: "+ board_id);
	console.log("quest id: "+ quest_id);

	$.ajax({
		url: `/api/capture/${board_id}/${quest_id}`,
		dataType: "json",
		cache: false,
	}).done(function(){
		location.replace(location.href);
	}).always(function(data,state){
		console.log("data:",data);
		console.log("state:",state);
	});
}

$(document).ready(function(){
	$('body')
		.on('click', '#board .quest', CaptureQuest)
	;
});

