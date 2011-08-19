(function($) {
	$(function() {
		$('#login-form input.text').focus(function() {
			var $this = $(this);
			$('span', $this.parent()).addClass('faded');
		}).blur(function() {
			var $this = $(this);
			if ($this.val() === '') {
				$('span', $this.parent()).removeClass('faded').show();
			}
		}).keydown(function() {
			var $this = $(this);
			$('span', $this.parent()).hide();
		}).keyup(function() {
			var $this = $(this);
			if ($this.val() === '') {
				$('span', $this.parent()).show();
			} else {
				$('span', $this.parent()).hide();
			}
		}).each(function() {
			var $this = $(this);
			if ($this.val() !== '') {
				$('span', $this.parent()).hide();
			}
		});
		$('#login form').submit(function() {
			var $this = $(this);
			$.ajax({
				url: $this.attr('action'),
				type: "POST",
				data:$this.serialize(),
				success: function(data) {
					if (data.key) {
						Spontaneous.Auth.Key.save(Spontaneous.site_id, data.key);
						window.location.href = data.redirect;
					}
				},
				error: function() {
					$('#failure-message').fadeOut(function() {
						$('#failed-name').text($('#user-login').val());
						$(this).fadeIn();
					});
					$("#error-message:hidden").slideDown(200);
				},
				dataType: 'json'
			});
			return false;
		});

		$('#login-form input#user-login').focus();
	});
}(jQuery));
