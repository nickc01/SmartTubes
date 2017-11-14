



function init()
	message.setHandler("Destroy", function()
		projectile.die();
	end);
end
