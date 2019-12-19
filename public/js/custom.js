////////////////////////////////////////////////////////////////////////////////////////
/////////////////// on change select month ////////////////////////////////////////
    //////////////////    from sfm to efm    ////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////


    $(document).on("change", "#sfm", function(){
	var sfm = $(this).val();
	var new_icm = document.getElementById("ic_month").value;  

	$.ajax({
	    url: "/welcome/home",
	    method: "GET",
	    dataType: "json",
	    data: {sfm: sfm, new_icm: new_icm},
	    error: function (xhr, status, error) {
		console.error('AJAX Error: ' + status + error);
	    },
	    success: function (response) {
		console.log(response);
		var efm = response["efm"];
		$("#efm").empty();

		$("#efm").append('<option>Select end month</option>');
		for(var i=0; i< efm.length; i++){
		    $("#efm").append('<option value="' + efm[i]+ '">' + efm[i] + '</option>');
		}
	    }
	});
    });



////////////////////////////////////////////////////////////////////////////////////////
/////////////////// on change select month ////////////////////////////////////////
    //////////////////from ic_month to sfm ////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////

    $(document).on("change", "#ic_month", function(){
	var ic_month = $(this).val();

	$.ajax({
	    url: "/welcome/home",
	    method: "GET",
	    dataType: "json",
	    data: {ic_month: ic_month},
	    error: function (xhr, status, error) {
		console.error('AJAX Error: ' + status + error);
	    },
	    success: function (response) {
		console.log(response);
		var sfm = response["sfm"];
		$("#sfm").empty();

		$("#sfm").append('<option>Select start month</option>');
		for(var i=0; i< sfm.length; i++){
		    $("#sfm").append('<option value="' + sfm[i]+ '">' + sfm[i] + '</option>');
		}
	    }
	});
    });



/////////////////////////////////////////////////////////////////////////////////////////////////////////////





    $(".js-height-full").height($(window).height());
$(".js-height-parent").each(function() {
    $(this).height($(this).parent().first().height());
});


// Fun Facts
function count($this) {
    var current = parseInt($this.html(), 10);
    current = current + 1; /* Where 50 is increment */

    $this.html(++current);
    if (current > $this.data('count')) {
	$this.html($this.data('count'));
    } else {
	setTimeout(function() {
	    count($this)
	}, 50);
    }
}

$(".stat-timer").each(function() {
    $(this).data('count', parseInt($(this).html(), 10));
    $(this).html('0');
    count($(this));
});



$('.header').affix({
    offset: {
	top: 100,
	bottom: function() {
	    return (this.bottom = $('.footer').outerHeight(true))
	}
    }
})

$(window).load(function() {
    $("#preloader").on(500).fadeOut();
    $(".preloader").on(600).fadeOut("slow");
});
